import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:go_router/go_router.dart';

class OwnerPayoutsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const OwnerPayoutsScreen({super.key, this.isEmbedded = false});

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

  Future<void> _recordPayout({
    required String staffId,
    required String name,
    required String role,
    required int amount,
    required String periodName,
    required String currencySymbol,
    String branchId = 'kyiv',
  }) async {
    HapticFeedback.mediumImpact();
    try {
      final currentUser = ref.read(authControllerProvider);
      final docRef = await FirebaseFirestore.instance.collection('payouts').add({
        'staffId': staffId,
        'staffName': name,
        'role': role,
        'branchId': branchId,
        'currency': currencySymbol,
        'amount': amount,
        'period': periodName,
        'createdAt': FieldValue.serverTimestamp(),
        'paidBy': currentUser?.name ?? 'Власник',
        'status': 'completed',
      });

      await logAdminAction(
        'Виплата ЗП: $name ($role, $branchId) — ${_formatMoney(amount, currencySymbol)} за $periodName',
        currentUser?.id ?? 'owner',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Виплату ${_formatMoney(amount, currencySymbol)} для $name зафіксовано',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Відмінити',
              textColor: const Color(0xFFF43F5E),
              onPressed: () async {
                try {
                  await docRef.delete();
                  HapticFeedback.lightImpact();
                } catch (_) {}
              },
            ),
            backgroundColor: const Color(0xFF0C1D2A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF10B981), width: 1),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка реєстрації виплати: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelPayoutDialog({
    required String payoutDocId,
    required String name,
    required int amount,
    required String currencySymbol,
    required String periodName,
  }) async {
    HapticFeedback.selectionClick();
    final themeConfig = ref.read(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C182B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.35) : const Color(0xFFFECDD3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.undo2, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Скасувати виплату',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Ви бажаєте скасувати реєстрацію виплати ${_formatMoney(amount, currencySymbol)} для $name за $periodName і повернути працівника до списку неоплачених?',
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF475569),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Ні, залишити',
              style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Скасувати виплату'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('payouts').doc(payoutDocId).delete();
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Виплату для $name скасовано',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0C1D2A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Помилка скасування: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmPayoutAll({
    required List<Map<String, dynamic>> unpaidStaff,
    required int remainingFundUah,
    required int remainingFundEur,
    required bool isAllLocations,
    required String periodName,
    required String currencySymbol,
  }) async {
    final count = unpaidStaff.length;
    if (count == 0) return;

    final totalDisplay = isAllLocations
        ? '${_formatMoney(remainingFundUah, '₴')}  •  ${_formatMoney(remainingFundEur, '€')}'
        : _formatMoney(currencySymbol == '€' ? remainingFundEur : remainingFundUah, currencySymbol);

    final themeConfig = ref.read(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C182B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.4) : const Color(0xFFFECDD3),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.checkCheck, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Відзначити всім: Виплачено',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ви збираєтесь зареєструвати виплату для всіх неоплачених працівників ($count осіб):',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF475569),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Невиплачено:',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$count осіб',
                        style: TextStyle(
                          color: isDark ? Colors.cyanAccent : const Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Період:',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        periodName,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Сума до відзначення:',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          totalDisplay,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
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
            child: Text(
              'Скасувати',
              style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Зареєструвати всім'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final currentUser = ref.read(authControllerProvider);
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        for (final item in unpaidStaff) {
          final docRef = firestore.collection('payouts').doc();
          batch.set(docRef, {
            'staffId': item['id'],
            'staffName': item['name'],
            'role': item['role'],
            'branchId': item['branchId'] ?? 'kyiv',
            'currency': item['currency'] ?? '₴',
            'amount': item['earnedSum'],
            'period': periodName,
            'createdAt': FieldValue.serverTimestamp(),
            'paidBy': currentUser?.name ?? 'Власник',
            'status': 'completed',
          });
        }

        await batch.commit();
        HapticFeedback.mediumImpact();

        await logAdminAction(
          'Масова реєстрація виплат ЗП: $totalDisplay для $count працівників за $periodName',
          currentUser?.id ?? 'owner',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Масову виплату $totalDisplay для $count працівників успішно збережено'),
                  ),
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
              content: Text('Помилка реєстрації виплат: $e'),
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
              color: isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.25) : const Color(0xFFFECDD3),
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
    final targetMonth = _selectedPeriod == 0 ? now : DateTime(now.year, now.month - 1, 1);
    final periodName = _getMonthName(targetMonth);
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
            if (themeConfig.isDark)
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
                              final c = GroupClass.fromJson(data);
                              if (!isAllLocations && activeBranchId != null) {
                                if (c.branchId.toLowerCase() != activeBranchId) continue;
                              }
                              allClasses.add(c);
                            } catch (_) {}
                          }

                          // Compute payouts for the chosen targetMonth separated by currency
                          int totalPayoutFundUah = 0;
                          int totalPayoutFundEur = 0;
                          final List<Map<String, dynamic>> staffPayouts = [];

                          for (final doc in staffDocs) {
                            final data = doc.data() as Map<String, dynamic>? ?? {};
                            final roleRaw = (data['role'] as String?)?.toLowerCase() ?? '';
                            final loginId = (data['loginId'] as String?) ?? '';
                            final bool isAdmin = roleRaw == 'admin' || roleRaw == 'administrator' || loginId.toLowerCase() == 'admin';
                            final role = isAdmin ? 'admin' : 'coach';
                            final name = (data['name'] as String?) ?? (isAdmin ? 'Адміністратор' : 'Без імені');
                            final phone = (data['phone'] as String?) ?? '';

                            final explicitBranchId = (data['branchId'] as String?)?.toLowerCase();
                            final branchIds = (data['branchIds'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
                            final String staffBranchId = explicitBranchId ??
                                ((loginId.toLowerCase().contains('vienna') ||
                                        name.toLowerCase().contains('vienna') ||
                                        name.toLowerCase().contains('huber') ||
                                        name.toLowerCase().contains('gruber'))
                                    ? 'vienna'
                                    : 'kyiv');

                            if (!isAllLocations) {
                              final matchesBranch = staffBranchId == activeBranchId ||
                                  (explicitBranchId != null && explicitBranchId == activeBranchId) ||
                                  branchIds.contains(activeBranchId);
                              if (!matchesBranch) continue;
                            }

                            final isViennaStaff = staffBranchId == 'vienna';
                            final staffCurrency = (data['currency'] as String?) ?? (isViennaStaff ? '€' : '₴');

                            final avatarUrl = (data['avatarUrl'] as String?) ??
                                (isAdmin
                                    ? 'https://ui-avatars.com/api/?name=Admin&background=db2777&color=ffffff'
                                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=db2777&color=ffffff');

                            final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? (isViennaStaff ? 25 : 400);
                            final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? (isViennaStaff ? 35 : 450);
                            final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? (isViennaStaff ? 45 : 600);
                            final adminSalary = (data['adminSalary'] as num?)?.toInt() ?? (isViennaStaff ? 1800 : 20000);

                            if (role == 'admin') {
                              if (isViennaStaff || staffCurrency == '€') {
                                totalPayoutFundEur += adminSalary;
                              } else {
                                totalPayoutFundUah += adminSalary;
                              }
                              staffPayouts.add({
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

                              if (isViennaStaff || staffCurrency == '€') {
                                totalPayoutFundEur += earnedSum;
                              } else {
                                totalPayoutFundUah += earnedSum;
                              }

                              staffPayouts.add({
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
                                'conductedTotal': conductedTotal,
                                'conductedG': conductedG,
                                'conductedI': conductedI,
                                'conductedS': conductedS,
                              });
                            }
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('payouts')
                                .orderBy('createdAt', descending: true)
                                .limit(100)
                                .snapshots(),
                            builder: (context, payoutHistorySnap) {
                              final allHistoryDocs = payoutHistorySnap.data?.docs ?? [];

                              // Build lookup of paid staff for the selected period
                              final Map<String, String> paidStaffPayoutDocIds = {};
                              for (final doc in allHistoryDocs) {
                                final d = doc.data() as Map<String, dynamic>? ?? {};
                                final docPeriod = d['period'] as String? ?? '';
                                if (docPeriod == periodName) {
                                  final sId = d['staffId'] as String?;
                                  final sName = (d['staffName'] as String?)?.toLowerCase().trim();
                                  if (sId != null && sId.isNotEmpty) {
                                    paidStaffPayoutDocIds[sId] = doc.id;
                                  }
                                  if (sName != null && sName.isNotEmpty) {
                                    paidStaffPayoutDocIds[sName] = doc.id;
                                  }
                                }
                              }

                              int remainingFundUah = 0;
                              int remainingFundEur = 0;
                              int unpaidCount = 0;

                              for (final item in staffPayouts) {
                                final sId = item['id'] as String? ?? '';
                                final sNameLower = (item['name'] as String? ?? '').toLowerCase().trim();
                                final isPaid = paidStaffPayoutDocIds.containsKey(sId) || paidStaffPayoutDocIds.containsKey(sNameLower);
                                final payoutDocId = paidStaffPayoutDocIds[sId] ?? paidStaffPayoutDocIds[sNameLower];
                                item['isPaid'] = isPaid;
                                item['payoutDocId'] = payoutDocId;

                                if (!isPaid) {
                                  unpaidCount++;
                                  final amount = item['earnedSum'] as int;
                                  final cur = item['currency'] as String? ?? (item['branchId'] == 'vienna' ? '€' : '₴');
                                  if (cur == '€') {
                                    remainingFundEur += amount;
                                  } else {
                                    remainingFundUah += amount;
                                  }
                                }
                              }

                              final historyDocs = allHistoryDocs.where((doc) {
                                if (isAllLocations) return true;
                                final d = doc.data() as Map<String, dynamic>? ?? {};
                                final bId = (d['branchId'] as String?)?.toLowerCase();
                                if (bId != null) return bId == activeBranchId;
                                final sName = (d['staffName'] as String?)?.toLowerCase() ?? '';
                                if (activeBranchId == 'vienna') {
                                  return sName.contains('vienna') || sName.contains('huber') || sName.contains('gruber');
                                } else {
                                  return !sName.contains('vienna') && !sName.contains('huber') && !sName.contains('gruber');
                                }
                              }).take(10).toList();

                              final isDark = themeConfig.isDark;

                              return ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                children: [
                                  // Period Switcher
                                  _buildPeriodSwitcher(now, themeConfig),
                                  const SizedBox(height: 16),

                                  // Balance Card with real required total & remaining fund
                                  _buildBalanceCard(
                                    remainingFundUah: remainingFundUah,
                                    remainingFundEur: remainingFundEur,
                                    totalFundUah: totalPayoutFundUah,
                                    totalFundEur: totalPayoutFundEur,
                                    unpaidCount: unpaidCount,
                                    isAllLocations: isAllLocations,
                                    periodName: periodName,
                                    staffPayouts: staffPayouts,
                                    currencySymbol: currencySymbol,
                                    themeConfig: themeConfig,
                                  ).animate().fadeIn().slideY(begin: 0.1),

                                  const SizedBox(height: 28),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'РОЗРАХУНОК ДО ВИПЛАТИ',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          shadows: isDark
                                              ? null
                                              : [
                                                  Shadow(
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                        ),
                                      ),
                                      Text(
                                        periodName,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 150.ms),

                                  const SizedBox(height: 14),

                                  if (staffPayouts.isEmpty)
                                    _buildEmptyState(themeConfig)
                                  else
                                    ...staffPayouts.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return _buildPayoutItemCard(item, periodName, currencySymbol, index, themeConfig);
                                    }),

                                  const SizedBox(height: 32),

                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.history,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ОСТАННІ ВИПЛАТИ (ІСТОРІЯ)',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          shadows: isDark
                                              ? null
                                              : [
                                                  Shadow(
                                                    color: Colors.white.withValues(alpha: 0.9),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 350.ms),

                                  const SizedBox(height: 14),

                                  if (historyDocs.isEmpty)
                                    _buildEmptyHistory(themeConfig)
                                  else
                                    ...historyDocs.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final doc = entry.value;
                                      final d = doc.data() as Map<String, dynamic>? ?? {};
                                      final sName = d['staffName'] ?? 'Співробітник';
                                      final amount = (d['amount'] as num?)?.toInt() ?? 0;
                                      final period = d['period'] ?? '';
                                      final itemCur = (d['currency'] as String?) ?? (d['branchId'] == 'vienna' ? '€' : '₴');
                                      return _buildHistoryItem(
                                        'Виплата: $sName',
                                        period,
                                        '- ${_formatMoney(amount, itemCur)}',
                                        const Color(0xFFF43F5E),
                                        400 + (index * 50),
                                        themeConfig,
                                      );
                                    }),

                                  SizedBox(height: widget.isEmbedded ? 180 : 48),
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
    final isDark = themeConfig.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFBE185D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.38 : 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.walletCards, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ФОНД ОПЛАТИ ПРАЦІ',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Виплати Персоналу',
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
          const SizedBox(width: 8),
          const ThemeHeaderButton(size: 38),
        ],
      ),
    );
  }

  Widget _buildPeriodSwitcher(DateTime now, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;
    final currentMonthName = _getMonthOnly(now);
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonthName = _getMonthOnly(prevMonthDate);

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
              color: isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.25) : const Color(0xFFFECDD3),
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
                child: _buildPeriodButton(
                  0,
                  '$currentMonthName (поточний)',
                  LucideIcons.calendar,
                  themeConfig,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildPeriodButton(
                  1,
                  '$prevMonthName (минулий)',
                  LucideIcons.history,
                  themeConfig,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(int index, String title, IconData icon, AppThemeConfig themeConfig) {
    final isSelected = _selectedPeriod == index;
    final isDark = themeConfig.isDark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPeriod = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFBE185D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.38 : 0.24),
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
                title,
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

  Widget _buildBalanceCard({
    required int remainingFundUah,
    required int remainingFundEur,
    required int totalFundUah,
    required int totalFundEur,
    required int unpaidCount,
    required bool isAllLocations,
    required String periodName,
    required List<Map<String, dynamic>> staffPayouts,
    required String currencySymbol,
    required AppThemeConfig themeConfig,
  }) {
    final isDark = themeConfig.isDark;
    final allPaid = staffPayouts.isNotEmpty && unpaidCount == 0;
    final hasFund = (isAllLocations && (remainingFundUah > 0 || remainingFundEur > 0)) ||
        (!isAllLocations && ((currencySymbol == '€' ? remainingFundEur : remainingFundUah) > 0));

    final unpaidStaff = staffPayouts.where((item) => item['isPaid'] != true).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF071A2E).withValues(alpha: 0.85) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: allPaid
              ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.6)
              : (isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.30) : const Color(0xFFFECDD3)),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (allPaid ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                .withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                              color: (allPaid ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                                  .withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (allPaid ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
                                    .withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              allPaid ? LucideIcons.checkCheck : LucideIcons.walletCards,
                              color: allPaid ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              allPaid ? 'ВСІ ЗП ВИПЛАЧЕНО' : 'ДО ВИПЛАТИ',
                              style: TextStyle(
                                color: allPaid
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48)),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
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
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                          const SizedBox(width: 5),
                          Text(
                            periodName,
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
                if (allPaid) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          isAllLocations
                              ? '${_formatMoney(totalFundUah, '₴')} • ${_formatMoney(totalFundEur, '€')}'
                              : _formatMoney(currencySymbol == '€' ? totalFundEur : totalFundUah, currencySymbol),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🎉 Всі ${staffPayouts.length} виплат за $periodName зафіксовано в системі',
                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  if (isAllLocations) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _formatMoney(remainingFundUah, '₴'),
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('•', style: TextStyle(color: themeConfig.textSecondary, fontSize: 24)),
                        ),
                        Flexible(
                          child: Text(
                            _formatMoney(remainingFundEur, '€'),
                            style: TextStyle(
                              color: isDark ? const Color(0xFFC084FC) : themeConfig.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _formatMoney(currencySymbol == '€' ? remainingFundEur : remainingFundUah, currencySymbol),
                      style: TextStyle(
                        color: themeConfig.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Невиплачено: $unpaidCount з ${staffPayouts.length} осіб • Фонд: ${isAllLocations ? '${_formatMoney(totalFundUah, '₴')} • ${_formatMoney(totalFundEur, '€')}' : _formatMoney(currencySymbol == '€' ? totalFundEur : totalFundUah, currencySymbol)}',
                    style: TextStyle(color: themeConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
                if (!allPaid && hasFund && unpaidStaff.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFBE185D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.35 : 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _confirmPayoutAll(
                        unpaidStaff: unpaidStaff,
                        remainingFundUah: remainingFundUah,
                        remainingFundEur: remainingFundEur,
                        isAllLocations: isAllLocations,
                        periodName: periodName,
                        currencySymbol: currencySymbol,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isAllLocations
                                  ? 'Виплатити всім ($unpaidCount)'
                                  : 'Виплатити всім (${_formatMoney(currencySymbol == '€' ? remainingFundEur : remainingFundUah, currencySymbol)})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  Widget _buildPayoutItemCard(
    Map<String, dynamic> item,
    String periodName,
    String currencySymbol,
    int index,
    AppThemeConfig themeConfig,
  ) {
    final isDark = themeConfig.isDark;
    final isCoach = item['role'] == 'coach';
    final name = item['name'] as String;
    final avatarUrl = item['avatarUrl'] as String;
    final earnedSum = item['earnedSum'] as int;
    final conductedTotal = item['conductedTotal'] as int;
    final staffBranchId = item['branchId'] as String? ?? 'kyiv';
    final isVienna = staffBranchId == 'vienna';
    final effectiveCurrency = item['currency'] as String? ?? (isVienna ? '€' : '₴');
    final isPaid = item['isPaid'] == true;

    final accentColor = isPaid
        ? const Color(0xFF10B981)
        : (isCoach ? const Color(0xFF00E5FF) : const Color(0xFFA855F7));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.6)
              : (isDark
                  ? accentColor.withValues(alpha: 0.25)
                  : (isCoach ? const Color(0xFFBAE6FD) : const Color(0xFFE9D5FF))),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level 1: Full name and big amount side by side (zero truncation!)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPaid) ...[
                                    const Icon(LucideIcons.checkCheck, size: 16, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    _formatMoney(earnedSum, effectiveCurrency),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Level 2: Badges and role subtext
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isPaid)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.55),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.check, size: 10, color: Color(0xFF10B981)),
                                      SizedBox(width: 3),
                                      Text(
                                        'ВИПЛАЧЕНО',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                isCoach
                                    ? '${_formatLessonsCount(conductedTotal)} (Гр: ${item['conductedG']}, Інд: ${item['conductedI']}, Спліт: ${item['conductedS']})'
                                    : 'Оклад • ${item['phone'].isNotEmpty ? item['phone'] : (item['loginId'] ?? '')}',
                                style: TextStyle(
                                  color: themeConfig.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                          currencySymbol: effectiveCurrency,
                        ),
                        icon: Icon(
                          LucideIcons.sliders,
                          size: 14,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),
                        label: Text(
                          'Тариф',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: themeConfig.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFBAE6FD),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Payout Action Button: 1-click register if unpaid, undo dialog if paid
                    Expanded(
                      flex: 2,
                      child: isPaid
                          ? Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final pId = item['payoutDocId'] as String?;
                                  if (pId != null && pId.isNotEmpty) {
                                    _cancelPayoutDialog(
                                      payoutDocId: pId,
                                      name: name,
                                      amount: earnedSum,
                                      currencySymbol: effectiveCurrency,
                                      periodName: periodName,
                                    );
                                  }
                                },
                                icon: const Icon(LucideIcons.checkCheck, size: 15, color: Color(0xFF10B981)),
                                label: Text(
                                  'Виплачено ${_formatMoney(earnedSum, effectiveCurrency)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF43F5E), Color(0xFFBE185D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.35 : 0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _recordPayout(
                                  staffId: item['id'],
                                  name: name,
                                  role: item['role'],
                                  amount: earnedSum,
                                  periodName: periodName,
                                  currencySymbol: effectiveCurrency,
                                  branchId: staffBranchId,
                                ),
                                icon: const Icon(LucideIcons.check, size: 15, color: Colors.white),
                                label: Text(
                                  'Виплатити ${_formatMoney(earnedSum, effectiveCurrency)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
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

  Widget _buildHistoryItem(String title, String date, String amount, Color color, int delay, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.70) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.15 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowUpRight, color: Color(0xFFF43F5E), size: 14),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: themeConfig.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      color: themeConfig.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFFF43F5E),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildEmptyState(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                LucideIcons.users,
                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Немає нарахувань за цей період',
              style: TextStyle(
                color: themeConfig.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Text(
          'Історія виплат порожня. Підтвердіть першу виплату вище.',
          style: TextStyle(
            color: themeConfig.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

