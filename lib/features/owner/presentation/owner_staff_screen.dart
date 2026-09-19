import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:go_router/go_router.dart';

class OwnerStaffScreen extends ConsumerStatefulWidget {
  const OwnerStaffScreen({super.key});

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final themeConfig = ref.watch(appThemeControllerProvider);

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeConfig),
                if (_isSearchVisible) _buildSearchBar(),
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
                              allClasses.add(GroupClass.fromJson(data));
                            } catch (_) {}
                          }

                          // Calculate metrics across all staff for the current month
                          int totalPayrollFund = 0;
                          int totalScheduledCoachFund = 0;
                          int totalConductedClasses = 0;
                          int coachCount = 0;
                          int adminCount = 0;

                          // Pre-compute staff stats
                          final List<Map<String, dynamic>> staffList = [];

                          for (final doc in staffDocs) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
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

                            final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? 400;
                            final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? 450;
                            final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? 600;
                            final adminSalary = (data['adminSalary'] as num?)?.toInt() ?? 20000;

                            if (role == 'admin') {
                              adminCount++;
                              totalPayrollFund += adminSalary;
                              staffList.add({
                                'id': doc.id,
                                'name': name,
                                'role': role,
                                'phone': phone,
                                'loginId': loginId,
                                'avatarUrl': avatarUrl,
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
                              totalPayrollFund += earnedSum;
                              totalScheduledCoachFund += scheduledSum;

                              staffList.add({
                                'id': doc.id,
                                'name': name,
                                'role': role,
                                'phone': phone,
                                'loginId': loginId,
                                'avatarUrl': avatarUrl,
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

                          // Guarantee Administrator appears even if Firestore doc was just created or sync is in flight
                          final hasAdmin = staffList.any((s) => s['role'] == 'admin');
                          if (!hasAdmin) {
                            adminCount++;
                            totalPayrollFund += 20000;
                            staffList.add({
                              'id': 'admin',
                              'name': 'Адміністратор',
                              'role': 'admin',
                              'phone': '+380 (99) 000-00-01',
                              'loginId': 'Admin',
                              'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=8b5cf6&color=ffffff',
                              'adminSalary': 20000,
                              'earnedSum': 20000,
                              'scheduledSum': 0,
                              'conductedTotal': 0,
                              'rateGroup': 400,
                              'rateIndividual': 450,
                              'rateSplit': 600,
                            });
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
                                totalPayrollFund: totalPayrollFund,
                                totalScheduledCoachFund: totalScheduledCoachFund,
                                totalConductedClasses: totalConductedClasses,
                                coachCount: coachCount,
                                adminCount: adminCount,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

                              const SizedBox(height: 20),

                              _buildFilterBar(coachCount, adminCount, staffList.length),

                              const SizedBox(height: 18),

                              if (filteredList.isEmpty)
                                _buildEmptyState()
                              else
                                ...filteredList.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final staff = entry.value;
                                  return _buildStaffItemCard(staff, index);
                                }),

                              const SizedBox(height: 48),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Персонал та Оплата',
                    style: TextStyle(color: themeConfig.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    'Управління тарифами та ставками',
                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemeHeaderButton(size: 38),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSearchVisible ? Colors.cyanAccent.withValues(alpha: 0.2) : themeConfig.glassCardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isSearchVisible ? Colors.cyanAccent.withValues(alpha: 0.4) : themeConfig.cardBorder,
                    ),
                  ),
                  child: Icon(
                    _isSearchVisible ? LucideIcons.x : LucideIcons.search,
                    color: _isSearchVisible ? Colors.cyanAccent : themeConfig.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Пошук за імʼям, телефоном або ID',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1),
    );
  }

  Widget _buildPayrollTelemetryCard({
    required int totalPayrollFund,
    required int totalScheduledCoachFund,
    required int totalConductedClasses,
    required int coachCount,
    required int adminCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.cyanAccent.withValues(alpha: 0.03),
            Colors.indigoAccent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.wallet, color: Colors.cyanAccent, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'ФОНД ОПЛАТИ (ПОТОЧНИЙ МІСЯЦЬ)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Live', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_formatNumber(totalPayrollFund)} ₴',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'фактично',
                      style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (totalScheduledCoachFund > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${_formatNumber(totalScheduledCoachFund)} ₴ заплановано до кінця місяця',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 18),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.waves,
                        value: '$coachCount',
                        label: 'Тренерів',
                        sub: '$totalConductedClasses занять',
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.shieldCheck,
                        value: '$adminCount',
                        label: 'Адміністраторів',
                        sub: 'Фіксована ставка',
                        color: Colors.purpleAccent,
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                    Expanded(
                      child: _buildTelemetryStatItem(
                        icon: LucideIcons.users,
                        value: '${coachCount + adminCount}',
                        label: 'Всього штат',
                        sub: 'Активний',
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterBar(int coachCount, int adminCount, int totalCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(0, 'Всі ($totalCount)', LucideIcons.layoutGrid),
          const SizedBox(width: 10),
          _buildFilterChip(1, '🏊 Тренери ($coachCount)', LucideIcons.waves),
          const SizedBox(width: 10),
          _buildFilterChip(2, '🛡️ Адміністратори ($adminCount)', LucideIcons.shieldCheck),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, IconData icon) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.cyanAccent : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffItemCard(Map<String, dynamic> staff, int index) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            isCoach ? Colors.cyanAccent.withValues(alpha: 0.02) : Colors.purpleAccent.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: isCoach ? Colors.cyanAccent.withValues(alpha: 0.18) : Colors.purpleAccent.withValues(alpha: 0.25),
          width: 1.1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Info + Role Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCoach ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.purpleAccent.withValues(alpha: 0.6),
                          width: 1.8,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(avatarUrl),
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isCoach
                                      ? Colors.cyanAccent.withValues(alpha: 0.12)
                                      : Colors.purpleAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCoach
                                        ? Colors.cyanAccent.withValues(alpha: 0.3)
                                        : Colors.purpleAccent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isCoach ? 'Тренер' : 'Адмін',
                                  style: TextStyle(
                                    color: isCoach ? Colors.cyanAccent : Colors.purpleAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            phone.isNotEmpty ? phone : (loginId.isNotEmpty ? 'Логін: $loginId' : 'Персонал басейну'),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
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
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(LucideIcons.slidersHorizontal, color: Colors.cyanAccent, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 14),

                // Middle: Rates / Salary config pills
                if (isCoach) ...[
                  Row(
                    children: [
                      Text(
                        'ТАРИФИ ТРЕНЕРА:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                      _buildRateBadge('Групові', '$rateGroup ₴', LucideIcons.users, Colors.cyanAccent),
                      _buildRateBadge('Індивід.', '$rateIndividual ₴', LucideIcons.user, Colors.amberAccent),
                      _buildRateBadge('Спліт', '$rateSplit ₴', LucideIcons.userPlus, Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Month Telemetry
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нараховано за місяць:',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${_formatNumber(earnedSum)} ₴',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($conductedTotal занять)',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
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
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '+ ${_formatNumber(scheduledSum)} ₴',
                                style: TextStyle(
                                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
                        'УМОВИ ОПЛАТИ АДМІНІСТРАТОРА:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.landmark, color: Colors.purpleAccent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Фіксований оклад',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatNumber(adminSalary)} ₴ / міс',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Ставка',
                            style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
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
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      isCoach ? 'Налаштувати тарифи занять' : 'Змінити оклад адміністратора',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCoach
                          ? Colors.cyanAccent.withValues(alpha: 0.12)
                          : Colors.purpleAccent.withValues(alpha: 0.15),
                      foregroundColor: isCoach ? Colors.cyanAccent : Colors.purpleAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isCoach
                              ? Colors.cyanAccent.withValues(alpha: 0.3)
                              : Colors.purpleAccent.withValues(alpha: 0.35),
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

  Widget _buildRateBadge(String title, String rate, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text('$title: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          Text(rate, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(LucideIcons.usersRound, color: Colors.white38, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Співробітників не знайдено',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Спробуйте змінити критерії пошуку або фільтр',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
