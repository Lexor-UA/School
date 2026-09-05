import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/class_activity.dart';

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

  void _showAllActivitiesModal(BuildContext context, List<ClassActivity> activities) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF09182B).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1.2),
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
                            color: Colors.white24,
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
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.bellRing, color: Color(0xFF00E5FF), size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'ІСТОРІЯ ЗМІН ТА ОНОВЛЕНЬ',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: activities.isEmpty
                            ? const Center(
                                child: Text(
                                  'Змін за останній час не зафіксовано',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: activities.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) => _buildActivityItem(activities[index]),
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: todayCount > 0
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: (todayCount > 0 ? const Color(0xFF00E5FF) : Colors.black).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
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
                                    : [Colors.white24, Colors.white12],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.bellRing, color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ОСТАННІ ЗМІНИ ПО ЗАНЯТТЯХ',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Записи, скасування та оновлення',
                                  style: TextStyle(
                                    color: Colors.white70,
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
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            color: Colors.white60,
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Activities list
                    ...topActivities.map((act) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildActivityItem(act),
                        )),

                    // Bottom actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isExpanded = !_isExpanded),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _isExpanded ? 'Згорнути' : 'Показати ще (${activities.length})',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showAllActivitiesModal(context, activities),
                          child: const Row(
                            children: [
                              Text(
                                'Вся історія',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(LucideIcons.arrowRight, size: 13, color: Colors.white60),
                            ],
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

  Widget _buildActivityItem(ClassActivity act) {
    Color iconColor;
    IconData iconData;
    String badgeText;

    switch (act.type) {
      case ClassActivityType.booking:
        iconColor = const Color(0xFF10B981);
        iconData = LucideIcons.userPlus;
        badgeText = 'Запис';
        break;
      case ClassActivityType.cancellation:
        iconColor = const Color(0xFFEF4444);
        iconData = LucideIcons.userMinus;
        badgeText = 'Скасування';
        break;
      case ClassActivityType.rescheduled:
        iconColor = const Color(0xFFF59E0B);
        iconData = LucideIcons.calendarClock;
        badgeText = 'Розклад';
        break;
      case ClassActivityType.classCancelled:
        iconColor = const Color(0xFFE11D48);
        iconData = LucideIcons.alertTriangle;
        badgeText = 'Заняття скасовано';
        break;
      default:
        iconColor = const Color(0xFF00E5FF);
        iconData = LucideIcons.info;
        badgeText = 'Зміна';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.35)),
            ),
            child: Icon(iconData, color: iconColor, size: 14),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimeAgo(act.timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  act.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (act.parentPhone != null && act.parentPhone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 11, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        act.parentPhone!,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
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
