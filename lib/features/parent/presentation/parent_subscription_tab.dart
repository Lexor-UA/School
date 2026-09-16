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
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';

class ParentSubscriptionTab extends ConsumerStatefulWidget {
  const ParentSubscriptionTab({super.key});

  @override
  ConsumerState<ParentSubscriptionTab> createState() => _ParentSubscriptionTabState();
}

class _ParentSubscriptionTabState extends ConsumerState<ParentSubscriptionTab> {
  bool _isLoading = false;
  int _currentIndex = 0;
  String _selectedOwner = '';
  final PageController _pageController = PageController(viewportFraction: 0.9);

  final List<Map<String, dynamic>> _services = [
    {'name': 'Абонемент на 4 тренування', 'price': '1200 грн', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренуваннь', 'price': '1900 грн', 'classes': 8, 'validityDays': 30},
    {'name': 'Абонемент на 12 тренуваннь', 'price': '2600 грн', 'classes': 12, 'validityDays': 30},
    {'name': 'Разове тренування у групі', 'price': '500 грн', 'classes': 1, 'validityDays': 1},
    {'name': 'Разове відвідування/доросла група', 'price': '600 грн', 'classes': 1, 'validityDays': 2},
    {'name': 'Абонемент на 4 тренування (ДОРОСЛА ГРУПА)', 'price': '1600 грн', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренувань (ДОРОСЛА ГРУПА)', 'price': '2900 грн', 'classes': 8, 'validityDays': 30},
  ];

  void _payForSubscription(String userId, String owner, String selectedService) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); // Імітація оплати

      final serviceDetails = _services.firstWhere((s) => s['name'] == selectedService);
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
        ownerName: owner,
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
    String? selectedService;

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
                          margin: const EdgeInsets.only(bottom: 24),
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
                          Text(
                            'parent.choose_subscription'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : themeConfig.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            final serviceName = service['name'] as String;
                            final isSelected = selectedService == serviceName;

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
                                      child: Text(
                                        serviceName,
                                        style: TextStyle(
                                          color: isDark ? (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9)) : themeConfig.textPrimary,
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        ),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                            disabledForegroundColor: Colors.white38,
                          ),
                          child: Text(
                            totalPrice > 0 ? '${'parent.pay_subscription'.tr()} $totalPrice грн' : 'parent.choose_subscription'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: totalPrice > 0 ? Colors.white : Colors.white38,
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    final subscriptions = ref.watch(subscriptionControllerProvider);
    final allSubs = user != null ? subscriptions.where((s) => s.userId == user.id).toList() : <Subscription>[];
    var activeSubs = allSubs.where((s) => s.isActive).toList();
    
    final filterOwners = [
      if (user != null) {'id': user.name, 'name': user.name, 'isParent': true},
      ...children.map((c) => {'id': c.name, 'name': c.name, 'isParent': false}),
    ];

    String effectiveOwner = _selectedOwner;
    if (effectiveOwner.isEmpty && filterOwners.isNotEmpty) {
      effectiveOwner = filterOwners.first['id'] as String;
    }

    if (effectiveOwner.isNotEmpty) {
      activeSubs = activeSubs.where((s) => s.ownerName == effectiveOwner).toList();
    }

    // Safety check if current index exceeds length after deletion/expiration
    if (_currentIndex >= activeSubs.length && activeSubs.isNotEmpty) {
      _currentIndex = activeSubs.length - 1;
    } else if (activeSubs.isEmpty) {
      _currentIndex = 0;
    }

    final currentSub = activeSubs.isNotEmpty ? activeSubs[_currentIndex] : null;

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
                              _currentIndex = 0;
                              if (_pageController.hasClients) {
                                _pageController.jumpToPage(0);
                              }
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
            
            // 3D Cards Carousel
            if (activeSubs.isEmpty)
              SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    'parent.no_active_subs'.tr(),
                    style: TextStyle(color: isDark ? Colors.white70 : themeConfig.textSecondary, fontSize: 16),
                  ),
                ),
              )
            else
              SizedBox(
                height: 240,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: activeSubs.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: isSelected ? 0.0 : 16.0,
                      ),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.6,
                        child: SubscriptionFlipCard(currentSub: activeSubs[index]),
                      ),
                    );
                  },
                ),
              ),

            if (activeSubs.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(activeSubs.length, (index) {
                    final isSelected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isSelected ? 24.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                            : (isDark ? Colors.white24 : const Color(0xFFBAE6FD)),
                        borderRadius: BorderRadius.circular(4.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
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
                                  text: '${currentSub.remainingClasses}',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: ' з ${currentSub.totalClasses > 0 ? currentSub.totalClasses : currentSub.remainingClasses}',
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
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

            const SizedBox(height: 24),

            // Action Button
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
                  _isLoading ? 'parent.processing'.tr() : 'parent.pay_subscription'.tr(),
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
