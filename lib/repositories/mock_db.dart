import '../models/app_user.dart';
import '../models/subscription.dart';

class MockDB {
  static const AppUser parentUser = AppUser(
    id: 'parent_123',
    name: 'Марія',
    role: UserRole.parent,
    level: 5,
    xp: 2800,
    maxXp: 3500,
    achievements: [
      Achievement(
        id: 'a1',
        name: 'Перший Заплив',
        description: 'Відвідано перше заняття',
        iconType: 'bronze_medal',
        isUnlocked: true,
      ),
      Achievement(
        id: 'a2',
        name: 'Майстер Кролю',
        description: 'Пропливти 1км кролем',
        iconType: 'silver_medal',
        isUnlocked: true,
      ),
      Achievement(
        id: 'a3',
        name: 'Золотий Дельфін',
        description: 'Ідеальна техніка батерфляю',
        iconType: 'gold_cup',
        isUnlocked: false,
      ),
      Achievement(
        id: 'a4',
        name: 'Аквамен',
        description: 'Рік без пропусків занять',
        iconType: 'diamond_cup',
        isUnlocked: false,
      ),
    ],
  );

  static final List<AppUser> users = [
    parentUser,
    const AppUser(id: 'coach_456', name: 'Тренер Алекс', role: UserRole.coach),
    const AppUser(id: 'owner_789', name: 'Артем (Власник)', role: UserRole.owner),
    const AppUser(id: 'admin_101', name: 'Анна (Адмін)', role: UserRole.admin),
  ];

  static final List<Subscription> subscriptions = [
    const Subscription(
      id: 'sub_001',
      userId: 'parent_123',
      totalClasses: 10,
      remainingClasses: 8,
      isActive: true,
    ),
  ];
}
