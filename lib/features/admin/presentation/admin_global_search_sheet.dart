import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

import 'edit_client_sheet.dart';
import 'edit_coach_sheet.dart';
import 'payment_sheet.dart';
import 'admin_calendar_screen.dart';
import 'admin_clients_screen.dart';
import 'admin_coaches_screen.dart';

class AdminGlobalSearchSheet extends ConsumerStatefulWidget {
  final int initialCategoryIndex;

  const AdminGlobalSearchSheet({
    super.key,
    this.initialCategoryIndex = 0,
  });

  @override
  ConsumerState<AdminGlobalSearchSheet> createState() => _AdminGlobalSearchSheetState();
}

class _AdminGlobalSearchSheetState extends ConsumerState<AdminGlobalSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  late int _selectedCategoryIndex;

  List<String> get _categories => [
    'admin.cat_all'.tr(),
    'admin.cat_clients'.tr(),
    'admin.cat_children'.tr(),
    'admin.cat_coaches'.tr(),
    'admin.cat_classes'.tr(),
    'admin.cat_subscriptions'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategoryIndex = widget.initialCategoryIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];
    final allSubscriptions = ref.watch(subscriptionControllerProvider);

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF13233C),
                Color(0xFF0A1220),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('children').snapshots(),
                builder: (context, childrenSnapshot) {
                  final allUsers = usersSnapshot.data?.docs ?? [];
                  final allChildren = childrenSnapshot.data?.docs ?? [];

                  // Categorize users
                  final clients = allUsers.where((u) {
                    final data = u.data() as Map<String, dynamic>;
                    return (data['role'] ?? '') == 'parent';
                  }).toList();

                  final coaches = allUsers.where((u) {
                    final data = u.data() as Map<String, dynamic>;
                    return (data['role'] ?? '') == 'coach';
                  }).toList();

                  // Filter results based on search query
                  final q = _query.toLowerCase().trim();

                  final matchingClients = clients.where((c) {
                    if (q.isEmpty) return false;
                    final d = c.data() as Map<String, dynamic>;
                    final name = (d['name'] ?? '').toString().toLowerCase();
                    final phone = (d['phone'] ?? '').toString().toLowerCase();
                    final login = (d['loginId'] ?? '').toString().toLowerCase();
                    return name.contains(q) || phone.contains(q) || login.contains(q);
                  }).toList();

                  final matchingChildren = allChildren.where((ch) {
                    if (q.isEmpty) return false;
                    final d = ch.data() as Map<String, dynamic>;
                    final name = (d['name'] ?? '').toString().toLowerCase();
                    return name.contains(q);
                  }).toList();

                  final matchingCoaches = coaches.where((co) {
                    if (q.isEmpty) return false;
                    final d = co.data() as Map<String, dynamic>;
                    final name = (d['name'] ?? '').toString().toLowerCase();
                    final phone = (d['phone'] ?? '').toString().toLowerCase();
                    final login = (d['loginId'] ?? '').toString().toLowerCase();
                    return name.contains(q) || phone.contains(q) || login.contains(q);
                  }).toList();

                  final matchingClasses = allClasses.where((cl) {
                    if (q.isEmpty) return false;
                    final title = cl.title.toLowerCase();
                    final coach = cl.coachName.toLowerCase();
                    final lane = cl.lane.toLowerCase();
                    final cat = cl.category.toLowerCase();
                    return title.contains(q) || coach.contains(q) || lane.contains(q) || cat.contains(q);
                  }).toList();

                  final matchingSubs = allSubscriptions.where((s) {
                    if (q.isEmpty) return false;
                    final sName = (s.serviceName ?? '').toLowerCase();
                    final oName = (s.ownerName ?? '').toLowerCase();
                    final uId = s.userId.toLowerCase();
                    return sName.contains(q) || oName.contains(q) || uId.contains(q);
                  }).toList();

                  final totalResults = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1 ? matchingClients.length : 0) +
                      (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2 ? matchingChildren.length : 0) +
                      (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3 ? matchingCoaches.length : 0) +
                      (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 4 ? matchingClasses.length : 0) +
                      (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 5 ? matchingSubs.length : 0);

                  return Column(
                    children: [
                      // 1. Drag Handle & Header
                      _buildHeader(context),

                      // 2. Search Input Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        child: _buildSearchInputField(),
                      ),

                      // 3. Category Filter Chips Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildCategoryChips(),
                      ),

                      const SizedBox(height: 4),

                      // 4. Content (Empty State suggestions or Results List)
                      Expanded(
                        child: q.isEmpty
                            ? _buildEmptyOrSuggestionsView(
                                recentClients: clients.take(4).toList(),
                                upcomingClasses: allClasses.take(3).toList(),
                              )
                            : _buildResultsList(
                                totalResults: totalResults,
                                matchingClients: matchingClients,
                                matchingChildren: matchingChildren,
                                matchingCoaches: matchingCoaches,
                                matchingClasses: matchingClasses,
                                matchingSubs: matchingSubs,
                                allUsersMap: {for (var u in allUsers) u.id: u.data() as Map<String, dynamic>},
                              ),
                      ),
                    ],
                  );
                },
              );
            },
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
          // Drag Handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          const Color(0xFF00B4D8).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin.smart_search_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'admin.smart_search_subtitle'.tr(),
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white60, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. SEARCH INPUT FIELD
  // ==========================================
  Widget _buildSearchInputField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2E4D).withValues(alpha: 0.9),
            const Color(0xFF122036).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'admin.smart_search_hint'.tr(),
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 19),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white60, size: 17),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (val) => setState(() => _query = val),
      ),
    );
  }

  // ==========================================
  // 3. CATEGORY CHIPS
  // ==========================================
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (idx) {
          final isSelected = _selectedCategoryIndex == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (idx == 1) Icon(LucideIcons.user, size: 13, color: isSelected ? const Color(0xFF081424) : Colors.white60),
                    if (idx == 2) Icon(LucideIcons.waves, size: 13, color: isSelected ? const Color(0xFF081424) : Colors.white60),
                    if (idx == 3) Icon(LucideIcons.award, size: 13, color: isSelected ? const Color(0xFF081424) : Colors.white60),
                    if (idx == 4) Icon(LucideIcons.calendar, size: 13, color: isSelected ? const Color(0xFF081424) : Colors.white60),
                    if (idx == 5) Icon(LucideIcons.creditCard, size: 13, color: isSelected ? const Color(0xFF081424) : Colors.white60),
                    if (idx > 0) const SizedBox(width: 5),
                    Text(
                      _categories[idx],
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF081424) : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==========================================
  // 4. EMPTY OR SUGGESTIONS VIEW
  // ==========================================
  Widget _buildEmptyOrSuggestionsView({
    required List<QueryDocumentSnapshot> recentClients,
    required List<GroupClass> upcomingClasses,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Швидкі розділи
          const Text(
            'Швидкий перехід за категоріями',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildQuickNavButton(
                  icon: LucideIcons.users,
                  title: 'Всі клієнти',
                  subtitle: 'База батьків та дітей',
                  color: const Color(0xFF00B4D8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminClientsScreen()));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickNavButton(
                  icon: LucideIcons.award,
                  title: 'Тренери клубу',
                  subtitle: 'Команда та контакти',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCoachesScreen()));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildQuickNavButton(
                  icon: LucideIcons.creditCard,
                  title: 'Каса & Оплата',
                  subtitle: 'Активні та боржники',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PaymentSheet(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickNavButton(
                  icon: LucideIcons.calendar,
                  title: 'Розклад занять',
                  subtitle: 'Календар басейну',
                  color: const Color(0xFF38BDF8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCalendarScreen()));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section: Останні клієнти
          if (recentClients.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Останні додані клієнти',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminClientsScreen()));
                  },
                  child: const Text('Всі', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...recentClients.map((c) {
              final d = c.data() as Map<String, dynamic>;
              return _buildClientResultRow(
                clientId: c.id,
                name: d['name'] ?? 'Клієнт',
                phone: d['phone'] ?? '',
                loginId: d['loginId'] ?? '',
              );
            }),
          ],

          const SizedBox(height: 18),

          // Section: Найближчі заняття
          if (upcomingClasses.isNotEmpty) ...[
            const Text(
              'Найближчі тренування',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...upcomingClasses.map((cl) => _buildClassResultRow(cl)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickNavButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
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
  // 5. RESULTS LIST
  // ==========================================
  Widget _buildResultsList({
    required int totalResults,
    required List<QueryDocumentSnapshot> matchingClients,
    required List<QueryDocumentSnapshot> matchingChildren,
    required List<QueryDocumentSnapshot> matchingCoaches,
    required List<GroupClass> matchingClasses,
    required List<Subscription> matchingSubs,
    required Map<String, Map<String, dynamic>> allUsersMap,
  }) {
    if (totalResults == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.searchX, size: 48, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(height: 14),
              Text(
                'Нічого не знайдено за запитом "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Спробуйте змінити пошуковий запит або обрати іншу категорію',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final showClients = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) && matchingClients.isNotEmpty;
    final showChildren = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) && matchingChildren.isNotEmpty;
    final showCoaches = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) && matchingCoaches.isNotEmpty;
    final showClasses = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 4) && matchingClasses.isNotEmpty;
    final showSubs = (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 5) && matchingSubs.isNotEmpty;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      children: [
        // Counter badge
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'ЗНАЙДЕНО: $totalResults',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // 1. Клієнти
        if (showClients) ...[
          _buildResultSectionHeader('Клієнти / Батьки', LucideIcons.users, const Color(0xFF00B4D8), matchingClients.length),
          ...matchingClients.map((c) {
            final d = c.data() as Map<String, dynamic>;
            return _buildClientResultRow(
              clientId: c.id,
              name: d['name'] ?? 'Клієнт',
              phone: d['phone'] ?? '',
              loginId: d['loginId'] ?? '',
            );
          }),
          const SizedBox(height: 14),
        ],

        // 2. Діти
        if (showChildren) ...[
          _buildResultSectionHeader('Діти / Учні', LucideIcons.waves, const Color(0xFF38BDF8), matchingChildren.length),
          ...matchingChildren.map((ch) {
            final d = ch.data() as Map<String, dynamic>;
            final parentId = d['parentId'] as String?;
            final parentName = parentId != null ? (allUsersMap[parentId]?['name'] ?? 'Батьки') : 'Невідомо';
            return _buildChildResultRow(
              childName: d['name'] ?? 'Учень',
              level: d['level'] ?? 1,
              xp: d['xp'] ?? 0,
              parentName: parentName,
            );
          }),
          const SizedBox(height: 14),
        ],

        // 3. Тренери
        if (showCoaches) ...[
          _buildResultSectionHeader('Тренери клубу', LucideIcons.award, const Color(0xFF8B5CF6), matchingCoaches.length),
          ...matchingCoaches.map((co) {
            final d = co.data() as Map<String, dynamic>;
            return _buildCoachResultRow(
              coachId: co.id,
              name: d['name'] ?? 'Тренер',
              phone: d['phone'] ?? '',
              loginId: d['loginId'] ?? '',
            );
          }),
          const SizedBox(height: 14),
        ],

        // 4. Заняття
        if (showClasses) ...[
          _buildResultSectionHeader('Заняття та розклад', LucideIcons.calendar, const Color(0xFF10B981), matchingClasses.length),
          ...matchingClasses.map((cl) => _buildClassResultRow(cl)),
          const SizedBox(height: 14),
        ],

        // 5. Абонементи
        if (showSubs) ...[
          _buildResultSectionHeader('Абонементи', LucideIcons.creditCard, const Color(0xFFF59E0B), matchingSubs.length),
          ...matchingSubs.map((s) => _buildSubResultRow(s)),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildResultSectionHeader(String title, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RESULT ROWS
  // ==========================================
  Widget _buildClientResultRow({
    required String clientId,
    required String name,
    required String phone,
    required String loginId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00B4D8).withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'К',
            style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$phone • Логін: $loginId',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.creditCard, color: Color(0xFFF59E0B), size: 18),
              tooltip: 'Каса / Оплата',
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PaymentSheet(initialTabIndex: 2),
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 18),
              tooltip: 'Редагувати',
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EditClientSheet(
                    clientId: clientId,
                    initialName: name,
                    initialPhone: phone,
                    initialLoginId: loginId,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildResultRow({
    required String childName,
    required int level,
    required int xp,
    required String parentName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.waves, color: Color(0xFF38BDF8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(childName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Батьки: $parentName',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Рівень $level',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachResultRow({
    required String coachId,
    required String name,
    required String phone,
    required String loginId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'Т',
            style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$phone • Логін: $loginId',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 18),
          tooltip: 'Редагувати тренера',
          onPressed: () {
            Navigator.pop(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => EditCoachSheet(
                coachId: coachId,
                initialName: name,
                initialPhone: phone,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassResultRow(GroupClass cl) {
    final timeFormat = DateFormat('dd.MM HH:mm');
    final timeStr = timeFormat.format(cl.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cl.title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Тренер: ${cl.coachName} • ${cl.lane}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${cl.enrolledChildIds.length}/${cl.maxCapacity}',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubResultRow(Subscription s) {
    final expiryStr = s.expiryDate != null ? DateFormat('dd.MM.yyyy').format(s.expiryDate!) : 'Безстроково';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.creditCard, color: Color(0xFFF59E0B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.serviceName ?? 'Абонемент', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Учень: ${s.ownerName} • До: $expiryStr',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: s.remainingClasses > 0 ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF43F5E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${s.remainingClasses} з ${s.totalClasses}',
              style: TextStyle(
                color: s.remainingClasses > 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
