import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/coach/controllers/coach_rating_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';

/// Luxury interactive star rating panel placed directly on completed class cards.
/// Enables clients to rate the coach (1 to 5 stars) with instant haptic feedback,
/// vibrant amber glow, and persistent local/Firestore synchronization.
class CompletedClassCoachRatingBar extends ConsumerWidget {
  final GroupClass classItem;
  final AppThemeConfig currentTheme;

  const CompletedClassCoachRatingBar({
    super.key,
    required this.classItem,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only display rating if a real coach is assigned
    final coachName = classItem.coachName.trim();
    if (coachName.isEmpty ||
        coachName == 'Тренер не призначений' ||
        coachName.toLowerCase().contains('не призначен')) {
      return const SizedBox.shrink();
    }

    final user = ref.watch(authControllerProvider);

    // Strict attendance check: star rating is ONLY displayed if client or their child actually attended
    final children = ref.watch(childrenControllerProvider).value ?? [];
    final family = ref.watch(familyStreamProvider).value;
    final parentIds = (family != null && (family.parentIds.isNotEmpty || family.parentNames.isNotEmpty))
        ? {...family.parentIds, ...family.parentNames.keys}
        : (user != null ? {user.id} : <String>{});
    final partnerId = user != null ? family?.getOtherParentId(user.id) : null;
    final allFamilyIds = {
      ...parentIds,
      ?partnerId,
      ...children.map((c) => c.id),
    };

    final wasPresent = classItem.attendedChildIds.any((id) => allFamilyIds.contains(id));
    if (!wasPresent) {
      return const SizedBox.shrink();
    }

    final clientId = user?.id.isNotEmpty == true ? user!.id : 'guest_client';
    final clientName = user?.name.isNotEmpty == true ? user!.name : 'Клієнт';

    final ratingArg = (classId: classItem.id, clientId: clientId);
    final currentRating = ref.watch(classRatingProvider(ratingArg));
    final hasRated = currentRating != null && currentRating > 0;
    final isDark = currentTheme.isDark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? (hasRated
                  ? [
                      const Color(0xFF261D11).withValues(alpha: 0.75),
                      const Color(0xFF17120C).withValues(alpha: 0.90),
                    ]
                  : [
                      const Color(0xFF0F1E2E).withValues(alpha: 0.65),
                      const Color(0xFF0A1522).withValues(alpha: 0.85),
                    ])
              : (hasRated
                  ? [
                      const Color(0xFFFFFBEB),
                      const Color(0xFFFEF3C7).withValues(alpha: 0.70),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9),
                    ]),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRated
              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.50 : 0.40)
              : (isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                  : const Color(0xFFE2E8F0)),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasRated
                ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.10)
                : Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Award / Star Icon Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasRated
                        ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                        : (isDark
                            ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                            : const [Color(0xFF38BDF8), Color(0xFF0284C7)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (hasRated ? const Color(0xFFF59E0B) : const Color(0xFF0284C7))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    hasRated ? LucideIcons.award : LucideIcons.star,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 9),

              // Title and Coach Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasRated ? 'Ваша оцінка тренеру:' : 'Оцініть роботу тренера:',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      coachName,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // If already rated, show numerical badge
              if (hasRated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.20 : 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.40 : 0.30),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12.5, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        '$currentRating.0',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // 5 Interactive Stars Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isFilled = (currentRating ?? 0) >= starVal;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      HapticFeedback.mediumImpact();

                      await ref.read(coachRatingControllerProvider.notifier).rateCoach(
                            classId: classItem.id,
                            coachId: classItem.coachId,
                            coachName: classItem.coachName,
                            clientId: clientId,
                            clientName: clientName,
                            stars: starVal,
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Дякуємо! Ви оцінили тренера $coachName на $starVal ★',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(milliseconds: 2200),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: AnimatedScale(
                        scale: isFilled ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 26,
                          color: isFilled
                              ? const Color(0xFFFBBF24)
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                          shadows: isFilled
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Helper caption
              Text(
                hasRated ? 'Дякуємо за оцінку!' : 'Натисніть зірочку',
                style: TextStyle(
                  color: hasRated
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  fontSize: 11,
                  fontWeight: hasRated ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
