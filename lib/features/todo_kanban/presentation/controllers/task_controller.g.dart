// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaskController)
final taskControllerProvider = TaskControllerProvider._();

final class TaskControllerProvider
    extends $AsyncNotifierProvider<TaskController, List<Task>> {
  TaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskControllerHash();

  @$internal
  @override
  TaskController create() => TaskController();
}

String _$taskControllerHash() => r'325a025919665ef8059b875dd8277c60144ac9c3';

abstract class _$TaskController extends $AsyncNotifier<List<Task>> {
  FutureOr<List<Task>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
