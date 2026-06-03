import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_snackbar.dart';
import '../../domain/entities/task.dart';
import 'task_card.dart';
import '../controllers/task_controller.dart';

class KanbanColumn extends ConsumerWidget {
  final String title;
  final String status;
  final List<Task> tasks;
  final double width; // 💡 修正點 1：確實宣告 width 變數
  final VoidCallback? onCreateTask;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.status,
    required this.tasks,
    required this.width, // 💡 修正點 2：在建構子內要求傳入 width
    this.onCreateTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💡 加上 WidgetRef ref
    final filteredTasks = tasks.where((task) => task.status == status).toList()
      ..sort((a, b) {
        final positionCompare = a.position.compareTo(b.position);
        if (positionCompare != 0) return positionCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

    // 💡 核心升級：將原本的 Container 包裹進 DragTarget 中
    return DragTarget<Task>(
      // 1. 當卡片飄到這條直欄上方時，是否願意接收它？（如果卡片原本的狀態就跟直欄一樣，就不需要重複接收）
      onWillAcceptWithDetails: (details) => details.data.status != status,

      // 2. 當使用者放開滑鼠、把卡片「啪」一聲丟進來這欄時觸發：
      onAcceptWithDetails: (details) async {
        final droppedTask = details.data;
        // 🚀 呼叫我們之前寫好的狀態變更函數，直接把卡片送到新的狀態欄位，Supabase 也會秒更新！
        final moved = await ref
            .read(taskControllerProvider.notifier)
            .updateStatus(droppedTask.id, status);
        showAppSnackBar(moved ? '已移到$title' : '移動任務失敗，已還原', isError: !moved);
      },

      // 3. 畫面渲染：isOver 代表目前有沒有卡片「正懸浮在這一欄上方」，可以用來做高階的視覺特效！
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200), // 絲滑的過渡動畫
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            // 💡 超級加分細節：當卡片懸浮在上方時，欄位背景顏色會微微變深（Slate 200），提示使用者這裡可以放開！
            color: isOver ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOver ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isOver ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欄位頭部
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status == 'todo'
                            ? Colors.orange
                            : status == 'in_progress'
                            ? Colors.blue
                            : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredTasks.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isOver)
                      const Text(
                        '放開即可移動',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                  ],
                ),
              ),
              // 任務卡片列表
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '把任務拖到這裡',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (onCreateTask != null) ...[
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      onPressed: onCreateTask,
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('新增到這欄'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          return _SortableTaskItem(
                            key: ValueKey(task.id),
                            task: task,
                            canMoveUp: index > 0,
                            canMoveDown: index < filteredTasks.length - 1,
                            onMoveUp: () async {
                              final reorderedTasks = [...filteredTasks];
                              final movedTask = reorderedTasks.removeAt(index);
                              reorderedTasks.insert(index - 1, movedTask);
                              await _saveOrder(ref, reorderedTasks);
                            },
                            onMoveDown: () async {
                              final reorderedTasks = [...filteredTasks];
                              final movedTask = reorderedTasks.removeAt(index);
                              reorderedTasks.insert(index + 1, movedTask);
                              await _saveOrder(ref, reorderedTasks);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveOrder(WidgetRef ref, List<Task> reorderedTasks) async {
    final reordered = await ref
        .read(taskControllerProvider.notifier)
        .reorderTasks(reorderedTasks);

    showAppSnackBar(
      reordered ? '任務排序已更新' : '更新任務排序失敗，已還原',
      isError: !reordered,
    );
  }
}

class _SortableTaskItem extends StatelessWidget {
  final Task task;
  final bool canMoveUp;
  final bool canMoveDown;
  final Future<void> Function() onMoveUp;
  final Future<void> Function() onMoveDown;

  const _SortableTaskItem({
    super.key,
    required this.task,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TaskCard(task: task),
        Positioned(
          top: 10,
          right: 52,
          child: Row(
            children: [
              _SortButton(
                icon: Icons.keyboard_arrow_up_rounded,
                tooltip: '上移',
                enabled: canMoveUp,
                onPressed: onMoveUp,
              ),
              const SizedBox(width: 4),
              _SortButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: '下移',
                enabled: canMoveDown,
                onPressed: onMoveDown,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Future<void> Function() onPressed;

  const _SortButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 18,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.55),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
      ),
    );
  }
}
