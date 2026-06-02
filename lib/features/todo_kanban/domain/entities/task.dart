class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;
  final List<String> labels;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.labels,
    required this.createdAt,
  });
}
