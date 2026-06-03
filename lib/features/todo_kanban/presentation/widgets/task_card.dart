import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_snackbar.dart';
import '../../domain/entities/task.dart';
import '../controllers/task_controller.dart';
import 'task_form_bottom_sheet.dart';

class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.82,
          child: SizedBox(width: 300, child: _buildCardContent(context, ref)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: _buildCardContent(context, ref),
      ),
      child: InkWell(
        onTap: () async {
          final result = await showTaskFormBottomSheet(
            context: context,
            ref: ref,
            task: task,
          );
          if (result != null) {
            await _deleteTaskWithUndo(ref, result.task);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: _buildCardContent(context, ref),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final dueMeta = _dueMeta(task);
    final priorityMeta = _priorityMeta(task.priority);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    onSelected: (newStatus) async {
                      if (newStatus == task.status) return;

                      final updated = await ref
                          .read(taskControllerProvider.notifier)
                          .updateStatus(task.id, newStatus);
                      showAppSnackBar(
                        updated ? '已移到${_statusLabel(newStatus)}' : '移動任務失敗',
                        isError: !updated,
                      );
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'todo', child: Text('待辦事項')),
                      PopupMenuItem(value: 'in_progress', child: Text('進行中')),
                      PopupMenuItem(value: 'done', child: Text('已完成')),
                    ],
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(
                  icon: priorityMeta.icon,
                  label: priorityMeta.label,
                  foreground: priorityMeta.foreground,
                  background: priorityMeta.background,
                ),
                if (dueMeta != null)
                  _Badge(
                    icon: dueMeta.icon,
                    label: dueMeta.label,
                    foreground: dueMeta.foreground,
                    background: dueMeta.background,
                  ),
              ],
            ),
            if (task.labels.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: task.labels
                    .take(4)
                    .map(
                      (label) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  '建立於 ${task.createdAt.month}/${task.createdAt.day}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteTaskWithUndo(WidgetRef ref, Task task) async {
  final taskController = ref.read(taskControllerProvider.notifier);
  final deleted = await taskController.deleteTask(task.id);

  showAppSnackBar(
    deleted ? '任務已刪除' : '刪除任務失敗',
    isError: !deleted,
    actionLabel: deleted ? '復原' : null,
    onAction: deleted ? () => _restoreDeletedTask(taskController, task) : null,
  );
}

Future<void> _restoreDeletedTask(
  TaskController taskController,
  Task task,
) async {
  showAppFeedback(
    '正在復原任務...',
    type: AppFeedbackType.info,
    duration: const Duration(seconds: 1),
  );

  final restored = await taskController.restoreDeletedTask(task);

  showAppSnackBar(restored ? '任務已復原' : '復原任務失敗', isError: !restored);
}

String _statusLabel(String status) {
  return switch (status) {
    'todo' => '待辦',
    'in_progress' => '進行中',
    'done' => '已完成',
    _ => '新欄位',
  };
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _Badge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({IconData icon, String label, Color foreground, Color background})
_priorityMeta(String priority) {
  switch (priority) {
    case 'high':
      return (
        icon: Icons.priority_high_rounded,
        label: '高優先',
        foreground: const Color(0xFFB91C1C),
        background: const Color(0xFFFEE2E2),
      );
    case 'low':
      return (
        icon: Icons.keyboard_arrow_down_rounded,
        label: '低優先',
        foreground: const Color(0xFF047857),
        background: const Color(0xFFD1FAE5),
      );
    default:
      return (
        icon: Icons.drag_handle_rounded,
        label: '中優先',
        foreground: const Color(0xFF475569),
        background: const Color(0xFFE2E8F0),
      );
  }
}

({IconData icon, String label, Color foreground, Color background})? _dueMeta(
  Task task,
) {
  final dueDate = task.dueDate;
  if (dueDate == null) return null;

  final today = DateUtils.dateOnly(DateTime.now());
  final due = DateUtils.dateOnly(dueDate);
  final daysLeft = due.difference(today).inDays;
  final formattedDate = '${due.month}/${due.day}';

  if (task.status != 'done' && daysLeft < 0) {
    return (
      icon: Icons.warning_amber_rounded,
      label: '逾期 $formattedDate',
      foreground: const Color(0xFFB91C1C),
      background: const Color(0xFFFEE2E2),
    );
  }

  if (task.status != 'done' && daysLeft <= 3) {
    return (
      icon: Icons.schedule_rounded,
      label: daysLeft == 0 ? '今天到期' : '$formattedDate 到期',
      foreground: const Color(0xFFB45309),
      background: const Color(0xFFFEF3C7),
    );
  }

  return (
    icon: Icons.event_outlined,
    label: '$formattedDate 到期',
    foreground: const Color(0xFF2563EB),
    background: const Color(0xFFDBEAFE),
  );
}
