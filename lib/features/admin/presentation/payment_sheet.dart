import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/chat/repositories/chat_repository.dart';

class PaymentSheet extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String? initialSearchQuery;

  const PaymentSheet({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  late int _selectedTab; // 0: Абонементи, 1: Не оплатили / Закінчились
  int _activeFilterMode = 1; // 0: Всього, 1: Активні, 2: Закінчуються
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!.trim().toLowerCase();
      _searchController.text = widget.initialSearchQuery!.trim();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final first = words[0].isNotEmpty ? words[0][0].toUpperCase() : '';
      final second = words[1].isNotEmpty ? words[1][0].toUpperCase() : '';
      return '$first$second';
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
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

  void _showReminderModal({
    required String clientId,
    required String clientName,
    required String ownerName,
    String? phone,
    String? reason,
  }) {
    final currentTheme = ref.read(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.22),
                          const Color(0xFF0284C7).withValues(alpha: 0.26),
                          const Color(0xFF0A223D).withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF8FAFC),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                        : const Color(0xFF0284C7).withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
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
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.30)
                                : const Color(0xFFBAE6FD),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.messageSquareQuote,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нагадування для $clientName',
                              style: TextStyle(
                                color: isDark ? currentTheme.textPrimary : const Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Учень: $ownerName • ${phone ?? "Немає тел."}',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.20)
                            : const Color(0xFFBAE6FD),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isDark ? currentTheme.textPrimary : const Color(0xFF1E293B),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? Colors.transparent : const Color(0xFFF0F9FF),
                            foregroundColor: isDark ? currentTheme.textPrimary : const Color(0xFF0369A1),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : const Color(0xFFBAE6FD),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(LucideIcons.copy, size: 16),
                          label: Text('admin.copy'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: text));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('admin.copied_to_clipboard'.tr()),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            foregroundColor: isDark ? const Color(0xFF081424) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: isDark ? 0 : 2,
                            shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          ),
                          icon: const Icon(LucideIcons.send, size: 16),
                          label: Text('admin.send_to_chat'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            final dialogId = clientId;

                            // 1. Send to client-admin chat
                            await ChatRepository().sendMessage(
                              dialogId: dialogId,
                              clientId: clientId,
                              clientName: clientName,
                              clientAvatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(clientName)}',
                              senderId: 'admin',
                              text: text,
                            );

                            // 2. Save official notification to Firestore for client profile & notification center
                            try {
                              await FirebaseFirestore.instance.collection('notifications').add({
                                'userId': clientId,
                                'title': 'Закінчення абонементу ($ownerName)',
                                'message': text,
                                'timestamp': FieldValue.serverTimestamp(),
                                'icon': 'creditCard',
                                'iconColor': 0xFFF59E0B, // Amber gold
                                'type': 'subscription_reminder',
                                'isRead': false,
                                'actionType': 'subscription',
                                'senderName': 'Адміністрація CitySwim',
                              });
                            } catch (e) {
                              debugPrint('Error writing to notifications collection: $e');
                            }

                            final admin = ref.read(authControllerProvider);
                            if (admin != null) {
                              await logAdminAction('Надіслано нагадування про оплату для "$clientName"', admin.id);
                            }

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('admin.reminder_sent'.tr()),
                                backgroundColor: const Color(0xFF10B981),
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
    final currentTheme = ref.watch(appThemeControllerProvider);
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
          data: (allSubs) => _buildMainSheet(context, allSubs, clientsMap, currentTheme),
          loading: () => _buildLoadingSheet(context, currentTheme),
          error: (err, stack) => _buildErrorSheet(context, err.toString(), currentTheme),
        );
      },
    );
  }

  Widget _buildLoadingSheet(BuildContext context, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A223D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: CircularProgressIndicator(color: currentTheme.accentPrimary),
      ),
    );
  }

  Widget _buildErrorSheet(BuildContext context, String error, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A223D).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: Text('${'common.error'.tr()}: $error', style: TextStyle(color: currentTheme.textSecondary)),
      ),
    );
  }

  Widget _buildMainSheet(
    BuildContext context,
    List<Subscription> allSubs,
    Map<String, Map<String, dynamic>> clientsMap,
    AppThemeConfig currentTheme,
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
          final total = sub.totalClasses;
          reason = 'Вичерпано заняття (0 з $total ${total % 10 == 1 && total % 100 != 11 ? "заняття" : "занять"})';
        } else if (sub.expiryDate != null && DateTime.now().isAfter(sub.expiryDate!)) {
          final days = DateTime.now().difference(sub.expiryDate!).inDays;
          String dayWord;
          if (days % 10 == 1 && days % 100 != 11) {
            dayWord = 'день';
          } else if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) {
            dayWord = 'дні';
          } else {
            dayWord = 'днів';
          }
          reason = 'Закінчився термін (прострочено $days $dayWord)';
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
    final isDark = currentTheme.isDark;

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
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.22),
                      const Color(0xFF0284C7).withValues(alpha: 0.26),
                      const Color(0xFF0A223D).withValues(alpha: 0.55),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                    : const Color(0xFF0284C7).withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
              if (isDark)
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 36,
                ),
            ],
          ),
          child: Column(
            children: [
              // 1. Top Drag Handle & Title
              _buildHeader(context, currentTheme),

              // 2. Executive Telemetry Bar (Зведена аналітика)
              _buildTelemetryKPIs(
                totalCount: allSubs.length,
                activeCount: activeSubs.length,
                expiringCount: expiringSoonSubs.length,
                unpaidCount: finalUnpaidList.length,
                currentTheme: currentTheme,
              ),

              // 3. Segmented Tab Selector (2 Tabs)
              _buildSegmentedTabs(
                activeCount: activeSubs.length,
                unpaidCount: finalUnpaidList.length,
                currentTheme: currentTheme,
              ),

              const SizedBox(height: 10),

              // 4. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _buildSearchBar(currentTheme),
              ),

              // 5. Active Tab View
              Expanded(
                child: _buildTabContent(
                  allSubs: allSubs,
                  activeSubs: activeSubs,
                  expiringSoonSubs: expiringSoonSubs,
                  unpaidList: finalUnpaidList,
                  clientsMap: clientsMap,
                  currentTheme: currentTheme,
                ),
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
  // ==========================================
  // 1. HEADER
  // ==========================================
  Widget _buildHeader(BuildContext context, AppThemeConfig currentTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: currentTheme.isDark
                    ? currentTheme.textSecondary.withValues(alpha: 0.35)
                    : const Color(0xFF94A3B8),
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
                    colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
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
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
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
                      style: TextStyle(
                        color: currentTheme.isDark ? currentTheme.textPrimary : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'admin.payment_subtitle'.tr(),
                      style: TextStyle(
                        color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                  ),
                  boxShadow: currentTheme.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155),
                    size: 18,
                  ),
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
    required int totalCount,
    required int activeCount,
    required int expiringCount,
    required int unpaidCount,
    required AppThemeConfig currentTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // 1. Всього
          Expanded(
            child: _buildTelemetryCard(
              count: '$totalCount',
              label: 'admin.tab_total'.tr(),
              color: const Color(0xFF00E5FF),
              icon: LucideIcons.layers,
              isSelected: _selectedTab == 0 && _activeFilterMode == 0,
              currentTheme: currentTheme,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _activeFilterMode = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 6),

          // 2. Активні
          Expanded(
            child: _buildTelemetryCard(
              count: '$activeCount',
              label: 'admin.tab_active'.tr(),
              color: const Color(0xFF10B981),
              icon: LucideIcons.circleCheck,
              isSelected: _selectedTab == 0 && _activeFilterMode == 1,
              currentTheme: currentTheme,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _activeFilterMode = 1;
                });
              },
            ),
          ),
          const SizedBox(width: 6),

          // 3. Закінчуються
          Expanded(
            child: _buildTelemetryCard(
              count: '$expiringCount',
              label: 'admin.tab_expiring'.tr(),
              color: const Color(0xFFF59E0B),
              icon: LucideIcons.hourglass,
              isSelected: _selectedTab == 0 && _activeFilterMode == 2,
              currentTheme: currentTheme,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                  _activeFilterMode = 2;
                });
              },
            ),
          ),
          const SizedBox(width: 6),

          // 4. Не оплатили
          Expanded(
            child: _buildTelemetryCard(
              count: '$unpaidCount',
              label: 'admin.tab_unpaid'.tr(),
              color: const Color(0xFFF43F5E),
              icon: LucideIcons.alertCircle,
              isSelected: _selectedTab == 1,
              currentTheme: currentTheme,
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
    required AppThemeConfig currentTheme,
  }) {
    final bool isDark = currentTheme.isDark;

    // High-contrast, WCAG AAA compliant color mapping
    final Color effectiveColor = isDark
        ? color
        : (color == const Color(0xFF00E5FF)
            ? const Color(0xFF0284C7) // Vivid deep ocean blue
            : (color == const Color(0xFF10B981)
                ? const Color(0xFF059669) // Deep emerald
                : (color == const Color(0xFFF59E0B)
                    ? const Color(0xFFD97706) // Rich warm amber
                    : const Color(0xFFE11D48)))); // Vivid crimson

    // Distinct soft tinted backgrounds & borders for each card in Light theme
    final Color lightBg = color == const Color(0xFF00E5FF)
        ? const Color(0xFFF0F9FF)
        : (color == const Color(0xFF10B981)
            ? const Color(0xFFF0FDF4)
            : (color == const Color(0xFFF59E0B)
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFFF1F2)));

    final Color lightBorder = color == const Color(0xFF00E5FF)
        ? const Color(0xFFBAE6FD)
        : (color == const Color(0xFF10B981)
            ? const Color(0xFFBBF7D0)
            : (color == const Color(0xFFF59E0B)
                ? const Color(0xFFFDE68A)
                : const Color(0xFFFECDD3)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      effectiveColor.withValues(alpha: isDark ? 0.32 : 0.22),
                      effectiveColor.withValues(alpha: isDark ? 0.10 : 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : lightBg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.20)
                      : lightBorder),
              width: isSelected ? 1.8 : 1.15,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isDark
                    ? null
                    : [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.06),
                          blurRadius: 5,
                          offset: const Offset(0, 1.5),
                        ),
                      ]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: isDark ? 0.22 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, color: effectiveColor, size: 12.5),
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      color: effectiveColor,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. SEGMENTED TABS (2 WIDE TABS)
  // ==========================================
  Widget _buildSegmentedTabs({
    required int activeCount,
    required int unpaidCount,
    required AppThemeConfig currentTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: currentTheme.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: currentTheme.isDark
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFBAE6FD),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                title: 'admin.tab_subs'.tr(),
                badge: '$activeCount',
                accentColor: const Color(0xFF10B981),
                icon: LucideIcons.walletCards,
                currentTheme: currentTheme,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 1,
                title: 'admin.tab_unpaid'.tr(),
                badge: '$unpaidCount',
                accentColor: const Color(0xFFF43F5E),
                icon: LucideIcons.alertCircle,
                currentTheme: currentTheme,
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
    required IconData icon,
    required AppThemeConfig currentTheme,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9.5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: index == 0
                      ? (currentTheme.isDark
                          ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)])
                      : const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (index == 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
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
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569)),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (currentTheme.isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : (currentTheme.isDark
                          ? null
                          : Border.all(color: const Color(0xFFCBD5E1))),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Пошук за ім\'ям учня, клієнта чи телефоном...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.65) : const Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
            size: 17,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: currentTheme.textMuted, size: 16),
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
  // 4. TAB CONTENT SWITCHER (2 TABS)
  // ==========================================
  Widget _buildTabContent({
    required List<Subscription> allSubs,
    required List<Subscription> activeSubs,
    required List<Subscription> expiringSoonSubs,
    required List<_UnpaidClientItem> unpaidList,
    required Map<String, Map<String, dynamic>> clientsMap,
    required AppThemeConfig currentTheme,
  }) {
    if (_selectedTab == 0) {
      return _buildActiveSubsTab(allSubs, activeSubs, expiringSoonSubs, clientsMap, currentTheme);
    } else {
      return _buildUnpaidSubsTab(unpaidList, currentTheme);
    }
  }

  // ==========================================
  // TAB 0: АКТИВНІ ТА ВСІ АБОНЕМЕНТИ
  // ==========================================
  Widget _buildActiveSubsTab(
    List<Subscription> allSubs,
    List<Subscription> activeSubs,
    List<Subscription> expiringSoonSubs,
    Map<String, Map<String, dynamic>> clientsMap,
    AppThemeConfig currentTheme,
  ) {
    List<Subscription> displayList;
    if (_activeFilterMode == 0) {
      displayList = allSubs;
    } else if (_activeFilterMode == 2) {
      displayList = expiringSoonSubs;
    } else {
      displayList = activeSubs;
    }

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
        const SizedBox(height: 6),
        Expanded(
          child: displayList.isEmpty
              ? _buildEmptyState(
                  icon: LucideIcons.badgeCheck,
                  title: 'Не знайдено абонементів',
                  subtitle: _activeFilterMode == 2
                      ? 'Чудово! У жодного клієнта абонемент не закінчується в найближчі 5 днів.'
                      : (_activeFilterMode == 0
                          ? 'В системі ще не створено жодного абонемента.'
                          : 'Всі абонементи вичерпано або клієнти очікують поновлення.'),
                  currentTheme: currentTheme,
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
                      currentTheme: currentTheme,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActiveSubCard({
    required Subscription sub,
    required String clientName,
    required String ownerName,
    required String phone,
    required bool isExpiringSoon,
    required AppThemeConfig currentTheme,
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

    DateTime? purchaseDate;
    final parts = sub.id.split('_');
    if (parts.length > 1) {
      final ts = int.tryParse(parts[1]);
      if (ts != null) {
        if (ts > 1000000000000000) {
          purchaseDate = DateTime.fromMicrosecondsSinceEpoch(ts);
        } else if (ts > 1000000000000) {
          purchaseDate = DateTime.fromMillisecondsSinceEpoch(ts);
        }
      }
    }
    if (purchaseDate == null && sub.expiryDate != null) {
      purchaseDate = sub.expiryDate!.subtract(const Duration(days: 30));
    }
    final purchaseStr = purchaseDate != null ? DateFormat('dd.MM.yyyy').format(purchaseDate) : null;

    final isActive = _isSubActive(sub);
    final isDark = currentTheme.isDark;

    // Jewel avatar gradient from app theme palette
    final avatarGradient = currentTheme.actionCardGradients[ownerName.hashCode.abs() % currentTheme.actionCardGradients.length];

    final accentColor = !isActive
        ? const Color(0xFF64748B)
        : (isExpiringSoon ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)));
    final secondaryAccent = !isActive
        ? const Color(0xFF475569)
        : (isExpiringSoon ? const Color(0xFFFB923C) : const Color(0xFF00D2FF));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.18),
                  (isExpiringSoon
                          ? const Color(0xFFF59E0B)
                          : (!isActive ? const Color(0xFF64748B) : const Color(0xFF0284C7)))
                      .withValues(alpha: 0.20),
                  const Color(0xFF0D2542).withValues(alpha: 0.45),
                ]
              : [
                  Colors.white,
                  (isExpiringSoon
                      ? const Color(0xFFFFFBEB)
                      : (!isActive ? const Color(0xFFF8FAFC) : const Color(0xFFF0F9FF))),
                ],
        ),
        border: Border.all(
          color: isExpiringSoon
              ? const Color(0xFFF59E0B).withValues(alpha: currentTheme.isDark ? 0.60 : 0.75)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.30)
                  : const Color(0xFFBAE6FD)),
          width: isExpiringSoon ? 1.3 : 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpiringSoon
                ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.12)
                : (isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0284C7).withValues(alpha: 0.07)),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                    // Squircle avatar with 2-letter monogram & jewel glow
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: !isActive
                              ? [const Color(0xFF64748B), const Color(0xFF475569)]
                              : (isExpiringSoon
                                  ? [const Color(0xFFF59E0B), const Color(0xFFFB923C)]
                                  : avatarGradient),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (!isActive
                                    ? const Color(0xFF64748B)
                                    : (isExpiringSoon ? const Color(0xFFF59E0B) : avatarGradient.first))
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(ownerName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.2,
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
                                  style: TextStyle(
                                    color: currentTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: const Text(
                                    'НЕАКТИВНИЙ',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              else if (isExpiringSoon)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                          : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.alertTriangle, size: 10, color: Color(0xFFD97706)),
                                      SizedBox(width: 4),
                                      Text(
                                        'ЗАКІНЧУЄТЬСЯ',
                                        style: TextStyle(
                                          color: Color(0xFFD97706),
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
                                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  clientName,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (phone.isNotEmpty && phone != 'Немає номеру') ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.5) : const Color(0xFF94A3B8)),
                                ),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
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
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFBAE6FD),
                      width: 1.1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              sub.serviceName ?? 'Абонемент',
                              style: TextStyle(
                                color: currentTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? accentColor.withValues(alpha: 0.20)
                                  : (isExpiringSoon ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? accentColor.withValues(alpha: 0.50)
                                    : (isExpiringSoon ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
                              ),
                            ),
                            child: Text(
                              '$remaining з ${sub.totalClasses} ${sub.totalClasses % 10 == 1 && sub.totalClasses % 100 != 11 ? "заняття" : "занять"}',
                              style: TextStyle(
                                color: isDark
                                    ? accentColor
                                    : (isExpiringSoon ? const Color(0xFFD97706) : const Color(0xFF047857)),
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
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (purchaseStr != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.calendarPlus,
                                  size: 12,
                                  color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  'Придбано: $purchaseStr',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (sub.expiryDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.calendarClock,
                                  size: 12,
                                  color: isExpiringSoon
                                      ? const Color(0xFFD97706)
                                      : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 4.5),
                                Text(
                                  'Діє до $expiryStr',
                                  style: TextStyle(
                                    color: isExpiringSoon
                                        ? const Color(0xFFD97706)
                                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                                    fontSize: 11,
                                    fontWeight: isExpiringSoon ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                if (daysLeftStr.isNotEmpty) ...[
                                  Text(' • ', style: TextStyle(color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.5) : const Color(0xFF94A3B8))),
                                  Text(
                                    daysLeftStr,
                                    style: TextStyle(
                                      color: isExpiringSoon
                                          ? const Color(0xFFD97706)
                                          : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action button: Send Reminder
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () => _showReminderModal(
                        clientId: sub.userId,
                        clientName: clientName,
                        ownerName: ownerName,
                        phone: phone != 'Немає номеру' ? phone : null,
                        reason: isExpiringSoon
                            ? 'Закінчується абонемент (залишилось $remaining занять)'
                            : 'Інформація про абонемент',
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isExpiringSoon ? const Color(0xFFFBBF24) : const Color(0xFF00E5FF)).withValues(alpha: 0.15)
                              : (isExpiringSoon ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? (isExpiringSoon ? const Color(0xFFFBBF24) : const Color(0xFF00E5FF)).withValues(alpha: 0.40)
                                : (isExpiringSoon ? const Color(0xFFFDE68A) : const Color(0xFFBAE6FD)),
                            width: 1.1,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: (isExpiringSoon ? const Color(0xFFF59E0B) : const Color(0xFF0284C7)).withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.bellRing,
                              size: 13,
                              color: isDark
                                  ? (isExpiringSoon ? const Color(0xFFFBBF24) : const Color(0xFF00E5FF))
                                  : (isExpiringSoon ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isExpiringSoon ? 'Нагадати клієнту' : 'Повідомлення клієнту',
                              style: TextStyle(
                                color: isExpiringSoon
                                    ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B))
                                    : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
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
  Widget _buildUnpaidSubsTab(List<_UnpaidClientItem> unpaidList, AppThemeConfig currentTheme) {
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
        currentTheme: currentTheme,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final item = displayList[idx];
        return _buildUnpaidCard(item, currentTheme);
      },
    );
  }

  Widget _buildUnpaidCard(_UnpaidClientItem item, AppThemeConfig currentTheme) {
    final isDark = currentTheme.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.18),
                  const Color(0xFFF43F5E).withValues(alpha: 0.22),
                  const Color(0xFF0D2542).withValues(alpha: 0.50),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFFF1F2),
                ],
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF43F5E).withValues(alpha: 0.45)
              : const Color(0xFFFECDD3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFF43F5E).withValues(alpha: 0.18)
                : const Color(0xFFE11D48).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
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
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFFF43F5E), Color(0xFFFB7185)]
                              : const [Color(0xFFE11D48), Color(0xFFF43F5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.25 : 0.60),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.4 : 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(item.ownerName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
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
                            style: TextStyle(
                              color: isDark ? currentTheme.textPrimary : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.user,
                                size: 12,
                                color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${item.clientName} • ${item.phone ?? "Немає тел."}',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFF43F5E).withValues(alpha: 0.18)
                        : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.40)
                          : const Color(0xFFFECDD3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.circleAlert,
                        color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.reason,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFFE4E6) : const Color(0xFF9F1239),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action button: Send Reminder
                InkWell(
                  onTap: () => _showReminderModal(
                    clientId: item.clientId,
                    clientName: item.clientName,
                    ownerName: item.ownerName,
                    phone: item.phone,
                    reason: item.reason,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                            : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : const Color(0xFF38BDF8).withValues(alpha: 0.60),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                              : const Color(0xFF0284C7).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.bellRing,
                          size: 16,
                          color: isDark ? const Color(0xFF03192E) : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Надіслати нагадування',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF03192E) : Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeConfig currentTheme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
            ),
            boxShadow: currentTheme.isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                    colors: currentTheme.isDark
                        ? [
                            const Color(0xFF00D2FF).withValues(alpha: 0.16),
                            const Color(0xFF0072FF).withValues(alpha: 0.08),
                          ]
                        : [
                            const Color(0xFFE0F2FE),
                            const Color(0xFFBAE6FD).withValues(alpha: 0.5),
                          ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentTheme.isDark
                        ? const Color(0xFF00D2FF).withValues(alpha: 0.25)
                        : const Color(0xFFBAE6FD),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentTheme.isDark
                          ? const Color(0xFF00D2FF).withValues(alpha: 0.12)
                          : const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: currentTheme.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: currentTheme.isDark ? currentTheme.textPrimary : const Color(0xFF0F172A),
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
                  color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
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
