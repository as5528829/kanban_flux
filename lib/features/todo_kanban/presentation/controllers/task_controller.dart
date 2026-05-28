import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart'; // 💡 引入 auth_controller
import '../../data/datasources/task_remote_data_source.dart';
import '../../domain/entities/task.dart';

part 'task_controller.g.dart';

@riverpod
class TaskController extends _$TaskController {
  late final TaskRemoteDataSource _dataSource;

  @override
  FutureOr<List<Task>> build() async {
    _dataSource = TaskRemoteDataSource(Supabase.instance.client);

    // 💡 外商高級技巧：利用 ref.watch 監聽 authController
    // 只要登入的使用者一變動（或登出），這個看板就會自動重新載入！
    final user = ref.watch(authControllerProvider);

    // 如果沒登入，看板直接回傳空列表（防呆）
    if (user == null) return [];

    // 有登入，就只撈這個使用者的 tasks
    return _dataSource.getTasks(user.id);
  }

  /// 新增任務
  Future<void> addTask(String title, String description) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 新增時帶入目前登入者的 id
      await _dataSource.createTask(title, description, user.id);
      return _dataSource.getTasks(user.id);
    });
  }

  /// 變更狀態（保持不變，因為 RLS 會自動幫我們用 user.id 在後端校驗）
  Future<void> updateStatus(String id, String newStatus) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _dataSource.updateTaskStatus(id, newStatus);
      return _dataSource.getTasks(user.id);
    });
  }
}