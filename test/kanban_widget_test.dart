import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/core/app_snackbar.dart';
import 'package:kanban_flux/features/todo_kanban/domain/entities/task.dart';
import 'package:kanban_flux/features/todo_kanban/domain/errors/task_failure.dart';
import 'package:kanban_flux/features/todo_kanban/presentation/controllers/task_controller.dart';
import 'package:kanban_flux/features/todo_kanban/presentation/pages/main_kanban_screen.dart';
import 'package:kanban_flux/features/todo_kanban/presentation/widgets/kanban_column.dart';
import 'package:kanban_flux/features/todo_kanban/presentation/widgets/task_form_bottom_sheet.dart';

void main() {
  final tasks = [
    Task(
      id: 'task-1',
      title: 'Test task',
      description: 'Widget test task',
      status: 'todo',
      priority: 'medium',
      dueDate: null,
      labels: const ['test'],
      position: 0,
      createdAt: DateTime(2026, 6, 4),
    ),
  ];

  group('MainKanbanScreen', () {
    testWidgets('shows three columns on desktop', (tester) async {
      await _setSurfaceSize(tester, const Size(1280, 900));
      await tester.pumpWidget(_boardApp(tasks));
      await tester.pumpAndSettle();

      expect(find.byType(KanbanColumn), findsNWidgets(3));
      expect(find.text('待辦事項'), findsOneWidget);
      expect(find.text('進行中'), findsWidgets);
      expect(find.text('已完成'), findsWidgets);
    });

    testWidgets('shows one active column on mobile', (tester) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      await tester.pumpWidget(_boardApp(tasks));
      await tester.pumpAndSettle();

      expect(find.byType(KanbanColumn), findsOneWidget);
      expect(find.text('Test task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows realtime update status', (tester) async {
      await _setSurfaceSize(tester, const Size(1280, 900));
      final container = ProviderContainer(
        overrides: [
          taskControllerProvider.overrideWith(() => _FakeTaskController(tasks)),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(taskSyncStatusProvider.notifier)
          .setSynced(source: TaskSyncSource.realtime);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MainKanbanScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('即時更新'), findsOneWidget);
      expect(find.byTooltip('重新整理'), findsOneWidget);
    });

    testWidgets('failed sync pill retries refresh', (tester) async {
      await _setSurfaceSize(tester, const Size(1280, 900));
      final controller = _FakeTaskController(tasks);
      final container = ProviderContainer(
        overrides: [taskControllerProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);
      container
          .read(taskSyncStatusProvider.notifier)
          .setFailed(
            const TaskFailure(
              type: TaskFailureType.network,
              message: '網路連線異常，請確認連線後再試一次。',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            scaffoldMessengerKey: appScaffoldMessengerKey,
            home: const MainKanbanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('同步失敗'));
      await tester.pumpAndSettle();

      expect(controller.refreshCalls, 1);
    });

    testWidgets('syncing disables manual refresh', (tester) async {
      await _setSurfaceSize(tester, const Size(1280, 900));
      final controller = _FakeTaskController(tasks);
      final container = ProviderContainer(
        overrides: [taskControllerProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);
      container.read(taskSyncStatusProvider.notifier).setSyncing();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MainKanbanScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('同步中'), findsOneWidget);
      final refreshButton = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == '同步中',
        ),
      );
      expect(refreshButton.onPressed, isNull);
      expect(controller.refreshCalls, 0);
    });
  });

  group('Task form', () {
    testWidgets('shows warning when title is empty', (tester) async {
      await _setSurfaceSize(tester, const Size(800, 1000));
      await tester.pumpWidget(_formApp());

      await tester.tap(find.text('開啟新增表單'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('建立任務'));
      await tester.tap(find.text('建立任務'));
      await tester.pump();

      expect(find.text('請輸入任務標題'), findsOneWidget);
      expect(find.text('建立全新任務'), findsOneWidget);
    });

    testWidgets('returns task after delete confirmation', (tester) async {
      await _setSurfaceSize(tester, const Size(800, 1000));
      await tester.pumpWidget(_formApp(task: tasks.first));

      await tester.tap(find.text('開啟編輯表單'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('刪除'));
      await tester.tap(find.text('刪除'));
      await tester.pumpAndSettle();

      expect(find.text('確認刪除'), findsNWidgets(2));
      await tester.tap(find.text('確認刪除').last);
      await tester.pumpAndSettle();

      expect(find.text('已回傳刪除 task-1'), findsOneWidget);
      expect(find.text('編輯任務'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _boardApp(List<Task> tasks) {
  return ProviderScope(
    overrides: [
      taskControllerProvider.overrideWith(() => _FakeTaskController(tasks)),
    ],
    child: const MaterialApp(home: MainKanbanScreen()),
  );
}

Widget _formApp({Task? task}) {
  return ProviderScope(
    child: MaterialApp(
      scaffoldMessengerKey: appScaffoldMessengerKey,
      home: _TaskFormHarness(task: task),
    ),
  );
}

class _FakeTaskController extends TaskController {
  final List<Task> tasks;
  int refreshCalls = 0;

  _FakeTaskController(this.tasks);

  @override
  Future<List<Task>> build() async => tasks;

  @override
  Future<bool> refreshTasks() async {
    refreshCalls++;
    return true;
  }
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _TaskFormHarness extends ConsumerStatefulWidget {
  final Task? task;

  const _TaskFormHarness({this.task});

  @override
  ConsumerState<_TaskFormHarness> createState() => _TaskFormHarnessState();
}

class _TaskFormHarnessState extends ConsumerState<_TaskFormHarness> {
  TaskFormDeleteResult? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final nextResult = await showTaskFormBottomSheet(
                  context: context,
                  ref: ref,
                  task: widget.task,
                );
                if (mounted) setState(() => result = nextResult);
              },
              child: Text(widget.task == null ? '開啟新增表單' : '開啟編輯表單'),
            ),
            if (result != null) Text('已回傳刪除 ${result!.task.id}'),
          ],
        ),
      ),
    );
  }
}
