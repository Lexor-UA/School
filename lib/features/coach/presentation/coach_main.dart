import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/core/router/app_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/shared/utils/app_snack_bar.dart';
import 'widgets/coach_dialogs_sheet.dart';
import 'coach_dashboard.dart';

class CoachMain extends ConsumerStatefulWidget {
  const CoachMain({super.key});

  @override
  ConsumerState<CoachMain> createState() => _CoachMainState();
}

class _CoachMainState extends ConsumerState<CoachMain> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);

    ref.listen<AppUser?>(authControllerProvider, (previous, next) {
      if (next == null && mounted) {
        ref.read(coachTabProvider.notifier).setTab(0);
        ref.read(goRouterProvider).go('/?skipSplash=true');
      }
    });

    final unreadCount = user != null ? ref.watch(coachUnreadBadgeProvider(user.id)) : 0;

    if (user != null) {
      ref.listen<int>(coachUnreadBadgeProvider(user.id), (previous, next) {
        if (previous != null && next > previous && mounted) {
          HapticFeedback.mediumImpact();
          AppSnackBar.show(
            context,
            message: 'У вас нове повідомлення від клієнта',
            icon: LucideIcons.messageSquare,
            backgroundColor: const Color(0xFF0284C7),
            action: SnackBarAction(
              label: 'Відкрити',
              textColor: Colors.white,
              onPressed: () => showCoachDialogsSheet(context),
            ),
          );
        }
      });
    }

    final selectedTab = ref.watch(coachTabProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: themeConfig.scaffoldBg,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Water animation background
            const Positioned.fill(
              child: RepaintBoundary(child: AnimatedWaterBackground()),
            ),

            // 2. Frosted fluid aquatic gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: themeConfig.bgGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Theme-tailored 3D animated water bubbles
            const Positioned.fill(
              child: RepaintBoundary(child: WaterParticles()),
            ),

            // 3. Main Tab Body
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: selectedTab,
                children: const [
                  CoachScheduleTab(),
                  CoachCalendarTab(),
                  CoachSwimmersTab(),
                  CoachProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. Floating Bottom Dock (VisionOS Deep Ocean Sapphire Glass)
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: themeConfig.isDark
                ? [
                    // Ambient ocean cyan aura
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: -1,
                      offset: const Offset(0, 6),
                    ),
                    // Deep solid ocean lift
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeConfig.isDark
                      ? const [
                          Color(0xFF0E2C4D),
                          Color(0xFF07192C),
                        ]
                      : const [
                          Color(0xFFFFFFFF),
                          Color(0xFFF8FAFC),
                        ],
                ),
                border: Border.all(
                  color: themeConfig.isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                      : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDockItem(
                    index: 0,
                    icon: LucideIcons.calendarClock,
                    label: 'coach.nav_schedule'.tr(),
                    isSelected: selectedTab == 0,
                    themeConfig: themeConfig,
                  ),
                  _buildDockItem(
                    index: 1,
                    icon: LucideIcons.calendarDays,
                    label: 'coach.nav_calendar'.tr(),
                    isSelected: selectedTab == 1,
                    themeConfig: themeConfig,
                  ),
                  _buildDockItem(
                    index: 2,
                    icon: LucideIcons.users,
                    label: 'coach.nav_swimmers'.tr(),
                    isSelected: selectedTab == 2,
                    themeConfig: themeConfig,
                  ),
                  _buildDockItem(
                    index: 3,
                    icon: LucideIcons.userCheck,
                    label: 'coach.nav_cabinet'.tr(),
                    isSelected: selectedTab == 3,
                    themeConfig: themeConfig,
                    badgeCount: unreadCount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required AppThemeConfig themeConfig,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(coachTabProvider.notifier).setTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 15 : 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeConfig.isDark
                      ? const [
                          Color(0xFF00E5FF),
                          Color(0xFF0284C7),
                        ]
                      : const [
                          Color(0xFF0EA5E9),
                          Color(0xFF0284C7),
                        ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (themeConfig.isDark
                    ? Colors.white.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.60))
                : Colors.transparent,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: themeConfig.isDark ? 0.45 : 0.28),
                    blurRadius: 16,
                    spreadRadius: themeConfig.isDark ? 0.5 : 0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (themeConfig.isDark ? const Color(0xFF7DD3FC).withValues(alpha: 0.75) : const Color(0xFF64748B)),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 7),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 180.ms).slideX(begin: -0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
