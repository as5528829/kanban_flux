import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final SupabaseClient _supabaseClient;

  // 透過建構子注入 SupabaseClient，這樣以後寫測試（Mock）會非常方便
  TaskRemoteDataSource(this._supabaseClient);

  /// 1. 從雲端撈取所有任務
  Future<List<TaskModel>> getTasks() async {
    try {
      // 呼叫 Supabase：去 tasks 資料表撈取所有資料，並依照建立時間排序
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .order('created_at', ascending: false);

      // response 是個 List<Map<String, dynamic>>，我們用前面寫好的 fromJson 轉成物件列表
      return (response as List)
          .map((taskJson) => TaskModel.fromJson(taskJson))
          .toList();
    } catch (e) {
      // 外商思維：絕對不要吃掉錯誤，拋出一個有意義的異常
      throw Exception('無法從雲端取得任務資料: $e');
    }
  }

  /// 2. 新增任務到雲端
  Future<TaskModel> createTask(String title, String description) async {
    try {
      // 呼叫 Supabase：插入一筆新資料
      final response = await _supabaseClient.from('tasks').insert({
        'title': title,
        'description': description,
        'status': 'todo', // 預設新任務都是 todo
      }).select().single(); // .single() 代表我們只要回傳的那一筆資料

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('雲端新增任務失敗: $e');
    }
  }
  /// 3. 更新雲端任務的狀態 (todo -> in_progress -> done)
  Future<TaskModel> updateTaskStatus(String id, String newStatus) async {
    try {
      final response = await _supabaseClient
          .from('tasks')
          .update({'status': newStatus}) // 要更新的欄位與值
          .eq('id', id)                  // 條件：過濾出對應的 id
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('雲端更新任務狀態失敗: $e');
    }
  }
}