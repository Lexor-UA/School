import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/presentation/anatomy_progress_screen.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class SwimStyleData {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final bool isPrimary;
  final int overallScore;
  final String levelTitle;
  final IconData icon;
  final List<MetricItem> metrics;
  final String coachAdvice;
  final List<String> tags;

  const SwimStyleData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isPrimary,
    required this.overallScore,
    required this.levelTitle,
    required this.icon,
    required this.metrics,
    required this.coachAdvice,
    required this.tags,
  });
}

class MetricItem {
  final String label;
  final int percentage;
  final IconData icon;
  final List<Color> gradient;
  final Color darkAccent;
  final Color lightAccent;

  const MetricItem({
    required this.label,
    required this.percentage,
    required this.icon,
    required this.gradient,
    required this.darkAccent,
    required this.lightAccent,
  });
}

class ParentProgressTab extends ConsumerStatefulWidget {
  const ParentProgressTab({super.key});

  @override
  ConsumerState<ParentProgressTab> createState() => _ParentProgressTabState();
}

class _ParentProgressTabState extends ConsumerState<ParentProgressTab> {
  int _selectedStyleIndex = 0;

  final List<SwimStyleData> _styles = const [
    SwimStyleData(
      id: 'crawl',
      title: 'Кроль',
      subtitle: 'Вільний стиль плавання',
      badge: 'Основний стиль',
      isPrimary: true,
      overallScore: 76,
      levelTitle: 'Просунутий',
      icon: LucideIcons.waves,
      metrics: [
        MetricItem(
          label: 'Техніка гребка',
          percentage: 82,
          icon: LucideIcons.sparkles,
          gradient: [Color(0xFF00E5FF), Color(0xFF0284C7)],
          darkAccent: Color(0xFF00E5FF),
          lightAccent: Color(0xFF0284C7),
        ),
        MetricItem(
          label: 'Швидкість & темп',
          percentage: 74,
          icon: LucideIcons.zap,
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          darkAccent: Color(0xFFFBBF24),
          lightAccent: Color(0xFFD97706),
        ),
        MetricItem(
          label: 'Робота ніг & крос',
          percentage: 68,
          icon: LucideIcons.activity,
          gradient: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          darkAccent: Color(0xFFFB7185),
          lightAccent: Color(0xFFE11D48),
        ),
        MetricItem(
          label: 'Положення тіла у воді',
          percentage: 81,
          icon: LucideIcons.compass,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
          darkAccent: Color(0xFF34D399),
          lightAccent: Color(0xFF059669),
        ),
      ],
      coachAdvice:
          'На наступному тренуванні попрацюємо над положенням тіла та роботою ніг. Зверніть увагу на розслаблення під час вдиху.',
      tags: ['#ПоложенняТіла', '#РоботаНіг', '#Дихання'],
    ),
    SwimStyleData(
      id: 'breaststroke',
      title: 'Брас',
      subtitle: 'Класичний брас',
      badge: 'Вивчається',
      isPrimary: false,
      overallScore: 81,
      levelTitle: 'Впевнений',
      icon: LucideIcons.shieldCheck,
      metrics: [
        MetricItem(
          label: 'Потужність поштовху',
          percentage: 88,
          icon: LucideIcons.sparkles,
          gradient: [Color(0xFF00E5FF), Color(0xFF0284C7)],
          darkAccent: Color(0xFF00E5FF),
          lightAccent: Color(0xFF0284C7),
        ),
        MetricItem(
          label: 'Синхронність рухів',
          percentage: 79,
          icon: LucideIcons.zap,
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          darkAccent: Color(0xFFFBBF24),
          lightAccent: Color(0xFFD97706),
        ),
        MetricItem(
          label: 'Фаза ковзання',
          percentage: 85,
          icon: LucideIcons.activity,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
          darkAccent: Color(0xFF34D399),
          lightAccent: Color(0xFF059669),
        ),
        MetricItem(
          label: 'Таймінг дихання',
          percentage: 72,
          icon: LucideIcons.compass,
          gradient: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          darkAccent: Color(0xFFFB7185),
          lightAccent: Color(0xFFE11D48),
        ),
      ],
      coachAdvice:
          'Спробуйте довше затримуватися у фазі ковзання після поштовху ногами. Це заощадить сили та суттєво збільшить швидкість.',
      tags: ['#Ковзання', '#Потужність', '#Синхронність'],
    ),
    SwimStyleData(
      id: 'butterfly',
      title: 'Батерфляй',
      subtitle: 'Стиль дельфіна',
      badge: 'Базовий',
      isPrimary: false,
      overallScore: 68,
      levelTitle: 'Середній',
      icon: LucideIcons.flame,
      metrics: [
        MetricItem(
          label: 'Хвилеподібний рух',
          percentage: 65,
          icon: LucideIcons.sparkles,
          gradient: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          darkAccent: Color(0xFFFB7185),
          lightAccent: Color(0xFFE11D48),
        ),
        MetricItem(
          label: 'Винос рук над водою',
          percentage: 70,
          icon: LucideIcons.zap,
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          darkAccent: Color(0xFFFBBF24),
          lightAccent: Color(0xFFD97706),
        ),
        MetricItem(
          label: 'Потужність гребка',
          percentage: 75,
          icon: LucideIcons.activity,
          gradient: [Color(0xFF00E5FF), Color(0xFF0284C7)],
          darkAccent: Color(0xFF00E5FF),
          lightAccent: Color(0xFF0284C7),
        ),
        MetricItem(
          label: 'Ритм удару ніг',
          percentage: 62,
          icon: LucideIcons.compass,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
          darkAccent: Color(0xFF34D399),
          lightAccent: Color(0xFF059669),
        ),
      ],
      coachAdvice:
          'Хвиля повинна починатися з грудної клітки й проходити через усе тіло. Не піднімайте плечі та голову занадто високо на вдиху.',
      tags: ['#ХвиляТіла', '#Ритм', '#СилаПлечей'],
    ),
    SwimStyleData(
      id: 'backstroke',
      title: 'На спині',
      subtitle: 'Кроль на спині',
      badge: 'Опановано',
      isPrimary: false,
      overallScore: 84,
      levelTitle: 'Відмінно',
      icon: LucideIcons.compass,
      metrics: [
        MetricItem(
          label: 'Ротація корпусу',
          percentage: 86,
          icon: LucideIcons.sparkles,
          gradient: [Color(0xFF00E5FF), Color(0xFF0284C7)],
          darkAccent: Color(0xFF00E5FF),
          lightAccent: Color(0xFF0284C7),
        ),
        MetricItem(
          label: 'Стабільність голови',
          percentage: 89,
          icon: LucideIcons.compass,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
          darkAccent: Color(0xFF34D399),
          lightAccent: Color(0xFF059669),
        ),
        MetricItem(
          label: 'Робота стоп',
          percentage: 78,
          icon: LucideIcons.activity,
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          darkAccent: Color(0xFFFBBF24),
          lightAccent: Color(0xFFD97706),
        ),
        MetricItem(
          label: 'Траєкторія гребка',
          percentage: 83,
          icon: LucideIcons.zap,
          gradient: [Color(0xFFF43F5E), Color(0xFFBE123C)],
          darkAccent: Color(0xFFFB7185),
          lightAccent: Color(0xFFE11D48),
        ),
      ],
      coachAdvice:
          'Зберігайте підборіддя злегка піднятим, погляд строго вгору. Постійна ротація плечей допоможе глибшому та потужнішому захвату води.',
      tags: ['#Ротація', '#Баланс', '#ПоглядВгору'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final currentStyle = _styles[_selectedStyleIndex];

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: ClipRRect(
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
                          .withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    color: themeConfig.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Мій прогрес',
          style: TextStyle(
            color: themeConfig.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18.5,
            letterSpacing: 0.3,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Sleek Style Switcher Horizontal Pills
                  _buildStyleSelector(themeConfig, isDark),
                  const SizedBox(height: 16),

                  // 2. VisionOS Frosted Glass Hero Card
                  _buildHeroCard(currentStyle, themeConfig, isDark),
                  const SizedBox(height: 16),

                  // 3. Coach Recommendations Luxury Card
                  _buildCoachAdviceCard(currentStyle, themeConfig, isDark),
                  const SizedBox(height: 16),

                  // 4. Interactive 3D Anatomy Banner
                  _buildAnatomyBanner(themeConfig, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. STYLE SELECTOR TABS
  // ===========================================================================
  Widget _buildStyleSelector(AppThemeConfig currentTheme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_styles.length, (index) {
          final style = _styles[index];
          final isSelected = _selectedStyleIndex == index;

          return Padding(
            padding: EdgeInsets.only(right: index == _styles.length - 1 ? 0 : 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedStyleIndex = index),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.85)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : const Color(0xFFBAE6FD)),
                      width: isSelected ? 1.2 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.45 : 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        style.icon,
                        size: 13,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        style.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // 2. VISIONOS HERO CARD (HEADER + METRICS)
  // ===========================================================================
  Widget _buildHeroCard(SwimStyleData style, AppThemeConfig currentTheme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.65),
                      const Color(0xFF092842).withValues(alpha: 0.78),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.92),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF003B73).withValues(alpha: 0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Style Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(style.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.title,
                                style: TextStyle(
                                  color: currentTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                style.subtitle,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.isPrimary
                          ? (isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.18)
                              : const Color(0xFFECFDF5))
                          : (isDark
                              ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                              : const Color(0xFFF0F9FF)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: style.isPrimary
                            ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.45) : const Color(0xFFA7F3D0))
                            : (isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.45) : const Color(0xFFBAE6FD)),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (style.isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7))
                              .withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.isPrimary ? LucideIcons.sparkles : LucideIcons.award,
                          size: 11,
                          color: style.isPrimary
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          style.badge,
                          style: TextStyle(
                            color: style.isPrimary
                                ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Overall Score Strip (Protected from clipping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE0F2FE).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFBAE6FD),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.gauge,
                      size: 15,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Рівень володіння',
                        style: TextStyle(
                          color: currentTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                              : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.20),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${style.overallScore}% • ${style.levelTitle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4 Detailed Metrics
              ...style.metrics.map((m) => _buildMetricItem(m, currentTheme, isDark)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildMetricItem(MetricItem metric, AppThemeConfig currentTheme, bool isDark) {
    final valueColor = isDark ? metric.darkAccent : metric.lightAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(metric.icon, size: 12, color: valueColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label,
                  style: TextStyle(
                    color: currentTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${metric.percentage}%',
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Custom Gradient Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fillWidth = (totalWidth * (metric.percentage / 100.0)).clamp(10.0, totalWidth);

              return Container(
                height: 10,
                width: totalWidth,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFCBD5E1),
                    width: 0.6,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: fillWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: metric.gradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: valueColor.withValues(alpha: isDark ? 0.45 : 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. COACH RECOMMENDATIONS LUXURY CARD
  // ===========================================================================
  Widget _buildCoachAdviceCard(SwimStyleData style, AppThemeConfig currentTheme, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E293B).withValues(alpha: 0.70),
                      const Color(0xFF0F172A).withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFFFFBEB).withValues(alpha: 0.85),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFFFDE68A),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.lightbulb, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Порада тренера',
                    style: TextStyle(
                      color: currentTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Рекомендація',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                style.coachAdvice,
                style: TextStyle(
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: style.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFFEF3C7).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFFDE68A),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }

  // ===========================================================================
  // 4. INTERACTIVE 3D ANATOMY BANNER
  // ===========================================================================
  Widget _buildAnatomyBanner(AppThemeConfig currentTheme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnatomyProgressScreen()),
        ),
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0E3D64).withValues(alpha: 0.75),
                          const Color(0xFF0369A1).withValues(alpha: 0.40),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFE0F2FE).withValues(alpha: 0.90),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                      : const Color(0xFF38BDF8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.activity, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Анатомія прогресу',
                          style: TextStyle(
                            color: currentTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '3D карта розвитку та навантаження м\'язів',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : const Color(0xFF0284C7).withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.chevronRight,
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}
