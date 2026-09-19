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
import 'package:swimming_school_app/features/parent/controllers/parent_notifications_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/parent_notifications_sheet.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/family_management_sheet.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/parent/presentation/edit_child_sheet.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
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
          const SizedBox(height: 10),

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
          const SizedBox(height: 10),

          // 3. 2-Column Bento Sport Cards (Trophies + Progress)
          _buildBentoSportCards(
            context,
            ref,
            isDark,
            textColor,
            textSubColor,
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 10),

          // 4. VisionOS Grouped Settings Card
          _buildGroupedSettingsCard(
            context,
            ref,
            isDark,
            textColor,
            textSubColor,
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuad),
          const SizedBox(height: 10),

          // 5. Luminous Ruby Logout Button (Clean, no version text)
          _buildLogoutFooter(
            context,
            ref,
            isDark,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                    padding: const EdgeInsets.all(2.5),
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
                      child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 25.5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
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
                          size: 12,
                          color: isDark ? accentColor : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
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

              const SizedBox(height: 9),
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
              const SizedBox(height: 8),

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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4.5),
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
            fontSize: 11.5,
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
    final familyAsync = ref.watch(familyStreamProvider);
    final family = familyAsync.value;
    final user = ref.watch(authControllerProvider);
    final isPaired = family?.isPaired ?? false;
    final partnerName = family?.getOtherParentName(user?.id ?? '') ?? '';
    final partnerPhone = family?.getOtherParentPhone(user?.id ?? '') ?? '';
    final partnerDisplayName = partnerName.trim().isNotEmpty 
        ? partnerName.trim() 
        : (partnerPhone.isNotEmpty ? partnerPhone : 'Другий з батьків');
    final partnerInitial = partnerDisplayName.isNotEmpty ? partnerDisplayName[0].toUpperCase() : 'П';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.50),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Family header & Family Access Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      const SizedBox(width: 8),
                      Text(
                        'Родина та діти',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => FamilyManagementSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaired
                            ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12)
                            : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.16) : const Color(0xFF0284C7).withValues(alpha: 0.10)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPaired
                              ? const Color(0xFF10B981).withValues(alpha: 0.45)
                              : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.3)),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaired ? LucideIcons.heartHandshake : LucideIcons.userPlus,
                            size: 13,
                            color: isPaired
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPaired ? 'Сім\'я: $partnerDisplayName' : 'Сімейний акаунт',
                            style: TextStyle(
                              color: isPaired
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                  : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: isPaired
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Prominent Partner Tile (when paired)
              if (isPaired) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => FamilyManagementSheet.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF10B981).withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.03),
                              ]
                            : [
                                const Color(0xFFECFDF5),
                                Colors.white.withValues(alpha: 0.85),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.28),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              partnerInitial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      partnerDisplayName,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Партнер',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                partnerPhone.isNotEmpty
                                    ? '$partnerPhone • Спільний доступ'
                                    : 'Спільний доступ активний',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFB0D4EC) : subColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 15,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Bottom Row: Children List & Add Button
              Row(
                children: [
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
                      child: Text(
                        'Додайте дитину для тренувань',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFB0D4EC) : subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Add child button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _showAddChildDialog(context, ref, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
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
                Text('🥇', style: TextStyle(fontSize: 15)),
                SizedBox(width: 4),
                Text('🥈', style: TextStyle(fontSize: 15)),
                SizedBox(width: 4),
                Text('🥉', style: TextStyle(fontSize: 15)),
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
                _buildMiniBar(height: 8.0, color: progressPrimaryColor.withValues(alpha: 0.35)),
                const SizedBox(width: 3.0),
                _buildMiniBar(height: 12.5, color: progressPrimaryColor.withValues(alpha: 0.65)),
                const SizedBox(width: 3.0),
                _buildMiniBar(height: 17.0, color: progressPrimaryColor),
                const SizedBox(width: 3.5),
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
      width: 5.0,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
              height: 88,
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
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Icon(icon, color: Colors.white, size: 13.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
                        size: 14,
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
    WidgetRef ref,
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
              // Push-сповіщення (Direct Switch Toggle)
              _buildPushNotificationRow(
                ref: ref,
                isDark: isDark,
                textColor: textColor,
                subColor: subColor,
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
              // Row 3: Family Account Tile
              _buildGroupedItem(
                icon: LucideIcons.heartHandshake,
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                title: 'Сімейний акаунт',
                subtitle: ref.watch(familyStreamProvider).value?.isPaired == true
                    ? 'Спільний доступ активний'
                    : 'Підключити чоловіка / дружину',
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                onTap: () => FamilyManagementSheet.show(context),
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
              // Row 4: Support Chat
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          child: Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.5),
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 11),
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

  // 5. Luminous Ruby Logout Button (High-contrast, vibrant ruby glass in light & dark themes)
  Widget _buildLogoutFooter(BuildContext context, WidgetRef ref, bool isDark) {
    final rubyAccent = isDark ? const Color(0xFFFF4D6D) : const Color(0xFFE11D48);

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
                          const Color(0xFFDC2626).withValues(alpha: 0.32),
                          const Color(0xFF7F1D1D).withValues(alpha: 0.45),
                        ]
                      : [
                          const Color(0xFFFFF1F2),
                          const Color(0xFFFFE4E6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFB7185).withValues(alpha: 0.70)
                      : const Color(0xFFFDA4AF),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFFE11D48) : const Color(0xFFBE123C))
                        .withValues(alpha: isDark ? 0.32 : 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: rubyAccent, size: 18),
                  const SizedBox(width: 9),
                  Text(
                    'parent.logout_short'.tr(),
                    style: TextStyle(
                      color: rubyAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
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

  Widget _buildPushNotificationRow({
    required WidgetRef ref,
    required bool isDark,
    required Color textColor,
    required Color subColor,
  }) {
    final pushEnabled = ref.watch(pushNotificationsEnabledProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.30),
                  blurRadius: 5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.bell, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Push-сповіщення',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  'Нагадування про тренування',
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB0D4EC) : subColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: pushEnabled,
              onChanged: (v) {
                ref.read(pushNotificationsEnabledProvider.notifier).toggle(v);
              },
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF0284C7),
              inactiveThumbColor: isDark ? const Color(0xFF94A3B8) : Colors.white,
              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

