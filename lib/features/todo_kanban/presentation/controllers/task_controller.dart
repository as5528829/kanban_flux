import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart'; // 💡 引入 auth_controller
import '../../data/datasources/task_remote_data_source.dart';
import '../../domain/entities/task.dart';
import '../../domain/errors/task_failure.dart';

part 'task_controller.g.dart';

final taskSyncStatusProvider =
    NotifierProvider<TaskSyncController, TaskSyncState>(TaskSyncController.new);

enum TaskSyncStatus { idle, syncing, synced, failed }

enum TaskSyncSource { local, manual, realtime }

class TaskSyncState {
  final TaskSyncStatus status;
  final DateTime? lastSyncedAt;
  final TaskFailure? failure;
  final TaskSyncSource? source;

  const TaskSyncState({
    required this.status,
    this.lastSyncedAt,
    this.failure,
    this.source,
  });
}

class TaskSyncController extends Notifier<TaskSyncState> {
  @override
  TaskSyncState build() => const TaskSyncState(status: TaskSyncStatus.idle);

  void setSyncing() {
    state = TaskSyncState(
      status: TaskSyncStatus.syncing,
      lastSyncedAt: state.lastSyncedAt,
      source: state.source,
    );
  }

  void setSynced({TaskSyncSource source = TaskSyncSource.local}) {
    state = TaskSyncState(
      status: TaskSyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      source: source,
    );
  }

  void setFailed(TaskFailure failure) {
    state = TaskSyncState(
      status: TaskSyncStatus.failed,
      lastSyncedAt: state.lastSyncedAt,
      failure: failure,
      source: state.source,
    );
  }
}

@riverpod
class TaskController extends _$TaskController {
  static const _syncTimeout = Duration(seconds: 15);
  static const _realtimeDebounceDuration = Duration(milliseconds: 500);

  late final TaskRemoteDataSource _dataSource = TaskRemoteDataSource(
    Supabase.instance.client,
  );
  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;
  String? _subscribedUserId;
  bool _isLocalMutationInProgress = false;
  bool _isDisposed = false;
  bool _disposeRegistered = false;

  @override
  FutureOr<List<Task>> build() async {
    // 💡 外商高級技巧：利用 ref.watch 監聽 authController
    // 只要登入的使用者一變動（或登出），這個看板就會自動重新載入！
    final user = ref.watch(authControllerProvider);

    // 如果沒登入，看板直接回傳空列表（防呆）
    if (user == null) {
      _unsubscribeRealtime();
      return [];
    }

    // 有登入，就只撈這個使用者的 tasks
    try {
      final tasks = await _dataSource.getTasks(user.id).timeout(_syncTimeout);
      if (ref.mounted) await _subscribeToRealtime(user.id);
      return tasks;
    } catch (error) {
      throw friendlyTaskFailure(error);
    }
  }

  /// 新增任務
  Future<bool> addTask(
    String title,
    String description, {
    String status = 'todo',
    String priority = 'medium',
    DateTime? dueDate,
    List<String> labels = const [],
  }) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    return _runMutation(() async {
      await _dataSource
          .createTask(
            title,
            description,
            status,
            priority,
            dueDate,
            labels,
            user.id,
          )
          .timeout(_syncTimeout);
      await _refreshTasks(user.id);
    });
  }

  /// 變更狀態（保持不變，因為 RLS 會自動幫我們用 user.id 在後端校驗）
  Future<bool> updateStatus(String id, String newStatus) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    return _runMutation(() async {
      await _dataSource.updateTaskStatus(id, newStatus).timeout(_syncTimeout);
      await _refreshTasks(user.id);
    });
  }

  // 💡 增加一個專門用來編輯任務內容的方法
  Future<bool> updateTaskContent(
    String id,
    String newTitle,
    String newDescription,
    String status,
    String priority,
    DateTime? dueDate,
    List<String> labels,
  ) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    return _runMutation(() async {
      await _dataSource
          .updateTaskContent(
            id,
            newTitle,
            newDescription,
            status,
            priority,
            dueDate,
            labels,
          )
          .timeout(_syncTimeout);
      await _refreshTasks(user.id);
    });
  }

  // 💡 增加一個專門用來刪除任務的方法
  Future<bool> deleteTask(String id) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    return _runMutation(() async {
      await _dataSource.deleteTask(id).timeout(_syncTimeout);
      await _refreshTasks(user.id);
    });
  }

  Future<bool> restoreDeletedTask(Task task) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    return _runMutation(() async {
      await _dataSource.restoreTask(task, user.id).timeout(_syncTimeout);
      await _refreshTasks(user.id);
    });
  }

  Future<bool> reorderTasks(List<Task> orderedTasks) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    final previousTasks = state.asData?.value;
    if (previousTasks == null) return false;

    final reorderedIds = orderedTasks.map((task) => task.id).toSet();
    final repositionedTasks = [
      for (var index = 0; index < orderedTasks.length; index++)
        _copyTaskWithPosition(orderedTasks[index], index),
    ];

    final nextTasks = [
      for (final task in previousTasks)
        if (!reorderedIds.contains(task.id)) task,
      ...repositionedTasks,
    ];
    state = AsyncData(nextTasks);
    _isLocalMutationInProgress = true;
    _setSyncing();

    try {
      await _dataSource
          .updateTaskPositions(orderedTasks.map((task) => task.id).toList())
          .timeout(_syncTimeout);
      await _refreshTasks(user.id);
      return true;
    } catch (error) {
      state = AsyncData(previousTasks);
      _setFailed(error);
      return false;
    } finally {
      _isLocalMutationInProgress = false;
    }
  }

  Future<bool> refreshTasks() async {
    final user = ref.read(authControllerProvider);
    if (user == null) {
      _setFailed(
        const TaskFailure(
          type: TaskFailureType.authExpired,
          message: '登入狀態已過期，請重新登入。',
        ),
      );
      return false;
    }

    try {
      _setSyncing();
      await _refreshTasks(user.id, source: TaskSyncSource.manual);
      return true;
    } catch (error) {
      _setFailed(error);
      return false;
    }
  }

  Future<bool> _runMutation(Future<void> Function() mutation) async {
    _isLocalMutationInProgress = true;
    try {
      _setSyncing();
      await mutation();
      return true;
    } catch (error) {
      _setFailed(error);
      return false;
    } finally {
      _isLocalMutationInProgress = false;
    }
  }

  Future<void> _refreshTasks(
    String userId, {
    TaskSyncSource source = TaskSyncSource.local,
  }) async {
    state = AsyncData(await _dataSource.getTasks(userId).timeout(_syncTimeout));
    ref.read(taskSyncStatusProvider.notifier).setSynced(source: source);
  }

  Future<void> _subscribeToRealtime(String userId) async {
    if (_subscribedUserId == userId && _realtimeChannel != null) return;

    _registerDispose();
    final client = Supabase.instance.client;
    await client.realtime.setAuth(client.auth.currentSession?.accessToken);
    if (!ref.mounted) return;

    final oldChannel = _realtimeChannel;
    if (oldChannel != null) {
      unawaited(client.removeChannel(oldChannel));
    }

    _subscribedUserId = userId;
    _realtimeChannel = client
        .channel(
          'tasks:$userId',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: '*',
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .subscribe((status, error) {
          if (_isDisposed || _subscribedUserId != userId) return;
          if (status == RealtimeSubscribeStatus.channelError) {
            _setFailed(
              TaskFailure(
                type: TaskFailureType.schema,
                message: '即時同步連線失敗，請確認已執行 Realtime migration。',
                cause: error,
              ),
            );
          } else if (status == RealtimeSubscribeStatus.timedOut) {
            _setFailed(
              TaskFailure(
                type: TaskFailureType.timeout,
                message: '即時同步連線逾時，請稍後重新整理。',
                cause: error,
              ),
            );
          }
        });
  }

  void _unsubscribeRealtime() {
    _realtimeDebounce?.cancel();
    _subscribedUserId = null;
    final channel = _realtimeChannel;
    _realtimeChannel = null;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
  }

  void _scheduleRealtimeRefresh(String userId) {
    if (_isDisposed || _isLocalMutationInProgress) return;

    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(_realtimeDebounceDuration, () {
      if (_isDisposed || _isLocalMutationInProgress) return;
      unawaited(_refreshFromRealtime(userId));
    });
  }

  Future<void> _refreshFromRealtime(String userId) async {
    final currentUser = ref.read(authControllerProvider);
    if (_isDisposed || currentUser?.id != userId) return;

    try {
      final tasks = await _dataSource.getTasks(userId).timeout(_syncTimeout);
      if (_isDisposed) return;
      state = AsyncData(tasks);
      ref
          .read(taskSyncStatusProvider.notifier)
          .setSynced(source: TaskSyncSource.realtime);
    } catch (error) {
      if (!_isDisposed) _setFailed(error);
    }
  }

  void _registerDispose() {
    if (_disposeRegistered) return;
    _disposeRegistered = true;
    ref.onDispose(() {
      _isDisposed = true;
      _unsubscribeRealtime();
    });
  }

  void _setSyncing() {
    ref.read(taskSyncStatusProvider.notifier).setSyncing();
  }

  void _setFailed(Object error) {
    ref
        .read(taskSyncStatusProvider.notifier)
        .setFailed(friendlyTaskFailure(error));
  }

  Task _copyTaskWithPosition(Task task, int position) {
    return Task(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      labels: task.labels,
      position: position,
      createdAt: task.createdAt,
    );
  }
}
