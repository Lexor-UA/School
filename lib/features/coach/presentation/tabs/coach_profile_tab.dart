import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import '../widgets/coach_dialogs_sheet.dart';
import '../coach_dashboard.dart';
import '../coach_journal_screen.dart';
import 'package:swimming_school_app/features/coach/controllers/coach_rating_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';

void _confirmCoachLogout(BuildContext context, WidgetRef ref) => confirmCoachLogout(context, ref);

class CoachProfileTab extends ConsumerStatefulWidget {
  const CoachProfileTab({super.key});

  @override
  ConsumerState<CoachProfileTab> createState() => _CoachProfileTabState();
}

class _CoachProfileTabState extends ConsumerState<CoachProfileTab> {
  bool _isIncomeHidden = false;
  int _selectedPeriod = 0; // 0: This month, 1: Previous month, 2: All
  late AppThemeConfig _themeConfig;
  late bool _isLight;
  String _currencySymbol = '₴';
  String _currencyLabel = '₴';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    _themeConfig = ref.watch(appThemeControllerProvider);
    _isLight = !_themeConfig.isDark;
    final activeBranch = ref.watch(effectiveBranchProvider);
    final isEur = activeBranch.currency.toUpperCase() == 'EUR' ||
        user.branchId == 'vienna' ||
        (user.branchId.isEmpty && activeBranch.id == 'vienna');
    _currencySymbol = isEur ? '€' : '₴';
    _currencyLabel = isEur ? '€' : 'common.uah_short'.tr();

    final int defaultGroupRate = isEur ? 25 : 400;
    final int defaultIndividualRate = isEur ? 35 : 450;
    final int defaultSplitRate = isEur ? 45 : 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
        builder: (context, userDocSnap) {
          final userData = userDocSnap.data?.data() as Map<String, dynamic>? ?? {};
          final int rateGroup = (userData['rateGroup'] as num?)?.toInt() ?? defaultGroupRate;
          final int rateIndividual = (userData['rateIndividual'] as num?)?.toInt() ?? defaultIndividualRate;
          final int rateSplit = (userData['rateSplit'] as num?)?.toInt() ?? defaultSplitRate;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('classes').snapshots(),
            builder: (context, classSnap) {
              final classDocs = classSnap.data?.docs ?? [];
              final List<GroupClass> coachClasses = [];
              final coachBranch = user.branchId.isNotEmpty ? user.branchId : activeBranch.id;

              for (final d in classDocs) {
                final data = Map<String, dynamic>.from(d.data() as Map);
                data['id'] = d.id;
                try {
                  final gc = GroupClass.fromJson(data);
                  final matchesBranch = coachBranch.isEmpty ||
                      gc.branchId.isEmpty ||
                      gc.branchId == coachBranch ||
                      user.branchIds.contains(gc.branchId);
                  if (matchesBranch && isClassForCoach(gc, user)) {
                    coachClasses.add(gc);
                  }
                } catch (_) {}
              }

              // Period Filter
              final now = DateTime.now();
              final filteredClasses = coachClasses.where((c) {
                if (_selectedPeriod == 0) {
                  return c.branchStartTime.year == now.year && c.branchStartTime.month == now.month;
                } else if (_selectedPeriod == 1) {
                  final prev = DateTime(now.year, now.month - 1, 1);
                  return c.branchStartTime.year == prev.year && c.branchStartTime.month == prev.month;
                }
                return true;
              }).toList();

              // Sort by startTime descending
              filteredClasses.sort((a, b) => b.branchStartTime.compareTo(a.branchStartTime));

              int conductedGroup = 0;
              int conductedIndividual = 0;
              int conductedSplit = 0;

              int scheduledGroup = 0;
              int scheduledIndividual = 0;
              int scheduledSplit = 0;

              for (final c in filteredClasses) {
                final isConducted = c.attendedChildIds.isNotEmpty;
                final tLower = c.title.toLowerCase();
                final cLower = c.category.toLowerCase();
                final isSplit = RegExp(r'\u0441\u043f\u043b\u0456\u0442|split', caseSensitive: false).hasMatch(tLower) ||
                    (RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(cLower) && c.maxCapacity == 2);
                final isIndividual = !isSplit &&
                    (RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(cLower) ||
                        RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(tLower) ||
                        c.maxCapacity == 1);

                if (isConducted) {
                  if (isSplit) {
                    conductedSplit++;
                  } else if (isIndividual) {
                    conductedIndividual++;
                  } else {
                    conductedGroup++;
                  }
                } else {
                  if (isSplit) {
                    scheduledSplit++;
                  } else if (isIndividual) {
                    scheduledIndividual++;
                  } else {
                    scheduledGroup++;
                  }
                }
              }

              final conductedGroupSum = conductedGroup * rateGroup;
              final conductedIndividualSum = conductedIndividual * rateIndividual;
              final conductedSplitSum = conductedSplit * rateSplit;
              final totalEarned = conductedGroupSum + conductedIndividualSum + conductedSplitSum;
              final totalConducted = conductedGroup + conductedIndividual + conductedSplit;

              final scheduledSum = (scheduledGroup * rateGroup) + (scheduledIndividual * rateIndividual) + (scheduledSplit * rateSplit);
              final totalScheduled = scheduledGroup + scheduledIndividual + scheduledSplit;

              final todayClasses = coachClasses.where((c) {
                return c.branchStartTime.year == now.year &&
                       c.branchStartTime.month == now.month &&
                       c.branchStartTime.day == now.day;
              }).toList();
              todayClasses.sort((a, b) => a.branchStartTime.compareTo(b.branchStartTime));
              final upcomingClass = todayClasses.where((c) => c.branchEndTime.isAfter(now)).firstOrNull;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 76),
                child: Column(
                  children: [
                    // 1. Coach Identity Card (with integrated Theme Switcher)
                    _buildIdentityCard(user),

                    const SizedBox(height: 9),

                    // 2. Interactive Salary Card (VisionOS Compact Executive)
                    _buildSalaryCard(
                      totalEarned: totalEarned,
                      totalConducted: totalConducted,
                      scheduledSum: scheduledSum,
                      totalScheduled: totalScheduled,
                      conductedGroup: conductedGroup,
                      conductedGroupSum: conductedGroupSum,
                      rateGroup: rateGroup,
                      conductedIndividual: conductedIndividual,
                      conductedIndividualSum: conductedIndividualSum,
                      rateIndividual: rateIndividual,
                      conductedSplit: conductedSplit,
                      conductedSplitSum: conductedSplitSum,
                      rateSplit: rateSplit,
                      allFilteredClasses: filteredClasses,
                    ),

                    const SizedBox(height: 9),

                    // 3. Communication Center (Admin & Clients)
                    _buildCommunicationCenter(context, user),

                    const SizedBox(height: 9),

                    // 4. Performance KPI (Single Compact Horizontal Row: Attendance & Rating)
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            '96%',
                            'coach.kpi_attendance'.tr(),
                            LucideIcons.trendingUp,
                            _isLight ? const Color(0xFF059669) : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final coachRatingData = ref.watch(
                                coachAverageRatingProvider(user.id.isNotEmpty ? user.id : user.name),
                              );
                              final ratingString = coachRatingData.count > 0
                                  ? '${coachRatingData.rating.toStringAsFixed(1)} ★'
                                  : '— ★';
                              final ratingLabel = coachRatingData.count > 0
                                  ? 'coach.rating_with_count'.tr(args: ['${coachRatingData.count}'])
                                  : 'coach.coach_rating_label'.tr();

                              return _buildKpiCard(
                                ratingString,
                                ratingLabel,
                                LucideIcons.award,
                                _isLight ? const Color(0xFFDB2777) : const Color(0xFFEC4899),
                                isRating: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // 5. Today's Express Mission / Upcoming Class (Visible ONLY if there is an upcoming class today)
                    if (upcomingClass != null) ...[
                      const SizedBox(height: 9),
                      _buildTodayMissionCard(upcomingClass, context),
                    ],

                    const SizedBox(height: 11),

                    // 6. Logout Action & System Version
                    _buildLogoutSection(context, ref),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunicationCenter(BuildContext context, AppUser user) {
    final unreadCount = ref.watch(coachUnreadBadgeProvider(user.id));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLight
              ? [Colors.white.withValues(alpha: 0.96), const Color(0xFFF8FAFC)]
              : [const Color(0xFF0F2744), const Color(0xFF0A1B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLight
              ? const Color(0xFFBAE6FD)
              : const Color(0xFF1E4570),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
                // Row 1: Admin Support Chat
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentChatScreen(
                            title: 'coach.chat_admin_title'.tr(),
                            subtitle: 'coach.chat_admin_sub'.tr(),
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'coach.chat_admin'.tr(),
                                  style: TextStyle(
                                    color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'common.online'.tr(),
                                  style: TextStyle(
                                    color: _isLight ? const Color(0xFF059669) : const Color(0xFF34D399),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Subtle divider
                Divider(
                  height: 1,
                  thickness: 0.8,
                  indent: 14,
                  endIndent: 14,
                  color: _isLight
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFF1E4570),
                ),

                // Row 2: Client Dialogs Center
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showCoachDialogsSheet(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 15),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'coach.client_messages_title'.tr(),
                                  style: TextStyle(
                                    color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  'coach.client_messages_sub'.tr(),
                                  style: TextStyle(
                                    color: _themeConfig.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
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
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Icon(
                            LucideIcons.chevronRight,
                            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTodayMissionCard(GroupClass upcomingClass, BuildContext context) {
    final durationMins = upcomingClass.endTime.difference(upcomingClass.startTime).inMinutes;
    final cleanTitle = upcomingClass.title.replaceFirst(
      RegExp(r'^(\u0406\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b\u044c\u043d\u0435|\u0413\u0440\u0443\u043f\u043e\u0432\u0435|\u0421\u043f\u043b\u0456\u0442)\s*\u0442\u0440\u0435\u043d\u0443\u0432\u0430\u043d\u043d\u044f:\s*', caseSensitive: false),
      '',
    ).trim();
    final displayTitle = cleanTitle.isNotEmpty ? cleanTitle : upcomingClass.title;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLight
              ? [Colors.white.withValues(alpha: 0.98), const Color(0xFFF8FAFC)]
              : [const Color(0xFF0F2744), const Color(0xFF0A1B30)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLight
              ? const Color(0xFFBAE6FD)
              : const Color(0xFF1E4570),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.30),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(upcomingClass.branchStartTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$durationMins ${'common.min_short'.tr()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${upcomingClass.category} • ${upcomingClass.attendedChildIds.length}/${upcomingClass.maxCapacity} ${'coach.marked_short'.tr()}',
                        style: TextStyle(
                          color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedCoachClassIdProvider.notifier).setClassId(upcomingClass.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachJournalScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'coach.nav_journal'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE11D48),
            Color(0xFFBE123C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmCoachLogout(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.logOut,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  'coach.end_shift_btn'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatConductedClassesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'coach.classes_count_many'.tr(args: ['$count']);
    if (mod10 == 1) return 'coach.classes_count_one'.tr(args: ['$count']);
    if (mod10 >= 2 && mod10 <= 4) return 'coach.classes_count_few'.tr(args: ['$count']);
    return 'coach.classes_count_many'.tr(args: ['$count']);
  }

  String _formatClassesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'coach.classes_count_many'.tr(args: ['$count']);
    if (mod10 == 1) return 'coach.classes_count_one'.tr(args: ['$count']);
    if (mod10 >= 2 && mod10 <= 4) return 'coach.classes_count_few'.tr(args: ['$count']);
    return 'coach.classes_count_many'.tr(args: ['$count']);
  }

  Widget _buildIdentityCard(AppUser user) {
    final displayName = user.name.isNotEmpty
        ? user.name
        : (user.loginId?.isNotEmpty == true ? user.loginId! : 'coach.title'.tr());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLight
              ? [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF8FAFC),
                ]
              : [
                  const Color(0xFF0F2744),
                  const Color(0xFF0A1B30),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLight
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF1E4570),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Concentric Glowing Avatar with Status Beacon
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isLight
                        ? const [Color(0xFF0284C7), Color(0xFF00E5FF)]
                        : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                          .withValues(alpha: _isLight ? 0.35 : 0.45),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLight ? Colors.white : const Color(0xFF05172A),
                  ),
                  child: const AvatarPicker(
                    heroTag: 'hero_avatar_Тренерам_profile',
                    radius: 28,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isLight ? Colors.white : const Color(0xFF0F172A),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.60),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // 2. Information Column (Harmonious 2-Row Hierarchy)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Coach Name gets 100% full width
                Text(
                  displayName,
                  style: TextStyle(
                    color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 5),

                // Row 2: Pro Rank Title · Online Status
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'coach.pro_rank'.tr(),
                        style: TextStyle(
                          color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        color: _isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'common.online'.tr(),
                      style: TextStyle(
                        color: _isLight ? const Color(0xFF059669) : const Color(0xFF34D399),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3. Dedicated Theme Switcher Button
          _buildThemeToggleBtn(),
        ],
      ),
    );
  }

  Widget _buildThemeToggleBtn() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final newMode = _isLight ? AppThemeMode.darkOcean : AppThemeMode.lightAzure;
          ref.read(appThemeControllerProvider.notifier).setTheme(newMode);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF081628),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isLight ? const Color(0xFFCBD5E1) : const Color(0xFF1E3E66),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isLight
                    ? const Color(0xFF0F172A).withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              _isLight ? LucideIcons.sun : LucideIcons.moon,
              size: 15.5,
              color: _isLight ? const Color(0xFFD97706) : const Color(0xFF00E5FF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryCard({
    required int totalEarned,
    required int totalConducted,
    required int scheduledSum,
    required int totalScheduled,
    required int conductedGroup,
    required int conductedGroupSum,
    required int rateGroup,
    required int conductedIndividual,
    required int conductedIndividualSum,
    required int rateIndividual,
    required int conductedSplit,
    required int conductedSplitSum,
    required int rateSplit,
    required List<GroupClass> allFilteredClasses,
  }) {
    final currencyFormat = NumberFormat('#,###', context.locale.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLight
              ? [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF8FAFC),
                ]
              : [
                  const Color(0xFF0F2744),
                  const Color(0xFF0A1B30),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLight
              ? const Color(0xFFBAE6FD)
              : const Color(0xFF1E4570),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight
                ? const Color(0xFF0F172A).withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Period Switcher (Segmented Control)
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF081628),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E3E66),
                width: 1.0,
              ),
            ),
                  child: Row(
                    children: [
                      _buildPeriodPill(label: 'coach.period_this_month'.tr(), index: 0),
                      _buildPeriodPill(label: 'coach.period_prev_month'.tr(), index: 1),
                      _buildPeriodPill(label: 'coach.period_all_classes'.tr(), index: 2),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Executive Balance & Details Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: _isLight
                              ? const Color(0xFF10B981).withValues(alpha: 0.30)
                              : Colors.white.withValues(alpha: 0.30),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: _isLight ? 0.25 : 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.wallet, color: Colors.white, size: 13.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _isIncomeHidden ? '••••••••' : currencyFormat.format(totalEarned),
                                style: TextStyle(
                                  color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                _currencyLabel,
                                style: TextStyle(
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 7),
                              GestureDetector(
                                onTap: () => setState(() => _isIncomeHidden = !_isIncomeHidden),
                                child: Icon(
                                  _isIncomeHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_getPeriodSubtitle()} • ${_formatConductedClassesCount(totalConducted)}',
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Details Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showSalaryDetailsSheet(
                          context,
                          allFilteredClasses,
                          rateGroup,
                          rateIndividual,
                          rateSplit,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: _isLight ? 0.30 : 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.receipt, size: 11.5, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'coach.details_count'.tr(args: ['$totalConducted']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(LucideIcons.chevronRight, size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Scheduled projection banner (if any scheduled classes in this period)
                if (totalScheduled > 0 && _selectedPeriod == 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: _isLight ? const Color(0xFFFEF3C7) : const Color(0xFF1E171E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isLight ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B).withValues(alpha: 0.40),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.hourglass,
                          size: 11,
                          color: _isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'coach.until_end_of_month_proj'.tr(args: [
                              _formatClassesCount(totalScheduled),
                              _isIncomeHidden ? '•••' : currencyFormat.format(scheduledSum),
                              _currencyLabel,
                            ]),
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF92400E) : const Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 9),

                // 3 Category Triptych (Solid Graphite Tri-Column)
                _buildCategoryTriptych(
                  conductedGroup: conductedGroup,
                  conductedGroupSum: conductedGroupSum,
                  rateGroup: rateGroup,
                  conductedIndividual: conductedIndividual,
                  conductedIndividualSum: conductedIndividualSum,
                  rateIndividual: rateIndividual,
                  conductedSplit: conductedSplit,
                  conductedSplitSum: conductedSplitSum,
                  rateSplit: rateSplit,
                  currencyFormat: currencyFormat,
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodPill({required String label, required int index}) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 5.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.90),
                    width: 0.8,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: _isLight ? 0.35 : 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (_isLight ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPeriodSubtitle() {
    final now = DateTime.now();
    final localeStr = context.locale.toString();
    if (_selectedPeriod == 0) {
      final monthName = DateFormat('LLLL', localeStr).format(now);
      return '${monthName[0].toUpperCase()}${monthName.substring(1)}';
    } else if (_selectedPeriod == 1) {
      final prev = DateTime(now.year, now.month - 1, 1);
      final monthName = DateFormat('LLLL', localeStr).format(prev);
      return '${monthName[0].toUpperCase()}${monthName.substring(1)}';
    }
    return 'coach.for_all_time'.tr();
  }

  Widget _buildCategoryTriptych({
    required int conductedGroup,
    required int conductedGroupSum,
    required int rateGroup,
    required int conductedIndividual,
    required int conductedIndividualSum,
    required int rateIndividual,
    required int conductedSplit,
    required int conductedSplitSum,
    required int rateSplit,
    required NumberFormat currencyFormat,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTriptychCol(
            title: 'coach.type_group_plural'.tr(),
            icon: LucideIcons.users,
            count: conductedGroup,
            sum: conductedGroupSum,
            accentColor: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
            secondaryColor: _isLight ? const Color(0xFF0369A1) : const Color(0xFF0284C7),
            currencyFormat: currencyFormat,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildTriptychCol(
            title: 'coach.type_indiv_short'.tr(),
            icon: LucideIcons.user,
            count: conductedIndividual,
            sum: conductedIndividualSum,
            accentColor: _isLight ? const Color(0xFF2563EB) : const Color(0xFF38BDF8),
            secondaryColor: _isLight ? const Color(0xFF1D4ED8) : const Color(0xFF0284C7),
            currencyFormat: currencyFormat,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildTriptychCol(
            title: 'coach.type_split'.tr(),
            icon: LucideIcons.userCheck,
            count: conductedSplit,
            sum: conductedSplitSum,
            accentColor: _isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
            secondaryColor: _isLight ? const Color(0xFFB45309) : const Color(0xFFD97706),
            currencyFormat: currencyFormat,
          ),
        ),
      ],
    );
  }

  Widget _buildTriptychCol({
    required String title,
    required IconData icon,
    required int count,
    required int sum,
    required Color accentColor,
    required Color secondaryColor,
    required NumberFormat currencyFormat,
  }) {
    final hasEarnings = sum > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isLight
              ? [
                  Colors.white,
                  hasEarnings ? accentColor.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                ]
              : [
                  const Color(0xFF11233B),
                  const Color(0xFF081628),
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasEarnings
              ? (_isLight ? accentColor.withValues(alpha: 0.55) : accentColor.withValues(alpha: 0.60))
              : (_isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E4570)),
          width: 1.0,
        ),
        boxShadow: hasEarnings
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: _isLight ? 0.15 : 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                if (_isLight)
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12,
                color: hasEarnings
                    ? accentColor
                    : (_isLight ? const Color(0xFF64748B) : Colors.white60),
              ),
              const SizedBox(width: 3.5),
              Text(
                title,
                style: TextStyle(
                  color: hasEarnings
                      ? (_isLight ? const Color(0xFF0F172A) : Colors.white)
                      : (_isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3.5),
          Text(
            _isIncomeHidden ? '••••' : '${currencyFormat.format(sum)} $_currencySymbol',
            style: TextStyle(
              color: hasEarnings
                  ? accentColor
                  : (_isLight ? const Color(0xFF475569) : Colors.white60),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
              shadows: (hasEarnings && !_isLight)
                  ? [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.65),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatClassesCount(count),
            style: TextStyle(
              color: hasEarnings
                  ? (_isLight ? const Color(0xFF334155) : Colors.white70)
                  : (_isLight ? const Color(0xFF64748B) : Colors.white60),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalaryDetailsSheet(
    BuildContext context,
    List<GroupClass> classes,
    int rateGroup,
    int rateIndividual,
    int rateSplit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: _isLight ? null : const Color(0xFF0A1B30),
            gradient: _isLight
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF0F9FF)],
                  )
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: _isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E4570),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isLight
                    ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.50),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            children: [
              // Sheet Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isLight ? const Color(0xFFBAE6FD) : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.receipt,
                              color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'coach.salary_breakdown_title'.tr(),
                              style: TextStyle(
                                color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isLight ? Colors.white : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: _isLight ? const Color(0xFFBAE6FD) : Colors.white.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: _isLight ? const Color(0xFF0F172A) : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                color: _isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E4570),
                height: 1,
              ),

              // Class List
              Expanded(
                child: classes.isEmpty
                    ? Center(
                        child: Text(
                          'coach.no_classes_in_period'.tr(),
                          style: TextStyle(
                            color: _isLight ? const Color(0xFF64748B) : Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final c = classes[index];
                          final isConducted = c.attendedChildIds.isNotEmpty;
                          final tLower = c.title.toLowerCase();
                          final cLower = c.category.toLowerCase();
                          final isSplit = RegExp(r'\u0441\u043f\u043b\u0456\u0442|split', caseSensitive: false).hasMatch(tLower) ||
                              (RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(cLower) && c.maxCapacity == 2);
                          final isIndividual = !isSplit &&
                              (RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(cLower) ||
                                  RegExp(r'\u0456\u043d\u0434\u0438\u0432\u0456\u0434\u0443\u0430\u043b|indiv', caseSensitive: false).hasMatch(tLower) ||
                                  c.maxCapacity == 1);

                          final String typeLabel;
                          final int earned;
                          final Color typeColor;

                          if (isSplit) {
                            typeLabel = 'coach.type_split'.tr();
                            earned = rateSplit;
                            typeColor = _isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B);
                          } else if (isIndividual) {
                            typeLabel = 'coach.type_individual'.tr();
                            earned = rateIndividual;
                            typeColor = _isLight ? const Color(0xFF2563EB) : const Color(0xFF38BDF8);
                          } else {
                            typeLabel = 'coach.type_group'.tr();
                            earned = rateGroup;
                            typeColor = _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLight
                                    ? [Colors.white, const Color(0xFFF0F9FF)]
                                    : [
                                        const Color(0xFF0F2744),
                                        const Color(0xFF11233B),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isConducted
                                    ? typeColor.withValues(alpha: _isLight ? 0.35 : 0.40)
                                    : (_isLight ? const Color(0xFFBAE6FD) : const Color(0xFF1E4570)),
                                width: 1.0,
                              ),
                              boxShadow: _isLight
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: _isLight ? 0.12 : 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: typeColor.withValues(alpha: _isLight ? 0.30 : 0.40)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: typeColor.withValues(alpha: _isLight ? 0.10 : 0.20),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSplit ? LucideIcons.userCheck : (isIndividual ? LucideIcons.user : LucideIcons.users),
                                      color: typeColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.title,
                                        style: TextStyle(
                                          color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(
                                            DateFormat('d MMM, HH:mm', context.locale.toString()).format(c.branchStartTime),
                                            style: TextStyle(
                                              color: _isLight ? const Color(0xFF64748B) : Colors.white60,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: _isLight ? 0.12 : 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: typeColor.withValues(alpha: _isLight ? 0.25 : 0.35)),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: TextStyle(
                                                color: typeColor,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isConducted ? '+$earned $_currencySymbol' : '0 $_currencySymbol',
                                      style: TextStyle(
                                        color: isConducted
                                            ? const Color(0xFF10B981)
                                            : (_isLight ? const Color(0xFF94A3B8) : Colors.white38),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isConducted ? 'coach.status_conducted'.tr() : 'coach.status_scheduled'.tr(),
                                      style: TextStyle(
                                        color: isConducted
                                            ? (_isLight ? const Color(0xFF475569) : Colors.white60)
                                            : (_isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24)),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String value, String label, IconData icon, Color color, {bool isRating = false, VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10.5),
      decoration: BoxDecoration(
        gradient: _isLight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF8FAFC),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2744),
                  Color(0xFF0A1B30),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLight ? color.withValues(alpha: 0.40) : const Color(0xFF1E4570),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isLight ? color.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          if (_isLight)
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLight
                    ? [color.withValues(alpha: 0.22), color.withValues(alpha: 0.12)]
                    : [color.withValues(alpha: 0.28), color.withValues(alpha: 0.14)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isLight ? color.withValues(alpha: 0.45) : color.withValues(alpha: 0.55),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRating || value.contains('★')) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.replaceAll(' ★', '').trim(),
                        style: TextStyle(
                          color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 3.5),
                      const Icon(LucideIcons.star, size: 14, color: Color(0xFFF59E0B)),
                    ],
                  ),
                ] else ...[
                  Text(
                    value,
                    style: TextStyle(
                      color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 1.5),
                Text(
                  label.replaceAll('\n', ' '),
                  style: TextStyle(
                    color: _isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            Icon(
              LucideIcons.chevronRight,
              size: 13,
              color: color.withValues(alpha: _isLight ? 0.70 : 0.85),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }
}
