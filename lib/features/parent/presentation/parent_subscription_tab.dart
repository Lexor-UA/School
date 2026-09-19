import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/shared/widgets/subscription_flip_card.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class SelectedSubscriptionOwnerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSelectedOwner(String? name) {
    state = name;
  }
}

final selectedSubscriptionOwnerProvider =
    NotifierProvider<SelectedSubscriptionOwnerNotifier, String?>(SelectedSubscriptionOwnerNotifier.new);

class ParentSubscriptionTab extends ConsumerStatefulWidget {
  const ParentSubscriptionTab({super.key});

  @override
  ConsumerState<ParentSubscriptionTab> createState() => _ParentSubscriptionTabState();
}

class _ParentSubscriptionTabState extends ConsumerState<ParentSubscriptionTab> {
  bool _isLoading = false;
  String _selectedOwner = '';

  final List<Map<String, dynamic>> _services = [
    // Дитячі абонементи
    {'name': 'Дитячий абонемент на 4 тренування', 'price': '1200 грн', 'classes': 4, 'validityDays': 30, 'isAdult': false},
    {'name': 'Дитячий абонемент на 8 тренувань', 'price': '1900 грн', 'classes': 8, 'validityDays': 30, 'isAdult': false},
    {'name': 'Дитячий абонемент на 12 тренувань', 'price': '2600 грн', 'classes': 12, 'validityDays': 30, 'isAdult': false},
    {'name': 'Разове дитяче тренування у групі', 'price': '500 грн', 'classes': 1, 'validityDays': 1, 'isAdult': false},
    // Дорослі абонементи
    {'name': 'Абонемент на 4 тренування (Доросла група)', 'price': '1600 грн', 'classes': 4, 'validityDays': 30, 'isAdult': true},
    {'name': 'Абонемент на 8 тренувань (Доросла група)', 'price': '2900 грн', 'classes': 8, 'validityDays': 30, 'isAdult': true},
    {'name': 'Разове відвідування (Доросла група)', 'price': '600 грн', 'classes': 1, 'validityDays': 2, 'isAdult': true},
    // Спліт абонементи (2 особи: дитина + дорослий або 2 дитини)
    {'name': 'Спліт-абонемент на 8 занять (2 особи)', 'price': '3400 грн', 'classes': 8, 'validityDays': 30, 'isAdult': null, 'isSplit': true},
    {'name': 'Разове спліт-тренування (2 особи)', 'price': '900 грн', 'classes': 1, 'validityDays': 2, 'isAdult': null, 'isSplit': true},
  ];

  void _payForSubscription(String userId, String owner, String selectedService) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); // Імітація оплати

      final currentUser = ref.read(authControllerProvider);
      final isOwnerAdult = owner == currentUser?.name;
      final serviceDetails = _services.firstWhere((s) => s['name'] == selectedService);
      final isServiceAdult = serviceDetails['isAdult'] as bool?;
      final isSplit = serviceDetails['isSplit'] as bool? ?? false;

      if (!isSplit) {
        if (isServiceAdult == true && !isOwnerAdult) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Дорослий абонемент не може бути оформлений для дитини.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        if (isServiceAdult == false && isOwnerAdult) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Дитячий абонемент не може бути оформлений для дорослого.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }

      // Check if this owner already has an active subscription in this family
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .where('parentIds', arrayContains: userId)
          .limit(1)
          .get();
      final List<String> relevantUserIds = familyDoc.docs.isNotEmpty
          ? List<String>.from(familyDoc.docs.first.data()['parentIds'] ?? [userId])
          : [userId];
      final queryUserIds = isServiceAdult == true ? [userId] : relevantUserIds;

      final existingSubSnap = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('userId', whereIn: queryUserIds)
          .where('ownerName', isEqualTo: isSplit ? 'Всі (Спліт)' : owner)
          .where('isActive', isEqualTo: true)
          .get();

      final hasActive = existingSubSnap.docs.any((d) {
        final data = d.data();
        final remaining = data['remainingClasses'] as int? ?? 0;
        final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
        final isNotExpired = expiry == null || expiry.isAfter(DateTime.now());
        return remaining > 0 && isNotExpired;
      });

      if (hasActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Для "$owner" вже діє активний абонемент!'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      final classes = serviceDetails['classes'] as int;
      final validityDays = serviceDetails['validityDays'] as int;
      final expiry = DateTime.now().add(Duration(days: validityDays));
      
      final newSub = Subscription(
        id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${owner.hashCode}',
        userId: userId,
        totalClasses: classes,
        remainingClasses: classes,
        isActive: true,
        serviceName: selectedService,
        expiryDate: expiry,
        ownerName: isSplit ? 'Всі (Спліт)' : owner,
      );
      
      await FirebaseFirestore.instance.collection('subscriptions').doc(newSub.id).set(newSub.toJson());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('parent.payment_success'.tr()),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('parent.payment_error'.tr(args: [e.toString()])),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentSheet(String userId, String effectiveOwner, bool isDark, AppThemeConfig themeConfig) {
    final currentUser = ref.read(authControllerProvider);
    final bool isOwnerAdult = effectiveOwner == currentUser?.name;
    String? selectedService;
    String categoryFilter = isOwnerAdult ? 'adult' : 'child';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            int totalPrice = 0;
            if (selectedService != null) {
              final service = _services.firstWhere((s) => s['name'] == selectedService);
              final priceStr = service['price'] as String;
              totalPrice = int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }

            final displayedServices = _services.where((s) {
              final isServiceAdult = s['isAdult'] as bool?;
              final isSplit = s['isSplit'] as bool? ?? false;

              if (isOwnerAdult) {
                // Adult owner: strictly exclude child-only subscriptions
                if (isServiceAdult == false && !isSplit) return false;
                if (categoryFilter == 'adult') return isServiceAdult == true && !isSplit;
                if (categoryFilter == 'split') return isSplit;
                return true; // 'all': only adult & split
              } else {
                // Child owner: strictly exclude all adult subscriptions!
                if (isServiceAdult == true) return false;
                if (categoryFilter == 'child') return isServiceAdult == false && !isSplit;
                if (categoryFilter == 'split') return isSplit;
                return true; // 'all': only child & split
              }
            }).toList();

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF0E3D64).withValues(alpha: 0.94),
                              const Color(0xFF092842).withValues(alpha: 0.98),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.96),
                              const Color(0xFFF0F9FF).withValues(alpha: 0.98),
                            ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF94A3B8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0284C7)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.creditCard, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'parent.choose_subscription'.tr(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : themeConfig.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Для: $effectiveOwner (${isOwnerAdult ? "Дорослий" : "Дитина"})',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Audience Tabs (Strictly filtered by owner role)
                      Row(
                        children: [
                          if (!isOwnerAdult) ...[
                            _buildModalCategoryTab('child', 'Для дітей', LucideIcons.baby, categoryFilter == 'child', isDark, () {
                              setModalState(() {
                                categoryFilter = 'child';
                                if (selectedService != null) {
                                  final s = _services.firstWhere((e) => e['name'] == selectedService);
                                  if (s['isAdult'] != false || s['isSplit'] == true) selectedService = null;
                                }
                              });
                            }),
                            const SizedBox(width: 6),
                          ],
                          if (isOwnerAdult) ...[
                            _buildModalCategoryTab('adult', 'Дорослі', LucideIcons.user, categoryFilter == 'adult', isDark, () {
                              setModalState(() {
                                categoryFilter = 'adult';
                                if (selectedService != null) {
                                  final s = _services.firstWhere((e) => e['name'] == selectedService);
                                  if (s['isAdult'] != true) selectedService = null;
                                }
                              });
                            }),
                            const SizedBox(width: 6),
                          ],
                          _buildModalCategoryTab('split', 'Спліт (2 ос.)', LucideIcons.users, categoryFilter == 'split', isDark, () {
                            setModalState(() {
                              categoryFilter = 'split';
                              if (selectedService != null) {
                                final s = _services.firstWhere((e) => e['name'] == selectedService);
                                if (s['isSplit'] != true) selectedService = null;
                              }
                            });
                          }),
                          const SizedBox(width: 6),
                          _buildModalCategoryTab('all', isOwnerAdult ? 'Всі дорослі' : 'Всі дитячі', LucideIcons.layers, categoryFilter == 'all', isDark, () {
                            setModalState(() {
                              categoryFilter = 'all';
                            });
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayedServices.length,
                          itemBuilder: (context, index) {
                            final service = displayedServices[index];
                            final serviceName = service['name'] as String;
                            final isSelected = selectedService == serviceName;
                            final bool isServiceAdult = service['isAdult'] as bool? ?? false;
                            final bool isSplit = service['isSplit'] as bool? ?? false;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedService = null;
                                  } else {
                                    selectedService = serviceName;
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [
                                            (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0EA5E9)).withValues(alpha: isDark ? 0.22 : 0.16),
                                            const Color(0xFF0284C7).withValues(alpha: isDark ? 0.10 : 0.06),
                                          ]
                                        : [
                                            isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.85),
                                            isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.60),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                        : (isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFBAE6FD)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.25 : 0.15),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? (isDark ? AppTheme.accentTeal : const Color(0xFF0284C7)) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                          width: 2,
                                        ),
                                        color: isSelected ? (isDark ? AppTheme.accentTeal : const Color(0xFF0284C7)) : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            serviceName,
                                            style: TextStyle(
                                              color: isDark ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9)) : themeConfig.textPrimary,
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSplit
                                                  ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12)
                                                  : (isServiceAdult
                                                      ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12)
                                                      : const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12)),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isSplit
                                                    ? const Color(0xFFA78BFA).withValues(alpha: 0.5)
                                                    : (isServiceAdult
                                                        ? const Color(0xFF818CF8).withValues(alpha: 0.45)
                                                        : const Color(0xFF10B981).withValues(alpha: 0.45)),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              isSplit ? 'Спліт (2 особи)' : (isServiceAdult ? 'Дорослий' : 'Дитячий'),
                                              style: TextStyle(
                                                color: isSplit
                                                    ? (isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED))
                                                    : (isServiceAdult
                                                        ? (isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5))
                                                        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.40),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        service['price'],
                                        style: TextStyle(
                                          color: isDark ? Colors.greenAccent : const Color(0xFF047857),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: totalPrice > 0 && selectedService != null
                              ? const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          border: totalPrice > 0 && selectedService != null
                              ? Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.2)
                              : null,
                          boxShadow: totalPrice > 0 && selectedService != null
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                    blurRadius: 18,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: ElevatedButton(
                          onPressed: totalPrice > 0 && selectedService != null
                              ? () {
                                  Navigator.pop(context);
                                  _payForSubscription(userId, effectiveOwner, selectedService!);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: totalPrice > 0 ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                            disabledForegroundColor: Colors.white38,
                          ),
                          child: Text(
                            totalPrice > 0
                                ? '${'parent.pay'.tr()} $totalPrice грн'
                                : 'parent.choose_subscription'.tr(),
                            style: TextStyle(
                              color: totalPrice > 0 ? Colors.white : (isDark ? Colors.white38 : themeConfig.textMuted),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalCategoryTab(String tabKey, String label, IconData icon, bool isSelected, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569))),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    final presetOwner = ref.watch(selectedSubscriptionOwnerProvider);
    if (presetOwner != null && presetOwner.isNotEmpty && _selectedOwner != presetOwner) {
      _selectedOwner = presetOwner;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedSubscriptionOwnerProvider.notifier).setSelectedOwner(null);
        }
      });
    }

    final familyAsync = ref.watch(familyStreamProvider);
    final family = familyAsync.value;
    final familyUserIds = (family != null && family.parentIds.isNotEmpty)
        ? family.parentIds
        : (user != null ? [user.id] : <String>[]);

    final subscriptions = ref.watch(subscriptionControllerProvider);
    final allSubs = user != null
        ? subscriptions.where((s) {
            if (s.isAdultSubscription) {
              return s.userId == user.id;
            } else {
              return familyUserIds.contains(s.userId);
            }
          }).toList()
        : <Subscription>[];
    
    final filterOwners = [
      if (user != null) {'id': user.name, 'name': user.name, 'isParent': true},
      ...children.map((c) => {'id': c.name, 'name': c.name, 'isParent': false}),
    ];

    String effectiveOwner = _selectedOwner;
    if (effectiveOwner.isEmpty && filterOwners.isNotEmpty) {
      effectiveOwner = filterOwners.first['id'] as String;
    }

    final activeForMember = allSubs.where((s) {
      final owner = (s.ownerName == null || s.ownerName!.isEmpty) ? (user?.name ?? '') : s.ownerName!;
      final matchesDirect = owner.trim().toLowerCase() == effectiveOwner.trim().toLowerCase();
      final isSplitShared = s.isSplitSubscription || (s.ownerName != null && s.ownerName!.contains('Спліт'));
      return (matchesDirect || isSplitShared) && s.isActive && s.remainingClasses > 0;
    }).toList();

    final currentSub = activeForMember.isNotEmpty ? activeForMember.first : null;
    final bool hasActiveSubscription = currentSub != null;
    final safeRemaining = currentSub != null
        ? (currentSub.totalClasses > 0
            ? currentSub.remainingClasses.clamp(0, currentSub.totalClasses)
            : currentSub.remainingClasses)
        : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: Text('parent.my_subscription'.tr()),
        titleTextStyle: TextStyle(
          color: themeConfig.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: ThemeHeaderButton(size: 38),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            
            // Filters
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: filterOwners.map((owner) {
                    final isSelected = effectiveOwner == owner['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedOwner = owner['id'] as String;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0EA5E9)).withValues(alpha: isDark ? 0.32 : 0.20),
                                        const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.10),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.85)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7).withValues(alpha: 0.60))
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : const Color(0xFFBAE6FD)),
                                width: isSelected ? 1.2 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.30 : 0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  owner['isParent'] == true ? LucideIcons.user : LucideIcons.baby,
                                  size: 15,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                      : (isDark ? Colors.white70 : themeConfig.textSecondary),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  owner['name'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDark ? Colors.white : const Color(0xFF0369A1))
                                        : (isDark ? Colors.white70 : themeConfig.textPrimary),
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // 3D Subscription Card or Empty State
            if (currentSub == null)
              Container(
                width: double.infinity,
                height: 220,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF0E3D64).withValues(alpha: 0.50),
                            const Color(0xFF092842).withValues(alpha: 0.65),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            const Color(0xFFF0F9FF).withValues(alpha: 0.85),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                        border: Border.all(
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.creditCard,
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Немає активного абонемента',
                      style: TextStyle(
                        color: isDark ? Colors.white : themeConfig.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Для "$effectiveOwner" абонемент ще не оформлено',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : themeConfig.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 240,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SubscriptionFlipCard(currentSub: currentSub),
                ),
              ),
            
            const SizedBox(height: 24),

            // Info Details (Oceanic Sapphire Glass Panel)
            if (currentSub != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF0E3D64).withValues(alpha: 0.60),
                                const Color(0xFF092842).withValues(alpha: 0.75),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.95),
                                const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF003B73).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Row 1: Власник
                        _buildDetailRow(
                          icon: LucideIcons.user,
                          label: 'parent.owner'.tr(),
                          valueWidget: Text(
                            currentSub.ownerName ?? 'Клієнт',
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          isDark: isDark,
                          themeConfig: themeConfig,
                          iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                        ),

                        _buildRowDivider(isDark),

                        // Row 2: Залишилось занять
                        _buildDetailRow(
                          icon: LucideIcons.waves,
                          label: 'Залишилось занять',
                          valueWidget: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$safeRemaining',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: ' з ${currentSub.totalClasses > 0 ? currentSub.totalClasses : safeRemaining}',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : themeConfig.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isDark: isDark,
                          themeConfig: themeConfig,
                          iconColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        ),

                        _buildRowDivider(isDark),

                        // Row 3: Діє до
                        _buildDetailRow(
                          icon: LucideIcons.calendar,
                          label: 'parent.valid_until'.tr(),
                          valueWidget: Text(
                            currentSub.expiryDate != null
                                ? DateFormat('dd.MM.yyyy').format(currentSub.expiryDate!)
                                : 'parent.unlimited'.tr(),
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          isDark: isDark,
                          themeConfig: themeConfig,
                          iconColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                        ),

                        _buildRowDivider(isDark),

                        // Row 4: Статус
                        _buildDetailRow(
                          icon: LucideIcons.shieldCheck,
                          label: 'parent.status'.tr(),
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                    : const Color(0xFF059669).withValues(alpha: 0.40),
                                width: 0.9,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5.5),
                                Text(
                                  'parent.active'.tr(),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isDark: isDark,
                          themeConfig: themeConfig,
                          iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        ),

                        if (family != null && family.isPaired && currentSub.userId != user?.id && !currentSub.isAdultSubscription) ...[
                          _buildRowDivider(isDark),
                          _buildDetailRow(
                            icon: LucideIcons.heartHandshake,
                            label: 'Спільний доступ',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.users, size: 14, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                const SizedBox(width: 5),
                                Text(
                                  'Оформив(-ла): ${family.getOtherParentName(user?.id ?? "")}',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            isDark: isDark,
                            themeConfig: themeConfig,
                            iconColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

            const SizedBox(height: 24),

            // Action Button or Active Subscription Status Card
            if (hasActiveSubscription)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF10B981).withValues(alpha: 0.18),
                            const Color(0xFF064E3B).withValues(alpha: 0.28),
                          ]
                        : [
                            const Color(0xFFECFDF5),
                            const Color(0xFFD1FAE5),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.40 : 0.50),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Абонемент активний',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF065F46),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Для "$effectiveOwner" вже діє абонемент (залишилось $safeRemaining занять). Новий абонемент буде доступний після завершення занять.',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF047857),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08)
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.40 : 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading || user == null ? null : () => _showPaymentSheet(user.id, effectiveOwner, isDark, themeConfig),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.creditCard, color: Colors.white, size: 20),
                  label: Text(
                    _isLoading
                        ? 'parent.processing'.tr()
                        : (effectiveOwner == user?.name
                            ? 'parent.pay_subscription'.tr()
                            : 'Оформити абонемент для $effectiveOwner'),
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.95, 0.95)),
            
            const SizedBox(height: 120), // spacing for bottom nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    required bool isDark,
    required AppThemeConfig themeConfig,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    final effectiveIconColor = iconColor ?? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7));
    final effectiveIconBg = iconBgColor ?? effectiveIconColor.withValues(alpha: isDark ? 0.12 : 0.10);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? effectiveIconColor.withValues(alpha: 0.25)
                      : effectiveIconColor.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                size: 15,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFFB0D4EC) : themeConfig.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        valueWidget,
      ],
    );
  }

  Widget _buildRowDivider(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.transparent,
                  const Color(0xFF00E5FF).withValues(alpha: 0.16),
                  Colors.transparent,
                ]
              : [
                  Colors.transparent,
                  const Color(0xFF0284C7).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
        ),
      ),
    );
  }
}