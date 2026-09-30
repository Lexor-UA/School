import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/owner/presentation/owner_edit_salary_sheet.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:go_router/go_router.dart';

class OwnerStaffScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const OwnerStaffScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<OwnerStaffScreen> createState() => _OwnerStaffScreenState();
}

class _OwnerStaffScreenState extends ConsumerState<OwnerStaffScreen> {
  int _selectedFilter = 0; // 0: Всі, 1: Тренери, 2: Адміністратори
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    ensureAdminInFirestore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _formatMoney(int amount, String currencySymbol) {
    final formatted = _formatNumber(amount);
    return currencySymbol == '€' ? '€ $formatted' : '$formatted ₴';
  }

  String _formatLessonsCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) {
      return '$count занять';
    }
    if (mod10 == 1) {
      return '$count заняття';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count заняття';
    }
    return '$count занять';
  }

  String _getMonthOnly(DateTime dt) {
    const months = [
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];
    return months[dt.month - 1];
  }

  void _openEditSalarySheet({
    required String staffId,
    required String name,
    required String role,
    required String phone,
    required String loginId,
    required int rateGroup,
    required int rateIndividual,
    required int rateSplit,
    required int adminSalary,
    String currencySymbol = '₴',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnerEditSalarySheet(
        staffId: staffId,
        name: name,
        role: role,
        phone: phone,
        loginId: loginId,
        initialRateGroup: rateGroup,
        initialRateIndividual: rateIndividual,
        initialRateSplit: rateSplit,
        initialAdminSalary: adminSalary,
        currencySymbol: currencySymbol,
      ),
    );
  }

  Widget _buildSegmentedBranchSwitcher(TenancyState tenancyState, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    final tabs = [
      {'id': 'all', 'label': 'Вся мережа', 'flag': '🌐', 'currency': '₴ / €'},
      {'id': 'kyiv', 'label': 'Київ', 'flag': '🇺🇦', 'currency': '₴'},
      {'id': 'vienna', 'label': 'Відень', 'flag': '🇦🇹', 'currency': '€'},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07182C).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.40) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: tabs.map((tab) {
              final tabId = tab['id']!;
              final isSelected = (tabId == 'all' && tenancyState.isAllLocations) ||
                  (!tenancyState.isAllLocations && tenancyState.activeBranch?.id == tabId);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(tenancyControllerProvider.notifier).switchBranch(tabId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? (tabId == 'all'
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : (tabId == 'kyiv'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                    )))
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1,
                            )
                          : Border.all(color: Colors.transparent),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (tabId == 'all'
                                        ? const Color(0xFF6366F1)
                                        : (tabId == 'kyiv' ? const Color(0xFF00E5FF) : const Color(0xFFA855F7)))
                                    .withValues(alpha: isDark ? 0.38 : 0.24),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tabId == 'all')
                          Icon(
                            LucideIcons.globe,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0284C7)),
                          )
                        else
                          Text(
                            tab['flag']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          tab['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final themeConfig = ref.watch(appThemeControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    final activeBranchId = tenancyState.activeBranchId;
    final isAllLocations = tenancyState.isAllLocations;
    final currencySymbol = tenancyState.activeBranch?.id == 'vienna' ? '€' : '₴';

    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : themeConfig.scaffoldBg,
      body: Stack(
        children: [
          if (!widget.isEmbedded) ...[
            const AnimatedWaterBackground(),
            const Positioned.fill(child: WaterParticles()),
          ],
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeConfig),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 10.0),
                  child: _buildSegmentedBranchSwitcher(tenancyState, themeConfig),
                ),
                if (_isSearchVisible) _buildSearchBar(themeConfig),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['coach', 'Coach', 'admin', 'Admin', 'administrator'])
                        .snapshots(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }

                      final staffDocs = userSnap.data?.docs ?? [];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
                        builder: (context, classSnap) {
                          final classDocs = classSnap.data?.docs ?? [];
                          final List<GroupClass> allClasses = [];

                          for (final d in classDocs) {
                            try {
                              final data = Map<String, dynamic>.from(d.data() as Map);
                              data['id'] = d.id;
                              final c = GroupClass.fromJson(data);
                              if (isAllLocations || activeBranchId == null || c.branchId == activeBranchId) {
                                allClasses.add(c);
                              }
                            } catch (_) {}
                          }

                          // Calculate metrics across staff for the current month
                          int totalPayrollFundUah = 0;
                          int totalPayrollFundEur = 0;
                          int totalScheduledCoachFundUah = 0;
                          int totalScheduledCoachFundEur = 0;
                          int totalConductedClasses = 0;
                          int coachCount = 0;
                          int adminCount = 0;

                          // Pre-compute staff stats
                          final List<Map<String, dynamic>> staffList = [];

                          for (final doc in staffDocs) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final String staffBranchId = (data['branchId'] as String?) ?? 'kyiv';
                            final List<dynamic> staffBranchIds = (data['branchIds'] as List<dynamic>?) ?? [staffBranchId];

                            // Strict branch isolation
                            if (!isAllLocations && activeBranchId != null) {
                              final matchesBranch = staffBranchId == activeBranchId || staffBranchIds.contains(activeBranchId);
                              if (!matchesBranch) continue;
                            }

                            final isViennaStaff = staffBranchId == 'vienna';
                            final staffCurrency = isViennaStaff ? '€' : '₴';

                            final roleRaw = (data['role'] as String?)?.toLowerCase() ?? '';
                            final loginId = (data['loginId'] as String?) ?? '';
                            final bool isAdmin = roleRaw == 'admin' || roleRaw == 'administrator' || loginId.toLowerCase() == 'admin';
                            final role = isAdmin ? 'admin' : 'coach';
                            final name = (data['name'] as String?) ?? (isAdmin ? 'Адміністратор' : 'Без імені');
                            final phone = (data['phone'] as String?) ?? '';
                            final avatarUrl = (data['avatarUrl'] as String?) ??
                                (isAdmin
                                    ? 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff'
                                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=0284c7&color=ffffff');

                            final defaultRateGroup = isViennaStaff ? 25 : 400;
                            final defaultRateIndividual = isViennaStaff ? 35 : 450;
                            final defaultRateSplit = isViennaStaff ? 45 : 600;
                            final defaultAdminSalary = isViennaStaff ? 1800 : 20000;

                            final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? defaultRateGroup;
                            final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? defaultRateIndividual;
                            final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? defaultRateSplit;
                            final adminSalary = (data['adminSalary'] as num?)?.toInt() ?? defaultAdminSalary;

                            if (role == 'admin') {
                              adminCount++;
                              if (isViennaStaff) {
                                totalPayrollFundEur += adminSalary;
                              } else {
                                totalPayrollFundUah += adminSalary;
                              }
                              staffList.add({
                                'id': doc.id,
                                'name': name,
                                'role': role,
                                'phone': phone,
                                'loginId': loginId,
                                'avatarUrl': avatarUrl,
                                'branchId': staffBranchId,
                                'currency': staffCurrency,
                                'adminSalary': adminSalary,
                                'earnedSum': adminSalary,
                                'scheduledSum': 0,
                                'conductedTotal': 0,
                                'rateGroup': rateGroup,
                                'rateIndividual': rateIndividual,
                                'rateSplit': rateSplit,
                              });
                            } else {
                              coachCount++;
                              // Find classes for this coach
                              final coachClasses = allClasses.where((c) {
                                final matchesId = c.coachId == doc.id;
                                final matchesName = c.coachName.isNotEmpty &&
                                    (c.coachName.toLowerCase().contains(name.toLowerCase()) ||
                                     name.toLowerCase().contains(c.coachName.toLowerCase()));
                                return matchesId || matchesName;
                              }).where((c) => c.startTime.year == now.year && c.startTime.month == now.month).toList();

                              int conductedG = 0, conductedI = 0, conductedS = 0;
                              int scheduledG = 0, scheduledI = 0, scheduledS = 0;

                              for (final c in coachClasses) {
                                final isConducted = c.startTime.isBefore(now) || c.attendedChildIds.isNotEmpty;
                                final tLower = c.title.toLowerCase();
                                final cLower = c.category.toLowerCase();
                                final isSplit = tLower.contains('спліт') || tLower.contains('split') || (cLower.contains('індивідуал') && c.maxCapacity == 2);
                                final isIndividual = !isSplit && (cLower.contains('індивідуал') || tLower.contains('індивідуал') || c.maxCapacity == 1);

                                if (isConducted) {
                                  if (isSplit) {
                                    conductedS++;
                                  } else if (isIndividual) {
                                    conductedI++;
                                  } else {
                                    conductedG++;
                                  }
                                } else {
                                  if (isSplit) {
                                    scheduledS++;
                                  } else if (isIndividual) {
                                    scheduledI++;
                                  } else {
                                    scheduledG++;
                                  }
                                }
                              }

                              final conductedTotal = conductedG + conductedI + conductedS;
                              final scheduledTotal = scheduledG + scheduledI + scheduledS;
                              final earnedSum = (conductedG * rateGroup) + (conductedI * rateIndividual) + (conductedS * rateSplit);
                              final scheduledSum = (scheduledG * rateGroup) + (scheduledI * rateIndividual) + (scheduledS * rateSplit);

                              totalConductedClasses += conductedTotal;
                              if (isViennaStaff) {
                                totalPayrollFundEur += earnedSum;
                                totalScheduledCoachFundEur += scheduledSum;
                              } else {
                                totalPayrollFundUah += earnedSum;
                                totalScheduledCoachFundUah += scheduledSum;
                              }

                              staffList.add({
                                'id': doc.id,
                                'name': name,
                                'role': role,
                                'phone': phone,
                                'loginId': loginId,
                                'avatarUrl': avatarUrl,
                                'branchId': staffBranchId,
                                'currency': staffCurrency,
                                'rateGroup': rateGroup,
                                'rateIndividual': rateIndividual,
                                'rateSplit': rateSplit,
                                'adminSalary': adminSalary,
                                'earnedSum': earnedSum,
                                'scheduledSum': scheduledSum,
                                'conductedTotal': conductedTotal,
                                'scheduledTotal': scheduledTotal,
                                'conductedG': conductedG,
                                'conductedI': conductedI,
                                'conductedS': conductedS,
                              });
                            }
                          }

                          // Guarantee Administrator appears if none exists
                          final hasAdmin = staffList.any((s) => s['role'] == 'admin');
                          if (!hasAdmin) {
                            if (isAllLocations || activeBranchId == 'kyiv') {
                              adminCount++;
                              totalPayrollFundUah += 20000;
                              staffList.add({
                                'id': 'admin',
                                'name': 'Адміністратор',
                                'role': 'admin',
                                'phone': '+380 (99) 000-00-01',
                                'loginId': 'Admin',
                                'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
                                'branchId': 'kyiv',
                                'currency': '₴',
                                'adminSalary': 20000,
                                'earnedSum': 20000,
                                'scheduledSum': 0,
                                'conductedTotal': 0,
                                'rateGroup': 400,
                                'rateIndividual': 450,
                                'rateSplit': 600,
                              });
                            } else if (activeBranchId == 'vienna') {
                              adminCount++;
                              totalPayrollFundEur += 1800;
                              staffList.add({
                                'id': 'admin_vienna',
                                'name': 'Admin Vienna',
                                'role': 'admin',
                                'phone': '+43 1 234 5678',
                                'loginId': 'vienna.admin@cityswim.at',
                                'avatarUrl': 'https://ui-avatars.com/api/?name=Admin+Vienna&background=8b5cf6&color=ffffff',
                                'branchId': 'vienna',
                                'currency': '€',
                                'adminSalary': 1800,
                                'earnedSum': 1800,
                                'scheduledSum': 0,
                                'conductedTotal': 0,
                                'rateGroup': 25,
                                'rateIndividual': 35,
                                'rateSplit': 45,
                              });
                            }
                          }

                          // Filter by role tab
                          var filteredList = staffList.where((item) {
                            if (_selectedFilter == 1) return item['role'] == 'coach';
                            if (_selectedFilter == 2) return item['role'] == 'admin';
                            return true;
                          }).toList();

                          // Filter by search query
                          if (_searchQuery.trim().isNotEmpty) {
                            final q = _searchQuery.trim().toLowerCase();
                            filteredList = filteredList.where((item) {
                              final n = (item['name'] as String).toLowerCase();
                              final p = (item['phone'] as String).toLowerCase();
                              final l = (item['loginId'] as String).toLowerCase();
                              return n.contains(q) || p.contains(q) || l.contains(q);
                            }).toList();
                          }

                          return ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            children: [
                              _buildPayrollTelemetryCard(
                                totalPayrollFundUah: totalPayrollFundUah,
                                totalPayrollFundEur: totalPayrollFundEur,
                                totalScheduledCoachFundUah: totalScheduledCoachFundUah,
                                totalScheduledCoachFundEur: totalScheduledCoachFundEur,
                                isAllLocations: isAllLocations,
                                totalConductedClasses: totalConductedClasses,
                                coachCount: coachCount,
                                adminCount: adminCount,
                                currencySymbol: currencySymbol,
                                now: now,
                                themeConfig: themeConfig,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

                              const SizedBox(height: 20),

                              _buildFilterBar(coachCount, adminCount, staffList.length, themeConfig),

                              const SizedBox(height: 18),

                              if (filteredList.isEmpty)
                                _buildEmptyState(themeConfig)
                              else
                                ...filteredList.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final staff = entry.value;
                                  final staffCur = staff['currency'] as String? ?? currencySymbol;
                                  return _buildStaffItemCard(staff, staffCur, index, themeConfig);
                                }),

                              SizedBox(height: widget.isEmbedded ? 100 : 48),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (!widget.isEmbedded) ...[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeConfig.glassCardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: themeConfig.cardBorder),
                      ),
                      child: Icon(LucideIcons.arrowLeft, color: themeConfig.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.users, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'КОМАНДА ТА СТАВКИ',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Персонал та Оплата',
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isSearchVisible
                        ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.25 : 0.15)
                        : (isDark ? const Color(0xFF0C2442) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSearchVisible
                          ? const Color(0xFF00E5FF)
                          : (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE2E8F0)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isSearchVisible ? LucideIcons.x : LucideIcons.search,
                      color: _isSearchVisible
                          ? const Color(0xFF00E5FF)
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const ThemeHeaderButton(size: 38),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: themeConfig.textPrimary, fontSize: 14),
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Пошук за імʼям, телефоном або ID',
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF00E5FF), size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black45, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.08),
    );
  }

  Widget _buildPayrollTelemetryCard({
    required int totalPayrollFundUah,
    required int totalPayrollFundEur,
    required int totalScheduledCoachFundUah,
    required int totalScheduledCoachFundEur,
    required bool isAllLocations,
    required int totalConductedClasses,
    required int coachCount,
    required int adminCount,
    required String currencySymbol,
    required DateTime now,
    required AppThemeConfig themeConfig,
  }) {
    final isDark = themeConfig.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.wallet, color: Color(0xFF00E5FF), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'ФОНД ОПЛАТИ',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getMonthOnly(now),
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isAllLocations) ...[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('🇺🇦 ', style: TextStyle(fontSize: 15)),
                        Text(
                          _formatMoney(totalPayrollFundUah, '₴'),
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Text('•', style: TextStyle(color: themeConfig.textSecondary, fontSize: 18)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('🇦🇹 ', style: TextStyle(fontSize: 15)),
                        Text(
                          _formatMoney(totalPayrollFundEur, '€'),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'факт',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                if (totalScheduledCoachFundUah > 0 || totalScheduledCoachFundEur > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${_formatMoney(totalScheduledCoachFundUah, '₴')} / ${_formatMoney(totalScheduledCoachFundEur, '€')} заплановано',
                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 12),
                  ),
                ],
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatMoney(currencySymbol == '€' ? totalPayrollFundEur : totalPayrollFundUah, currencySymbol),
                      style: TextStyle(
                        color: themeConfig.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'фактично',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                if ((currencySymbol == '€' ? totalScheduledCoachFundEur : totalScheduledCoachFundUah) > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${_formatMoney(currencySymbol == '€' ? totalScheduledCoachFundEur : totalScheduledCoachFundUah, currencySymbol)} заплановано до кінця місяця',
                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 12),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.waves,
                        value: '$coachCount',
                        label: 'Тренери',
                        sub: _formatLessonsCount(totalConductedClasses),
                        color: const Color(0xFF00E5FF),
                        themeConfig: themeConfig,
                      ),
                    ),
                    Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.shieldCheck,
                        value: '$adminCount',
                        label: 'Адміністратори',
                        sub: 'Фіксована ставка',
                        color: const Color(0xFFA855F7),
                        themeConfig: themeConfig,
                      ),
                    ),
                    Container(width: 1, height: 32, color: isDark ? Colors.white12 : Colors.black12),
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.users,
                        value: '${coachCount + adminCount}',
                        label: 'Всього штат',
                        sub: 'Активний',
                        color: const Color(0xFF10B981),
                        themeConfig: themeConfig,
                      ),
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

  Widget _buildTelemetryStatItem({
    required IconData icon,
    required String value,
    required String label,
    required String sub,
    required Color color,
    required AppThemeConfig themeConfig,
  }) {
    final isDark = themeConfig.isDark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(value, style: TextStyle(color: themeConfig.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(sub, style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFilterBar(int coachCount, int adminCount, int totalCount, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07182C).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterSegment(0, 'Всі ($totalCount)', LucideIcons.layoutGrid, themeConfig),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildFilterSegment(1, 'Тренери ($coachCount)', LucideIcons.waves, themeConfig),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildFilterSegment(2, 'Адміни ($adminCount)', LucideIcons.shieldCheck, themeConfig),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSegment(int index, String label, IconData icon, AppThemeConfig themeConfig) {
    final isSelected = _selectedFilter == index;
    final isDark = themeConfig.isDark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (index == 0
                  ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                  : (index == 1
                      ? const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0284C7)])
                      : const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)])))
              : null,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (index == 0
                            ? const Color(0xFF6366F1)
                            : (index == 1 ? const Color(0xFF00E5FF) : const Color(0xFFA855F7)))
                        .withValues(alpha: isDark ? 0.38 : 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name, bool isCoach) {
    return Container(
      decoration: BoxDecoration(
        gradient: isCoach
            ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)])
            : const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF7C3AED)]),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildStaffItemCard(
    Map<String, dynamic> staff,
    String currencySymbol,
    int index,
    AppThemeConfig themeConfig,
  ) {
    final isDark = themeConfig.isDark;
    final isCoach = staff['role'] == 'coach';
    final name = staff['name'] as String;
    final avatarUrl = staff['avatarUrl'] as String;
    final earnedSum = staff['earnedSum'] as int;
    final scheduledSum = staff['scheduledSum'] as int;
    final conductedTotal = staff['conductedTotal'] as int;
    final phone = staff['phone'] as String;
    final loginId = staff['loginId'] as String;

    final rateGroup = staff['rateGroup'] as int;
    final rateIndividual = staff['rateIndividual'] as int;
    final rateSplit = staff['rateSplit'] as int;
    final adminSalary = staff['adminSalary'] as int;
    final staffBranchId = staff['branchId'] as String? ?? 'kyiv';
    final isVienna = staffBranchId == 'vienna';
    final effectiveCurrency = staff['currency'] as String? ?? (isVienna ? '€' : '₴');

    final accentColor = isCoach ? const Color(0xFF00E5FF) : const Color(0xFFA855F7);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? accentColor.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.30),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.07 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Info + Role & Branch Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (avatarUrl.isNotEmpty && !avatarUrl.contains('ui-avatars.com') && avatarUrl.startsWith('http'))
                            ? null
                            : (isCoach
                                ? const LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: (avatarUrl.isNotEmpty && !avatarUrl.contains('ui-avatars.com') && avatarUrl.startsWith('http'))
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _buildFallbackAvatar(name, isCoach),
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCoach
                                      ? const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.16 : 0.12)
                                      : const Color(0xFFA855F7).withValues(alpha: isDark ? 0.16 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCoach
                                        ? const Color(0xFF06B6D4).withValues(alpha: 0.35)
                                        : const Color(0xFFA855F7).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isCoach ? 'ТРЕНЕР' : 'АДМІН',
                                  style: TextStyle(
                                    color: isCoach
                                        ? (isDark ? const Color(0xFF22D3EE) : const Color(0xFF0284C7))
                                        : (isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED)),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isVienna
                                      ? const Color(0xFFA855F7).withValues(alpha: isDark ? 0.16 : 0.12)
                                      : const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.16 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isVienna
                                        ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                                        : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isVienna ? '🇦🇹 Відень' : '🇺🇦 Київ',
                                  style: TextStyle(
                                    color: isVienna
                                        ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA))
                                        : (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0284C7)),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Text(
                                phone.isNotEmpty ? phone : (loginId.isNotEmpty ? 'Логін: $loginId' : 'Персонал'),
                                style: TextStyle(
                                  color: themeConfig.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action button to edit salary
                    InkWell(
                      onTap: () => _openEditSalarySheet(
                        staffId: staff['id'],
                        name: name,
                        role: staff['role'],
                        phone: phone,
                        loginId: loginId,
                        rateGroup: rateGroup,
                        rateIndividual: rateIndividual,
                        rateSplit: rateSplit,
                        adminSalary: adminSalary,
                        currencySymbol: effectiveCurrency,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Icon(LucideIcons.slidersHorizontal, color: accentColor, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 14),

                // Middle: Rates / Salary config pills
                if (isCoach) ...[
                  Row(
                    children: [
                      Text(
                        'ТАРИФИ ТРЕНЕРА:',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRateBadge('Групові', _formatMoney(rateGroup, effectiveCurrency), LucideIcons.users, isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), isDark),
                      _buildRateBadge('Індивід.', _formatMoney(rateIndividual, effectiveCurrency), LucideIcons.user, isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), isDark),
                      _buildRateBadge('Спліт', _formatMoney(rateSplit, effectiveCurrency), LucideIcons.userPlus, isDark ? const Color(0xFFA855F7) : const Color(0xFF7C3AED), isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Month Telemetry
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.32) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нараховано за місяць:',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatMoney(earnedSum, effectiveCurrency),
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${_formatLessonsCount(conductedTotal)})',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (scheduledSum > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'План до кінця міс.:',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+ ${_formatMoney(scheduledSum, effectiveCurrency)}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Admin Salary Card
                  Row(
                    children: [
                      Text(
                        'ОКЛАД АДМІНІСТРАТОРА:',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.32) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFA855F7).withValues(alpha: isDark ? 0.25 : 0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.landmark, color: Color(0xFFA855F7), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Фіксований оклад',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatMoney(adminSalary, effectiveCurrency)} / міс',
                                  style: TextStyle(
                                    color: themeConfig.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withValues(alpha: isDark ? 0.15 : 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Ставка',
                            style: TextStyle(
                              color: Color(0xFFA855F7),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Bottom Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openEditSalarySheet(
                      staffId: staff['id'],
                      name: name,
                      role: staff['role'],
                      phone: phone,
                      loginId: loginId,
                      rateGroup: rateGroup,
                      rateIndividual: rateIndividual,
                      rateSplit: rateSplit,
                      adminSalary: adminSalary,
                      currencySymbol: effectiveCurrency,
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      isCoach ? 'Налаштувати тарифи' : 'Змінити оклад',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCoach
                          ? (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFFE0F2FE))
                          : (isDark ? const Color(0xFFA855F7).withValues(alpha: 0.14) : const Color(0xFFF3E8FF)),
                      foregroundColor: isCoach
                          ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          : (isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isCoach
                              ? const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.35)
                              : const Color(0xFFA855F7).withValues(alpha: isDark ? 0.35 : 0.35),
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
    ).animate().fadeIn(delay: (index * 70).ms).slideX(begin: 0.05);
  }

  Widget _buildRateBadge(String title, String rate, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.30 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            '$title: ',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            rate,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                LucideIcons.usersRound,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Співробітників не знайдено',
              style: TextStyle(
                color: themeConfig.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Спробуйте змінити критерії пошуку або фільтр',
              style: TextStyle(
                color: themeConfig.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
