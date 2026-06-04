import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban_flux/features/todo_kanban/domain/errors/task_failure.dart';
import 'package:kanban_flux/features/todo_kanban/presentation/controllers/task_controller.dart';

void main() {
  test('syncing to synced clears failure and updates time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(taskSyncStatusProvider.notifier);

    controller.setFailed(
      const TaskFailure(
        type: TaskFailureType.network,
        message: 'network failed',
      ),
    );
    controller.setSyncing();
    controller.setSynced();

    final state = container.read(taskSyncStatusProvider);
    expect(state.status, TaskSyncStatus.synced);
    expect(state.failure, isNull);
    expect(state.lastSyncedAt, isNotNull);
    expect(state.source, TaskSyncSource.local);
  });

  test('failed sync preserves last successful sync time', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(taskSyncStatusProvider.notifier);

    controller.setSynced();
    final lastSyncedAt = container.read(taskSyncStatusProvider).lastSyncedAt;

    controller.setSyncing();
    controller.setFailed(
      const TaskFailure(
        type: TaskFailureType.permission,
        message: 'permission failed',
      ),
    );

    final state = container.read(taskSyncStatusProvider);
    expect(state.status, TaskSyncStatus.failed);
    expect(state.lastSyncedAt, lastSyncedAt);
    expect(state.failure?.type, TaskFailureType.permission);
    expect(state.source, TaskSyncSource.local);
  });

  test('realtime sync records realtime source', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(taskSyncStatusProvider.notifier);

    controller.setSynced(source: TaskSyncSource.realtime);

    final state = container.read(taskSyncStatusProvider);
    expect(state.status, TaskSyncStatus.synced);
    expect(state.source, TaskSyncSource.realtime);
  });
}
