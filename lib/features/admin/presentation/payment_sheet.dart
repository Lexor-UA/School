import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/chat/repositories/chat_repository.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const PaymentSheet({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  late int _selectedTab; // 0: Активні, 1: Не оплатили / Закінчились, 2: Швидка каса
  String _searchQuery = '';
  bool _onlyExpiringSoon = false;

  // Cashier State
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedOwnerName;
  String _paymentMethod = 'Картка';
  Map<String, dynamic>? _selectedPackage;
  bool _isProcessing = false;
  bool _isSuccess = false;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'sub_8_kids',
      'name': 'Абонемент на 8 тренуваннь',
      'classes': 8,
      'price': 1900,
      'validityDays': 30,
      'icon': LucideIcons.calendarDays,
      'badge': 'Популярний',
      'color': const Color(0xFF38BDF8),
    },
    {
      'id': 'sub_12_kids',
      'name': 'Абонемент на 12 тренуваннь',
      'classes': 12,
      'price': 2600,
      'validityDays': 30,
      'icon': LucideIcons.sparkles,
      'badge': 'Вигідно',
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'sub_4_kids',
      'name': 'Абонемент на 4 тренування',
      'classes': 4,
      'price': 1200,
      'validityDays': 30,
      'icon': LucideIcons.calendar,
      'badge': null,
      'color': const Color(0xFF60A5FA),
    },
    {
      'id': 'sub_single_group',
      'name': 'Разове тренування у групі',
      'classes': 1,
      'price': 500,
      'validityDays': 1,
      'icon': LucideIcons.user,
      'badge': 'Разове',
      'color': const Color(0xFF06B6D4),
    },
    {
      'id': 'sub_single_adult',
      'name': 'Разове відвідування/доросла група',
      'classes': 1,
      'price': 600,
      'validityDays': 2,
      'icon': LucideIcons.users,
      'badge': 'Дорослі',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'sub_4_adult',
      'name': 'Абонемент на 4 тренування (ДОРОСЛА ГРУПА)',
      'classes': 4,
      'price': 1600,
      'validityDays': 30,
      'icon': LucideIcons.calendarCheck,
      'badge': 'Дорослі 4',
      'color': const Color(0xFFA855F7),
    },
    {
      'id': 'sub_8_adult',
      'name': 'Абонемент на 8 тренувань (ДОРОСЛА ГРУПА)',
      'classes': 8,
      'price': 2900,
      'validityDays': 30,
      'icon': LucideIcons.award,
      'badge': 'Дорослі 8',
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _selectedPackage = _packages[0];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSubActive(Subscription sub) {
    if (!sub.isActive) return false;
    if (sub.remainingClasses <= 0) return false;
    if (sub.expiryDate != null && DateTime.now().isAfter(sub.expiryDate!)) {
      return false;
    }
    return true;
  }

  bool _isSubExpiringSoon(Subscription sub) {
    if (!_isSubActive(sub)) return false;
    if (sub.remainingClasses <= 2) return true;
    if (sub.expiryDate != null) {
      final days = sub.expiryDate!.difference(DateTime.now()).inDays;
      if (days <= 5) return true;
    }
    return false;
  }

  void _initiateRenewal({
    required String clientId,
    required String clientName,
    required String ownerName,
  }) {
    setState(() {
      _selectedClientId = clientId;
      _selectedClientName = clientName;
      _selectedOwnerName = ownerName;
      _selectedTab = 2; // Switch to Cashier tab
    });
  }

  String _formatClassesCount(int count) {
    if (count == 1) return '1 заняття';
    if (count >= 2 && count <= 4) return '$count заняття';
    return '$count занять';
  }

  Future<void> _processPayment() async {
    if (_selectedClientId == null || _selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, оберіть клієнта та послугу'),
          backgroundColor: Color(0xFFF43F5E),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final validityDays = _selectedPackage!['validityDays'] as int;
      final classes = _selectedPackage!['classes'] as int;
      final price = _selectedPackage!['price'] as int;
      final serviceName = _selectedPackage!['name'] as String;
      final expiry = DateTime.now().add(Duration(days: validityDays));
      final owner = _selectedOwnerName ?? _selectedClientName ?? 'Клієнт';

      final newSubId = 'sub_${DateTime.now().microsecondsSinceEpoch}_${owner.hashCode.abs()}';

      final newSub = Subscription(
        id: newSubId,
        userId: _selectedClientId!,
        totalClasses: classes,
        remainingClasses: classes,
        isActive: true,
        serviceName: serviceName,
        expiryDate: expiry,
        ownerName: owner,
      );

      // 1. Write to Firestore
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(newSub.id)
          .set(newSub.toJson());

      // 2. Log Admin action
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Оплачено $price ₴: "$serviceName" для "$owner" ($_paymentMethod)',
          admin.id,
        );
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });

        await Future.delayed(const Duration(milliseconds: 1600));

        if (mounted) {
          setState(() {
            _isSuccess = false;
            _selectedTab = 0; // Return to Active Tab
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка проведення оплати: $e'),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  void _showReminderModal({
    required String clientId,
    required String clientName,
    required String ownerName,
    String? phone,
    String? reason,
  }) {
    final text = 'Вітаємо, $clientName! 🏊 Нагадуємо, що абонемент на тренування з плавання в CitySwim для $ownerName завершився. Будемо раді бачити вас знову на заняттях! Щоб обрати зручний розклад та поновити абонемент, напишіть нам або завітайте до школи.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF16243A), Color(0xFF0F1928)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.messageSquareQuote, color: Color(0xFF38BDF8), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нагадування для $clientName',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Учень: $ownerName • ${phone ?? "Немає тел."}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: const Text('Скопіювати'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: text));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Текст нагадування скопійовано в буфер!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: const Color(0xFF081424),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.send, size: 16),
                          label: const Text('В чат додатку', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            final dialogId = 'chat_$clientId';
                            await ChatRepository().sendMessage(
                              dialogId: dialogId,
                              clientId: clientId,
                              clientName: clientName,
                              clientAvatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(clientName)}',
                              senderId: 'admin',
                              text: text,
                            );

                            final admin = ref.read(authControllerProvider);
                            if (admin != null) {
                              await logAdminAction('Надіслано нагадування про оплату для "$clientName"', admin.id);
                            }

                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Нагадування успішно надіслано в чат клієнта!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(allSubscriptionsProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'parent').snapshots(),
      builder: (context, usersSnap) {
        final Map<String, Map<String, dynamic>> clientsMap = {};
        if (usersSnap.hasData) {
          for (var doc in usersSnap.data!.docs) {
            clientsMap[doc.id] = doc.data() as Map<String, dynamic>;
          }
        }

        return subsAsync.when(
          data: (allSubs) => _buildMainSheet(context, allSubs, clientsMap),
          loading: () => _buildLoadingSheet(context),
          error: (err, stack) => _buildErrorSheet(context, err.toString()),
        );
      },
    );
  }

  Widget _buildLoadingSheet(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0A1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
      ),
    );
  }

  Widget _buildErrorSheet(BuildContext context, String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: Text('Помилка: $error', style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildMainSheet(
    BuildContext context,
    List<Subscription> allSubs,
    Map<String, Map<String, dynamic>> clientsMap,
  ) {
    // 1. Separate Active Subscriptions
    final activeSubs = allSubs.where(_isSubActive).toList();

    // Sort active: expiring soonest first
    activeSubs.sort((a, b) {
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });

    final expiringSoonSubs = activeSubs.where(_isSubExpiringSoon).toList();

    // 2. Identify Unpaid / Expired / Lapsed clients
    final List<_UnpaidClientItem> unpaidList = [];

    for (final sub in allSubs) {
      if (!_isSubActive(sub)) {
        final clientData = clientsMap[sub.userId];
        final clientName = clientData?['name'] ?? sub.ownerName ?? 'Клієнт';
        final phone = clientData?['phone'];
        final owner = sub.ownerName ?? clientName;

        String reason;
        if (sub.remainingClasses <= 0) {
          reason = 'Вичерпано заняття (0 з ${sub.totalClasses})';
        } else if (sub.expiryDate != null && DateTime.now().isAfter(sub.expiryDate!)) {
          final days = DateTime.now().difference(sub.expiryDate!).inDays;
          reason = 'Закінчився термін (прострочено $days дн.)';
        } else {
          reason = 'Неактивний абонемент';
        }

        unpaidList.add(_UnpaidClientItem(
          clientId: sub.userId,
          clientName: clientName,
          ownerName: owner,
          phone: phone,
          serviceName: sub.serviceName ?? 'Абонемент',
          remainingClasses: sub.remainingClasses,
          totalClasses: sub.totalClasses,
          expiryDate: sub.expiryDate,
          reason: reason,
        ));
      }
    }

    // Also include registered parents who have ZERO subscriptions at all
    clientsMap.forEach((clientId, data) {
      final userHasSub = allSubs.any((s) => s.userId == clientId);
      if (!userHasSub) {
        unpaidList.add(_UnpaidClientItem(
          clientId: clientId,
          clientName: data['name'] ?? 'Клієнт',
          ownerName: data['name'] ?? 'Клієнт',
          phone: data['phone'],
          serviceName: 'Без абонемента',
          remainingClasses: 0,
          totalClasses: 0,
          expiryDate: null,
          reason: 'Не брав абонемент (перестав ходити)',
        ));
      }
    });

    // Deduplicate unpaid list by clientId + ownerName
    final Map<String, _UnpaidClientItem> uniqueUnpaid = {};
    for (var item in unpaidList) {
      final key = '${item.clientId}_${item.ownerName}';
      if (!uniqueUnpaid.containsKey(key)) {
        uniqueUnpaid[key] = item;
      }
    }
    final finalUnpaidList = uniqueUnpaid.values.toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF13233C).withValues(alpha: 0.96),
                const Color(0xFF0A1422).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                blurRadius: 36,
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Top Drag Handle & Title
              _buildHeader(context),

              // 2. Executive Telemetry Bar (Зведена аналітика)
              _buildTelemetryKPIs(
                activeCount: activeSubs.length,
                expiringCount: expiringSoonSubs.length,
                unpaidCount: finalUnpaidList.length,
              ),

              // 3. Segmented Tab Selector
              _buildSegmentedTabs(
                activeCount: activeSubs.length,
                unpaidCount: finalUnpaidList.length,
              ),

              const SizedBox(height: 10),

              // 4. Search Bar (for tabs 0 and 1)
              if (_selectedTab != 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _buildSearchBar(),
                ),

              // 5. Active Tab View
              Expanded(
                child: _isSuccess
                    ? _buildSuccessView()
                    : (_isProcessing
                        ? _buildProcessingView()
                        : _buildTabContent(
                            activeSubs: activeSubs,
                            expiringSoonSubs: expiringSoonSubs,
                            unpaidList: finalUnpaidList,
                            clientsMap: clientsMap,
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.walletCards, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.payment_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'admin.payment_subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. EXECUTIVE TELEMETRY BAR
  // ==========================================
  Widget _buildTelemetryKPIs({
    required int activeCount,
    required int expiringCount,
    required int unpaidCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTelemetryCard(
              count: '$activeCount',
              label: 'admin.tab_active'.tr(),
              color: const Color(0xFF10B981),
              icon: LucideIcons.circleCheck,
              isSelected: _selectedTab == 0 && !_onlyExpiringSoon,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _onlyExpiringSoon = false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTelemetryCard(
              count: '$expiringCount',
              label: 'admin.tab_expiring'.tr(),
              color: const Color(0xFFF59E0B),
              icon: LucideIcons.hourglass,
              isSelected: _selectedTab == 0 && _onlyExpiringSoon,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _onlyExpiringSoon = true;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTelemetryCard(
              count: '$unpaidCount',
              label: 'admin.tab_unpaid'.tr(),
              color: const Color(0xFFF43F5E),
              icon: LucideIcons.alertCircle,
              isSelected: _selectedTab == 1,
              onTap: () {
                setState(() => _selectedTab = 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.10),
              width: isSelected ? 1.3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: TextStyle(
                        color: color,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // ==========================================
  // 3. SEGMENTED TABS
  // ==========================================
  Widget _buildSegmentedTabs({
    required int activeCount,
    required int unpaidCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                title: 'admin.tab_active'.tr(),
                badge: '$activeCount',
                accentColor: const Color(0xFF10B981),
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 1,
                title: 'admin.tab_unpaid'.tr(),
                badge: '$unpaidCount',
                accentColor: const Color(0xFFF43F5E),
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 2,
                title: 'admin.tab_cash'.tr(),
                badge: null,
                accentColor: const Color(0xFF00D2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required String? badge,
    required Color accentColor,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: index == 2
                      ? [const Color(0xFF00D2FF), const Color(0xFF0077B6)]
                      : (index == 0
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFF43F5E), const Color(0xFFE11D48)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (index == 2
                            ? const Color(0xFF00D2FF)
                            : (index == 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E)))
                        .withValues(alpha: 0.35),
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
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Пошук за ім\'ям учня, клієнта чи телефоном...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12.5),
          prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 17),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ==========================================
  // 4. TAB CONTENT SWITCHER
  // ==========================================
  Widget _buildTabContent({
    required List<Subscription> activeSubs,
    required List<Subscription> expiringSoonSubs,
    required List<_UnpaidClientItem> unpaidList,
    required Map<String, Map<String, dynamic>> clientsMap,
  }) {
    if (_selectedTab == 0) {
      return _buildActiveSubsTab(activeSubs, expiringSoonSubs, clientsMap);
    } else if (_selectedTab == 1) {
      return _buildUnpaidSubsTab(unpaidList);
    } else {
      return _buildCashierTab(clientsMap);
    }
  }

  // ==========================================
  // TAB 0: АКТИВНІ АБОНЕМЕНТИ
  // ==========================================
  Widget _buildActiveSubsTab(
    List<Subscription> activeSubs,
    List<Subscription> expiringSoonSubs,
    Map<String, Map<String, dynamic>> clientsMap,
  ) {
    var displayList = _onlyExpiringSoon ? expiringSoonSubs : activeSubs;

    if (_searchQuery.isNotEmpty) {
      displayList = displayList.where((s) {
        final clientName = clientsMap[s.userId]?['name']?.toString().toLowerCase() ?? '';
        final ownerName = (s.ownerName ?? '').toLowerCase();
        final phone = clientsMap[s.userId]?['phone']?.toString().toLowerCase() ?? '';
        final service = (s.serviceName ?? '').toLowerCase();
        return clientName.contains(_searchQuery) ||
            ownerName.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            service.contains(_searchQuery);
      }).toList();
    }

    return Column(
      children: [
        // Sub-filter chip bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Всі активні (${activeSubs.length})',
                isSelected: !_onlyExpiringSoon,
                onTap: () => setState(() => _onlyExpiringSoon = false),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: '⚠️ Закінчуються скоро (${expiringSoonSubs.length})',
                isSelected: _onlyExpiringSoon,
                accentColor: const Color(0xFFF59E0B),
                onTap: () => setState(() => _onlyExpiringSoon = true),
              ),
            ],
          ),
        ),

        Expanded(
          child: displayList.isEmpty
              ? _buildEmptyState(
                  icon: LucideIcons.badgeCheck,
                  title: 'Не знайдено активних абонементів',
                  subtitle: _onlyExpiringSoon
                      ? 'Чудово! У жодного клієнта абонемент не закінчується в найближчі 5 днів.'
                      : 'Всі абонементи вичерпано або клієнти очікують поновлення.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final sub = displayList[idx];
                    final clientData = clientsMap[sub.userId];
                    final clientName = clientData?['name'] ?? sub.ownerName ?? 'Клієнт';
                    final phone = clientData?['phone'] ?? 'Немає номеру';
                    final owner = sub.ownerName ?? clientName;
                    final isExpiring = _isSubExpiringSoon(sub);

                    return _buildActiveSubCard(
                      sub: sub,
                      clientName: clientName,
                      ownerName: owner,
                      phone: phone,
                      isExpiringSoon: isExpiring,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color accentColor = const Color(0xFF10B981),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubCard({
    required Subscription sub,
    required String clientName,
    required String ownerName,
    required String phone,
    required bool isExpiringSoon,
  }) {
    final remaining = sub.remainingClasses;
    final total = sub.totalClasses > 0 ? sub.totalClasses : 1;
    final progress = (remaining / total).clamp(0.0, 1.0);

    String expiryStr = 'Безстроковий';
    String daysLeftStr = '';
    int? daysLeft;
    if (sub.expiryDate != null) {
      expiryStr = DateFormat('dd.MM.yyyy').format(sub.expiryDate!);
      daysLeft = sub.expiryDate!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        daysLeftStr = 'Прострочено';
      } else if (daysLeft == 0) {
        daysLeftStr = 'Сьогодні!';
      } else if (daysLeft == 1) {
        daysLeftStr = '1 день';
      } else {
        daysLeftStr = '$daysLeft дн.';
      }
    }

    final accentColor = isExpiringSoon ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final secondaryAccent = isExpiringSoon ? const Color(0xFFFB923C) : const Color(0xFF00D2FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isExpiringSoon
                ? const Color(0xFF281E15).withValues(alpha: 0.88)
                : const Color(0xFF13233C).withValues(alpha: 0.88),
            const Color(0xFF0A1422).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: isExpiringSoon
              ? const Color(0xFFF59E0B).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
          width: isExpiringSoon ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpiringSoon
                ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Squircle avatar with gradient glow
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor,
                            secondaryAccent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF061524),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ownerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isExpiringSoon)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.alertTriangle, size: 10, color: Color(0xFFF59E0B)),
                                      SizedBox(width: 4),
                                      Text(
                                        'ЗАКІНЧУЄТЬСЯ',
                                        style: TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.user,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  clientName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (phone.isNotEmpty && phone != 'Немає номеру') ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Inset Progress telemetry container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            sub.serviceName ?? 'Абонемент',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              '$remaining з ${sub.totalClasses} занять',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentColor, secondaryAccent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendarClock,
                                size: 12.5,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Діє до $expiryStr',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          if (daysLeftStr.isNotEmpty)
                            Text(
                              'Залишилось: $daysLeftStr',
                              style: TextStyle(
                                color: isExpiringSoon ? const Color(0xFFF59E0B) : Colors.white70,
                                fontSize: 11.5,
                                fontWeight: isExpiringSoon ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _initiateRenewal(
                        clientId: sub.userId,
                        clientName: clientName,
                        ownerName: ownerName,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00D2FF).withValues(alpha: 0.16),
                              const Color(0xFF0072FF).withValues(alpha: 0.22),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00D2FF).withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.refreshCw, size: 13, color: Color(0xFF38BDF8)),
                            SizedBox(width: 6),
                            Text(
                              'Продовжити',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
    );
  }

  // ==========================================
  // TAB 1: НЕ ОПЛАТИЛИ / ЗАКІНЧИЛИСЬ
  // ==========================================
  Widget _buildUnpaidSubsTab(List<_UnpaidClientItem> unpaidList) {
    var displayList = unpaidList;
    if (_searchQuery.isNotEmpty) {
      displayList = displayList.where((u) {
        return u.clientName.toLowerCase().contains(_searchQuery) ||
            u.ownerName.toLowerCase().contains(_searchQuery) ||
            (u.phone?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    if (displayList.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.partyPopper,
        title: 'Усі клієнти мають оплачені абонементи!',
        subtitle: 'Немає боржників чи тих, у кого закінчились заняття.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = displayList[idx];
        return _buildUnpaidCard(item);
      },
    );
  }

  Widget _buildUnpaidCard(_UnpaidClientItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF28141E).withValues(alpha: 0.88),
            const Color(0xFF0F1422).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          item.ownerName.isNotEmpty ? item.ownerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
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
                            item.ownerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.user,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${item.clientName} • ${item.phone ?? "Немає тел."}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reason alert banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circleAlert, color: Color(0xFFFB7185), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.reason,
                          style: const TextStyle(
                            color: Color(0xFFFDA4AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showReminderModal(
                          clientId: item.clientId,
                          clientName: item.clientName,
                          ownerName: item.ownerName,
                          phone: item.phone,
                          reason: item.reason,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bellRing, size: 14, color: Color(0xFF38BDF8)),
                              SizedBox(width: 6),
                              Text(
                                'Нагадати',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _initiateRenewal(
                          clientId: item.clientId,
                          clientName: item.clientName,
                          ownerName: item.ownerName,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF00D2FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.creditCard, size: 14, color: Color(0xFF052317)),
                              SizedBox(width: 6),
                              Text(
                                'Поновити',
                                style: TextStyle(
                                  color: Color(0xFF052317),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
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
    );
  }

  // ==========================================
  // TAB 2: ШВИДКА КАСА (НОВА ОПЛАТА)
  // ==========================================
  Widget _buildCashierTab(Map<String, Map<String, dynamic>> clientsMap) {
    final clientsList = clientsMap.entries.toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Оберіть клієнта
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Оберіть клієнта',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedClientId != null
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: const Color(0xFF0D1B2D),
                value: _selectedClientId,
                hint: Row(
                  children: [
                    Icon(LucideIcons.user, color: Colors.white.withValues(alpha: 0.4), size: 16),
                    const SizedBox(width: 10),
                    const Text('Оберіть клієнта зі списку...', style: TextStyle(color: Colors.white54, fontSize: 13.5)),
                  ],
                ),
                icon: const Icon(LucideIcons.chevronDown, color: Color(0xFF38BDF8), size: 18),
                items: clientsList.map((e) {
                  final name = e.value['name'] ?? 'Невідомо';
                  final phone = e.value['phone'] ?? '';
                  return DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(
                      '$name ${phone.isNotEmpty ? "($phone)" : ""}',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedClientId = val;
                      _selectedClientName = clientsMap[val]?['name'];
                      _selectedOwnerName = _selectedClientName;
                    });
                  }
                },
              ),
            ),
          ),

          if (_selectedClientId != null) ...[
            const SizedBox(height: 10),
            // Owner name input (e.g. child name)
            TextFormField(
              initialValue: _selectedOwnerName,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                labelText: 'Ім\'я учня / власника абонемента',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(LucideIcons.baby, color: Color(0xFF38BDF8), size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                ),
              ),
              onChanged: (val) => _selectedOwnerName = val,
            ),
          ],

          const SizedBox(height: 22),

          // 2. Оберіть абонемент / послугу
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Оберіть послугу або абонемент',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _packages.length,
            itemBuilder: (ctx, idx) {
              final pkg = _packages[idx];
              final isSelected = _selectedPackage?['id'] == pkg['id'];
              final color = pkg['color'] as Color;

              return GestureDetector(
                onTap: () => setState(() => _selectedPackage = pkg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF162E4A).withValues(alpha: 0.94),
                              const Color(0xFF0E1C30).withValues(alpha: 0.98),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withValues(alpha: 0.10),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: color.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Icon(pkg['icon'] as IconData, color: color, size: 17),
                            ),
                          ),
                          if (pkg['badge'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.45),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                pkg['badge'],
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${pkg['price']} ₴ • ${_formatClassesCount(pkg['classes'] as int)}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // 3. Метод оплати
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Спосіб оплати',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _buildPaymentMethodPill('Картка', LucideIcons.creditCard)),
              const SizedBox(width: 8),
              Expanded(child: _buildPaymentMethodPill('Готівка', LucideIcons.banknote)),
              const SizedBox(width: 8),
              Expanded(child: _buildPaymentMethodPill('Термінал', LucideIcons.smartphoneNfc)),
            ],
          ),

          const SizedBox(height: 26),

          // 4. Кнопка проведення оплати
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF00D2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _processPayment,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Сплатити ${_selectedPackage?['price'] ?? 0} ₴',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPill(String label, IconData icon) {
    final isSelected = _paymentMethod == label;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF00D2FF).withValues(alpha: 0.25),
                    const Color(0xFF0077B6).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D2FF) : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF00D2FF) : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATES: PROCESSING & SUCCESS
  // ==========================================
  Widget _buildProcessingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        const Text(
          'Проведення платежу та реєстрація абонемента...',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0xFF10B981), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: const Icon(LucideIcons.check, color: Color(0xFF041C15), size: 40),
        ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
        const SizedBox(height: 20),
        const Text(
          'Оплату успішно зараховано!',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        Text(
          'Абонемент для ${_selectedOwnerName ?? _selectedClientName} активовано',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ).animate().fadeIn(delay: 350.ms),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D2FF).withValues(alpha: 0.16),
                      const Color(0xFF0072FF).withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D2FF).withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 26, color: const Color(0xFF38BDF8)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnpaidClientItem {
  final String clientId;
  final String clientName;
  final String ownerName;
  final String? phone;
  final String serviceName;
  final int remainingClasses;
  final int totalClasses;
  final DateTime? expiryDate;
  final String reason;

  _UnpaidClientItem({
    required this.clientId,
    required this.clientName,
    required this.ownerName,
    required this.phone,
    required this.serviceName,
    required this.remainingClasses,
    required this.totalClasses,
    required this.expiryDate,
    required this.reason,
  });
}
