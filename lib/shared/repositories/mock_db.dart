import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

class MockDB {
  static const AppUser parentUser = AppUser(
    id: 'parent_123',
    name: 'Марія',
    role: UserRole.parent,
    level: 5,
    xp: 2800,
    maxXp: 3500,
    avatarUrl: 'assets/images/maria.jpg',
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
    const AppUser(id: 'coach_456', name: 'Тренер Алекс', role: UserRole.coach, avatarUrl: 'https://images.unsplash.com/photo-1530549387789-4c1017266635?auto=format&fit=crop&q=80&w=400'),
    const AppUser(id: 'owner_789', name: 'Андрій (Власник)', role: UserRole.owner, avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
    const AppUser(id: 'admin_101', name: 'Анна (Адмін)', role: UserRole.admin, avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400'),
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
