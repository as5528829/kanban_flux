import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_snackbar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/task.dart';
import '../../domain/errors/task_failure.dart';
import '../controllers/task_controller.dart';
import '../widgets/kanban_column.dart';
import '../widgets/task_form_bottom_sheet.dart';

class MainKanbanScreen extends ConsumerStatefulWidget {
  const MainKanbanScreen({super.key});

  @override
  ConsumerState<MainKanbanScreen> createState() => _MainKanbanScreenState();
}

class _MainKanbanScreenState extends ConsumerState<MainKanbanScreen> {
  final _searchController = TextEditingController();
  _TaskFilter _activeFilter = _TaskFilter.all;
  _BoardStatus _activeMobileStatus = _BoardStatus.todo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskControllerProvider);
    final syncState = ref.watch(taskSyncStatusProvider);
    final effectiveSyncState = _effectiveSyncState(tasksAsync, syncState);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Kanban Flux',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF1F5F9),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(
            Icons.dashboard_customize_outlined,
            color: Color(0xFF64748B),
            size: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _SyncStatusPill(
              syncState: effectiveSyncState,
              onRetry: effectiveSyncState.status == TaskSyncStatus.failed
                  ? _refreshTasks
                  : null,
            ),
          ),
          IconButton(
            tooltip: effectiveSyncState.status == TaskSyncStatus.syncing
                ? '同步中'
                : '重新整理',
            onPressed: effectiveSyncState.status == TaskSyncStatus.syncing
                ? null
                : _refreshTasks,
            icon: effectiveSyncState.status == TaskSyncStatus.syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF64748B),
                    size: 21,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              onPressed: () async {
                // Auth controller lives at app level; keeping the call here avoids
                // routing indirection for a single sign-out action.
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F5F9), Colors.white],
          ),
        ),
        child: tasksAsync.when(
          loading: _buildLoadingBoard,
          error: (err, stack) => _buildErrorState(err),
          data: (tasks) {
            if (tasks.isEmpty) return _buildEmptyBoard();

            final visibleTasks = _filterTasks(tasks);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryStrip(tasks: tasks),
                      const SizedBox(height: 14),
                      _buildSearchAndFilters(),
                      if (visibleTasks.isEmpty) ...[
                        const SizedBox(height: 12),
                        _FilteredEmptyNotice(onReset: _resetFilters),
                      ],
                    ],
                  ),
                ),
                Expanded(child: _buildBoard(visibleTasks)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateTask(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '搜尋任務、描述或 label',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清除搜尋',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _TaskFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: _activeFilter == filter,
                  label: Text(filter.label),
                  avatar: Icon(filter.icon, size: 16),
                  onSelected: (_) => setState(() => _activeFilter = filter),
                  selectedColor: const Color(0xFFE0E7FF),
                  showCheckmark: false,
                  side: BorderSide(
                    color: _activeFilter == filter
                        ? const Color(0xFFC7D2FE)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard(List<Task> tasks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1000;

        if (isWideScreen) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildColumns(tasks),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_BoardStatus>(
                  selected: {_activeMobileStatus},
                  onSelectionChanged: (values) {
                    setState(() => _activeMobileStatus = values.first);
                  },
                  segments: _BoardStatus.values
                      .map(
                        (status) => ButtonSegment(
                          value: status,
                          label: Text(status.label),
                          icon: Icon(status.icon),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: KanbanColumn(
                  title: _activeMobileStatus.label,
                  status: _activeMobileStatus.value,
                  tasks: tasks,
                  width: double.infinity,
                  onCreateTask: () =>
                      _showCreateTask(initialStatus: _activeMobileStatus.value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildColumns(List<Task> tasks) {
    final columns = [
      KanbanColumn(
        title: '待辦事項',
        status: 'todo',
        tasks: tasks,
        width: double.infinity,
        onCreateTask: () => _showCreateTask(initialStatus: 'todo'),
      ),
      KanbanColumn(
        title: '進行中',
        status: 'in_progress',
        tasks: tasks,
        width: double.infinity,
        onCreateTask: () => _showCreateTask(initialStatus: 'in_progress'),
      ),
      KanbanColumn(
        title: '已完成',
        status: 'done',
        tasks: tasks,
        width: double.infinity,
        onCreateTask: () => _showCreateTask(initialStatus: 'done'),
      ),
    ];

    return columns
        .map((column) => Expanded(child: column))
        .toList(growable: false);
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final query = _searchController.text.trim().toLowerCase();

    return tasks.where((task) {
      final matchesQuery =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.labels.any((label) => label.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      return switch (_activeFilter) {
        _TaskFilter.all => true,
        _TaskFilter.highPriority => task.priority == 'high',
        _TaskFilter.dueSoon => _isDueSoon(task),
        _TaskFilter.overdue => _isOverdue(task),
      };
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _activeFilter = _TaskFilter.all);
  }

  void _showCreateTask({String initialStatus = 'todo'}) {
    showTaskFormBottomSheet(
      context: context,
      ref: ref,
      initialStatus: initialStatus,
    );
  }

  Future<void> _refreshTasks() async {
    final refreshed = await ref
        .read(taskControllerProvider.notifier)
        .refreshTasks();
    final syncState = ref.read(taskSyncStatusProvider);

    showAppSnackBar(
      refreshed ? '任務已重新整理' : (syncState.failure?.message ?? '重新整理失敗，請稍後再試。'),
      isError: !refreshed,
    );
  }

  Widget _buildEmptyBoard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            const Text(
              '你的工作板還是空的',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '建立第一張任務，然後用拖曳把它推進不同階段。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: () => _showCreateTask(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('建立第一張任務'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final failure = friendlyTaskFailure(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              '任務載入失敗',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _refreshTasks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBoard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children:
                List.generate(
                      4,
                      (index) => const Expanded(child: _Skeleton(height: 72)),
                    )
                    .expand((widget) => [widget, const SizedBox(width: 10)])
                    .toList()
                  ..removeLast(),
          ),
          const SizedBox(height: 16),
          const _Skeleton(height: 52),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children:
                  List.generate(
                        3,
                        (index) =>
                            const Expanded(child: _Skeleton(height: 460)),
                      )
                      .expand((widget) => [widget, const SizedBox(width: 12)])
                      .toList()
                    ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }
}

TaskSyncState _effectiveSyncState(
  AsyncValue<List<Task>> tasksAsync,
  TaskSyncState syncState,
) {
  if (tasksAsync.isLoading) {
    return TaskSyncState(
      status: TaskSyncStatus.syncing,
      lastSyncedAt: syncState.lastSyncedAt,
      source: syncState.source,
    );
  }

  if (tasksAsync.hasError) {
    return TaskSyncState(
      status: TaskSyncStatus.failed,
      lastSyncedAt: syncState.lastSyncedAt,
      failure: friendlyTaskFailure(tasksAsync.error!),
      source: syncState.source,
    );
  }

  if (syncState.status == TaskSyncStatus.idle ||
      syncState.status == TaskSyncStatus.syncing) {
    return TaskSyncState(
      status: TaskSyncStatus.synced,
      lastSyncedAt: syncState.lastSyncedAt,
      source: syncState.source,
    );
  }

  return syncState;
}

class _SyncStatusPill extends StatelessWidget {
  final TaskSyncState syncState;
  final VoidCallback? onRetry;

  const _SyncStatusPill({required this.syncState, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final meta = _syncMeta(syncState);

    return Tooltip(
      message: meta.tooltip,
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(maxWidth: 138),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: meta.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: meta.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncState.status == TaskSyncStatus.syncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: meta.foreground,
                  ),
                )
              else
                Icon(meta.icon, size: 15, color: meta.foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  meta.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: meta.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({
  String label,
  String tooltip,
  IconData icon,
  Color foreground,
  Color background,
  Color border,
})
_syncMeta(TaskSyncState syncState) {
  return switch (syncState.status) {
    TaskSyncStatus.syncing => (
      label: '同步中',
      tooltip: '正在同步到 Supabase',
      icon: Icons.sync_rounded,
      foreground: const Color(0xFF2563EB),
      background: const Color(0xFFDBEAFE),
      border: const Color(0xFFBFDBFE),
    ),
    TaskSyncStatus.synced => (
      label: _syncedLabel(syncState.lastSyncedAt, syncState.source),
      tooltip: syncState.source == TaskSyncSource.realtime
          ? '已收到其他分頁或裝置的最新資料'
          : '資料已同步到 Supabase',
      icon: Icons.cloud_done_outlined,
      foreground: const Color(0xFF047857),
      background: const Color(0xFFD1FAE5),
      border: const Color(0xFFA7F3D0),
    ),
    TaskSyncStatus.failed => (
      label: '同步失敗',
      tooltip: syncState.failure?.message ?? '同步失敗，點擊重試',
      icon: Icons.cloud_off_outlined,
      foreground: const Color(0xFFB91C1C),
      background: const Color(0xFFFEE2E2),
      border: const Color(0xFFFECACA),
    ),
    TaskSyncStatus.idle => (
      label: '尚未同步',
      tooltip: '尚未開始同步',
      icon: Icons.cloud_outlined,
      foreground: const Color(0xFF64748B),
      background: const Color(0xFFF8FAFC),
      border: const Color(0xFFE2E8F0),
    ),
  };
}

String _syncedLabel(DateTime? lastSyncedAt, TaskSyncSource? source) {
  if (lastSyncedAt == null) return '已同步';

  final hour = lastSyncedAt.hour.toString().padLeft(2, '0');
  final minute = lastSyncedAt.minute.toString().padLeft(2, '0');
  return source == TaskSyncSource.realtime
      ? '即時更新 $hour:$minute'
      : '已同步 $hour:$minute';
}

enum _TaskFilter {
  all('All', Icons.all_inclusive_rounded),
  highPriority('High priority', Icons.priority_high_rounded),
  dueSoon('Due soon', Icons.schedule_rounded),
  overdue('Overdue', Icons.warning_amber_rounded);

  final String label;
  final IconData icon;

  const _TaskFilter(this.label, this.icon);
}

enum _BoardStatus {
  todo('todo', '待辦事項', Icons.radio_button_unchecked_rounded),
  inProgress('in_progress', '進行中', Icons.timelapse_rounded),
  done('done', '已完成', Icons.check_circle_outline_rounded);

  final String value;
  final String label;
  final IconData icon;

  const _BoardStatus(this.value, this.label, this.icon);
}

class _SummaryStrip extends StatelessWidget {
  final List<Task> tasks;

  const _SummaryStrip({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final inProgress = tasks
        .where((task) => task.status == 'in_progress')
        .length;
    final done = tasks.where((task) => task.status == 'done').length;
    final overdue = tasks.where(_isOverdue).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final cards = [
          _SummaryCard(
            label: '總任務',
            value: tasks.length,
            icon: Icons.layers_outlined,
          ),
          _SummaryCard(
            label: '進行中',
            value: inProgress,
            icon: Icons.timelapse_rounded,
          ),
          _SummaryCard(
            label: '逾期',
            value: overdue,
            icon: Icons.warning_amber_rounded,
          ),
          _SummaryCard(
            label: '已完成',
            value: done,
            icon: Icons.check_circle_outline_rounded,
          ),
        ];

        if (isCompact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(width: 150, child: card),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Row(
          children:
              cards
                  .map((card) => Expanded(child: card))
                  .expand((widget) => [widget, const SizedBox(width: 10)])
                  .toList()
                ..removeLast(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
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

class _FilteredEmptyNotice extends StatelessWidget {
  final VoidCallback onReset;

  const _FilteredEmptyNotice({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_off_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '沒有符合目前搜尋或篩選的任務。',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            TextButton(onPressed: onReset, child: const Text('清除')),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;

  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SizedBox(height: height),
    );
  }
}

bool _isDueSoon(Task task) {
  final dueDate = task.dueDate;
  if (dueDate == null || task.status == 'done') return false;

  final today = DateUtils.dateOnly(DateTime.now());
  final due = DateUtils.dateOnly(dueDate);
  final daysLeft = due.difference(today).inDays;
  return daysLeft >= 0 && daysLeft <= 3;
}

bool _isOverdue(Task task) {
  final dueDate = task.dueDate;
  if (dueDate == null || task.status == 'done') return false;

  final today = DateUtils.dateOnly(DateTime.now());
  final due = DateUtils.dateOnly(dueDate);
  return due.isBefore(today);
}
