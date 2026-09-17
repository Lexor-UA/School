import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/class_activity.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class CoachChangesBanner extends ConsumerStatefulWidget {
  const CoachChangesBanner({super.key});

  @override
  ConsumerState<CoachChangesBanner> createState() => _CoachChangesBannerState();
}

class _CoachChangesBannerState extends ConsumerState<CoachChangesBanner> {
  bool _isExpanded = false;

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'щойно';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} хв тому';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return 'Сьогодні о ${DateFormat("HH:mm").format(dt)}';
    } else if (diff.inDays < 2) {
      return 'Вчора о ${DateFormat("HH:mm").format(dt)}';
    } else {
      return DateFormat('d MMM, HH:mm', 'uk').format(dt);
    }
  }

  void _showAllActivitiesModal(BuildContext context, List<ClassActivity> activities, AppThemeConfig themeConfig) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: themeConfig.isDark
                ? const Color(0xFF09182B).withValues(alpha: 0.96)
                : const Color(0xFFF0F9FF).withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: themeConfig.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : const Color(0xFF0284C7).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: themeConfig.isDark ? Colors.white24 : const Color(0xFF94A3B8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: themeConfig.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  LucideIcons.bellRing,
                                  color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'ІСТОРІЯ ЗМІН ТА ОНОВЛЕНЬ',
                                style: TextStyle(
                                  color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: themeConfig.isDark ? Colors.white70 : themeConfig.textMuted,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: activities.isEmpty
                            ? Center(
                                child: Text(
                                  'Змін за останній час не зафіксовано',
                                  style: TextStyle(color: themeConfig.textMuted),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: activities.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) => _buildActivityItem(activities[index], themeConfig),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final activitiesAsync = ref.watch(classActivitiesStreamProvider);

    return activitiesAsync.when(
      data: (allActivities) {
        // Filter by coach
        final activities = allActivities.where((act) {
          if (user?.id == 'mock_coach') return true;
          final matchesId = act.coachId == user?.id;
          final matchesName = user != null &&
              user.name.isNotEmpty &&
              act.coachName.toLowerCase().contains(user.name.toLowerCase());
          return matchesId || matchesName || act.coachId.isEmpty;
        }).toList();

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayCount = activities.where((a) => a.timestamp.isAfter(todayStart)).length;

        if (activities.isEmpty) {
          return const SizedBox.shrink();
        }

        final topActivities = _isExpanded ? activities.take(5).toList() : activities.take(2).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeConfig.isDark
                        ? [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.04),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.78),
                            Colors.white.withValues(alpha: 0.62),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: themeConfig.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.95),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeConfig.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                          : const Color(0xFF003B73).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: todayCount > 0
                                    ? [const Color(0xFF00E5FF), const Color(0xFF0284C7)]
                                    : [
                                        themeConfig.isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                        themeConfig.isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.bellRing, color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ОСТАННІ ЗМІНИ ПО ЗАНЯТТЯХ',
                                  style: TextStyle(
                                    color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Записи, скасування та оновлення',
                                  style: TextStyle(
                                    color: themeConfig.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (todayCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '+$todayCount сьогодні',
                                style: TextStyle(
                                  color: themeConfig.isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeConfig.isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.10),
                              border: Border.all(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  LucideIcons.chevronDown,
                                  color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Activities list
                    ...topActivities.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActivityItem(act, themeConfig),
                        )),

                    // Bottom actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                              decoration: BoxDecoration(
                                color: themeConfig.isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: themeConfig.isDark
                                      ? Colors.white.withValues(alpha: 0.16)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.30),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.0 : 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isExpanded ? 'Згорнути' : 'Показати ще (${activities.length})',
                                    style: TextStyle(
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                    size: 13,
                                    color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAllActivitiesModal(context, activities, themeConfig),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                              decoration: BoxDecoration(
                                color: themeConfig.isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.10)
                                    : const Color(0xFFE0F2FE).withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: themeConfig.isDark
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.32)
                                      : const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: themeConfig.isDark ? 0.0 : 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Вся історія',
                                    style: TextStyle(
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.arrowRight,
                                    size: 12,
                                    color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityItem(ClassActivity act, AppThemeConfig themeConfig) {
    Color iconColor;
    Color badgeTextColor;
    Color badgeBgColor;
    IconData iconData;
    String badgeText;

    switch (act.type) {
      case ClassActivityType.booking:
        iconColor = const Color(0xFF10B981);
        badgeTextColor = themeConfig.isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
        badgeBgColor = const Color(0xFF10B981).withValues(alpha: themeConfig.isDark ? 0.22 : 0.15);
        iconData = LucideIcons.userPlus;
        badgeText = 'Запис';
        break;
      case ClassActivityType.cancellation:
        iconColor = const Color(0xFFF43F5E);
        badgeTextColor = themeConfig.isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C);
        badgeBgColor = const Color(0xFFF43F5E).withValues(alpha: themeConfig.isDark ? 0.22 : 0.15);
        iconData = LucideIcons.userMinus;
        badgeText = 'Скасування';
        break;
      case ClassActivityType.rescheduled:
        iconColor = const Color(0xFFF59E0B);
        badgeTextColor = themeConfig.isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
        badgeBgColor = const Color(0xFFF59E0B).withValues(alpha: themeConfig.isDark ? 0.22 : 0.15);
        iconData = LucideIcons.calendarClock;
        badgeText = 'Розклад';
        break;
      case ClassActivityType.classCancelled:
        iconColor = const Color(0xFFF43F5E);
        badgeTextColor = themeConfig.isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C);
        badgeBgColor = const Color(0xFFF43F5E).withValues(alpha: themeConfig.isDark ? 0.22 : 0.15);
        iconData = LucideIcons.alertTriangle;
        badgeText = 'Заняття скасовано';
        break;
      default:
        iconColor = const Color(0xFF00E5FF);
        badgeTextColor = themeConfig.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
        badgeBgColor = const Color(0xFF00E5FF).withValues(alpha: themeConfig.isDark ? 0.22 : 0.15);
        iconData = LucideIcons.info;
        badgeText = 'Зміна';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: themeConfig.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeConfig.isDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFBAE6FD).withValues(alpha: 0.70),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeConfig.isDark
                ? Colors.black.withValues(alpha: 0.20)
                : const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: themeConfig.isDark ? 0.18 : 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.40)),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: themeConfig.isDark ? 0.28 : 0.16),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(iconData, color: badgeTextColor, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: iconColor.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimeAgo(act.timestamp),
                      style: TextStyle(
                        color: themeConfig.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  act.message,
                  style: TextStyle(
                    color: themeConfig.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (act.parentPhone != null && act.parentPhone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(LucideIcons.phone, size: 11, color: themeConfig.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        act.parentPhone!,
                        style: TextStyle(color: themeConfig.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
