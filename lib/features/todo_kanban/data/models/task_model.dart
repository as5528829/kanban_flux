import '../../domain/entities/task.dart';

class TaskModel extends Task {
  TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.createdAt,
  });

  // 把 Supabase 傳回來的 Map (JSON) 轉換成我們的 TaskModel 物件
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // 把我們的物件轉換成 Map (JSON)，方便之後傳給 Supabase 儲存
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}