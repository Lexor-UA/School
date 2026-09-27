import 'dart:ui';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
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
import 'package:swimming_school_app/features/parent/presentation/graduate_child_sheet.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swimming_school_app/features/parent/presentation/widgets/client_dialogs_sheet.dart';
import 'package:swimming_school_app/core/router/app_router.dart';

/// Варіанти стилізації карток та елементів екрана профілю для порівняння та тестування
enum ProfileStyleVariant {
  deepSapphireGlass, // Варіант 1: «Deep Sapphire Glass» (Преміальне сапфірове скло, 85-90% непрозорість, перловий текст #E2E8F0, смарагдовий акцент)
  solidOceanicCards, // Варіант 2: «Solid Oceanic Cards» (Солідні океанічні плашки 96-98%, максимальний контраст #F1F5F9, неоновий контур #00E5FF)
  originalClassic,   // Оригінал (Повний відкат до попереднього стану: білий frost 10-12%, підписи #B0D4EC)
}

/// Поточний активний стиль профілю (для легкого перемикання між варіантами або повернення як було)
const ProfileStyleVariant currentProfileVariant = ProfileStyleVariant.solidOceanicCards;

class _ProfileStyleConfig {
  static BoxDecoration cardDecoration(bool isDark, {double radius = 22}) {
    if (!isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.70),
            Colors.white.withValues(alpha: 0.30),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140284C7),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      );
    }

    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0E2847).withValues(alpha: 0.85),
              const Color(0xFF071B30).withValues(alpha: 0.90),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF021020).withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case ProfileStyleVariant.solidOceanicCards:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A2239).withValues(alpha: 0.96),
              const Color(0xFF051525).withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF010A14).withValues(alpha: 0.70),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        );

      case ProfileStyleVariant.originalClassic:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  static Color subtitleColor(bool isDark, Color fallbackSubColor) {
    if (!isDark) return fallbackSubColor;
    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return const Color(0xFFE2E8F0);
      case ProfileStyleVariant.solidOceanicCards:
        return const Color(0xFFF1F5F9);
      case ProfileStyleVariant.originalClassic:
        return const Color(0xFFB0D4EC);
    }
  }

  static Color statsUnitColor(bool isDark, Color fallbackAccent) {
    if (!isDark) return fallbackAccent;
    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return const Color(0xFF38BDF8);
      case ProfileStyleVariant.solidOceanicCards:
        return const Color(0xFF00E5FF);
      case ProfileStyleVariant.originalClassic:
        return fallbackAccent;
    }
  }

  static BoxDecoration statusBadgeDecoration(bool isDark, Color accentColor) {
    if (!isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0284C7).withValues(alpha: 0.14),
            const Color(0xFF0369A1).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
          width: 0.9,
        ),
      );
    }

    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00E5FF).withValues(alpha: 0.22),
              const Color(0xFF0284C7).withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.65),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
              blurRadius: 8,
            ),
          ],
        );
      case ProfileStyleVariant.solidOceanicCards:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0284C7).withValues(alpha: 0.30),
              const Color(0xFF0369A1).withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.75),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        );
      case ProfileStyleVariant.originalClassic:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.22),
              accentColor.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.45),
            width: 0.9,
          ),
        );
    }
  }

  static Color statusBadgeTextColor(bool isDark, Color accentColor) {
    if (!isDark) return const Color(0xFF0284C7);
    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return const Color(0xFFE0F7FA);
      case ProfileStyleVariant.solidOceanicCards:
        return Colors.white;
      case ProfileStyleVariant.originalClassic:
        return accentColor;
    }
  }

  static BoxDecoration addChildButtonDecoration(bool isDark) {
    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF34D399).withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case ProfileStyleVariant.solidOceanicCards:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case ProfileStyleVariant.originalClassic:
        return BoxDecoration(
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
            width: 0.9,
          ),
        );
    }
  }

  static Color addChildTextColor(bool isDark) {
    switch (currentProfileVariant) {
      case ProfileStyleVariant.deepSapphireGlass:
      case ProfileStyleVariant.solidOceanicCards:
        return Colors.white;
      case ProfileStyleVariant.originalClassic:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    }
  }
}

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
                  color: isDark ? const Color(0xFF0E2847).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                        : const Color(0xFFBAE6FD),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? const Color(0xFF021020).withValues(alpha: 0.45) : const Color(0xFF0284C7).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final minContentHeight = constraints.maxHeight - 121;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 115),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minContentHeight > 0 ? minContentHeight : 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
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
                      ),
                      const SizedBox(height: 13),

                      // 2. Family & Children Section
                      _buildFamilySection(
                        context,
                        ref,
                        childrenList,
                        isDark,
                        textColor,
                        textSubColor,
                        accentColor,
                      ),
                      const SizedBox(height: 13),

                      // 3. VisionOS Grouped Settings Card
                      _buildGroupedSettingsCard(
                        context,
                        ref,
                        user,
                        isDark,
                        textColor,
                        textSubColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 5. Luminous Ruby Logout Button (Clean, no version text)
                  _buildLogoutFooter(
                    context,
                    ref,
                    isDark,
                  ),
                ],
              ),
            ),
          );
        },
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
  ) {
    final fbUser = FirebaseAuth.instance.currentUser;
    final contactInfo = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : (fbUser?.email != null && fbUser!.email!.isNotEmpty)
            ? fbUser.email!
            : (user?.loginId != null && user!.loginId!.isNotEmpty)
                ? user.loginId!
                : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16, tileMode: TileMode.decal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: _ProfileStyleConfig.cardDecoration(isDark, radius: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Avatar + Name + Badges
              Row(
                children: [
                  // Avatar with glowing halo
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor, Colors.blueAccent, Colors.cyanAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.38),
                          blurRadius: 14,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1E32) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 29.5),
                    ),
                  ),
                  const SizedBox(width: 13),
                  // Name & Contact Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'New User')
                              ? user.name
                              : (fbUser?.displayName?.trim().isNotEmpty == true
                                  ? fbUser!.displayName!.trim()
                                  : 'Олександр'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contactInfo != null) ...[
                          const SizedBox(height: 2.5),
                          Text(
                            contactInfo,
                            style: TextStyle(
                              color: _ProfileStyleConfig.subtitleColor(isDark, subColor),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: _ProfileStyleConfig.statusBadgeDecoration(isDark, accentColor),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 13.5,
                            color: _ProfileStyleConfig.statusBadgeTextColor(isDark, accentColor),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasChildren ? 'parent.parent_account'.tr() : 'parent.client_account'.tr(),
                            style: TextStyle(
                              color: _ProfileStyleConfig.statusBadgeTextColor(isDark, accentColor),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
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
                            const Color(0xFF00E5FF).withValues(alpha: 0.20),
                            Colors.transparent,
                          ]
                        : [
                            Colors.transparent,
                            const Color(0xFF0284C7).withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 11),

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
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                Colors.transparent,
                                const Color(0xFF00E5FF).withValues(alpha: 0.25),
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
            Icon(icon, size: 16.5, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2.5),
              Text(
                unit,
                style: TextStyle(
                  color: _ProfileStyleConfig.statsUnitColor(isDark, color),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: _ProfileStyleConfig.subtitleColor(isDark, subColor),
            fontSize: 12.5,
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
    final partnerInitial = partnerDisplayName.characters.isNotEmpty ? partnerDisplayName.characters.first.toUpperCase() : 'П';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14, tileMode: TileMode.decal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _ProfileStyleConfig.cardDecoration(isDark, radius: 20),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.users, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Родина та діти',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => FamilyManagementSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
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
                              size: 13.5,
                              color: isPaired
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 4.5),
                            Flexible(
                              child: Text(
                                isPaired ? 'Сім\'я: $partnerDisplayName' : 'Сімейний акаунт',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPaired
                                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                                      : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3.5),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 13,
                              color: isPaired
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Prominent Partner Tile (when paired)
              if (isPaired) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => FamilyManagementSheet.show(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
                          width: 34,
                          height: 34,
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
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
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
                                        fontSize: 13.5,
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
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                partnerPhone.isNotEmpty
                                    ? '$partnerPhone • Спільний доступ'
                                    : 'Спільний доступ активний',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFB0D4EC) : subColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Graduation callout banner for teens reaching 16+
              if (children.any((c) => c.isAdultAge)) ...[
                ...children.where((c) => c.isAdultAge).map((adultChild) => Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF10B981).withValues(alpha: 0.22),
                              const Color(0xFF06B6D4).withValues(alpha: 0.12),
                            ]
                          : [
                              const Color(0xFFECFDF5),
                              const Color(0xFFF0FDF4),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.35),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.graduationCap, color: Colors.white, size: 17),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${adultChild.name} вже 16 років! 🎓',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              'Час перевести у дорослий акаунт зі збереженням занять та нагород',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFB0D4EC) : subColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => GraduateChildSheet.show(context, adultChild),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Випустити',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
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
                                margin: const EdgeInsets.only(right: 7),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: childColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      child.currentAge != null ? '${child.name} (${formatAgeUk(child.currentAge!)})' : child.name,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (child.isAdultAge) ...[
                                      const SizedBox(width: 3.5),
                                      const Text('🎓', style: TextStyle(fontSize: 11.5)),
                                    ],
                                    const SizedBox(width: 5),
                                    Icon(
                                      LucideIcons.pencil,
                                      size: 12,
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
                          color: _ProfileStyleConfig.subtitleColor(isDark, subColor),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 9),
                  // Add child button
                  InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _showAddChildDialog(context, ref, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: _ProfileStyleConfig.addChildButtonDecoration(isDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: _ProfileStyleConfig.addChildTextColor(isDark),
                          ),
                          const SizedBox(width: 4.5),
                          Text(
                            'Додати',
                            style: TextStyle(
                              color: _ProfileStyleConfig.addChildTextColor(isDark),
                              fontSize: 12.5,
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

  // 3. VisionOS Grouped Settings Card
  Widget _buildGroupedSettingsCard(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    final clientUnread = user != null ? ref.watch(clientUnreadBadgeProvider(user.id)) : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16, tileMode: TileMode.decal),
        child: Container(
          decoration: _ProfileStyleConfig.cardDecoration(isDark, radius: 22),
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
                padding: const EdgeInsets.only(left: 64, right: 16),
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
              // Row 2: Family Account Tile
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
                padding: const EdgeInsets.only(left: 64, right: 16),
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
              // Row 3: Messages & Support Chat
              _buildGroupedItem(
                icon: LucideIcons.messageSquare,
                gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                title: 'Повідомлення та підтримка',
                subtitle: 'Чат з адміністратором та тренером',
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                trailingWidget: clientUnread > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          '$clientUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : null,
                onTap: () => showClientDialogsSheet(context),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 64, right: 16),
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
              // Row 4: Branch Location (Locked upon registration)
              _buildGroupedItem(
                icon: LucideIcons.mapPin,
                gradientColors: const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                title: 'Філія та локація',
                subtitle: user?.branchId == 'vienna' ? '🇦🇹 Відень' : '🇺🇦 Київ',
                textColor: textColor,
                subColor: subColor,
                isDark: isDark,
                showChevron: false,
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              const Color(0xFF0284C7).withValues(alpha: 0.10),
                            ]
                          : [
                              const Color(0xFFE0F2FE),
                              const Color(0xFFBAE6FD).withValues(alpha: 0.6),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: currentProfileVariant == ProfileStyleVariant.originalClassic ? 0.45 : 0.65)
                          : const Color(0xFF0284C7).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.20),
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          size: 10,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Закріплено',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: _ProfileStyleConfig.statusBadgeTextColor(isDark, const Color(0xFF00E5FF)),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 12,
                        color: (isDark ? (currentProfileVariant == ProfileStyleVariant.originalClassic ? const Color(0xFF00E5FF) : Colors.white) : const Color(0xFF0284C7)).withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showBranchInfoSheet(context, isDark, user?.branchId ?? 'kyiv');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchInfoSheet(BuildContext context, bool isDark, String branchId) {
    final isVienna = branchId == 'vienna';
    final branchTitle = isVienna ? 'CitySwim Відень' : 'CitySwim Київ';
    final flag = isVienna ? '🇦🇹' : '🇺🇦';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: math.max(MediaQuery.of(ctx).padding.bottom, 20) + 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.97),
                  isDark ? const Color(0xFF070E1A).withValues(alpha: 0.98) : const Color(0xFFF1F5F9).withValues(alpha: 0.98),
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
              children: [
                // Top drag handle with close button row
                Row(
                  children: [
                    const SizedBox(width: 34),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                      tooltip: 'Закрити',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location Pin Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF0E3D64), Color(0xFF082038)]
                          : const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.65 : 0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.28 : 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.mapPin,
                      size: 28,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  '$flag $branchTitle',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFF7DD3FC),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 14,
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Основна закріплена філія',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D2137).withValues(alpha: 0.65) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          LucideIcons.info,
                          size: 16,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ця філія закріплена за вашим акаунтом для персонального розкладу та абонементів. Якщо ви бажаєте змінити філію, будь ласка, зверніться до адміністратора.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? Colors.white.withValues(alpha: 0.78) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Button (Sapphire VIP CTA)
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF0E3D64), Color(0xFF082038)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.70 : 0.40),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.28 : 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                      showClientDialogsSheet(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          size: 19,
                          color: isDark ? const Color(0xFF00E5FF) : Colors.white,
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Написати адміністратору',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            height: 1.25,
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
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.5),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                          color: textColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _ProfileStyleConfig.subtitleColor(isDark, subColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                if (showChevron) const SizedBox(width: 6),
              ],
              if (showChevron)
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: isDark
                      ? (currentProfileVariant == ProfileStyleVariant.originalClassic
                          ? const Color(0xFFB0D4EC).withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7))
                      : subColor.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. Luminous Velvet Ruby Logout Button (High-contrast, vibrant ruby gradient with crisp white text)
  Widget _buildLogoutFooter(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFFFF2A55),
                  const Color(0xFFC00030),
                ]
              : [
                  const Color(0xFFFF3366),
                  const Color(0xFFE11D48),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2A55).withValues(alpha: isDark ? 0.42 : 0.28),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.mediumImpact();
            _confirmLogout(context, ref, isDark);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'parent.logout_short'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authControllerProvider.notifier).logout();
              } catch (e) {
                debugPrint('Logout error: $e');
              }
              ref.read(parentTabProvider.notifier).setTab(0);
              ref.read(goRouterProvider).go('/?skipSplash=true');
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.30),
                  blurRadius: 5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.bell, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Push-сповіщення',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 1.5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Нагадування про тренування',
                    style: TextStyle(
                      color: _ProfileStyleConfig.subtitleColor(isDark, subColor),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.90,
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

