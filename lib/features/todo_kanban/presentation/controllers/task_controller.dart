import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart'; // 💡 引入 auth_controller
import '../../data/datasources/task_remote_data_source.dart';
import '../../domain/entities/task.dart';

part 'task_controller.g.dart';

final taskSyncStatusProvider =
    NotifierProvider<TaskSyncController, TaskSyncState>(TaskSyncController.new);

enum TaskSyncStatus { idle, syncing, synced, failed }

class TaskSyncState {
  final TaskSyncStatus status;
  final DateTime? lastSyncedAt;

  const TaskSyncState({required this.status, this.lastSyncedAt});
}

class TaskSyncController extends Notifier<TaskSyncState> {
  @override
  TaskSyncState build() => const TaskSyncState(status: TaskSyncStatus.idle);

  void setStatus(TaskSyncStatus status) {
    state = TaskSyncState(
      status: status,
      lastSyncedAt: status == TaskSyncStatus.synced
          ? DateTime.now()
          : state.lastSyncedAt,
    );
  }
}

@riverpod
class TaskController extends _$TaskController {
  final TaskRemoteDataSource _dataSource = TaskRemoteDataSource(
    Supabase.instance.client,
  );

  @override
  FutureOr<List<Task>> build() async {
    // 💡 外商高級技巧：利用 ref.watch 監聽 authController
    // 只要登入的使用者一變動（或登出），這個看板就會自動重新載入！
    final user = ref.watch(authControllerProvider);

    // 如果沒登入，看板直接回傳空列表（防呆）
    if (user == null) return [];

    // 有登入，就只撈這個使用者的 tasks
    return _dataSource.getTasks(user.id);
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

    try {
      _setSyncStatus(TaskSyncStatus.syncing);
      await _dataSource.createTask(
        title,
        description,
        status,
        priority,
        dueDate,
        labels,
        user.id,
      );
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
  }

  /// 變更狀態（保持不變，因為 RLS 會自動幫我們用 user.id 在後端校驗）
  Future<bool> updateStatus(String id, String newStatus) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    try {
      _setSyncStatus(TaskSyncStatus.syncing);
      await _dataSource.updateTaskStatus(id, newStatus);
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
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

    try {
      _setSyncStatus(TaskSyncStatus.syncing);
      await _dataSource.updateTaskContent(
        id,
        newTitle,
        newDescription,
        status,
        priority,
        dueDate,
        labels,
      );
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
  }

  // 💡 增加一個專門用來刪除任務的方法
  Future<bool> deleteTask(String id) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    try {
      _setSyncStatus(TaskSyncStatus.syncing);
      await _dataSource.deleteTask(id);
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
  }

  Future<bool> restoreDeletedTask(Task task) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    try {
      _setSyncStatus(TaskSyncStatus.syncing);
      await _dataSource.restoreTask(task, user.id);
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
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
    _setSyncStatus(TaskSyncStatus.syncing);

    try {
      await _dataSource.updateTaskPositions(
        orderedTasks.map((task) => task.id).toList(),
      );
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      state = AsyncData(previousTasks);
      _setSyncStatus(TaskSyncStatus.failed);
      return false;
    }
  }

  Future<void> _refreshTasks(String userId) async {
    state = AsyncData(await _dataSource.getTasks(userId));
    _setSyncStatus(TaskSyncStatus.synced);
  }

  void _setSyncStatus(TaskSyncStatus status) {
    ref.read(taskSyncStatusProvider.notifier).setStatus(status);
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
