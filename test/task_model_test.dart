import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/features/todo_kanban/data/models/task_model.dart';

void main() {
  group('TaskModel.fromJson', () {
    test('uses defaults when UI metadata fields are missing', () {
      final task = TaskModel.fromJson({
        'id': 'task-1',
        'title': 'Design board',
        'description': null,
        'status': 'todo',
        'created_at': '2026-06-02T08:00:00.000Z',
      });

      expect(task.priority, 'medium');
      expect(task.dueDate, isNull);
      expect(task.labels, isEmpty);
      expect(task.position, 0);
      expect(task.description, '');
    });

    test('parses labels from dynamic lists', () {
      final task = TaskModel.fromJson({
        'id': 'task-2',
        'title': 'Ship filter chips',
        'description': 'Search and filters',
        'status': 'in_progress',
        'priority': 'high',
        'due_date': null,
        'labels': ['frontend', 'urgent'],
        'position': 3,
        'created_at': '2026-06-02T08:00:00.000Z',
      });

      expect(task.priority, 'high');
      expect(task.labels, ['frontend', 'urgent']);
      expect(task.position, 3);
    });

    test('parses due_date when present', () {
      final task = TaskModel.fromJson({
        'id': 'task-3',
        'title': 'Review polish',
        'description': '',
        'status': 'done',
        'priority': 'low',
        'due_date': '2026-06-05',
        'labels': [],
        'position': 1,
        'created_at': '2026-06-02T08:00:00.000Z',
      });

      expect(task.dueDate, DateTime(2026, 6, 5));
    });
  });
}
