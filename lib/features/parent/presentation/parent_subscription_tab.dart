import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/shared/widgets/subscription_flip_card.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';

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
    {'name': 'Абонемент на 4 тренування(ДОРОСЛА ГРУПА)', 'price': '1600 грн', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренувань(ДОРОСЛА ГРУПА)', 'price': '2900 грн', 'classes': 8, 'validityDays': 30},
  ];

  void _payForMultipleSubscriptions(String userId, String owner, List<String> selectedServices) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); // Імітація оплати

      for (final serviceName in selectedServices) {
        final serviceDetails = _services.firstWhere((s) => s['name'] == serviceName);
        final classes = serviceDetails['classes'] as int;
        final validityDays = serviceDetails['validityDays'] as int;
        final expiry = DateTime.now().add(Duration(days: validityDays));
        
        final newSub = Subscription(
          id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${owner.hashCode}',
          userId: userId,
          totalClasses: classes,
          remainingClasses: classes,
          isActive: true,
          serviceName: serviceName,
          expiryDate: expiry,
          ownerName: owner,
        );
        
        await FirebaseFirestore.instance.collection('subscriptions').doc(newSub.id).set(newSub.toJson());
      }
      
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

  void _showPaymentSheet(String userId, String effectiveOwner) {
    List<String> selectedServices = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            int totalPrice = 0;
            for (final service in _services) {
              final serviceName = service['name'] as String;
              if (selectedServices.contains(serviceName)) {
                final priceStr = service['price'] as String;
                final priceNum = int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                totalPrice += priceNum;
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('parent.choose_subscription'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        final serviceName = service['name'] as String;
                        final isSelected = selectedServices.contains(serviceName);
                        
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedServices.remove(serviceName);
                              } else {
                                selectedServices.add(serviceName);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: isSelected ? AppTheme.accentTeal : Colors.white.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(serviceName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 8),
                                Text(service['price'], style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: totalPrice > 0
                          ? () {
                              Navigator.pop(context);
                              _payForMultipleSubscriptions(userId, effectiveOwner, selectedServices);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                        disabledForegroundColor: Colors.white54,
                      ),
                      child: Text(
                        totalPrice > 0 ? 'parent.pay_subscription'.tr() + ' $totalPrice грн' : 'parent.choose_subscription'.tr(), 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: totalPrice > 0 ? Colors.white : Colors.white54
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    final allSubs = user != null ? ref.read(subscriptionControllerProvider.notifier).getSubscriptionsForUser(user.id) : <Subscription>[];
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
        centerTitle: true,
        title: Text('parent.my_subscription'.tr()),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: filterOwners.map((owner) {
                  final isSelected = effectiveOwner == owner['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            owner['isParent'] == true ? LucideIcons.user : LucideIcons.baby,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(owner['name'] as String),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.accentTeal,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedOwner = owner['id'] as String;
                            _currentIndex = 0;
                            // Optionally jump to page 0 if using page controller
                            if (_pageController.hasClients) {
                              _pageController.jumpToPage(0);
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            
            // 3D Cards Carousel
            if (activeSubs.isEmpty)
              SizedBox(
                height: 240,
                child: Center(
                  child: Text('parent.no_active_subs'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: _currentIndex == index ? 24.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? AppTheme.accentTeal : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    );
                  }),
                ),
              ),
            
            const SizedBox(height: 24),

            // Info Details
            if (currentSub != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('parent.owner'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          currentSub.ownerName ?? 'Клієнт',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Залишилось занять', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          '${currentSub.remainingClasses} з ${currentSub.totalClasses > 0 ? currentSub.totalClasses : currentSub.remainingClasses}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('parent.valid_until'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(
                          currentSub.expiryDate != null ? DateFormat('dd.MM.yyyy').format(currentSub.expiryDate!) : 'parent.unlimited'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('parent.status'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('parent.active'.tr(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Action Button
            if (activeSubs.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.orangeAccent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'У цього профілю вже є активний абонемент. Використайте його перед покупкою нового.',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms)
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || user == null ? null : () => _showPaymentSheet(user.id, effectiveOwner),
                  icon: _isLoading  
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.creditCard, color: Colors.white, size: 20),
                  label: Text(
                    _isLoading ? 'parent.processing'.tr() : 'parent.pay_subscription'.tr(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: AppTheme.accentTeal.withValues(alpha: 0.4),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
            
            const SizedBox(height: 120), // spacing for bottom nav bar
          ],
        ),
      ),
    );
  }
}
