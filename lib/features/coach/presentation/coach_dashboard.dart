import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'tabs/coach_schedule_tab.dart';
export 'tabs/coach_swimmers_tab.dart';
export 'tabs/coach_profile_tab.dart';
export 'coach_calendar_tab.dart';
export 'coach_journal_tab.dart';
export 'widgets/coach_dialogs.dart';

class SelectedCoachClassIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setClassId(String? id) {
    state = id;
  }
}

/// Active class selected for the Coach Journal
final selectedCoachClassIdProvider = NotifierProvider<SelectedCoachClassIdNotifier, String?>(SelectedCoachClassIdNotifier.new);

class CoachTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

/// Provider for active coach tab
final coachTabProvider = NotifierProvider<CoachTabNotifier, int>(CoachTabNotifier.new);
