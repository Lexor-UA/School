import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import '../coach_class_attendees_sheet.dart';
import '../coach_dashboard.dart';

String _coachTr(String key, String fallback, {List<String>? args}) => coachTr(key, fallback, args: args);

class CoachSwimmersTab extends ConsumerStatefulWidget {
  const CoachSwimmersTab({super.key});

  @override
  ConsumerState<CoachSwimmersTab> createState() => _CoachSwimmersTabState();
}

class _CoachSwimmersTabState extends ConsumerState<CoachSwimmersTab> {
  int _selectedSegment = 0; // 0: Мої учні, 1: Групи школи, 2: Всі плавці
  int _categoryFilter = 0;  // 0: Всі, 1: Діти, 2: Дорослі
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AppThemeConfig _themeConfig;
  late bool _isLight;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCoachChatWithClient({
    required String targetClientId,
    required String targetClientName,
    String? childName,
  }) {
    if (targetClientId.isEmpty) return;
    final coach = ref.read(authControllerProvider);
    final dialogId = 'coach_${coach?.id}_client_$targetClientId';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentChatScreen(
          dialogId: dialogId,
          recipientId: targetClientId,
          recipientName: targetClientName,
          coachId: coach?.id,
          coachName: coach?.name,
          coachAvatar: coach?.avatarUrl,
          clientId: targetClientId,
          clientName: targetClientName,
          childName: childName,
          type: 'coach_client',
          title: targetClientName,
          subtitle: childName != null ? 'Батьки плавця ($childName)' : 'Клієнт • Онлайн',
        ),
      ),
    );
  }

  Widget _buildSegmentItem(int index, String label, IconData icon) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (_isLight ? Colors.transparent : Colors.white.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: _isLight ? 0.32 : 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? (_isLight ? const Color(0xFF032238) : Colors.white)
                    : (_isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? (_isLight ? const Color(0xFF032238) : Colors.white)
                        : (_isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _categoryFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (_isLight ? Colors.white.withValues(alpha: 0.82) : const Color(0xFF0E2746)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.45)
                : (_isLight ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF00E5FF).withValues(alpha: 0.22)),
            width: 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (_isLight
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (_isLight ? const Color(0xFF032238) : Colors.white)
                : (_isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeConfig = ref.watch(appThemeControllerProvider);
    _isLight = !_themeConfig.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.users, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Групи та плавці',
                              style: TextStyle(
                                color: _themeConfig.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Мої учні, групи школи та каталог усіх плавців',
                              style: TextStyle(
                                color: _themeConfig.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Segmented Switcher: [ 👥 Мої учні ] / [ 🏊 Групи ] / [ 👤 Всі плавці ]
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _isLight
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF0F2E52), Color(0xFF07192F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isLight ? Colors.white.withValues(alpha: 0.78) : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isLight
                            ? Colors.white.withValues(alpha: 0.95)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: _isLight ? 0.08 : 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildSegmentItem(0, 'Мої учні', LucideIcons.userCheck),
                        const SizedBox(width: 4),
                        _buildSegmentItem(1, 'Групи', LucideIcons.layers),
                        const SizedBox(width: 4),
                        _buildSegmentItem(2, 'Всі плавці', LucideIcons.users),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isLight
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF0D2542), Color(0xFF07182B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isLight ? Colors.white.withValues(alpha: 0.85) : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isLight ? Colors.white : const Color(0xFF00E5FF).withValues(alpha: 0.28),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: _isLight ? 0.08 : 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _themeConfig.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: _selectedSegment == 0
                            ? 'Пошук серед моїх учнів'
                            : _selectedSegment == 1
                                ? 'Пошук групи чи тренера'
                                : 'Пошук плавця за ім\'ям',
                        hintStyle: TextStyle(
                          color: _isLight ? const Color(0xFF94A3B8) : Colors.white38,
                          fontSize: 13.5,
                        ),
                        isDense: true,
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                          size: 18,
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: _isLight ? const Color(0xFF64748B) : const Color(0xFF00E5FF),
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Filter Chips: [ Всі ] [ 🧒 Діти ] [ 👤 Дорослі ]
                  Row(
                    children: [
                      _buildFilterChip('Всі', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('🧒 Діти', 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('👤 Дорослі', 2),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content body based on segment
          if (_selectedSegment == 0)
            _buildMySwimmersSliver()
          else if (_selectedSegment == 1)
            _buildGroupsSliver()
          else
            _buildSwimmersSliver(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: MY SWIMMERS (COACH'S ASSIGNED STUDENTS)
  // ==========================================
  Widget _buildMySwimmersSliver() {
    final coach = ref.watch(authControllerProvider);
    final coachId = coach?.id ?? '';
    final coachName = (coach?.name ?? '').trim().toLowerCase();

    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    if (scheduleAsync.isLoading && allClasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
          ),
        ),
      );
    }

    // Filter classes where this coach is assigned
    final coachClasses = allClasses.where((c) {
      if (coachId.isNotEmpty && c.coachId == coachId) return true;
      if (coachName.isNotEmpty && c.coachName.trim().toLowerCase() == coachName) return true;
      return false;
    }).toList();

    // Map student ID to their assigned classes with this coach
    final Map<String, List<GroupClass>> studentClassesMap = {};
    for (final c in coachClasses) {
      for (final id in c.enrolledChildIds) {
        studentClassesMap.putIfAbsent(id, () => []).add(c);
      }
    }

    final enrolledIds = studentClassesMap.keys.toSet();

    // If the coach has no classes in schedule at all
    if (coachClasses.isEmpty) {
      return _buildMySwimmersEmptyState(
        icon: LucideIcons.calendarX,
        title: 'У вас наразі немає призначених занять',
        description:
            'Вам ще не призначено груп або занять у розкладі клубу CitySwim. Як тільки адміністратор закріпить за вами заняття, тут автоматично з\'являться ваші учні.',
        showScheduleButton: true,
      );
    }

    // If the coach has classes, but 0 enrolled students
    if (enrolledIds.isEmpty) {
      return _buildMySwimmersEmptyState(
        icon: LucideIcons.userX,
        title: 'У ваших групах поки немає зареєстрованих учнів',
        description:
            'За вами закріплено ${coachClasses.length} занять у розкладі, але на них ще не записався жоден плавець або очікується формування списків.',
        showScheduleButton: true,
      );
    }

    // Stream children and clients to resolve swimmer details
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('children').snapshots(),
      builder: (context, childSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['parent', 'client'])
              .snapshots(),
          builder: (context, userSnap) {
            if (childSnap.connectionState == ConnectionState.waiting && !childSnap.hasData) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                  ),
                ),
              );
            }

            final childDocs = childSnap.data?.docs ?? [];
            final userDocs = userSnap.data?.docs ?? [];

            final List<Map<String, dynamic>> mySwimmers = [];

            // Add children enrolled in this coach's classes
            for (final d in childDocs) {
              if (enrolledIds.contains(d.id)) {
                final data = Map<String, dynamic>.from(d.data() as Map);
                data['id'] = d.id;
                final child = Child.fromJson(data);
                mySwimmers.add({
                  'id': d.id,
                  'name': child.name,
                  'isAdult': false,
                  'child': child,
                  'age': child.currentAge ?? child.age,
                  'classes': studentClassesMap[d.id] ?? [],
                });
              }
            }

            // Add adult clients enrolled in this coach's classes
            for (final d in userDocs) {
              if (enrolledIds.contains(d.id)) {
                final data = Map<String, dynamic>.from(d.data() as Map);
                final name = (data['name'] as String? ?? '').trim();
                if (name.isNotEmpty) {
                  mySwimmers.add({
                    'id': d.id,
                    'name': name,
                    'isAdult': true,
                    'child': null,
                    'age': data['age'] as int?,
                    'classes': studentClassesMap[d.id] ?? [],
                  });
                }
              }
            }

            // Filter by category: 0: All, 1: Kids, 2: Adults
            var filtered = mySwimmers.where((s) {
              if (_categoryFilter == 1 && s['isAdult'] == true) return false;
              if (_categoryFilter == 2 && s['isAdult'] == false) return false;
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final name = (s['name'] as String).toLowerCase();
                final classes = (s['classes'] as List<GroupClass>?) ?? [];
                final matchesClass = classes.any((c) => c.title.toLowerCase().contains(query));
                if (!name.contains(query) && !matchesClass) return false;
              }
              return true;
            }).toList();

            // Sort alphabetically by name
            filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userX,
                          color: _isLight ? const Color(0xFF94A3B8) : Colors.white30,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Серед ваших учнів нікого не знайдено',
                          style: TextStyle(
                            color: _themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 220),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    final bool isAdult = item['isAdult'] as bool;
                    final classes = item['classes'] as List<GroupClass>?;
                    if (!isAdult && item['child'] != null) {
                      return _buildSwimmerDirectoryCard(
                        item['child'] as Child,
                        index,
                        assignedClasses: classes,
                      );
                    } else {
                      return _buildAdultSwimmerCard(
                        item['name'] as String,
                        item['age'] as int?,
                        index,
                        userId: item['id'] as String,
                        assignedClasses: classes,
                      );
                    }
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMySwimmersEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required bool showScheduleButton,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                      blurRadius: 22,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _themeConfig.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _themeConfig.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              if (showScheduleButton) ...[
                const SizedBox(height: 22),
                InkWell(
                  onTap: () => ref.read(coachTabProvider.notifier).setTab(0),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendarDays, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Переглянути мій розклад',
                          style: TextStyle(
                            color: Colors.white,
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

              const SizedBox(height: 20),

              // Helpful context tip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isLight
                      ? const Color(0xFFF0F9FF)
                      : const Color(0xFF0C243E).withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isLight
                        ? const Color(0xFFBAE6FD)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 16,
                      color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ви можете переглянути повний перелік груп школи або базу всіх плавців у вкладках вгорі.',
                        style: TextStyle(
                          color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF7DD3FC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
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
  // TAB 1: GROUPS CATALOG
  // ==========================================
  Widget _buildGroupsSliver() {
    final scheduleAsync = ref.watch(scheduleControllerProvider);
    final allClasses = scheduleAsync.value ?? [];

    if (scheduleAsync.isLoading && allClasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
          ),
        ),
      );
    }

    // Extract unique school groups (by title and lane)
    final Map<String, GroupClass> uniqueGroupsMap = {};
    for (final c in allClasses) {
      final key = '${c.title.trim().toLowerCase()}_${c.lane.trim().toLowerCase()}';
      if (!uniqueGroupsMap.containsKey(key)) {
        uniqueGroupsMap[key] = c;
      } else {
        final existing = uniqueGroupsMap[key]!;
        final combinedEnrolled = {...existing.enrolledChildIds, ...c.enrolledChildIds}.toList();
        uniqueGroupsMap[key] = existing.copyWith(
          enrolledChildIds: combinedEnrolled,
          maxCapacity: c.maxCapacity > existing.maxCapacity ? c.maxCapacity : existing.maxCapacity,
        );
      }
    }

    var groups = uniqueGroupsMap.values.toList();

    // Category filter: 0: All, 1: Kids, 2: Adults
    groups = groups.where((g) {
      final isAdult = g.category.toLowerCase().contains('доросла') ||
          g.title.toLowerCase().contains('доросла') ||
          g.title.toLowerCase().contains('аквафітнес');
      if (_categoryFilter == 1 && isAdult) return false;
      if (_categoryFilter == 2 && !isAdult) return false;
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = g.title.toLowerCase().contains(_searchQuery);
        final matchesLane = g.lane.toLowerCase().contains(_searchQuery);
        final matchesCoach = g.coachName.toLowerCase().contains(_searchQuery);
        if (!matchesTitle && !matchesLane && !matchesCoach) return false;
      }
      return true;
    }).toList();

    // Sort alphabetically by title
    groups.sort((a, b) => a.title.compareTo(b.title));

    if (groups.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.layers,
                  color: _isLight ? const Color(0xFF94A3B8) : Colors.white30,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Груп за вашим запитом не знайдено',
                  style: TextStyle(
                    color: _themeConfig.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 220),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildGroupCard(groups[index], index);
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupClass group, int index) {
    final isAdult = group.category.toLowerCase().contains('доросла') ||
        group.title.toLowerCase().contains('доросла') ||
        group.title.toLowerCase().contains('аквафітнес');
    final enrolledCount = group.enrolledChildIds.length;
    final capacity = group.maxCapacity > 0 ? group.maxCapacity : 10;
    final fillRatio = (enrolledCount / capacity).clamp(0.0, 1.0);
    final accentColor = isAdult
        ? (_isLight ? const Color(0xFF9333EA) : const Color(0xFFA855F7))
        : (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        const Color(0xFF0F2D50),
                        const Color(0xFF081C33),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isLight ? Colors.white : accentColor.withValues(alpha: 0.38),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title + Category Badge (ДІТИ / ДОРОСЛІ)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            style: TextStyle(
                              color: _themeConfig.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                group.lane.toLowerCase().contains('дитяч') ? LucideIcons.baby : LucideIcons.waves,
                                size: 13,
                                color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                group.lane.isNotEmpty ? group.lane : 'Спортивний басейн',
                                style: TextStyle(
                                  color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: _isLight ? 0.10 : 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: _isLight ? 0.35 : 0.50),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: _isLight ? 0.10 : 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdult ? LucideIcons.user : LucideIcons.users,
                            size: 11,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdult ? 'ДОРОСЛІ' : 'ДІТИ',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: Coach & Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _isLight
                        ? const Color(0xFFF1F5F9).withValues(alpha: 0.85)
                        : const Color(0xFF0B213B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isLight
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.userCheck,
                              size: 13,
                              color: _isLight ? const Color(0xFF64748B) : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                group.coachName.isNotEmpty ? group.coachName : 'Тренер клубу',
                                style: TextStyle(
                                  color: _themeConfig.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock3,
                            size: 13,
                            color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${DateFormat('HH:mm').format(group.startTime)} \u2013 ${DateFormat('HH:mm').format(group.endTime)}',
                            style: TextStyle(
                              color: _isLight ? const Color(0xFF0F172A) : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Row 3: Fill rate & Capacity Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Заповненість: $enrolledCount з $capacity місць',
                      style: TextStyle(
                        color: _themeConfig.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(fillRatio * 100).toInt()}%',
                      style: TextStyle(
                        color: fillRatio >= 1.0
                            ? const Color(0xFFF43F5E)
                            : (_isLight ? const Color(0xFF059669) : const Color(0xFF10B981)),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        color: _isLight ? const Color(0xFFE2E8F0) : Colors.white.withValues(alpha: 0.08),
                      ),
                      FractionallySizedBox(
                        widthFactor: fillRatio,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: fillRatio >= 1.0
                                  ? [const Color(0xFFF43F5E), const Color(0xFFFB7185)]
                                  : [const Color(0xFF00E5FF), const Color(0xFF10B981)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (fillRatio >= 1.0 ? const Color(0xFFF43F5E) : const Color(0xFF00E5FF)).withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Row 4: Action button - Open Group Attendees Sheet (Option A: Royal Sapphire Azure Gradient)
                InkWell(
                  onTap: () => showCoachClassAttendeesSheet(context, group),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLight
                            ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                            : const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: _isLight ? 0.32 : 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users, size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Склад групи ($enrolledCount)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
    ).animate().fadeIn(delay: (index * 40).ms);
  }

  // ==========================================
  // TAB 1: ALL SWIMMERS & ADULT CLIENTS
  // ==========================================
  Widget _buildSwimmersSliver() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('children').snapshots(),
      builder: (context, childSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['parent', 'client'])
              .snapshots(),
          builder: (context, userSnap) {
            if (childSnap.connectionState == ConnectionState.waiting && !childSnap.hasData) {
              return SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                  ),
                ),
              );
            }

            final childDocs = childSnap.data?.docs ?? [];
            final userDocs = userSnap.data?.docs ?? [];

            final List<Map<String, dynamic>> allSwimmers = [];

            // Add children
            for (final d in childDocs) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              data['id'] = d.id;
              final child = Child.fromJson(data);
              allSwimmers.add({
                'id': d.id,
                'name': child.name,
                'isAdult': false,
                'child': child,
                'age': child.currentAge ?? child.age,
              });
            }

            // Add adult clients
            for (final d in userDocs) {
              final data = Map<String, dynamic>.from(d.data() as Map);
              final name = (data['name'] as String? ?? '').trim();
              if (name.isNotEmpty) {
                allSwimmers.add({
                  'id': d.id,
                  'name': name,
                  'isAdult': true,
                  'child': null,
                  'age': data['age'] as int?,
                });
              }
            }

            // Filter by category: 0: All, 1: Kids, 2: Adults
            var filtered = allSwimmers.where((s) {
              if (_categoryFilter == 1 && s['isAdult'] == true) return false;
              if (_categoryFilter == 2 && s['isAdult'] == false) return false;
              if (_searchQuery.isNotEmpty && !(s['name'] as String).toLowerCase().contains(_searchQuery)) {
                return false;
              }
              return true;
            }).toList();

            // Sort alphabetically by name
            filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.userX,
                          color: _isLight ? const Color(0xFF94A3B8) : Colors.white30,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Плавців за вашим запитом не знайдено',
                          style: TextStyle(
                            color: _themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 220),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    final bool isAdult = item['isAdult'] as bool;
                    if (!isAdult && item['child'] != null) {
                      return _buildSwimmerDirectoryCard(item['child'] as Child, index);
                    } else {
                      return _buildAdultSwimmerCard(
                        item['name'] as String,
                        item['age'] as int?,
                        index,
                        userId: item['id'] as String,
                      );
                    }
                  },
                  childCount: filtered.length,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdultSwimmerCard(
    String name,
    int? age,
    int index, {
    required String userId,
    List<GroupClass>? assignedClasses,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        const Color(0xFF0F2D50),
                        const Color(0xFF081C33),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isLight ? Colors.white : const Color(0xFFA855F7).withValues(alpha: 0.38),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: _themeConfig.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.10 : 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.30 : 0.45),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.user, size: 10, color: Color(0xFFA855F7)),
                                SizedBox(width: 4),
                                Text(
                                  'ДОРОСЛИЙ ПЛАВЕЦЬ',
                                  style: TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$age р.',
                              style: TextStyle(
                                color: _themeConfig.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (assignedClasses != null && assignedClasses.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: assignedClasses.take(3).map((cls) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.08 : 0.15),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: const Color(0xFFA855F7).withValues(alpha: _isLight ? 0.25 : 0.40),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.waves,
                                    size: 10,
                                    color: Color(0xFFA855F7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cls.title,
                                    style: TextStyle(
                                      color: _isLight ? const Color(0xFF7C3AED) : const Color(0xFFC084FC),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Message button to chat with adult client
                GestureDetector(
                  onTap: () => _openCoachChatWithClient(targetClientId: userId, targetClientName: name),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.messageCircle, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms);
  }

  Widget _buildSwimmerDirectoryCard(
    Child child,
    int index, {
    List<GroupClass>? assignedClasses,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _isLight
            ? [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.80),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLight
                    ? [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.74),
                      ]
                    : [
                        const Color(0xFF0F2D50),
                        const Color(0xFF081C33),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isLight ? Colors.white : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                width: _isLight ? 1.5 : 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => showSwimmerDetailsSheet(context, child),
                splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                highlightColor: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Header (Avatar + Name & Level/XP + Chevron)
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: TextStyle(
                                    color: _themeConfig.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isLight
                                              ? const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]
                                              : [
                                                  const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                                  const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isLight
                                              ? const Color(0xFF7DD3FC)
                                              : const Color(0xFF00E5FF).withValues(alpha: 0.50),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        '${_coachTr('coach.level_label', 'Рівень')} ${child.level}',
                                        style: TextStyle(
                                          color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF38BDF8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (child.parentId.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => _openCoachChatWithClient(
                                targetClientId: child.parentId,
                                targetClientName: 'Батьки (${child.name})',
                                childName: child.name,
                              ),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.messageCircle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isLight ? const Color(0xFFF1F5F9) : const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              border: Border.all(
                                color: _isLight ? const Color(0xFFE2E8F0) : const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                              boxShadow: _isLight
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.chevronRight,
                                color: _isLight ? const Color(0xFF0284C7) : Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (assignedClasses != null && assignedClasses.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: assignedClasses.take(3).map((cls) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                    .withValues(alpha: _isLight ? 0.08 : 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                      .withValues(alpha: _isLight ? 0.25 : 0.40),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.waves,
                                    size: 11,
                                    color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cls.title,
                                    style: TextStyle(
                                      color: _isLight ? const Color(0xFF0369A1) : const Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Row 2: Actions (Note + Profile Card)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showCoachNoteDialog(context, child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: _isLight
                                      ? const LinearGradient(
                                          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF0F2B48), Color(0xFF07192C)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isLight
                                        ? const Color(0xFFBAE6FD)
                                        : const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF))
                                          .withValues(alpha: _isLight ? 0.08 : 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.fileText,
                                      color: _isLight ? const Color(0xFF0284C7) : const Color(0xFF00E5FF),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _coachTr('coach.note_btn', 'Нотатка'),
                                      style: TextStyle(
                                        color: _isLight ? const Color(0xFF0369A1) : Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showSwimmerDetailsSheet(context, child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: _isLight
                                      ? const LinearGradient(
                                          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _isLight
                                        ? const Color(0xFFE2E8F0)
                                        : Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.user,
                                      color: _isLight ? const Color(0xFF64748B) : Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _coachTr('coach.details_btn', 'Картка плавця'),
                                      style: TextStyle(
                                        color: _isLight ? const Color(0xFF334155) : Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
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
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms);
  }
}

