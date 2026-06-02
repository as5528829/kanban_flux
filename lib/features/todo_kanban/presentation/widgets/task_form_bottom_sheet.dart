import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_snackbar.dart';
import '../../domain/entities/task.dart';
import '../controllers/task_controller.dart';

Future<void> showTaskFormBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  Task? task,
  String initialStatus = 'todo',
}) {
  final titleController = TextEditingController(text: task?.title ?? '');
  final descController = TextEditingController(text: task?.description ?? '');
  final labelsController = TextEditingController(
    text: task == null ? '' : task.labels.join(', '),
  );
  var selectedStatus = task?.status ?? initialStatus;
  var selectedPriority = task?.priority ?? 'medium';
  var selectedDueDate = task?.dueDate;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final isEditing = task != null;
          final editingTask = task;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? '編輯任務' : '建立全新任務',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    autofocus: !isEditing,
                    decoration: const InputDecoration(
                      labelText: '任務標題',
                      hintText: '要做些什麼事呢？',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '詳細描述（選填）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '狀態',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    selected: {selectedStatus},
                    onSelectionChanged: (values) {
                      setSheetState(() => selectedStatus = values.first);
                    },
                    segments: const [
                      ButtonSegment(
                        value: 'todo',
                        label: Text('待辦'),
                        icon: Icon(Icons.radio_button_unchecked_rounded),
                      ),
                      ButtonSegment(
                        value: 'in_progress',
                        label: Text('進行中'),
                        icon: Icon(Icons.timelapse_rounded),
                      ),
                      ButtonSegment(
                        value: 'done',
                        label: Text('完成'),
                        icon: Icon(Icons.check_circle_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '優先級',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    selected: {selectedPriority},
                    onSelectionChanged: (values) {
                      setSheetState(() => selectedPriority = values.first);
                    },
                    segments: const [
                      ButtonSegment(
                        value: 'low',
                        label: Text('低'),
                        icon: Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      ButtonSegment(
                        value: 'medium',
                        label: Text('中'),
                        icon: Icon(Icons.drag_handle_rounded),
                      ),
                      ButtonSegment(
                        value: 'high',
                        label: Text('高'),
                        icon: Icon(Icons.priority_high_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_outlined, size: 18),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 5),
                            );

                            if (picked != null) {
                              setSheetState(() => selectedDueDate = picked);
                            }
                          },
                          label: Text(
                            selectedDueDate == null
                                ? '選擇截止日'
                                : _formatDate(selectedDueDate!),
                          ),
                        ),
                      ),
                      if (selectedDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '清除截止日',
                          onPressed: () {
                            setSheetState(() => selectedDueDate = null);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: labelsController,
                    decoration: const InputDecoration(
                      labelText: 'Labels',
                      hintText: '設計, 前端, 緊急',
                      helperText: '以逗號分隔多個標籤',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (isEditing)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                          ),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('刪除'),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('確認刪除'),
                                content: const Text('你確定要刪除這項任務嗎？此操作無法復原。'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('確認刪除'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true) {
                              final deleted = await ref
                                  .read(taskControllerProvider.notifier)
                                  .deleteTask(editingTask!.id);
                              navigator.pop();
                              showAppSnackBar(
                                deleted ? '任務已刪除' : '刪除任務失敗',
                                isError: !deleted,
                              );
                            }
                          },
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final description = descController.text.trim();
                          final labels = _parseLabels(labelsController.text);

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('請輸入任務標題'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final navigator = Navigator.of(context);
                          late final bool saved;
                          if (isEditing) {
                            saved = await ref
                                .read(taskControllerProvider.notifier)
                                .updateTaskContent(
                                  editingTask!.id,
                                  title,
                                  description,
                                  selectedStatus,
                                  selectedPriority,
                                  selectedDueDate,
                                  labels,
                                );
                          } else {
                            saved = await ref
                                .read(taskControllerProvider.notifier)
                                .addTask(
                                  title,
                                  description,
                                  status: selectedStatus,
                                  priority: selectedPriority,
                                  dueDate: selectedDueDate,
                                  labels: labels,
                                );
                          }

                          navigator.pop();
                          showAppSnackBar(
                            saved
                                ? (isEditing ? '任務已更新' : '任務已建立')
                                : (isEditing ? '更新任務失敗' : '建立任務失敗'),
                            isError: !saved,
                          );
                        },
                        child: Text(isEditing ? '儲存修改' : '建立任務'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    titleController.dispose();
    descController.dispose();
    labelsController.dispose();
  });
}

List<String> _parseLabels(String value) {
  return value
      .split(',')
      .map((label) => label.trim())
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList();
}

String _formatDate(DateTime date) {
  return '${date.year}/${date.month}/${date.day}';
}
