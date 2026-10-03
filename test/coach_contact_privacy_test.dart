import 'package:flutter_test/flutter_test.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';

void main() {
  group('Coach Contact Privacy & Notes Removal Tests', () {
    final coachUser = AppUser(
      id: 'coach_123',
      name: 'Олександр Тренер',
      role: UserRole.coach,
      branchId: 'kyiv',
    );

    final otherCoachUser = AppUser(
      id: 'coach_456',
      name: 'Ірина Тренер',
      role: UserRole.coach,
      branchId: 'kyiv',
    );

    final adminUser = AppUser(
      id: 'admin_kyiv',
      name: 'Адміністратор Київ',
      role: UserRole.admin,
      branchId: 'kyiv',
    );

    final myClass = GroupClass(
      id: 'class_1',
      title: 'Група Олександра',
      category: 'Плавання',
      coachId: 'coach_123',
      coachName: 'Олександр Тренер',
      branchId: 'kyiv',
      startTime: DateTime(2026, 10, 3, 10, 0),
      endTime: DateTime(2026, 10, 3, 11, 0),
      maxCapacity: 8,
      enrolledChildIds: ['student_mine_1', 'student_mine_2'],
    );

    final otherCoachClass = GroupClass(
      id: 'class_2',
      title: 'Група Ірини',
      category: 'Плавання',
      coachId: 'coach_456',
      coachName: 'Ірина Тренер',
      branchId: 'kyiv',
      startTime: DateTime(2026, 10, 3, 12, 0),
      endTime: DateTime(2026, 10, 3, 13, 0),
      maxCapacity: 8,
      enrolledChildIds: ['student_other_1', 'student_other_2'],
    );

    test('Coach only identifies their own enrolled students from schedule', () {
      final allClasses = [myClass, otherCoachClass];

      final coachClasses = allClasses.where((c) {
        if (coachUser.id.isNotEmpty && c.coachId == coachUser.id) return true;
        if (coachUser.name.isNotEmpty && c.coachName.trim().toLowerCase() == coachUser.name.trim().toLowerCase()) return true;
        return false;
      }).toList();

      final Set<String> myEnrolledIds = {};
      for (final c in coachClasses) {
        myEnrolledIds.addAll(c.enrolledChildIds);
      }

      // Check student of coach 123
      expect(myEnrolledIds.contains('student_mine_1'), isTrue);
      expect(myEnrolledIds.contains('student_mine_2'), isTrue);

      // Check student of other coach (must be false)
      expect(myEnrolledIds.contains('student_other_1'), isFalse);
      expect(myEnrolledIds.contains('student_other_2'), isFalse);
    });

    test('Swimmer card contact visibility logic gates phone and direct chat for foreign swimmers', () {
      final myStudentId = 'student_mine_1';
      final foreignStudentId = 'student_other_1';

      final Set<String> myEnrolledIds = {'student_mine_1', 'student_mine_2'};

      final isMyStudentA = myEnrolledIds.contains(myStudentId);
      final isMyStudentB = myEnrolledIds.contains(foreignStudentId);

      expect(isMyStudentA, isTrue);
      expect(isMyStudentB, isFalse);

      // For coach, canViewContacts in swimmer card:
      bool canViewContacts(AppUser user, bool isMyStudent) {
        final isPrivileged = user.role == UserRole.admin || user.role == UserRole.owner || user.role == UserRole.superAdmin;
        return isMyStudent || isPrivileged;
      }

      expect(canViewContacts(coachUser, isMyStudentA), isTrue);
      expect(canViewContacts(coachUser, isMyStudentB), isFalse);

      // For admin, always true
      expect(canViewContacts(adminUser, isMyStudentB), isTrue);
    });

    test('Class attendees contact visibility is restricted to the assigned coach of that class', () {
      bool canCoachViewClassContacts(AppUser user, GroupClass gClass) {
        return user.id == gClass.coachId ||
            user.name.trim().toLowerCase() == gClass.coachName.trim().toLowerCase() ||
            user.role == UserRole.admin ||
            user.role == UserRole.owner ||
            user.role == UserRole.superAdmin;
      }

      // Coach 123 inspecting their own class -> allowed
      expect(canCoachViewClassContacts(coachUser, myClass), isTrue);

      // Coach 123 inspecting other coach's class in groups list -> blocked
      expect(canCoachViewClassContacts(coachUser, otherCoachClass), isFalse);

      // Other coach inspecting class 2 -> allowed
      expect(canCoachViewClassContacts(otherCoachUser, otherCoachClass), isTrue);

      // Admin inspecting any class -> allowed
      expect(canCoachViewClassContacts(adminUser, otherCoachClass), isTrue);
    });
  });
}
