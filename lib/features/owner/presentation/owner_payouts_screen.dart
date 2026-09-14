import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/owner/presentation/owner_edit_salary_sheet.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:go_router/go_router.dart';

class OwnerPayoutsScreen extends ConsumerStatefulWidget {
  const OwnerPayoutsScreen({super.key});

  @override
  ConsumerState<OwnerPayoutsScreen> createState() => _OwnerPayoutsScreenState();
}

class _OwnerPayoutsScreenState extends ConsumerState<OwnerPayoutsScreen> {
  int _selectedPeriod = 0; // 0: Цей місяць, 1: Минулий місяць

  @override
  void initState() {
    super.initState();
    ensureAdminInFirestore();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _getMonthName(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _confirmPayout({
    required String staffId,
    required String name,
    required String role,
    required int amount,
    required String periodName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C182B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.banknote, color: Colors.pinkAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Підтвердити виплату', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ви збираєтесь підтвердити виплату заробітної плати:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Отримувач:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Посада:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      Text(role == 'coach' ? 'Тренер' : 'Адміністратор', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Період:', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      Text(periodName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Сума до виплати:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${_formatNumber(amount)} ₴', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Підтвердити'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final currentUser = ref.read(authControllerProvider);
        await FirebaseFirestore.instance.collection('payouts').add({
          'staffId': staffId,
          'staffName': name,
          'role': role,
          'amount': amount,
          'period': periodName,
          'createdAt': FieldValue.serverTimestamp(),
          'paidBy': currentUser?.name ?? 'Власник',
          'status': 'completed',
        });

        await logAdminAction(
          'Виплата ЗП: $name ($role) — ${_formatNumber(amount)} ₴ за $periodName',
          currentUser?.id ?? 'owner',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Виплату ${_formatNumber(amount)} ₴ для $name успішно збережено')),
                ],
              ),
              backgroundColor: const Color(0xFF0F261C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Помилка збереження виплати: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
    final targetMonth = _selectedPeriod == 0 ? now : DateTime(now.year, now.month - 1, 1);
    final periodName = _getMonthName(targetMonth);
    final themeConfig = ref.watch(appThemeControllerProvider);

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          if (themeConfig.isDark)
            const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeConfig),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', whereIn: ['coach', 'Coach', 'admin', 'Admin', 'administrator'])
                        .snapshots(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
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

                          // Compute payouts for the chosen targetMonth
                          int totalPayoutFund = 0;
                          final List<Map<String, dynamic>> staffPayouts = [];

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
                                    ? 'https://ui-avatars.com/api/?name=Admin&background=db2777&color=ffffff'
                                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=db2777&color=ffffff');

                            final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? 400;
                            final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? 450;
                            final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? 600;
                            final adminSalary = (data['adminSalary'] as num?)?.toInt() ?? 20000;

                            if (role == 'admin') {
                              totalPayoutFund += adminSalary;
                              staffPayouts.add({
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
                                'earnedSum': adminSalary,
                                'conductedTotal': 0,
                                'conductedG': 0,
                                'conductedI': 0,
                                'conductedS': 0,
                              });
                            } else {
                              // Coach
                              final coachClasses = allClasses.where((c) {
                                final matchesId = c.coachId == doc.id;
                                final matchesName = c.coachName.isNotEmpty &&
                                    (c.coachName.toLowerCase().contains(name.toLowerCase()) ||
                                     name.toLowerCase().contains(c.coachName.toLowerCase()));
                                return matchesId || matchesName;
                              }).where((c) => c.startTime.year == targetMonth.year && c.startTime.month == targetMonth.month).toList();

                              int conductedG = 0, conductedI = 0, conductedS = 0;

                              for (final c in coachClasses) {
                                final isConducted = c.startTime.isBefore(now) || c.attendedChildIds.isNotEmpty;
                                if (!isConducted) continue;

                                final tLower = c.title.toLowerCase();
                                final cLower = c.category.toLowerCase();
                                final isSplit = tLower.contains('спліт') || tLower.contains('split') || (cLower.contains('індивідуал') && c.maxCapacity == 2);
                                final isIndividual = !isSplit && (cLower.contains('індивідуал') || tLower.contains('індивідуал') || c.maxCapacity == 1);

                                if (isSplit) {
                                  conductedS++;
                                } else if (isIndividual) {
                                  conductedI++;
                                } else {
                                  conductedG++;
                                }
                              }

                              final conductedTotal = conductedG + conductedI + conductedS;
                              final earnedSum = (conductedG * rateGroup) + (conductedI * rateIndividual) + (conductedS * rateSplit);

                              totalPayoutFund += earnedSum;

                              staffPayouts.add({
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
                                'conductedTotal': conductedTotal,
                                'conductedG': conductedG,
                                'conductedI': conductedI,
                                'conductedS': conductedS,
                              });
                            }
                          }

                          // Guarantee Administrator appears in payouts even if Firestore doc was just created
                          final hasAdmin = staffPayouts.any((s) => s['role'] == 'admin');
                          if (!hasAdmin) {
                            totalPayoutFund += 20000;
                            staffPayouts.add({
                              'id': 'admin',
                              'name': 'Адміністратор',
                              'role': 'admin',
                              'phone': '+380 (99) 000-00-01',
                              'loginId': 'Admin',
                              'avatarUrl': 'https://ui-avatars.com/api/?name=Admin&background=db2777&color=ffffff',
                              'rateGroup': 400,
                              'rateIndividual': 450,
                              'rateSplit': 600,
                              'adminSalary': 20000,
                              'earnedSum': 20000,
                              'conductedTotal': 0,
                              'conductedG': 0,
                              'conductedI': 0,
                              'conductedS': 0,
                            });
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('payouts')
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, payoutHistorySnap) {
                              final historyDocs = payoutHistorySnap.data?.docs ?? [];

                              return ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                children: [
                                  // Period Switcher
                                  _buildPeriodSwitcher(),
                                  const SizedBox(height: 16),

                                  // Balance Card with real required total
                                  _buildBalanceCard(totalPayoutFund, periodName).animate().fadeIn().slideY(begin: 0.1),

                                  const SizedBox(height: 28),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'РОЗРАХУНОК ДО ВИПЛАТИ',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                      ),
                                      Text(
                                        periodName,
                                        style: TextStyle(color: Colors.pinkAccent.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 150.ms),

                                  const SizedBox(height: 14),

                                  if (staffPayouts.isEmpty)
                                    _buildEmptyState()
                                  else
                                    ...staffPayouts.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return _buildPayoutItemCard(item, periodName, index);
                                    }),

                                  const SizedBox(height: 32),

                                  Row(
                                    children: [
                                      const Icon(LucideIcons.history, color: Colors.white70, size: 16),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'ОСТАННІ ВИПЛАТИ (ІСТОРІЯ)',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 350.ms),

                                  const SizedBox(height: 14),

                                  if (historyDocs.isEmpty)
                                    _buildEmptyHistory()
                                  else
                                    ...historyDocs.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final doc = entry.value;
                                      final d = doc.data() as Map<String, dynamic>? ?? {};
                                      final sName = d['staffName'] ?? 'Співробітник';
                                      final amount = (d['amount'] as num?)?.toInt() ?? 0;
                                      final period = d['period'] ?? '';
                                      return _buildHistoryItem(
                                        'Виплата: $sName',
                                        period,
                                        '- ${_formatNumber(amount)} ₴',
                                        Colors.pinkAccent,
                                        400 + (index * 50),
                                      );
                                    }),

                                  const SizedBox(height: 48),
                                ],
                              );
                            },
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
                    'Виплати Персоналу',
                    style: TextStyle(color: themeConfig.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    'Фонд оплати праці та нарахування',
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(LucideIcons.banknote, color: Colors.pinkAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton(0, 'Поточний місяць'),
          ),
          Expanded(
            child: _buildPeriodButton(1, 'Минулий місяць'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(int index, String title) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pinkAccent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int totalFund, String periodName) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withValues(alpha: 0.18),
            Colors.purpleAccent.withValues(alpha: 0.08),
            const Color(0xFF030D1B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
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
                            color: Colors.pinkAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.walletCards, color: Colors.pinkAccent, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'НАРАХОВАНО ДО ВИПЛАТИ ($periodName)'
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(LucideIcons.creditCard, color: Colors.pinkAccent.withValues(alpha: 0.8), size: 18),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_formatNumber(totalFund)} ₴',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Сумарний фонд оплати за ставками тренерів та адмінів',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutItemCard(Map<String, dynamic> item, String periodName, int index) {
    final isCoach = item['role'] == 'coach';
    final name = item['name'] as String;
    final avatarUrl = item['avatarUrl'] as String;
    final earnedSum = item['earnedSum'] as int;
    final conductedTotal = item['conductedTotal'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCoach ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.pinkAccent.withValues(alpha: 0.2),
          width: 1.1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(avatarUrl),
                      backgroundColor: Colors.white10,
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
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCoach ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.purpleAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
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
                            isCoach
                                ? '$conductedTotal занять (Гр: ${item['conductedG']}, Інд: ${item['conductedI']}, Спліт: ${item['conductedS']})'
                                : 'Фіксована ставка • ${item['phone'].isNotEmpty ? item['phone'] : 'Оклад'}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatNumber(earnedSum)} ₴',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          periodName,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Edit Rate button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () => _openEditSalarySheet(
                          staffId: item['id'],
                          name: name,
                          role: item['role'],
                          phone: item['phone'],
                          loginId: item['loginId'],
                          rateGroup: item['rateGroup'],
                          rateIndividual: item['rateIndividual'],
                          rateSplit: item['rateSplit'],
                          adminSalary: item['adminSalary'],
                        ),
                        icon: const Icon(LucideIcons.sliders, size: 14),
                        label: const Text('Тариф', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Confirm Payout button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmPayout(
                          staffId: item['id'],
                          name: name,
                          role: item['role'],
                          amount: earnedSum,
                          periodName: periodName,
                        ),
                        icon: const Icon(LucideIcons.checkCheck, size: 16),
                        label: const Text('Виплатити', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent.withValues(alpha: 0.25),
                          foregroundColor: Colors.pinkAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.4)),
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
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05);
  }

  Widget _buildHistoryItem(String title, String date, String amount, Color color, int delay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowUpRight, color: Colors.pinkAccent, size: 14),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                ],
              ),
            ],
          ),
          Text(amount, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(LucideIcons.users, color: Colors.white30, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Немає нарахувань за цей період',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Center(
        child: Text(
          'Історія виплат порожня. Підтвердіть першу виплату вище.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
      ),
    );
  }
}
