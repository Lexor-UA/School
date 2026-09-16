import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'add_client_sheet.dart';
import 'edit_client_sheet.dart';
import 'payment_sheet.dart';

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Всі, 1: З абонементом, 2: Без абонемента

  String _formatClassesGenitive(int total) {
    if (total % 100 != 11 && total % 10 == 1) {
      return '$total заняття';
    }
    return '$total занять';
  }

  String _getInitials(String name, [String fallback = 'К']) {
    final clean = name.trim();
    if (clean.isEmpty) return fallback;
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    // Check if CamelCase (e.g. CitySwim -> CS)
    final uppercaseLetters = clean.replaceAll(RegExp(r'[^A-ZА-ЯІЇЄ]'), '');
    if (uppercaseLetters.length >= 2) {
      return uppercaseLetters.substring(0, 2);
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean[0].toUpperCase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCredentials(String loginId, String name, [String password = '1']) {
    Clipboard.setData(ClipboardData(text: '${'admin.clients_login_label'.tr()}$loginId\n${'admin.clients_password_label'.tr()}$password'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('admin.clients_copied_msg'.tr(args: [name]))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteClient(String clientId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final currentTheme = ref.read(appThemeControllerProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: currentTheme.statusErrorBadgeText.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentTheme.statusErrorBadgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.alertTriangle, color: currentTheme.statusErrorBadgeText, size: 20),
            ),
            const SizedBox(width: 12),
            Text('admin.clients_delete_title'.tr(), style: TextStyle(color: currentTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'admin.clients_delete_confirm'.tr(args: [name]),
          style: TextStyle(color: currentTheme.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin.cancel'.tr(), style: TextStyle(color: currentTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentTheme.statusErrorBadgeText,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('admin.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(clientId).delete();

        final childrenSnap = await FirebaseFirestore.instance
            .collection('children')
            .where('parentId', isEqualTo: clientId)
            .get();
        List<String> allRelatedIds = [clientId];
        for (var doc in childrenSnap.docs) {
          allRelatedIds.add(doc.id);
          await doc.reference.delete();
        }

        final subsSnap = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: clientId)
            .get();
        for (var doc in subsSnap.docs) {
          await doc.reference.delete();
        }

        final classesSnap = await FirebaseFirestore.instance
            .collection('classes')
            .where('enrolledChildIds', arrayContainsAny: allRelatedIds)
            .get();
        for (var doc in classesSnap.docs) {
          List<dynamic> enrolled = List.from(doc.data()['enrolledChildIds'] ?? []);
          enrolled.removeWhere((id) => allRelatedIds.contains(id));
          await doc.reference.update({'enrolledChildIds': enrolled});
        }

        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Видалено клієнта "$name"', admin.id);
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text('admin.clients_deleted_success'.tr(args: [name])),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('${'common.error'.tr()}: $e'), backgroundColor: const Color(0xFFF43F5E)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSubscriptions = ref.watch(subscriptionControllerProvider);
    final currentTheme = ref.watch(appThemeControllerProvider);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: currentTheme.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: currentTheme.accentPrimary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddClientSheet(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.userPlus, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'admin.clients_new_btn'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
      body: Stack(
        children: [
          // 1. Full-fidelity animated water ripples
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),

          // 2. Fluid aquatic gradient overlay (harmonized with Client screen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentTheme.bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Theme-tailored 3D animated water bubbles
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 3. Ambient volumetric glow orbs
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb1Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb2Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Header
                _buildHeader(context, currentTheme),

                // 2. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: _buildSearchBar(currentTheme),
                ),

                // 3. Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _buildFilterTabs(currentTheme),
                ),

                // 4. Clients List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'parent')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      var clients = snapshot.data!.docs;

                      // Filter by search
                      if (_searchQuery.isNotEmpty) {
                        clients = clients.where((c) {
                          final data = c.data() as Map<String, dynamic>;
                          final name = data['name']?.toString().toLowerCase() ?? '';
                          final loginId = data['loginId']?.toString().toLowerCase() ?? '';
                          final phone = data['phone']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery) ||
                              loginId.contains(_searchQuery) ||
                              phone.contains(_searchQuery);
                        }).toList();
                      }

                      // Filter by tab
                      if (_selectedFilterIndex == 1) {
                        // Тільки з активним абонементом
                        clients = clients.where((c) {
                          return allSubscriptions.any((s) =>
                              s.userId == c.id &&
                              s.isActive &&
                              s.remainingClasses > 0 &&
                              (s.expiryDate == null || s.expiryDate!.isAfter(DateTime.now())));
                        }).toList();
                      } else if (_selectedFilterIndex == 2) {
                        // Без активного абонемента
                        clients = clients.where((c) {
                          final hasActive = allSubscriptions.any((s) =>
                              s.userId == c.id &&
                              s.isActive &&
                              s.remainingClasses > 0 &&
                              (s.expiryDate == null || s.expiryDate!.isAfter(DateTime.now())));
                          return !hasActive;
                        }).toList();
                      }

                      if (clients.isEmpty) {
                        return _buildNoSearchResults();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        physics: const BouncingScrollPhysics(),
                        itemCount: clients.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final clientDoc = clients[index];
                          final data = clientDoc.data() as Map<String, dynamic>;
                          final clientId = clientDoc.id;
                          final name = data['name'] ?? 'Невідомо';
                          final phone = data['phone'] ?? 'Немає номеру';
                          final loginId = data['loginId'] ?? 'Не призначено';
                          final password = (data['password'] as String?) ?? '1';
                          final age = data['age'] is int ? data['age'] as int : int.tryParse(data['age']?.toString() ?? '');

                          final userSubs = allSubscriptions.where((s) => s.userId == clientId).toList();

                          return _buildClientCard(
                            clientId: clientId,
                            name: name,
                            phone: phone,
                            age: age,
                            loginId: loginId,
                            password: password,
                            subscriptions: userSubs,
                            index: index,
                            currentTheme: currentTheme,
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

  Widget _buildHeader(BuildContext context, AppThemeConfig currentTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentTheme.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: currentTheme.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : currentTheme.cardBorder,
              ),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: currentTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'admin.clients_title'.tr(),
                      style: TextStyle(
                        color: currentTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: currentTheme.statusActiveBadgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentTheme.accentPrimary.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'admin.clients_parents_students'.tr(),
                        style: TextStyle(
                          color: currentTheme.statusActiveBadgeText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'admin.clients_subtitle'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const ThemeHeaderButton(size: 38),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeConfig currentTheme) {
    return Container(
      decoration: BoxDecoration(
        color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
          width: 1.3,
        ),
        boxShadow: currentTheme.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: currentTheme.isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'admin.clients_search_hint'.tr(),
          hintStyle: TextStyle(
            color: currentTheme.isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.65) : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: currentTheme.textSecondary, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AppThemeConfig currentTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterPill(0, 'admin.clients_filter_all'.tr(), currentTheme),
          const SizedBox(width: 8),
          _buildFilterPill(1, 'admin.clients_filter_with_sub'.tr(), currentTheme),
          const SizedBox(width: 8),
          _buildFilterPill(2, 'admin.clients_filter_no_sub'.tr(), currentTheme),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label, AppThemeConfig currentTheme) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: currentTheme.accentGradient,
                )
              : null,
          color: isSelected
              ? null
              : (currentTheme.isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? currentTheme.accentPrimary
                : (currentTheme.isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFCBD5E1)),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentTheme.accentPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (currentTheme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF003B73).withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard({
    required String clientId,
    required String name,
    required String phone,
    int? age,
    required String loginId,
    required String password,
    required List<dynamic> subscriptions,
    required int index,
    required AppThemeConfig currentTheme,
  }) {
    final activeSubs = subscriptions.where((s) => s.isActive && s.remainingClasses > 0).toList();
    final bool hasActiveSubs = activeSubs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentTheme.isDark
              ? [
                  Colors.white.withValues(alpha: 0.18),
                  const Color(0xFF0284C7).withValues(alpha: 0.18),
                  const Color(0xFF0D2542).withValues(alpha: 0.45),
                ]
              : [
                  Colors.white.withValues(alpha: 0.94),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.94),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: currentTheme.isDark
              ? (hasActiveSubs
                  ? currentTheme.accentPrimary.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.28))
              : (hasActiveSubs
                  ? currentTheme.accentPrimary.withValues(alpha: 0.40)
                  : currentTheme.statusErrorBadgeText.withValues(alpha: 0.35)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.isDark
                ? const Color(0xFF003B73).withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (hasActiveSubs)
            BoxShadow(
              color: currentTheme.accentPrimary.withValues(alpha: currentTheme.isDark ? 0.16 : 0.08),
              blurRadius: 20,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // 1. Client Identity Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glowing Avatar with Initials
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasActiveSubs
                        ? currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length]
                        : [const Color(0xFF64748B), const Color(0xFF475569)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (hasActiveSubs
                              ? currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length].first
                              : const Color(0xFF64748B))
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(name, 'К'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name, Status Badge, Phone & Age
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Full Client Name + Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: currentTheme.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasActiveSubs ? currentTheme.statusActiveBadgeBg : currentTheme.statusErrorBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: BoxDecoration(
                                  color: hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4.5),
                              Text(
                                hasActiveSubs ? 'admin.clients_status_active'.tr() : 'admin.clients_status_unpaid'.tr(),
                                style: TextStyle(
                                  color: hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Row 2: Phone number and Age pill
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.phone, size: 12.5, color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted),
                            const SizedBox(width: 4.5),
                            Text(
                              phone,
                              style: TextStyle(
                                color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (age != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentTheme.accentPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: currentTheme.accentPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.calendar, size: 10, color: currentTheme.accentPrimary),
                                const SizedBox(width: 3),
                                Text(
                                  '$age ${'admin.years_short'.tr()}',
                                  style: TextStyle(
                                    color: currentTheme.accentPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

          // 2. Credentials Box with Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFCBD5E1),
                width: 1.1,
              ),
              boxShadow: currentTheme.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF003B73).withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.keyRound,
                  color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: 'admin.clients_login_label'.tr()),
                        TextSpan(
                          text: loginId,
                          style: TextStyle(
                            color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(text: '   |   ${'admin.clients_password_label'.tr()}'),
                        TextSpan(
                          text: password,
                          style: TextStyle(
                            color: currentTheme.isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyCredentials(loginId, name, password),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.25),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.copy, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'admin.clients_copy'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Children Section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('children')
                .where('parentId', isEqualTo: clientId)
                .snapshots(),
            builder: (context, childSnap) {
              if (!childSnap.hasData || childSnap.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              final children = childSnap.data!.docs;

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.baby, size: 13.5, color: currentTheme.accentPrimary),
                        const SizedBox(width: 5),
                        Text(
                          'admin.clients_children_count'.tr(args: [children.length.toString()]),
                          style: TextStyle(color: currentTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: children.map((doc) {
                        final cData = doc.data() as Map<String, dynamic>;
                        final cName = cData['name'] ?? 'Дитина';
                        final cAge = cData['age'];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.12) : currentTheme.chipBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.22) : currentTheme.chipBorder),
                          ),
                          child: Text(
                            '🏊 $cName${cAge != null ? ", $cAge ${'admin.years_short'.tr()}" : ""}',
                            style: TextStyle(color: currentTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // 4. Quick Subscription Status Banner
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PaymentSheet(initialSearchQuery: name),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (hasActiveSubs ? currentTheme.statusActiveBadgeBg : currentTheme.statusErrorBadgeBg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText).withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: currentTheme.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: (hasActiveSubs ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    hasActiveSubs ? LucideIcons.walletCards : LucideIcons.alertCircle,
                    size: 14,
                    color: hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasActiveSubs
                          ? '${activeSubs.first.serviceName ?? "Активний абонемент"} • ${activeSubs.first.remainingClasses} з ${_formatClassesGenitive(activeSubs.first.totalClasses)}'
                          : 'admin.clients_no_subs'.tr(),
                      style: TextStyle(
                        color: hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 13,
                    color: hasActiveSubs ? currentTheme.statusActiveBadgeText : currentTheme.statusErrorBadgeText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Container(
            height: 1,
            color: currentTheme.dividerColor,
          ),
          const SizedBox(height: 8),

          // 5. Streamlined Action Toolbar
          Row(
            children: [
              // Edit Client Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => EditClientSheet(
                          clientId: clientId,
                          initialName: name,
                          initialPhone: phone,
                          initialAge: age,
                          initialLoginId: loginId,
                          initialPassword: password,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.5),
                      decoration: BoxDecoration(
                        gradient: currentTheme.isDark
                            ? LinearGradient(
                                colors: [
                                  currentTheme.accentPrimary.withValues(alpha: 0.20),
                                  currentTheme.accentSecondary.withValues(alpha: 0.10),
                                ],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentTheme.isDark
                              ? currentTheme.accentPrimary.withValues(alpha: 0.35)
                              : const Color(0xFFBAE6FD),
                          width: 1,
                        ),
                        boxShadow: currentTheme.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                            size: 13.5,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'admin.clients_tooltip_edit'.tr(),
                            style: TextStyle(
                              color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Client Icon Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteClient(clientId, name),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 35,
                    decoration: BoxDecoration(
                      color: currentTheme.isDark
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                          : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentTheme.isDark
                            ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                            : const Color(0xFFFECDD3),
                        width: 1,
                      ),
                      boxShadow: currentTheme.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.trash2,
                        color: currentTheme.isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                        size: 15,
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
).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06);
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 50, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('admin.clients_empty_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('admin.clients_empty_desc'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 44, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Text('admin.clients_not_found'.tr(), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('admin.clients_not_found_desc'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5)),
        ],
      ),
    );
  }
}
