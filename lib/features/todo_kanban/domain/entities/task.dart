class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}