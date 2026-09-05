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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCredentials(String loginId, String name) {
    Clipboard.setData(ClipboardData(text: '${'admin.clients_login_label'.tr()}$loginId\n${'admin.clients_password_label'.tr()}1'));
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('admin.clients_delete_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'admin.clients_delete_confirm'.tr(args: [name]),
          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
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
          SnackBar(content: Text('Помилка: $e'), backgroundColor: const Color(0xFFF43F5E)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSubscriptions = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09182B),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
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
          // 1. Full-fidelity animated water ripples and particles (like in Client screen)
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 2. Fluid aquatic gradient overlay (harmonized with Client screen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.20),
                    const Color(0xFF0284C7).withValues(alpha: 0.12),
                    const Color(0xFF0F172A).withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                    const Color(0xFF00B4D8).withValues(alpha: 0.22),
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
                    const Color(0xFF10B981).withValues(alpha: 0.15),
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
                _buildHeader(context),

                // 2. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: _buildSearchBar(),
                ),

                // 3. Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _buildFilterTabs(),
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
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
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

                          final userSubs = allSubscriptions.where((s) => s.userId == clientId).toList();

                          return _buildClientCard(
                            clientId: clientId,
                            name: name,
                            phone: phone,
                            loginId: loginId,
                            subscriptions: userSubs,
                            index: index,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'admin.clients_parents_students'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF10B981),
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
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          hintText: 'admin.clients_search_hint'.tr(),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
          prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
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

  Widget _buildFilterTabs() {
    return Row(
      children: [
        _buildFilterPill(0, 'admin.clients_filter_all'.tr()),
        const SizedBox(width: 8),
        _buildFilterPill(1, 'admin.clients_filter_with_sub'.tr()),
        const SizedBox(width: 8),
        _buildFilterPill(2, 'admin.clients_filter_no_sub'.tr()),
      ],
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    const Color(0xFF0077B6).withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard({
    required String clientId,
    required String name,
    required String phone,
    required String loginId,
    required List<dynamic> subscriptions,
    required int index,
  }) {
    final activeSubs = subscriptions.where((s) => s.isActive && s.remainingClasses > 0).toList();
    final bool hasActiveSubs = activeSubs.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.88),
            const Color(0xFF0A1422).withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasActiveSubs
              ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
              : const Color(0xFFF43F5E).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          if (hasActiveSubs)
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Client Info & Action buttons
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasActiveSubs
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF64748B), const Color(0xFF475569)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (hasActiveSubs ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'К',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
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
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (hasActiveSubs ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (hasActiveSubs ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            hasActiveSubs ? 'admin.clients_status_active'.tr() : 'admin.clients_status_unpaid'.tr(),
                            style: TextStyle(
                              color: hasActiveSubs ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.phone, size: 12.5, color: Colors.white.withValues(alpha: 0.45)),
                        const SizedBox(width: 5),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Action Buttons (Payment, Edit, Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.creditCard, color: Color(0xFFF59E0B), size: 16),
                      tooltip: 'admin.clients_tooltip_pay'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PaymentSheet(initialTabIndex: 2),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 15),
                      tooltip: 'admin.clients_tooltip_edit'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditClientSheet(
                            clientId: clientId,
                            initialName: name,
                            initialPhone: phone,
                            initialLoginId: loginId,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF3B30).withValues(alpha: 0.24),
                          const Color(0xFFFF1744).withValues(alpha: 0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.60),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3B30), size: 16),
                      tooltip: 'admin.clients_tooltip_delete'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteClient(clientId, name),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Credentials Box with Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.keyRound, color: Color(0xFF38BDF8), size: 15),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                      children: [
                        TextSpan(text: 'admin.clients_login_label'.tr()),
                        TextSpan(
                          text: loginId,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(text: '   |   ${'admin.clients_password_label'.tr()}'),
                        const TextSpan(
                          text: '1',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyCredentials(loginId, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.copy, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'admin.clients_copy'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
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

          const SizedBox(height: 14),

          // 3. Children Section
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('children')
                .where('parentId', isEqualTo: clientId)
                .snapshots(),
            builder: (context, childSnap) {
              if (!childSnap.hasData || childSnap.data!.docs.isEmpty) {
                return Row(
                  children: [
                    Icon(LucideIcons.baby, size: 14, color: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(width: 6),
                    Text(
                      'admin.clients_no_children'.tr(),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                    ),
                  ],
                );
              }

              final children = childSnap.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.baby, size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        'admin.clients_children_count'.tr(args: [children.length.toString()]),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: children.map((doc) {
                      final cData = doc.data() as Map<String, dynamic>;
                      final cName = cData['name'] ?? 'Дитина';
                      final cAge = cData['age'];
                      final cLevel = cData['level'] ?? 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '🏊 $cName${cAge != null ? ", $cAge ${'admin.years_short'.tr()}" : ""} • ${'admin.level_label'.tr(args: [cLevel.toString()])}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // 4. Subscriptions Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.walletCards, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'admin.clients_subscriptions_header'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (subscriptions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Color(0xFFFDA4AF), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'admin.clients_no_subs'.tr(),
                        style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: subscriptions.map((sub) {
                    final isAct = sub.isActive && sub.remainingClasses > 0;
                    final daysLeft = sub.expiryDate?.difference(DateTime.now()).inDays;
                    final isExpiring = isAct && daysLeft != null && daysLeft <= 5;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isAct
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF10B981).withValues(alpha: 0.12),
                                  const Color(0xFF00B4D8).withValues(alpha: 0.05),
                                ],
                              )
                            : null,
                        color: isAct ? null : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAct
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAct ? LucideIcons.circleCheck : LucideIcons.circleSlash,
                            size: 15,
                            color: isAct ? const Color(0xFF10B981) : Colors.white38,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sub.serviceName ?? "Абонемент"} (${sub.ownerName ?? "Власник"})',
                                  style: TextStyle(
                                    color: isAct ? Colors.white : Colors.white60,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (sub.expiryDate != null)
                                  Text(
                                    'admin.clients_valid_until'.tr(args: [
                                      DateFormat('dd.MM.yyyy').format(sub.expiryDate!),
                                      daysLeft != null ? 'admin.clients_days_left'.tr(args: [daysLeft.toString()]) : '',
                                    ]),
                                    style: TextStyle(
                                      color: isExpiring ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                      fontWeight: isExpiring ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: isAct
                                  ? const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    )
                                  : null,
                              color: isAct ? null : const Color(0xFFF43F5E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'admin.clients_sub_progress'.tr(args: ['${sub.remainingClasses}', '${sub.totalClasses}']),
                              style: TextStyle(
                                color: isAct ? Colors.white : const Color(0xFFF43F5E),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
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
