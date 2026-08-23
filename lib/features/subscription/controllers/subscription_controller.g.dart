// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubscriptionController)
final subscriptionControllerProvider = SubscriptionControllerProvider._();

final class SubscriptionControllerProvider
    extends $NotifierProvider<SubscriptionController, List<Subscription>> {
  SubscriptionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionControllerHash();

  @$internal
  @override
  SubscriptionController create() => SubscriptionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Subscription> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Subscription>>(value),
    );
  }
}

String _$subscriptionControllerHash() =>
    r'3a76fd63b334a3ae026a6941e2f0d36784ba27af';

abstract class _$SubscriptionController extends $Notifier<List<Subscription>> {
  List<Subscription> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Subscription>, List<Subscription>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Subscription>, List<Subscription>>,
              List<Subscription>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
