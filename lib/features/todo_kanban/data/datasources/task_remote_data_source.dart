import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  final SupabaseClient _supabaseClient;

  // 透過建構子注入 SupabaseClient，這樣以後寫測試（Mock）會非常方便
  TaskRemoteDataSource(this._supabaseClient);

  /// 1. 只撈取屬於目前登入使用者的任務
  Future<List<TaskModel>> getTasks(String userId) async {
    try {
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', userId) // 💡 關鍵：過濾出 user_id 等於目前登入者 ID 的資料
          .order('created_at', ascending: false);

      return (response as List)
          .map((taskJson) => TaskModel.fromJson(taskJson))
          .toList();
    } catch (e) {
      throw Exception('無法取得您的專屬任務資料: $e');
    }
  }

  /// 2. 新增任務時，自動塞入目前使用者的 user_id
  Future<TaskModel> createTask(
    String title,
    String description,
    String status,
    String priority,
    DateTime? dueDate,
    List<String> labels,
    String userId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'status': status,
            'priority': priority,
            'due_date': _formatDate(dueDate),
            'labels': labels,
            'user_id': userId, // 💡 關鍵：明確告訴後端這張卡片是誰建的
          })
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('新增任務失敗: $e');
    }
  }

  /// 3. 更新雲端任務的狀態 (todo -> in_progress -> done)
  Future<TaskModel> updateTaskStatus(String id, String newStatus) async {
    try {
      final response = await _supabaseClient
          .from('tasks')
          .update({'status': newStatus}) // 要更新的欄位與值
          .eq('id', id) // 條件：過濾出對應的 id
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('雲端更新任務狀態失敗: $e');
    }
  }

  /// 4. 更新任務標題與描述
  Future<TaskModel> updateTaskContent(
    String id,
    String title,
    String description,
    String status,
    String priority,
    DateTime? dueDate,
    List<String> labels,
  ) async {
    try {
      final response = await _supabaseClient
          .from('tasks')
          .update({
            'title': title,
            'description': description,
            'status': status,
            'priority': priority,
            'due_date': _formatDate(dueDate),
            'labels': labels,
          })
          .eq('id', id)
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('更新任務內容失敗: $e');
    }
  }

  /// 5. 刪除任務
  Future<void> deleteTask(String id) async {
    try {
      await _supabaseClient.from('tasks').delete().eq('id', id);
    } catch (e) {
      throw Exception('刪除任務失敗: $e');
    }
  }

  String? _formatDate(DateTime? date) {
    return date?.toIso8601String().split('T').first;
  }
}
