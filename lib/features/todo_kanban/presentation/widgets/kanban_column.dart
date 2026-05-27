import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final String status;
  final List<Task> tasks;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.status,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 核心邏輯：只過濾出符合這個欄位狀態（todo/in_progress/done）的任務
    final filteredTasks = tasks.where((task) => task.status == status).toList();

    return Container(
      width: 300, // 固定寬度，方便橫向滑動
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欄位標題與計數
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${filteredTasks.length}'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 任務列表
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: filteredTasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}