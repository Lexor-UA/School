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
        isAutoDispose: false,
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
    r'0d8df0242c39c4b5369374f23a670eedb8c0030d';

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
