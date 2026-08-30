// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'children_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChildrenController)
final childrenControllerProvider = ChildrenControllerProvider._();

final class ChildrenControllerProvider
    extends $StreamNotifierProvider<ChildrenController, List<Child>> {
  ChildrenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'childrenControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$childrenControllerHash();

  @$internal
  @override
  ChildrenController create() => ChildrenController();
}

String _$childrenControllerHash() =>
    r'8f022ad726b642f4327bae875f638728f2faaeb2';

abstract class _$ChildrenController extends $StreamNotifier<List<Child>> {
  Stream<List<Child>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Child>>, List<Child>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Child>>, List<Child>>,
              AsyncValue<List<Child>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
