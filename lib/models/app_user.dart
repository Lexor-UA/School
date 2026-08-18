enum UserRole { parent, coach, owner, admin }

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconType; // e.g. 'gold_cup', 'silver_medal', 'bronze_medal'
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconType,
    this.isUnlocked = false,
  });
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final int level;
  final int xp;
  final int maxXp;
  final List<Achievement> achievements;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.level = 1,
    this.xp = 0,
    this.maxXp = 100,
    this.achievements = const [],
  });
}
