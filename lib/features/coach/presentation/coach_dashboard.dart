import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/coach/presentation/qr_scanner_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';

class CoachDashboard extends ConsumerStatefulWidget {
  const CoachDashboard({super.key});

  @override
  ConsumerState<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends ConsumerState<CoachDashboard> {
  String? _selectedClassId;
  List<Child> _enrolledChildren = [];
  bool _isLoadingChildren = false;

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  Future<void> _fetchChildren(List<String> childIds) async {
    if (childIds.isEmpty) {
      if (mounted) setState(() { _enrolledChildren = []; _isLoadingChildren = false; });
      return;
    }
    
    setState(() => _isLoadingChildren = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('children')
          .where(FieldPath.documentId, whereIn: childIds.take(10).toList())
          .get();
      
      final children = snapshot.docs.map((doc) => Child.fromJson({'id': doc.id, ...doc.data()})).toList();
      if (mounted) {
        setState(() {
          _enrolledChildren = children;
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching children: $e');
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _manualCheckIn(GroupClass gClass, String childId, String childName) async {
    try {
      final newAttended = List<String>.from(gClass.attendedChildIds)..add(childId);
      await FirebaseFirestore.instance.collection('classes').doc(gClass.id).update({
        'attendedChildIds': newAttended,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$childName ${'coach.marked_manually'.tr()}'),
            backgroundColor: Colors.greenAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking presence: $e');
    }
  }

  void _awardMedal(Child child) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Нагородити дитину', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMedalOption(child, 'champion', 'Чемпіон', 'За відмінне старання на тренуванні', '🏆'),
              _buildMedalOption(child, 'ninja', 'Водяний ніндзя', 'За швидкість та спритність', '🥷'),
              _buildMedalOption(child, 'star', 'Супер Зірка', 'За ідеальну дисципліну', '⭐'),
            ],
          ),
        );
      }
    );
  }

  Widget _buildMedalOption(Child child, String id, String name, String desc, String icon) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: () async {
        Navigator.pop(context);
        final achievement = Achievement(id: id, name: name, description: desc, iconType: icon, isUnlocked: true);
        final newAchievements = List<Achievement>.from(child.achievements)..add(achievement);
        
        await FirebaseFirestore.instance.collection('children').doc(child.id).update({
          'achievements': newAchievements.map((a) => a.toJson()).toList(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нагороду видано!'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('coach.title'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ref.watch(scheduleControllerProvider).when(
        data: (classes) {
          // Filter classes for today for this coach
          final today = DateTime.now();
          final coachClasses = classes.where((c) => 
            c.coachId == user?.id && 
            c.startTime.year == today.year && 
            c.startTime.month == today.month && 
            c.startTime.day == today.day
          ).toList();

          if (coachClasses.isNotEmpty && _selectedClassId == null) {
            _selectedClassId = coachClasses.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchChildren(coachClasses.first.enrolledChildIds);
            });
          }
          
          final selectedClass = coachClasses.firstWhere((c) => c.id == _selectedClassId, orElse: () => coachClasses.isNotEmpty ? coachClasses.first : coachClasses.firstWhere((_) => false, orElse: () => throw 'No classes'));
          
          final presentCount = selectedClass.attendedChildIds.length;
          final totalCount = selectedClass.enrolledChildIds.length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: -5),
                              ],
                            ),
                            child: const AvatarPicker(
                              heroTag: 'hero_avatar_Тренерам_dashboard',
                              radius: 36,
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'coach.hello'.tr()}, ${user?.name ?? 'Тренер'}!',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                Text(
                                  'У вас ${coachClasses.length} занять сьогодні',
                                  style: const TextStyle(color: Colors.cyanAccent, letterSpacing: 1, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Top Stats (Glassmorphism)
                      Row(
                        children: [
                          Expanded(child: _buildGlassStat('coach.students'.tr(), '$totalCount', LucideIcons.users, Colors.cyanAccent)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGlassStat('coach.attendance'.tr(), totalCount > 0 ? '${((presentCount / totalCount) * 100).toInt()}%' : '0%', LucideIcons.activity, Colors.greenAccent)),
                        ],
                      ).animate().slideY(begin: 0.2, end: 0, delay: 100.ms).fadeIn(),
                      const SizedBox(height: 32),

                      // Premium Scan Action Button
                      Center(
                        child: _buildPremiumScanButton(),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 48),

                      // Today's Classes
                      Text(
                        'coach.schedule_today'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2.5),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      
                      if (coachClasses.isEmpty)
                        const Text('Немає занять на сьогодні', style: TextStyle(color: Colors.white70))
                      else
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.none,
                            children: coachClasses.map((c) {
                              final time = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
                              final isActive = c.id == _selectedClassId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedClassId = c.id);
                                    _fetchChildren(c.enrolledChildIds);
                                  },
                                  child: _buildPremiumClassChip(time: time, name: c.title, isActive: isActive).animate().slideX(begin: 0.2, end: 0, delay: 400.ms).fadeIn(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      const SizedBox(height: 40),

                      // Attendees List Header
                      if (coachClasses.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'coach.journal'.tr(),
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                                boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10)],
                              ),
                              child: Text(
                                '$presentCount / $totalCount',
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              if (_isLoadingChildren)
                const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              else if (coachClasses.isNotEmpty && _enrolledChildren.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Немає записаних учнів', style: TextStyle(color: Colors.white54)),
                    )
                  )
                )
              else if (coachClasses.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList.builder(
                    itemCount: _enrolledChildren.length,
                    itemBuilder: (context, index) {
                      final child = _enrolledChildren[index];
                      final isPresent = selectedClass.attendedChildIds.contains(child.id);
                      return _buildAttendeeCard(child, isPresent, selectedClass, index).animate().fadeIn(delay: (800 + index * 100).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Помилка завантаження')),
      ),
    );
  }

  Widget _buildGlassStat(String label, String value, IconData icon, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 15)],
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    Icon(LucideIcons.trendingUp, color: accentColor.withValues(alpha: 0.5), size: 16),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  value, 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 32, 
                    fontWeight: FontWeight.w900, 
                    shadows: [Shadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 15)]
                  )
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumScanButton() {
    return GestureDetector(
      onTap: _scanQR,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 2),
            BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).slide(begin: const Offset(-1, 0), end: const Offset(1, 0), duration: 2.seconds),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.scanLine, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'coach.scan_qr'.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02), duration: 1.5.seconds);
  }

  Widget _buildPremiumClassChip({required String time, required String name, required bool isActive}) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? Colors.cyanAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.15), 
          width: isActive ? 2 : 1
        ),
        boxShadow: isActive ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isActive ? 10 : 5, sigmaY: isActive ? 10 : 5),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w900, 
                        color: isActive ? Colors.white : Colors.white70,
                        shadows: isActive ? [const Shadow(color: Colors.cyanAccent, blurRadius: 10)] : []
                      ),
                    ),
                    if (isActive) 
                      Container(
                        width: 10, height: 10, 
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent, 
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 10)]
                        )
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0, duration: 800.ms)
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.cyanAccent : Colors.white54, 
                    fontSize: 13, 
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.5
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(Child child, bool isPresent, GroupClass gClass, int index) {
    Color avatarColor = Colors.cyanAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPresent ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          width: isPresent ? 1.5 : 1
        ),
        boxShadow: isPresent ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.1), blurRadius: 15)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Glowing Avatar Ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatarColor.withValues(alpha: 0.8), avatarColor.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: avatarColor.withValues(alpha: 0.4), blurRadius: 12),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF071426),
                    child: Text(child.name.isNotEmpty ? child.name[0].toUpperCase() : '?', style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isPresent ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.orangeAccent.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(color: (isPresent ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.2), blurRadius: 8),
                              ],
                            ),
                            child: Text(
                              isPresent ? 'coach.status_present_m'.tr() : 'coach.status_expected'.tr(), 
                              style: TextStyle(
                                color: isPresent ? Colors.greenAccent : Colors.orangeAccent, 
                                fontSize: 11, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Рівень ${child.level}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPresent) 
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.medal, color: Colors.orangeAccent, size: 24),
                        onPressed: () => _awardMedal(child),
                        tooltip: 'Видати нагороду',
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 24),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(LucideIcons.chevronsRight, color: Colors.white38, size: 20)
                          .animate(onPlay: (c) => c.repeat())
                          .slideX(begin: -0.2, end: 0.2, duration: 1.seconds)
                          .fade(begin: 0.2, end: 1.0),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.userCheck, color: Colors.white54, size: 28),
                        onPressed: () => _manualCheckIn(gClass, child.id, child.name),
                        tooltip: 'Відмітити присутність',
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
}
