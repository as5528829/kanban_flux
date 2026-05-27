import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../controllers/task_controller.dart';

// 💡 升級為 ConsumerWidget 以便使用 Riverpod 的 ref
class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: task.description.isNotEmpty ? Text(task.description) : null,
        // 💡 右側加上一個按鈕選單，點擊可以直接切換狀態
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String newStatus) async {
            // 💡 呼叫 Controller 變更狀態
            await ref.read(taskControllerProvider.notifier).updateStatus(task.id, newStatus);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'todo',
              child: Text('移至 待辦事項'),
            ),
            const PopupMenuItem<String>(
              value: 'in_progress',
              child: Text('移至 進行中'),
            ),
            const PopupMenuItem<String>(
              value: 'done',
              child: Text('移至 已完成'),
            ),
          ],
        ),
      ),
    );
  }
}