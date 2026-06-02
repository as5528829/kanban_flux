import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart'; // 💡 引入 auth_controller
import '../../data/datasources/task_remote_data_source.dart';
import '../../domain/entities/task.dart';

part 'task_controller.g.dart';

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
      return false;
    }
  }

  /// 變更狀態（保持不變，因為 RLS 會自動幫我們用 user.id 在後端校驗）
  Future<bool> updateStatus(String id, String newStatus) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    try {
      await _dataSource.updateTaskStatus(id, newStatus);
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
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
      return false;
    }
  }

  // 💡 增加一個專門用來刪除任務的方法
  Future<bool> deleteTask(String id) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return false;

    try {
      await _dataSource.deleteTask(id);
      await _refreshTasks(user.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshTasks(String userId) async {
    state = AsyncData(await _dataSource.getTasks(userId));
  }
}
