import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

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

/// Checks strictly whether [c] belongs to the given [user] (coach).
/// Does not fall back to other coaches' classes.
bool isClassForCoach(GroupClass c, AppUser? user) {
  if (user == null) return false;
  // 1. Direct ID match
  if (c.coachId == user.id) return true;
  // 2. LoginId match
  if (user.loginId != null && user.loginId!.isNotEmpty && c.coachId == user.loginId) return true;
  // 3. Default coach alias match (for default/sample coach Olena Koval)
  final isDefaultUser = user.id == 'default_coach' || user.id == 'mock_coach' || user.loginId == 'coach';
  final isDefaultClass = c.coachId == 'default_coach' || c.coachId == 'coach';
  if (isDefaultUser && isDefaultClass) return true;
  // 4. Exact or substring Name match (clean, trimmed, non-generic)
  final uName = user.name.trim().toLowerCase();
  final cName = c.coachName.trim().toLowerCase();
  if (uName.isNotEmpty &&
      cName.isNotEmpty &&
      uName != 'тренер' &&
      !cName.contains('не призначен') &&
      cName != 'unassigned') {
    if (uName == cName) return true;
    if (cName.contains(uName) || uName.contains(cName)) return true;
  }
  return false;
}
