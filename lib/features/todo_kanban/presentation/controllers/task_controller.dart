import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../domain/entities/task.dart';

// 這行很重要，是給 Riverpod 自動生成程式碼用的
part 'task_controller.g.dart';

@riverpod
class TaskController extends _$TaskController {

  // 建立一個私有的 Data Source 實例
  late final TaskRemoteDataSource _dataSource;

  @override
  FutureOr<List<Task>> build() async {
    // 初始化 Data Source
    _dataSource = TaskRemoteDataSource(Supabase.instance.client);
    // 預設行為：去雲端撈取資料並回傳
    return _dataSource.getTasks();
  }

  /// 新增任務的 Function
  Future<void> addTask(String title, String description) async {
    // 1. 先將狀態設為「載入中」，讓 UI 知道要轉圈圈（非必要，但體驗較好）
    state = const AsyncLoading();

    // 2. 執行非同步的新增操作
    state = await AsyncValue.guard(() async {
      // 去雲端新增
      await _dataSource.createTask(title, description);
      // 新增成功後，重新去雲端撈最新的列表來更新狀態
      return _dataSource.getTasks();
    });
  }
  /// 變更任務狀態的 Function
  Future<void> updateStatus(String id, String newStatus) async {
    // 1. 先將狀態設為載入中（畫面上會轉圈圈，確保資料同步安全）
    state = const AsyncLoading();

    // 2. 執行安全更新
    state = await AsyncValue.guard(() async {
      // 先在雲端更新狀態
      await _dataSource.updateTaskStatus(id, newStatus);
      // 更新成功後，重新抓取最新的任務列表
      return _dataSource.getTasks();
    });
  }
}