import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/shared/utils/page_transitions.dart';
import 'package:swimming_school_app/features/parent/presentation/trophy_room_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_progress_tab.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_switcher_sheet.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final childrenList = childrenAsync.value ?? [];
    final hasChildren = childrenList.isNotEmpty;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    final textColor = themeConfig.textPrimary;
    final textSubColor = themeConfig.textSecondary;
    final accentColor = themeConfig.accentPrimary;

    final totalTrophies = childrenList.fold<int>(0, (sum, c) => sum + c.achievements.length);
    final medalsCount = totalTrophies > 0 ? totalTrophies : 3;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'parent.my_profile'.tr(),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 21),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // 1. Hero Profile Card with Swimming Quick Stats
          _buildHeroProfileWithStats(
            context,
            user,
            hasChildren,
            isDark,
            textColor,
            textSubColor,
            accentColor,
            medalsCount,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 12),

          // 2. Family & Children Section
          _buildFamilySection(
            context,
            ref,
            childrenList,
            isDark,
            textColor,
            textSubColor,
            accentColor,
          ).animate().fadeIn(delay: 50.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 12),

          // 3. 2-Column Bento Sport Cards (Trophies + Progress)
          _buildBentoSportCards(
            context,
            ref,
            isDark,
            textColor,
            textSubColor,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 12),

          // 4. VisionOS Grouped Settings Card
          _buildGroupedSettingsCard(
            context,
            themeConfig,
            isDark,
            textColor,
            textSubColor,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 12),

          // 5. Luminous Ruby Logout Button (Clean, no version text)
          _buildLogoutFooter(
            context,
            ref,
            isDark,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 1. Hero Profile Card with Glow Avatar and Swimming Stats Counter
  Widget _buildHeroProfileWithStats(
    BuildContext context,
    AppUser? user,
    bool hasChildren,
    bool isDark,
    Color textColor,
    Color subColor,
    Color accentColor,
    int medalsCount,
  ) {
    final contactInfo = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : (user?.loginId != null && user!.loginId!.isNotEmpty)
            ? user.loginId!
            : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                Colors.white.withValues(alpha: isDark ? 0.04 : 0.30),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.60),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Avatar + Name + Badges
              Row(
                children: [
                  // Avatar with glowing halo
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor, Colors.blueAccent, Colors.cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.32),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E32) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name & Contact Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name ?? 'Олександр',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contactInfo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            contactInfo,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB0D4EC) : subColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? accentColor : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.22 : 0.14),
                          (isDark ? accentColor : const Color(0xFF0369A1)).withValues(alpha: isDark ? 0.08 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: (isDark ? accentColor : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.45 : 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 12,
                          color: isDark ? accentColor : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasChildren ? 'parent.parent_account'.tr() : 'parent.client_account'.tr(),
                          style: TextStyle(
                            color: isDark ? accentColor : const Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Subtle Divider
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.transparent,
                            const Color(0xFF00E5FF).withValues(alpha: 0.16),
                            Colors.transparent,
                          ]
                        : [
                            Colors.transparent,
                            const Color(0xFF0284C7).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Swimming Quick Stats Counters
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStatItem(
                      icon: LucideIcons.waves,
                      value: '24',
                      label: 'Занять',
                      color: const Color(0xFF06B6D4),
                      isDark: isDark,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.transparent,
                                const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                Colors.transparent,
                              ]
                            : [
                                Colors.transparent,
                                const Color(0xFF0284C7).withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildHeroStatItem(
                      icon: LucideIcons.mapPin,
                      value: '15.4',
                      unit: 'км',
                      label: 'Дистанція',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.transparent,
                                const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                Colors.transparent,
                              ]
                            : [
                                Colors.transparent,
                                const Color(0xFF0284C7).withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildHeroStatItem(
                      icon: LucideIcons.award,
                      value: '$medalsCount',
                      label: 'Нагород',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      textColor: textColor,
                      subColor: subColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStatItem({
    required IconData icon,
    required String value,
    String? unit,
    required String label,
    required Color color,
    required bool isDark,
    required Color textColor,
    required Color subColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC) : subColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // 2. Family & Children Section
  Widget _buildFamilySection(
    BuildContext context,
    WidgetRef ref,
    List<Child> children,
    bool isDark,
    Color textColor,
    Color subColor,
    Color accentColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.10 : 0.65),
                Colors.white.withValues(alpha: isDark ? 0.03 : 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.50),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(LucideIcons.users, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              if (children.isNotEmpty) ...[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: children.map((child) {
                        final childColor = Color(int.tryParse(child.colorHex) ?? 0xFF06B6D4);
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: childColor.withValues(alpha: isDark ? 0.35 : 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: childColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                child.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Моя родина',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Додайте дитину для обліку занять',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // Add child button
              InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => _showAddChildDialog(context, ref, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.14),
                        const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : const Color(0xFF059669).withValues(alpha: 0.45),
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 13,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Додати',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. 2-Column Bento Sport Cards (Trophies + Progress)
  Widget _buildBentoSportCards(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final progressPrimaryColor = isDark ? const Color(0xFF06B6D4) : const Color(0xFF0284C7);

    return Row(
      children: [
        // Left Card: 🏆 Мої нагороди
        Expanded(
          child: _buildBentoCard(
            title: 'Мої нагороди',
            subtitle: 'Зала слави & медалі',
            badgeText: '🏆 Трофеї',
            icon: LucideIcons.trophy,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            glowColor: const Color(0xFFF59E0B),
            lightTextColor: const Color(0xFFB45309),
            isDark: isDark,
            textColor: textColor,
            subColor: subColor,
            visualWidget: const Row(
              children: [
                Text('🥇', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text('🥈', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text('🥉', style: TextStyle(fontSize: 16)),
              ],
            ),
            onTap: () => Navigator.push(context, FadeScaleRoute(page: const TrophyRoomScreen())),
          ),
        ),
        const SizedBox(width: 10),
        // Right Card: 📈 Мій прогрес
        Expanded(
          child: _buildBentoCard(
            title: 'Мій прогрес',
            subtitle: "Анатомія м'язів",
            badgeText: '⚡ Активність',
            icon: LucideIcons.trendingUp,
            gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
            glowColor: const Color(0xFF06B6D4),
            lightTextColor: const Color(0xFF0284C7),
            isDark: isDark,
            textColor: textColor,
            subColor: subColor,
            visualWidget: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMiniBar(height: 8, color: progressPrimaryColor.withValues(alpha: 0.35)),
                const SizedBox(width: 3),
                _buildMiniBar(height: 13, color: progressPrimaryColor.withValues(alpha: 0.65)),
                const SizedBox(width: 3),
                _buildMiniBar(height: 18, color: progressPrimaryColor),
                const SizedBox(width: 4),
                Icon(LucideIcons.arrowUpRight, size: 13, color: progressPrimaryColor),
              ],
            ),
            onTap: () => Navigator.push(context, FadeScaleRoute(page: const ParentProgressTab())),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBar({required double height, required Color color}) {
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required Color glowColor,
    Color? lightTextColor,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Widget visualWidget,
    required VoidCallback onTap,
  }) {
    final effectiveBadgeColor = isDark ? glowColor : (lightTextColor ?? glowColor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              height: 106,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                    Colors.white.withValues(alpha: isDark ? 0.04 : 0.28),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: glowColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: Icon + Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Icon(icon, color: Colors.white, size: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: effectiveBadgeColor.withValues(alpha: isDark ? 0.35 : 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: effectiveBadgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle: Visual widget (medals or bars)
                  visualWidget,

                  // Bottom row: Title + Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.8)
                            : subColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. VisionOS Grouped Settings Card
  Widget _buildGroupedSettingsCard(
    BuildContext context,
    AppThemeConfig themeConfig,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.10 : 0.65),
                Colors.white.withValues(alpha: isDark ? 0.03 : 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.50),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Theme Switcher
              _buildGroupedItem(
                icon: LucideIcons.palette,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                title: 'Тема додатку',
                subtitle: themeConfig.title,
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                trailingWidget: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: themeConfig.accentPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeConfig.accentPrimary.withValues(alpha: 0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                onTap: () => ThemeSwitcherSheet.show(context),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 54, right: 14),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFBAE6FD).withValues(alpha: 0.50),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              // Row 2: Settings Dialog
              _buildGroupedItem(
                icon: LucideIcons.settings,
                gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                title: 'parent.settings'.tr(),
                subtitle: 'Сповіщення та параметри',
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                onTap: () => _showSettingsDialog(context, isDark, themeConfig),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 54, right: 14),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFBAE6FD).withValues(alpha: 0.50),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              // Row 3: Support Chat
              _buildGroupedItem(
                icon: LucideIcons.messageCircle,
                gradientColors: const [Color(0xFF06B6D4), Color(0xFF0D9488)],
                title: 'parent.contact_support'.tr() == 'parent.contact_support'
                    ? 'Написати в підтримку'
                    : 'parent.contact_support'.tr(),
                subtitle: 'parent.chat_with_admin'.tr() == 'parent.chat_with_admin'
                    ? 'Онлайн-чат із адміністратором'
                    : 'parent.chat_with_admin'.tr(),
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParentChatScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedItem({
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subColor,
    required bool isDark,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFB0D4EC) : subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 6),
              ],
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.7) : subColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Luminous Ruby Logout Button (High-contrast frosted glass in light & dark themes)
  Widget _buildLogoutFooter(BuildContext context, WidgetRef ref, bool isDark) {
    final rubyColor = isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _confirmLogout(context, ref, isDark),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFEF4444).withValues(alpha: 0.18),
                          const Color(0xFFB91C1C).withValues(alpha: 0.08),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.90),
                          const Color(0xFFFFF1F2).withValues(alpha: 0.95),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                      : const Color(0xFFFECDD3),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFE11D48))
                        .withValues(alpha: isDark ? 0.14 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: rubyColor, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    'parent.logout_short'.tr(),
                    style: TextStyle(
                      color: rubyColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Вийти з акаунта?'),
        content: const Text('Ви дійсно бажаєте вийти зі свого профілю?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(parentTabProvider.notifier).setTab(0);
              ref.read(authControllerProvider.notifier).logout();
              context.go('/');
            },
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddChildSheet(isDark: isDark),
    );
  }

  void _showSettingsDialog(BuildContext context, bool isDark, AppThemeConfig themeConfig) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.15 : 0.85),
                    Colors.white.withValues(alpha: isDark ? 0.05 : 0.40),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(LucideIcons.settings, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Налаштування',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(LucideIcons.palette, color: themeConfig.accentPrimary),
                          title: Text(
                            'Тема додатку',
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            themeConfig.title,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
                          ),
                          trailing: const Icon(LucideIcons.chevronRight, size: 18),
                          onTap: () {
                            Navigator.pop(ctx);
                            ThemeSwitcherSheet.show(context);
                          },
                        ),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                        SwitchListTile(
                          title: Text(
                            'Push-сповіщення',
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Нагадування про тренування',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 12),
                          ),
                          value: true,
                          onChanged: (v) {},
                          activeThumbColor: themeConfig.accentPrimary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: themeConfig.accentPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Закрити', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _AddChildSheet extends ConsumerStatefulWidget {
  final bool isDark;
  const _AddChildSheet({required this.isDark});

  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<_AddChildSheet> {
  int _childCount = 1;
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final List<TextEditingController> _ageControllers = [TextEditingController()];
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _ageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addChild() {
    setState(() {
      _childCount++;
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
    });
  }

  void _removeChild() {
    if (_childCount > 1) {
      setState(() {
        _childCount--;
        _nameControllers.last.dispose();
        _ageControllers.last.dispose();
        _nameControllers.removeLast();
        _ageControllers.removeLast();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final futures = <Future>[];
    for (int i = 0; i < _childCount; i++) {
      final name = _nameControllers[i].text.trim();
      if (name.isNotEmpty) {
        final age = int.tryParse(_ageControllers[i].text.trim());
        futures.add(ref.read(childrenControllerProvider.notifier).addChild(name, age));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.94),
                isDark ? const Color(0xFF070E1A).withValues(alpha: 0.97) : const Color(0xFFF1F5F9).withValues(alpha: 0.97),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'parent.add_child'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.4)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          iconSize: 20,
                          icon: Icon(LucideIcons.minusCircle, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: _removeChild,
                        ),
                        Text(
                          '$_childCount',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          icon: Icon(LucideIcons.plusCircle, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: _addChild,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _childCount,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Дитина ${index + 1}',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameControllers[index],
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: "parent.child_name".tr(),
                              labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ageControllers[index],
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "parent.child_age".tr(),
                              labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'parent.save'.tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
