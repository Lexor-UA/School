// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todayClasses)
final todayClassesProvider = TodayClassesProvider._();

final class TodayClassesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupClass>>,
          List<GroupClass>,
          Stream<List<GroupClass>>
        >
    with $FutureModifier<List<GroupClass>>, $StreamProvider<List<GroupClass>> {
  TodayClassesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayClassesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayClassesHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupClass>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupClass>> create(Ref ref) {
    return todayClasses(ref);
  }
}

String _$todayClassesHash() => r'873921736b65ec9cbae977f23b462a6ba18770bc';

@ProviderFor(recentActions)
final recentActionsProvider = RecentActionsProvider._();

final class RecentActionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ActivityLog>>,
          List<ActivityLog>,
          Stream<List<ActivityLog>>
        >
    with
        $FutureModifier<List<ActivityLog>>,
        $StreamProvider<List<ActivityLog>> {
  RecentActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentActionsHash();

  @$internal
  @override
  $StreamProviderElement<List<ActivityLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ActivityLog>> create(Ref ref) {
    return recentActions(ref);
  }
}

String _$recentActionsHash() => r'5253f1c36e22ec004ce4af0db217e0369a2972cf';

@ProviderFor(adminTasks)
final adminTasksProvider = AdminTasksProvider._();

final class AdminTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminTask>>,
          List<AdminTask>,
          Stream<List<AdminTask>>
        >
    with $FutureModifier<List<AdminTask>>, $StreamProvider<List<AdminTask>> {
  AdminTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminTasksHash();

  @$internal
  @override
  $StreamProviderElement<List<AdminTask>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AdminTask>> create(Ref ref) {
    return adminTasks(ref);
  }
}

String _$adminTasksHash() => r'f8c93f5ca7410da2fc90dbc4e3bc3e4acfef9f6e';

@ProviderFor(unpaidSubscriptionsCount)
final unpaidSubscriptionsCountProvider = UnpaidSubscriptionsCountProvider._();

final class UnpaidSubscriptionsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  UnpaidSubscriptionsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unpaidSubscriptionsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unpaidSubscriptionsCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return unpaidSubscriptionsCount(ref);
  }
}

String _$unpaidSubscriptionsCountHash() =>
    r'12364375e7eb2d8d561b0ab60537607133d70dda';

@ProviderFor(allSubscriptions)
final allSubscriptionsProvider = AllSubscriptionsProvider._();

final class AllSubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          Stream<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $StreamProvider<List<Subscription>> {
  AllSubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allSubscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allSubscriptionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subscription>> create(Ref ref) {
    return allSubscriptions(ref);
  }
}

String _$allSubscriptionsHash() => r'6ab1f368f551ad62150b62457c62548c1adfb435';

@ProviderFor(coaches)
final coachesProvider = CoachesProvider._();

final class CoachesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          Stream<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $StreamProvider<List<AppUser>> {
  CoachesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachesHash();

  @$internal
  @override
  $StreamProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppUser>> create(Ref ref) {
    return coaches(ref);
  }
}

String _$coachesHash() => r'45e68155e985fb2f31af94de88ad71ed8570ef40';

@ProviderFor(adminDashboard)
final adminDashboardProvider = AdminDashboardProvider._();

final class AdminDashboardProvider
    extends
        $FunctionalProvider<
          AdminDashboardState,
          AdminDashboardState,
          AdminDashboardState
        >
    with $Provider<AdminDashboardState> {
  AdminDashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminDashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminDashboardHash();

  @$internal
  @override
  $ProviderElement<AdminDashboardState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminDashboardState create(Ref ref) {
    return adminDashboard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminDashboardState>(value),
    );
  }
}

String _$adminDashboardHash() => r'1a6a431c9161601f64ee939059dff3a4bbaa732b';
