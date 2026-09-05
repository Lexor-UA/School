// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScheduleController)
final scheduleControllerProvider = ScheduleControllerProvider._();

final class ScheduleControllerProvider
    extends $StreamNotifierProvider<ScheduleController, List<GroupClass>> {
  ScheduleControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduleControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduleControllerHash();

  @$internal
  @override
  ScheduleController create() => ScheduleController();
}

String _$scheduleControllerHash() =>
    r'1916f5d976a46d225fe8e63c4a68f6ff9b68de8b';

abstract class _$ScheduleController extends $StreamNotifier<List<GroupClass>> {
  Stream<List<GroupClass>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<GroupClass>>, List<GroupClass>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GroupClass>>, List<GroupClass>>,
              AsyncValue<List<GroupClass>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
