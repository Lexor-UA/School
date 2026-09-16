import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';

class TrophyDefinition {
  final String id;
  final String title;
  final String description;
  final String criteria;
  final IconData icon;
  final List<Color> colors;
  final String iconEmoji;

  const TrophyDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.criteria,
    required this.icon,
    required this.colors,
    required this.iconEmoji,
  });
}

class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  final String _selectedFilterId = 'all';

  static const List<TrophyDefinition> _catalog = [
    TrophyDefinition(
      id: 'champion',
      title: 'Чемпіон дня',
      description: 'Найвище старання, швидкість та дисципліна на воді.',
      criteria: 'Отримується за визначні результати на занятті за рішенням тренера.',
      icon: LucideIcons.trophy,
      colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
      iconEmoji: '🏆',
    ),
    TrophyDefinition(
      id: 'dolphin',
      title: 'Дельфін',
      description: 'Ідеальне ковзання та плавна хвилеподібна техніка гребка.',
      criteria: 'Виконайте 50м стилем батерфляй з бездоганною фазою вдиху.',
      icon: LucideIcons.waves,
      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
      iconEmoji: '🐬',
    ),
    TrophyDefinition(
      id: 'torpedo',
      title: 'Швидкісна торпеда',
      description: 'Потужний старт та рекордний темп на дистанції.',
      criteria: 'Покращте свій особистий рекорд часу на дистанції 50 метрів.',
      icon: LucideIcons.zap,
      colors: [Color(0xFFF97316), Color(0xFFEF4444)],
      iconEmoji: '⚡',
    ),
    TrophyDefinition(
      id: 'superstar',
      title: 'Супер Зірка',
      description: 'Зразкова дисципліна, підтримка колег та командний дух.',
      criteria: 'Отримайте відзнаку від тренера за лідерство та мотивацію групи.',
      icon: LucideIcons.star,
      colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
      iconEmoji: '⭐',
    ),
    TrophyDefinition(
      id: 'master_of_depths',
      title: 'Майстер Глибин',
      description: 'Впевнений контроль дихання та робота на глибині.',
      criteria: 'Затримка дихання під водою понад 45 секунд під наглядом тренера.',
      icon: LucideIcons.anchor,
      colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
      iconEmoji: '🌊',
    ),
    TrophyDefinition(
      id: 'iron_endurance',
      title: 'Залізна Витримка',
      description: 'Безперервна серія тренувань без жодного пропуску.',
      criteria: 'Відвідайте 10 запланованих занять поспіль без пропусків.',
      icon: LucideIcons.shieldCheck,
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      iconEmoji: '🛡️',
    ),
    TrophyDefinition(
      id: 'shark',
      title: 'Акула Басейну',
      description: 'Справжній кілометраж — підкорення першої великої дистанції.',
      criteria: 'Подолайте сумарно 1000 метрів за одне навчальне тренування.',
      icon: LucideIcons.flame,
      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      iconEmoji: '🦈',
    ),
    TrophyDefinition(
      id: 'diver',
      title: 'Майстер занурення',
      description: 'Віртуозна техніка стартового стрибка та підводного ковзання.',
      criteria: 'Опануйте глибокий старт із тумби з виходом у ковзання на 15 метрів.',
      icon: LucideIcons.compass,
      colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
      iconEmoji: '🤿',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final user = ref.watch(authControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    // Collect all achievements according to filter
    final earnedAchievements = <String, String>{}; // trophyId -> holderName

    if (_selectedFilterId == 'all') {
      if (user != null) {
        for (var a in user.achievements) {
          earnedAchievements[a.id.toLowerCase()] = user.name;
        }
      }
      for (var ch in children) {
        for (var a in ch.achievements) {
          earnedAchievements[a.id.toLowerCase()] = ch.name;
        }
      }
    } else if (_selectedFilterId == user?.id) {
      if (user != null) {
        for (var a in user.achievements) {
          earnedAchievements[a.id.toLowerCase()] = user.name;
        }
      }
    } else {
      final child = children.firstWhere(
        (c) => c.id == _selectedFilterId,
        orElse: () => children.isNotEmpty ? children.first : throw Exception(),
      );
      for (var a in child.achievements) {
        earnedAchievements[a.id.toLowerCase()] = child.name;
      }
    }

    final totalCatalogCount = _catalog.length;
    final unlockedCount = _catalog.where((t) => earnedAchievements.containsKey(t.id.toLowerCase())).length;
    final shelfCount = (totalCatalogCount / 2).ceil();

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeConfig.bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Glassmorphic Back Button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                                    : const Color(0xFFBAE6FD),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      .withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                LucideIcons.chevronLeft,
                                color: themeConfig.textPrimary,
                                size: 22,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                      const ThemeHeaderButton(size: 38),
                    ],
                  ),
                ),

                // Title & Subtitle Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Вітрина Трофеїв',
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Натисніть на трофей для деталей та умов отримання',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : themeConfig.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Telemetry Score Strip & Child Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTelemetryBar(
                    unlockedCount,
                    totalCatalogCount,
                    themeConfig,
                    isDark,
                    user,
                    children,
                  ),
                ),
                const SizedBox(height: 16),

                // 3D Cabinet View with Shelves
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 24, bottom: 60),
                    itemCount: shelfCount,
                    itemBuilder: (context, index) {
                      final firstIndex = index * 2;
                      final secondIndex = firstIndex + 1;

                      final trophy1 = _catalog[firstIndex];
                      final isUnlocked1 = earnedAchievements.containsKey(trophy1.id.toLowerCase());
                      final holder1 = earnedAchievements[trophy1.id.toLowerCase()];

                      TrophyDefinition? trophy2;
                      bool isUnlocked2 = false;
                      String? holder2;

                      if (secondIndex < _catalog.length) {
                        trophy2 = _catalog[secondIndex];
                        isUnlocked2 = earnedAchievements.containsKey(trophy2.id.toLowerCase());
                        holder2 = earnedAchievements[trophy2.id.toLowerCase()];
                      }

                      return _buildShelf(
                        context: context,
                        trophy1: trophy1,
                        isUnlocked1: isUnlocked1,
                        holder1: holder1,
                        trophy2: trophy2,
                        isUnlocked2: isUnlocked2,
                        holder2: holder2,
                        index: index,
                        themeConfig: themeConfig,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TELEMETRY BAR
  // ===========================================================================
  Widget _buildTelemetryBar(
    int unlockedCount,
    int totalCount,
    AppThemeConfig currentTheme,
    bool isDark,
    dynamic user,
    List<dynamic> children,
  ) {
    final percent = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0E3D64).withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                  : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                    .withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Glowing Trophy Icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.award, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              // Progress Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Колекція нагород',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$unlockedCount з $totalCount',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3D GLASS SHELF
  // ===========================================================================
  Widget _buildShelf({
    required BuildContext context,
    required TrophyDefinition trophy1,
    required bool isUnlocked1,
    required String? holder1,
    required TrophyDefinition? trophy2,
    required bool isUnlocked2,
    required String? holder2,
    required int index,
    required AppThemeConfig themeConfig,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 70),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The 3D Glass Platform
          Positioned(
            bottom: -22,
            left: 14,
            right: 14,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.35),
                          const Color(0xFF091F33).withValues(alpha: 0.70),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFBAE6FD).withValues(alpha: 0.65),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                      : const Color(0xFF7DD3FC),
                  width: 1.4,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, -6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Trophies standing on the shelf
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTrophyItem(
                context: context,
                trophy: trophy1,
                isUnlocked: isUnlocked1,
                holderName: holder1,
                index: index * 2,
                themeConfig: themeConfig,
                isDark: isDark,
              ),
              if (trophy2 != null)
                _buildTrophyItem(
                  context: context,
                  trophy: trophy2,
                  isUnlocked: isUnlocked2,
                  holderName: holder2,
                  index: index * 2 + 1,
                  themeConfig: themeConfig,
                  isDark: isDark,
                )
              else
                const SizedBox(width: 145),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 150).ms).slideY(
          begin: 0.15,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ===========================================================================
  // INDIVIDUAL TROPHY ITEM
  // ===========================================================================
  Widget _buildTrophyItem({
    required BuildContext context,
    required TrophyDefinition trophy,
    required bool isUnlocked,
    required String? holderName,
    required int index,
    required AppThemeConfig themeConfig,
    required bool isDark,
  }) {
    final colors = trophy.colors;

    return GestureDetector(
      onTap: () => _showTrophyModal(context, trophy, isUnlocked, holderName, themeConfig, isDark),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated 3D Floating Trophy Frame
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) => Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(
                  isUnlocked
                      ? (math.sin((_rotationController.value * math.pi * 2) + (index * 0.7)) * 0.22)
                      : 0,
                ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 145,
                height: 165,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Radiant Glow on Shelf floor
                    if (isUnlocked)
                      Positioned(
                        bottom: -12,
                        child: Container(
                          width: 95,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: colors[0].withValues(alpha: isDark ? 0.75 : 0.45),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // The Glass Shield
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: 120,
                          height: 145,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isUnlocked
                                  ? colors[0].withValues(alpha: isDark ? 0.85 : 0.65)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.16)
                                      : const Color(0xFFBAE6FD)),
                              width: isUnlocked ? 1.6 : 1.0,
                            ),
                            gradient: LinearGradient(
                              colors: isUnlocked
                                  ? (isDark
                                      ? [
                                          colors[0].withValues(alpha: 0.30),
                                          colors[1].withValues(alpha: 0.15),
                                          const Color(0xFF092842).withValues(alpha: 0.65),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.95),
                                          colors[0].withValues(alpha: 0.18),
                                          const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                                        ])
                                  : (isDark
                                      ? [
                                          Colors.white.withValues(alpha: 0.10),
                                          const Color(0xFF0E2538).withValues(alpha: 0.50),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.90),
                                          const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                                        ]),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: isUnlocked
                                ? [
                                    BoxShadow(
                                      color: colors[0].withValues(alpha: isDark ? 0.35 : 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Sweeping reflection for unlocked trophies
                              if (isUnlocked)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.45),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat()).slide(
                                        begin: const Offset(-1.2, -1.2),
                                        end: const Offset(1.2, 1.2),
                                        duration: 3200.ms,
                                      ),
                                ),

                              // The Trophy Icon
                              Center(
                                child: Icon(
                                  isUnlocked ? trophy.icon : LucideIcons.lock,
                                  size: isUnlocked ? 52 : 44,
                                  color: isUnlocked
                                      ? colors[0]
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : const Color(0xFF94A3B8)),
                                  shadows: isUnlocked
                                      ? [
                                          Shadow(color: colors[0], blurRadius: 12),
                                          Shadow(color: colors[1], blurRadius: 20),
                                        ]
                                      : null,
                                ).animate(onPlay: (c) => isUnlocked ? c.repeat(reverse: true) : null)
                                 .moveY(begin: isUnlocked ? -3 : 0, end: isUnlocked ? 3 : 0, duration: 2.seconds),
                              ),

                              // Stars indicator for unlocked trophies
                              if (isUnlocked)
                                Positioned(
                                  bottom: 10,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      3,
                                      (i) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                        child: const Icon(
                                          LucideIcons.star,
                                          color: Color(0xFFFFD700),
                                          size: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Закрито',
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name Plate
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 135,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUnlocked
                        ? (isDark
                            ? [
                                const Color(0xFF0F263D).withValues(alpha: 0.90),
                                const Color(0xFF071424).withValues(alpha: 0.90),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.95),
                                const Color(0xFFF0F9FF).withValues(alpha: 0.92),
                              ])
                        : (isDark
                            ? [
                                Colors.black.withValues(alpha: 0.60),
                                const Color(0xFF0A1624).withValues(alpha: 0.60),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.88),
                                const Color(0xFFF1F5F9).withValues(alpha: 0.85),
                              ]),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked
                        ? colors[0].withValues(alpha: isDark ? 0.65 : 0.45)
                        : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1)),
                    width: isUnlocked ? 1.2 : 0.8,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: colors[0].withValues(alpha: isDark ? 0.25 : 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  trophy.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isUnlocked
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    fontSize: 11.5,
                    fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INTERACTIVE TROPHY DETAIL MODAL
  // ===========================================================================
  void _showTrophyModal(
    BuildContext context,
    TrophyDefinition trophy,
    bool isUnlocked,
    String? holderName,
    AppThemeConfig currentTheme,
    bool isDark,
  ) {
    final colors = trophy.colors;

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF071A2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: isUnlocked
                  ? colors[0].withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : const Color(0xFFBAE6FD)),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Floating 3D Icon Badge
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUnlocked
                      ? null
                      : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? Colors.white.withValues(alpha: 0.6) : Colors.white24,
                    width: 2,
                  ),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isUnlocked ? trophy.icon : LucideIcons.lock,
                    size: 40,
                    color: isUnlocked ? Colors.white : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                trophy.title,
                style: TextStyle(
                  color: currentTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                trophy.description,
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Criteria Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFBAE6FD),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.target,
                          size: 14,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Умови отримання',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trophy.criteria,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? (isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.20)
                          : const Color(0xFFECFDF5))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFFA7F3D0))
                        : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUnlocked ? LucideIcons.checkCircle2 : LucideIcons.clock,
                      size: 14,
                      color: isUnlocked
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUnlocked ? 'Здобуто: $holderName' : 'Ще не здобуто',
                      style: TextStyle(
                        color: isUnlocked
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                            : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Зрозуміло',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
