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
import 'package:swimming_school_app/features/parent/presentation/edit_child_sheet.dart';
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_notifications_sheet.dart';

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

    final notifState = ref.watch(parentNotificationsControllerProvider);

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
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                        : const Color(0xFFBAE6FD),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(LucideIcons.bell, color: isDark ? const Color(0xFF00E5FF) : textColor, size: 18),
                  onPressed: () => ParentNotificationsSheet.show(context),
                ),
              ),
              if (notifState.hasUnread)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.7),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Center(
                      child: Text(
                        '${notifState.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1.seconds),
                ),
            ],
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
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
          const SizedBox(height: 7),

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
          const SizedBox(height: 7),

          // 3. 2-Column Bento Sport Cards (Trophies + Progress)
          _buildBentoSportCards(
            context,
            ref,
            isDark,
            textColor,
            textSubColor,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 7),

          // 4. VisionOS Grouped Settings Card
          _buildGroupedSettingsCard(
            context,
            themeConfig,
            isDark,
            textColor,
            textSubColor,
            notifState,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 7),

          // 5. Luminous Ruby Logout Button (Clean, no version text)
          _buildLogoutFooter(
            context,
            ref,
            isDark,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 10),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                Colors.white.withValues(alpha: isDark ? 0.04 : 0.30),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
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
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E32) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 22.5),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contactInfo != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            contactInfo,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB0D4EC) : subColor,
                              fontSize: 11.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? accentColor : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.22 : 0.14),
                          (isDark ? accentColor : const Color(0xFF0369A1)).withValues(alpha: isDark ? 0.08 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isDark ? accentColor : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.45 : 0.35),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 11,
                          color: isDark ? accentColor : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasChildren ? 'parent.parent_account'.tr() : 'parent.client_account'.tr(),
                          style: TextStyle(
                            color: isDark ? accentColor : const Color(0xFF0284C7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),
              // Subtle Divider
              Container(
                margin: const EdgeInsets.symmetric(vertical: 1),
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
              const SizedBox(height: 6),

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
                    height: 22,
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
                    height: 22,
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
            Icon(icon, size: 12.5, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 1.5),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC) : subColor,
            fontSize: 10.5,
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
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.10 : 0.65),
                Colors.white.withValues(alpha: isDark ? 0.03 : 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.50),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(LucideIcons.users, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              if (children.isNotEmpty) ...[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: children.map((child) {
                        final childColor = Color(int.tryParse(child.colorHex) ?? 0xFF06B6D4);
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showEditChildDialog(context, ref, child, isDark),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.40),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: childColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: childColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  child.currentAge != null ? '${child.name} (${formatAgeUk(child.currentAge!)})' : child.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.pencil,
                                  size: 11,
                                  color: childColor.withValues(alpha: isDark ? 0.75 : 0.85),
                                ),
                              ],
                            ),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Додайте дитину для занять',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
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
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showAddChildDialog(context, ref, isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.14),
                        const Color(0xFF059669).withValues(alpha: isDark ? 0.15 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : const Color(0xFF059669).withValues(alpha: 0.45),
                      width: 0.9,
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
                Text('🥇', style: TextStyle(fontSize: 13.5)),
                SizedBox(width: 3),
                Text('🥈', style: TextStyle(fontSize: 13.5)),
                SizedBox(width: 3),
                Text('🥉', style: TextStyle(fontSize: 13.5)),
              ],
            ),
            onTap: () => Navigator.push(context, FadeScaleRoute(page: const TrophyRoomScreen())),
          ),
        ),
        const SizedBox(width: 8),
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
                _buildMiniBar(height: 6.5, color: progressPrimaryColor.withValues(alpha: 0.35)),
                const SizedBox(width: 2.5),
                _buildMiniBar(height: 10.5, color: progressPrimaryColor.withValues(alpha: 0.65)),
                const SizedBox(width: 2.5),
                _buildMiniBar(height: 14.5, color: progressPrimaryColor),
                const SizedBox(width: 3),
                Icon(LucideIcons.arrowUpRight, size: 11.5, color: progressPrimaryColor),
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
      width: 4.5,
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
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
              height: 74,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.12 : 0.70),
                    Colors.white.withValues(alpha: isDark ? 0.04 : 0.28),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: glowColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 0.9,
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
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Icon(icon, color: Colors.white, size: 12.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: effectiveBadgeColor.withValues(alpha: isDark ? 0.35 : 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: effectiveBadgeColor,
                            fontSize: 9.5,
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 13,
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
    ParentNotificationsState notifState,
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
              // Row 0: Notifications Center
              _buildGroupedItem(
                icon: LucideIcons.bellRing,
                gradientColors: const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                title: 'Центр сповіщень',
                subtitle: notifState.hasUnread
                    ? 'Нових нагадувань: ${notifState.unreadCount}'
                    : 'Всі повідомлення та нагадування',
                textColor: textColor,
                subColor: notifState.hasUnread ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)) : subColor,
                isDark: isDark,
                trailingWidget: notifState.hasUnread
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notifState.unreadCount} нових',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : null,
                onTap: () => ParentNotificationsSheet.show(context),
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
              // Row 1: Theme Switcher
              _buildGroupedItem(
                icon: LucideIcons.palette,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                title: 'Тема додатку',
                subtitle: themeConfig.title,
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 13.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: textColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFFB0D4EC) : subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 5),
              ],
              Icon(
                LucideIcons.chevronRight,
                size: 14,
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
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _confirmLogout(context, ref, isDark),
            child: Container(
              width: double.infinity,
              height: 38,
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                      : const Color(0xFFFECDD3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFE11D48))
                        .withValues(alpha: isDark ? 0.14 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: rubyColor, size: 15),
                  const SizedBox(width: 7),
                  Text(
                    'parent.logout_short'.tr(),
                    style: TextStyle(
                      color: rubyColor,
                      fontSize: 13.5,
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
      builder: (ctx) => AddChildSheet(isDark: isDark),
    );
  }

  void _showEditChildDialog(BuildContext context, WidgetRef ref, Child child, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditChildSheet(child: child, isDark: isDark),
    );
  }

  void _showSettingsDialog(BuildContext context, bool isDark, AppThemeConfig themeConfig) {
    bool pushNotificationsEnabled = true;

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
                  colors: isDark
                      ? [
                          const Color(0xFF0E3D64).withValues(alpha: 0.85),
                          const Color(0xFF092842).withValues(alpha: 0.90),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.96),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.94),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                      : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.45 : 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.settings, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Налаштування',
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                  : const Color(0xFFE0F2FE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.palette,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            'Тема додатку',
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: Text(
                            themeConfig.title,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB0D4EC) : themeConfig.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            ThemeSwitcherSheet.show(context);
                          },
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                        StatefulBuilder(
                          builder: (context, setLocalState) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : const Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.bell,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Push-сповіщення',
                                          style: TextStyle(
                                            color: themeConfig.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Нагадування про тренування',
                                          style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFB0D4EC)
                                                : themeConfig.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: pushNotificationsEnabled,
                                    onChanged: (v) {
                                      setLocalState(() => pushNotificationsEnabled = v);
                                    },
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF0284C7),
                                    inactiveThumbColor: isDark ? const Color(0xFF94A3B8) : Colors.white,
                                    inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Shortcut to open Notifications Sheet directly
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            ParentNotificationsSheet.show(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.15) : const Color(0xFFE0F2FE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.bellRing,
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Переглянути всі сповіщення',
                                        style: TextStyle(
                                          color: themeConfig.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Нагадування про абонемент та тренування',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFB0D4EC) : themeConfig.textSecondary,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
                              color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Закрити',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
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
