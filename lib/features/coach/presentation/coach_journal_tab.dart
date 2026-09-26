import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/coach/presentation/coach_dashboard.dart';
import 'package:swimming_school_app/features/coach/presentation/qr_scanner_screen.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';

class CoachJournalTab extends ConsumerStatefulWidget {
  const CoachJournalTab({super.key});

  @override
  ConsumerState<CoachJournalTab> createState() => _CoachJournalTabState();
}

class _CoachJournalTabState extends ConsumerState<CoachJournalTab> {
  List<Child> _enrolledChildren = [];
  bool _isLoadingChildren = false;
  late DateTime _selectedDate;
  bool _onlyMyClasses = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateShort(DateTime date) {
    const months = [
      '', 'січ', 'лют', 'бер', 'кві', 'тра', 'чер',
      'лип', 'сер', 'вер', 'жов', 'лис', 'гру'
    ];
    return '${date.day} ${months[date.month]}';
  }

  Future<void> _fetchChildren(List<String> childIds) async {
    if (childIds.isEmpty) {
      if (mounted) setState(() => _enrolledChildren = []);
      return;
    }

    setState(() => _isLoadingChildren = true);
    try {
      final idsToFetch = childIds.take(20).toList();
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where(FieldPath.documentId, whereIn: idsToFetch)
          .get();

      final children = snapshot.docs.map((doc) => Child.fromJson({'id': doc.id, ...doc.data()})).toList();
      final foundIds = children.map((c) => c.id).toSet();
      final missingIds = idsToFetch.where((id) => !foundIds.contains(id)).toList();

      if (missingIds.isNotEmpty) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: missingIds)
            .get();

        for (final doc in userSnapshot.docs) {
          final data = doc.data();
          children.add(
            Child(
              id: doc.id,
              parentId: '',
              name: (data['name'] as String?)?.trim().isNotEmpty == true
                  ? (data['name'] as String).trim()
                  : 'Клієнт',
              level: (data['level'] as num?)?.toInt() ?? 1,
              xp: (data['xp'] as num?)?.toInt() ?? 0,
              maxXp: (data['maxXp'] as num?)?.toInt() ?? 100,
              colorHex: '0xFF00E5FF',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _enrolledChildren = children;
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching children: $e');
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _toggleAttendance(GroupClass gClass, String childId) async {
    final user = ref.read(authControllerProvider);
    if (user != null && user.role == UserRole.coach) {
      final coachBranch = user.branchId;
      final coachBranches = user.branchIds;
      final hasAccess = coachBranch == gClass.branchId || coachBranches.contains(gClass.branchId);
      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('У вас немає доступу до відмітки відвідування в іншій філії'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final isAttended = gClass.attendedChildIds.contains(childId);
    final newAttended = isAttended
        ? (List<String>.from(gClass.attendedChildIds)..remove(childId))
        : (List<String>.from(gClass.attendedChildIds)..add(childId));

    try {
      await FirebaseFirestore.instance.collection('classes').doc(gClass.id).update({
        'attendedChildIds': newAttended,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAttended ? 'coach.attendance_unmarked'.tr() : 'coach.attendance_marked'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isAttended ? const Color(0xFF334155) : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling attendance: $e');
    }
  }

  void _showNoteDialog(Child child) => showCoachNoteDialog(context, child);

  Widget _buildDatePill(String label, DateTime targetDate, bool isSelected, AppThemeConfig themeConfig) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
          _enrolledChildren = [];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: themeConfig.isDark
                      ? [const Color(0xFF00E5FF), const Color(0xFF0284C7)]
                      : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                )
              : null,
          color: isSelected
              ? null
              : (themeConfig.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (themeConfig.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFF0284C7).withValues(alpha: 0.20)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : themeConfig.textPrimary,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final selectedClassId = ref.watch(selectedCoachClassIdProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: scheduleAsync.when(
        data: (allClasses) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final tomorrow = today.add(const Duration(days: 1));

          final coachBranch = user?.branchId ?? 'kyiv';
          final coachBranches = user?.branchIds ?? [coachBranch];
          final branchClasses = user != null
              ? allClasses.where((c) => c.branchId == coachBranch || coachBranches.contains(c.branchId)).toList()
              : allClasses;

          // 1. Filter by selected day
          final dayClasses = branchClasses.where((c) {
            final classDate = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
            return _isSameDay(classDate, _selectedDate);
          }).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          // 2. Filter by coach if _onlyMyClasses is active
          final myClasses = dayClasses.where((c) {
            final isMock = user?.id == 'mock_coach';
            final matchesId = c.coachId == user?.id;
            final matchesName = user != null &&
                user.name.isNotEmpty &&
                c.coachName.toLowerCase().contains(user.name.toLowerCase());
            return matchesId || matchesName || isMock;
          }).toList();

          final effectiveClasses = _onlyMyClasses ? myClasses : dayClasses;

          // Determine active class
          GroupClass? activeClass;
          if (effectiveClasses.isNotEmpty) {
            activeClass = effectiveClasses.firstWhere(
              (c) => c.id == selectedClassId,
              orElse: () => effectiveClasses.first,
            );

            if (selectedClassId != activeClass.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedCoachClassIdProvider.notifier).setClassId(activeClass!.id);
                _fetchChildren(activeClass.enrolledChildIds);
              });
            } else if (_enrolledChildren.isEmpty && activeClass.enrolledChildIds.isNotEmpty && !_isLoadingChildren) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchChildren(activeClass!.enrolledChildIds);
              });
            }
          }

          final presentCount = activeClass?.attendedChildIds.length ?? 0;
          final enrolledCount = activeClass?.enrolledChildIds.length ?? 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Class Selector & Action Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header Bar: Frosted back button + Live status badge + Title
                      Row(
                        children: [
                          if (Navigator.canPop(context)) ...[
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                margin: const EdgeInsets.only(right: 14),
                                decoration: BoxDecoration(
                                  color: themeConfig.isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.90),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (themeConfig.isDark
                                              ? const Color(0xFF00E5FF)
                                              : const Color(0xFF003B73))
                                          .withValues(alpha: themeConfig.isDark ? 0.15 : 0.08),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.arrowLeft,
                                    color: themeConfig.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ТРЕНЕРСЬКИЙ ЖУРНАЛ',
                                      style: TextStyle(
                                        color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'coach.journal_heading'.tr() == 'coach.journal_heading'
                                      ? 'Журнал та відвідуваність'
                                      : 'coach.journal_heading'.tr(),
                                  style: TextStyle(
                                    color: themeConfig.textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 2. Date Selector Bar & Filter Toggle
                      Row(
                        children: [
                          // Day Pills: Вчора, Сьогодні, Завтра
                          _buildDatePill('Вчора', yesterday, _isSameDay(_selectedDate, yesterday), themeConfig),
                          const SizedBox(width: 8),
                          _buildDatePill('Сьогодні', today, _isSameDay(_selectedDate, today), themeConfig),
                          const SizedBox(width: 8),
                          _buildDatePill('Завтра', tomorrow, _isSameDay(_selectedDate, tomorrow), themeConfig),
                          const SizedBox(width: 8),
                          // Calendar custom date button
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: themeConfig.isDark
                                          ? const ColorScheme.dark(
                                              primary: Color(0xFF00E5FF),
                                              surface: Color(0xFF0B1E36),
                                            )
                                          : const ColorScheme.light(
                                              primary: Color(0xFF0284C7),
                                              surface: Colors.white,
                                            ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = DateTime(picked.year, picked.month, picked.day);
                                  _enrolledChildren = [];
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: (!_isSameDay(_selectedDate, yesterday) &&
                                        !_isSameDay(_selectedDate, today) &&
                                        !_isSameDay(_selectedDate, tomorrow))
                                    ? LinearGradient(
                                        colors: themeConfig.isDark
                                            ? [const Color(0xFF00E5FF), const Color(0xFF0284C7)]
                                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                                      )
                                    : null,
                                color: (!_isSameDay(_selectedDate, yesterday) &&
                                        !_isSameDay(_selectedDate, today) &&
                                        !_isSameDay(_selectedDate, tomorrow))
                                    ? null
                                    : (themeConfig.isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.85)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (!_isSameDay(_selectedDate, yesterday) &&
                                          !_isSameDay(_selectedDate, today) &&
                                          !_isSameDay(_selectedDate, tomorrow))
                                      ? Colors.transparent
                                      : (themeConfig.isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : const Color(0xFF0284C7).withValues(alpha: 0.20)),
                                ),
                                boxShadow: (!_isSameDay(_selectedDate, yesterday) &&
                                        !_isSameDay(_selectedDate, today) &&
                                        !_isSameDay(_selectedDate, tomorrow))
                                    ? [
                                        BoxShadow(
                                          color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 15,
                                    color: (!_isSameDay(_selectedDate, yesterday) &&
                                            !_isSameDay(_selectedDate, today) &&
                                            !_isSameDay(_selectedDate, tomorrow))
                                        ? Colors.white
                                        : themeConfig.textPrimary,
                                  ),
                                  if (!_isSameDay(_selectedDate, yesterday) &&
                                      !_isSameDay(_selectedDate, today) &&
                                      !_isSameDay(_selectedDate, tomorrow)) ...[
                                    const SizedBox(width: 5),
                                    Text(
                                      _formatDateShort(_selectedDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Coach Filter Toggle ("Мої заняття" / "Всі заняття басейну")
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _onlyMyClasses = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _onlyMyClasses
                                    ? (themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.15))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _onlyMyClasses
                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFF0284C7).withValues(alpha: 0.15)),
                                ),
                              ),
                              child: Text(
                                'Мої заняття (${myClasses.length})',
                                style: TextStyle(
                                  color: _onlyMyClasses
                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : themeConfig.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: _onlyMyClasses ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _onlyMyClasses = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_onlyMyClasses
                                    ? (themeConfig.isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                                        : const Color(0xFF0284C7).withValues(alpha: 0.15))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_onlyMyClasses
                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFF0284C7).withValues(alpha: 0.15)),
                                ),
                              ),
                              child: Text(
                                'Всі заняття басейну (${dayClasses.length})',
                                style: TextStyle(
                                  color: !_onlyMyClasses
                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : themeConfig.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: !_onlyMyClasses ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Horizontal Class Ribbon on Selected Day
                      if (effectiveClasses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: themeConfig.isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeConfig.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (themeConfig.isDark ? Colors.black : const Color(0xFF003B73)).withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.calendarX,
                                size: 36,
                                color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _onlyMyClasses
                                    ? 'У вас немає занять на ${_formatDateShort(_selectedDate)}'
                                    : 'Немає занять у басейні на ${_formatDateShort(_selectedDate)}',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_onlyMyClasses && dayClasses.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _onlyMyClasses = false),
                                  icon: const Icon(LucideIcons.eye, size: 15),
                                  label: Text('Показати заняття інших тренерів (${dayClasses.length})'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    side: BorderSide(
                                      color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: effectiveClasses.map((c) {
                              final isSel = activeClass?.id == c.id;
                              final timeStr = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
                              final isGym = c.category.toLowerCase().contains('gym') ||
                                  c.title.toLowerCase().contains('gym') ||
                                  c.title.toLowerCase().contains('зал');
                              final sportIcon = isGym ? '🏋️' : '🏊';
                              final count = c.enrolledChildIds.length;

                              return GestureDetector(
                                onTap: () {
                                  ref.read(selectedCoachClassIdProvider.notifier).setClassId(c.id);
                                  _fetchChildren(c.enrolledChildIds);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: effectiveClasses.length == 1 ? 320 : 210,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    gradient: isSel
                                        ? LinearGradient(
                                            colors: themeConfig.isDark
                                                ? [
                                                    const Color(0xFF00E5FF).withValues(alpha: 0.32),
                                                    const Color(0xFF0284C7).withValues(alpha: 0.20),
                                                  ]
                                                : [
                                                    const Color(0xFF0284C7),
                                                    const Color(0xFF0369A1),
                                                  ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSel
                                        ? null
                                        : (themeConfig.isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.white.withValues(alpha: 0.88)),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSel
                                          ? (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8))
                                          : (themeConfig.isDark
                                              ? Colors.white.withValues(alpha: 0.12)
                                              : const Color(0xFF0284C7).withValues(alpha: 0.20)),
                                      width: isSel ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: (themeConfig.isDark
                                                      ? const Color(0xFF00E5FF)
                                                      : const Color(0xFF0284C7))
                                                  .withValues(alpha: themeConfig.isDark ? 0.30 : 0.25),
                                              blurRadius: 14,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [
                                            if (!themeConfig.isDark)
                                              BoxShadow(
                                                color: const Color(0xFF003B73).withValues(alpha: 0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                          ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Top row: Sport icon + Time + Active beacon
                                      Row(
                                        children: [
                                          Text(sportIcon, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 7),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: isSel
                                                  ? (themeConfig.isDark ? const Color(0xFF00E5FF) : Colors.white)
                                                  : themeConfig.textPrimary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isSel)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: themeConfig.isDark ? const Color(0xFF00E5FF) : Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (themeConfig.isDark ? const Color(0xFF00E5FF) : Colors.white).withValues(alpha: 0.9),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Class title without truncation
                                      Text(
                                        c.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSel
                                              ? Colors.white
                                              : themeConfig.textPrimary,
                                          fontSize: 13,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Bottom row: Lane + Enrolled count badge
                                      Row(
                                        children: [
                                          if (c.lane.isNotEmpty) ...[
                                            Flexible(
                                              child: Text(
                                                c.lane,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isSel
                                                      ? (themeConfig.isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.85))
                                                      : themeConfig.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? (themeConfig.isDark
                                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                                                      : Colors.white.withValues(alpha: 0.25))
                                                  : (themeConfig.isDark
                                                      ? Colors.white.withValues(alpha: 0.08)
                                                      : const Color(0xFF0284C7).withValues(alpha: 0.10)),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSel
                                                    ? (themeConfig.isDark
                                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                                        : Colors.white.withValues(alpha: 0.35))
                                                    : (themeConfig.isDark
                                                        ? Colors.white.withValues(alpha: 0.08)
                                                        : const Color(0xFF0284C7).withValues(alpha: 0.15)),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.users,
                                                  size: 11,
                                                  color: isSel
                                                      ? (themeConfig.isDark ? const Color(0xFF00E5FF) : Colors.white)
                                                      : themeConfig.textSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$count',
                                                  style: TextStyle(
                                                    color: isSel
                                                        ? (themeConfig.isDark ? const Color(0xFF00E5FF) : Colors.white)
                                                        : themeConfig.textSecondary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      if (activeClass != null) ...[
                        const SizedBox(height: 18),

                        // 4. Cyber-Luxe Smart QR Scanner Card
                        Builder(
                          builder: (context) {
                            final selectedClass = activeClass!;
                            final isClassToday = _isSameDay(selectedClass.startTime, DateTime.now());
                            return GestureDetector(
                              onTap: () async {
                                if (!isClassToday) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(LucideIcons.calendarClock, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Сканування перепустки доступне лише в день проведення заняття (${_formatDateShort(selectedClass.startTime)})',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFF59E0B),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  return;
                                }

                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrScannerScreen(targetClass: selectedClass),
                                  ),
                                );

                                if (updated == true && mounted) {
                                  final doc = await FirebaseFirestore.instance
                                      .collection('classes')
                                      .doc(selectedClass.id)
                                      .get();
                                  if (doc.exists && mounted) {
                                    final updatedClass = GroupClass.fromJson({'id': doc.id, ...doc.data()!});
                                    _fetchChildren(updatedClass.enrolledChildIds);
                                  }
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: !isClassToday
                                        ? [
                                            (themeConfig.isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B)).withValues(alpha: 0.9),
                                            (themeConfig.isDark ? const Color(0xFF0F172A) : const Color(0xFF475569)).withValues(alpha: 0.9),
                                          ]
                                        : (themeConfig.isDark
                                            ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                            : const [Color(0xFF0284C7), Color(0xFF0369A1)]),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (!isClassToday
                                              ? Colors.black
                                              : (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)))
                                          .withValues(alpha: themeConfig.isDark ? 0.35 : 0.25),
                                      blurRadius: 18,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.12),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          !isClassToday ? LucideIcons.calendarClock : Icons.qr_code_scanner_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            !isClassToday ? 'СКАНУВАННЯ ЗАКРИТО' : 'СКАНУВАТИ ПЕРЕПУСТКУ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14.5,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            !isClassToday
                                                ? 'Доступно в день проведення (${_formatDateShort(selectedClass.startTime)})'
                                                : 'Миттєва відмітка входу учня біля басейну',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          !isClassToday ? LucideIcons.lock : LucideIcons.chevronRight,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),

                        // 5. Attendance count header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'СПИСОК ПЛАВЦІВ (${_enrolledChildren.length})',
                              style: TextStyle(
                                color: themeConfig.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: themeConfig.isDark ? 0.15 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.check, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Присутні: $presentCount з $enrolledCount',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Enrolled Students List
              if (activeClass == null)
                const SliverToBoxAdapter(child: SizedBox(height: 60))
              else if (_isLoadingChildren)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: themeConfig.accentPrimary),
                    ),
                  ),
                )
              else if (_enrolledChildren.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: themeConfig.isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: themeConfig.isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFF0284C7).withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (themeConfig.isDark ? Colors.black : const Color(0xFF003B73)).withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                                border: Border.all(
                                  color: (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.users,
                                  color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'На це заняття ще немає записаних учнів',
                              style: TextStyle(
                                color: themeConfig.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Учні з\'являться тут автоматично після запису або сканування QR-перепустки',
                              style: TextStyle(color: themeConfig.textSecondary, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final child = _enrolledChildren[index];
                        final isPresent = activeClass!.attendedChildIds.contains(child.id);
                        return _buildSwimmerCard(child, isPresent, activeClass, index, themeConfig);
                      },
                      childCount: _enrolledChildren.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: themeConfig.accentPrimary)),
        error: (e, _) => Center(child: Text('coach.load_error'.tr(args: ['$e']), style: TextStyle(color: themeConfig.textPrimary))),
      ),
    );
  }

  Widget _buildSwimmerCard(Child child, bool isPresent, GroupClass gClass, int index, AppThemeConfig themeConfig) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPresent
            ? const Color(0xFF10B981).withValues(alpha: themeConfig.isDark ? 0.08 : 0.10)
            : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.88)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF0284C7).withValues(alpha: 0.18)),
          width: 1.2,
        ),
        boxShadow: isPresent
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  blurRadius: 14,
                  spreadRadius: -1,
                )
              ]
            : [
                if (!themeConfig.isDark)
                  BoxShadow(
                    color: const Color(0xFF003B73).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Glowing swimmer avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPresent
                          ? [const Color(0xFF10B981), const Color(0xFF047857)]
                          : (themeConfig.isDark
                              ? [const Color(0xFF00E5FF), const Color(0xFF0284C7)]
                              : [const Color(0xFF0284C7), const Color(0xFF0369A1)]),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPresent
                                ? const Color(0xFF10B981)
                                : (themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)))
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Name, level & XP
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeConfig.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFF0284C7).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${'coach.level_label'.tr()} ${child.level}',
                              style: TextStyle(
                                color: themeConfig.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Action buttons: Note & Attendance toggle
                Row(
                  children: [
                    // Note button
                    IconButton(
                      icon: Icon(LucideIcons.fileText, color: themeConfig.textSecondary, size: 20),
                      onPressed: () => _showNoteDialog(child),
                      tooltip: 'coach.btn_add_note'.tr(),
                    ),

                    // One-tap attendance check
                    GestureDetector(
                      onTap: () => _toggleAttendance(gClass, child.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? const Color(0xFF10B981)
                              : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                          border: isPresent
                              ? null
                              : Border.all(
                                  color: themeConfig.isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : const Color(0xFFCBD5E1),
                                ),
                          boxShadow: isPresent
                              ? [
                                  const BoxShadow(
                                    color: Color(0xFF10B981),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isPresent ? LucideIcons.check : LucideIcons.userCheck,
                          color: isPresent
                              ? Colors.white
                              : (themeConfig.isDark ? Colors.white70 : const Color(0xFF64748B)),
                          size: 20,
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
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
  }
}
