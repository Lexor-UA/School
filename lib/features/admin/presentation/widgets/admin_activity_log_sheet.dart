import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/models/activity_log.dart';

enum ActivityPeriod { day, week, month }

class AdminActivityLogSheet extends ConsumerStatefulWidget {
  final List<ActivityLog> actions;

  const AdminActivityLogSheet({
    super.key,
    required this.actions,
  });

  @override
  ConsumerState<AdminActivityLogSheet> createState() => AdminActivityLogSheetState();
}

class AdminActivityLogSheetState extends ConsumerState<AdminActivityLogSheet> {
  ActivityPeriod _selectedPeriod = ActivityPeriod.day;

  IconData _getActionIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('абонемент') || lower.contains('абон')) {
      return LucideIcons.creditCard;
    }
    if (lower.contains('учен') || lower.contains('клієнт') || lower.contains('дитин')) {
      return LucideIcons.userCheck;
    }
    if (lower.contains('тренер') || lower.contains('інструктор')) {
      return LucideIcons.award;
    }
    if (lower.contains('заняття') || lower.contains('тренуван') || lower.contains('розклад')) {
      return LucideIcons.calendar;
    }
    if (lower.contains('оплат') || lower.contains('чек') || lower.contains('грн') || lower.contains('грош')) {
      return LucideIcons.wallet;
    }
    if (lower.contains('видален') || lower.contains('скасув')) {
      return LucideIcons.trash2;
    }
    return LucideIcons.activity;
  }

  Color _getActionColor(String action, AppThemeConfig currentTheme) {
    final lower = action.toLowerCase();
    if (lower.contains('видален') || lower.contains('скасув')) {
      return const Color(0xFFF43F5E);
    }
    if (lower.contains('оплат') || lower.contains('чек') || lower.contains('грн')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('абонемент')) {
      return const Color(0xFF38BDF8);
    }
    if (lower.contains('тренер')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('учен') || lower.contains('клієнт')) {
      return const Color(0xFF8B5CF6);
    }
    return currentTheme.accentPrimary;
  }

  String _formatActionTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Щойно';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${'admin.mins_ago'.tr()}';
    } else if (diff.inHours < 24 && timestamp.day == now.day) {
      return '${'admin.today'.tr()}, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (diff.inHours < 48 && timestamp.day == now.subtract(const Duration(days: 1)).day) {
      return 'Вчора, ${DateFormat('HH:mm').format(timestamp)}';
    } else if (timestamp.year == now.year) {
      return DateFormat('d MMM, HH:mm', 'uk').format(timestamp);
    } else {
      return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;

    final now = DateTime.now();
    final dayCutoff = now.subtract(const Duration(hours: 24));
    final weekCutoff = now.subtract(const Duration(days: 7));
    final monthCutoff = now.subtract(const Duration(days: 30));

    final dayActions = widget.actions.where((a) =>
        a.timestamp.isAfter(dayCutoff) ||
        (a.timestamp.year == now.year && a.timestamp.month == now.month && a.timestamp.day == now.day)).toList();
    final weekActions = widget.actions.where((a) => a.timestamp.isAfter(weekCutoff)).toList();
    final monthActions = widget.actions.where((a) => a.timestamp.isAfter(monthCutoff)).toList();

    final List<ActivityLog> currentList;
    final String emptyTitle;
    final String emptySubtitle;

    switch (_selectedPeriod) {
      case ActivityPeriod.day:
        currentList = dayActions;
        emptyTitle = 'Немає дій за день';
        emptySubtitle = 'За останні 24 години нових змін чи активностей не зафіксовано';
        break;
      case ActivityPeriod.week:
        currentList = weekActions;
        emptyTitle = 'Немає дій за тиждень';
        emptySubtitle = 'За останні 7 днів нових записів активностей не знайдено';
        break;
      case ActivityPeriod.month:
        currentList = monthActions;
        emptyTitle = 'Немає дій за місяць';
        emptySubtitle = 'За останні 30 днів записи дій адміністратора відсутні';
        break;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF13233C).withValues(alpha: 0.96),
                      const Color(0xFF0C1626).withValues(alpha: 0.98),
                    ],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                  : currentTheme.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 18, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: currentTheme.accentGradient,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentTheme.accentPrimary.withValues(alpha: 0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.history,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'admin.recent_actions'.tr(),
                            style: TextStyle(
                              color: currentTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Журнал активностей адміністратора',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isDark ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(LucideIcons.x, color: isDark ? Colors.white70 : currentTheme.textSecondary, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Control: День | Тиждень | Місяць
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : currentTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    _buildPeriodTab(
                      title: 'День',
                      count: dayActions.length,
                      period: ActivityPeriod.day,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    _buildPeriodTab(
                      title: 'Тиждень',
                      count: weekActions.length,
                      period: ActivityPeriod.week,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                    _buildPeriodTab(
                      title: 'Місяць',
                      count: monthActions.length,
                      period: ActivityPeriod.month,
                      currentTheme: currentTheme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Divider(
                color: isDark ? Colors.white10 : currentTheme.cardBorder,
                height: 1,
              ),

              // List of actions or period empty state
              Flexible(
                child: currentList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.clockAlert,
                                  size: 32,
                                  color: currentTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              emptyTitle,
                              style: TextStyle(
                                color: currentTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              emptySubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final a = currentList[index];
                          final actionIcon = _getActionIcon(a.action);
                          final actionColor = _getActionColor(a.action, currentTheme);
                          final timeStr = _formatActionTime(a.timestamp);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.white.withValues(alpha: 0.03),
                                      ],
                                    )
                                  : null,
                              color: isDark ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : currentTheme.cardBorder,
                              ),
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: actionColor.withValues(alpha: isDark ? 0.45 : 0.25),
                                    ),
                                    boxShadow: isDark
                                        ? [
                                            BoxShadow(
                                              color: actionColor.withValues(alpha: 0.28),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      actionIcon,
                                      color: actionColor,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.action,
                                        style: TextStyle(
                                          color: currentTheme.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.clock,
                                            size: 11,
                                            color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted,
                                              fontSize: 11.5,
                                              fontWeight: isDark ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String title,
    required int count,
    required ActivityPeriod period,
    required AppThemeConfig currentTheme,
    required bool isDark,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              _selectedPeriod = period;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: currentTheme.accentGradient,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.28)
                      : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
