import '../../domain/entities/task.dart';

class TaskModel extends Task {
  TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.dueDate,
    required super.labels,
    required super.createdAt,
  });

  // 把 Supabase 傳回來的 Map (JSON) 轉換成我們的 TaskModel 物件
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'medium',
      dueDate: _parseDueDate(json['due_date']),
      labels: _parseLabels(json['labels']),
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
      'priority': priority,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'labels': labels,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime? _parseDueDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  static List<String> _parseLabels(dynamic value) {
    if (value == null) return const [];
    return (value as List).map((label) => label.toString()).toList();
  }
}
