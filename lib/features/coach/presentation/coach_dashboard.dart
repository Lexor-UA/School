import 'dart:ui';
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

class CoachDashboard extends ConsumerStatefulWidget {
  const CoachDashboard({super.key});

  @override
  ConsumerState<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends ConsumerState<CoachDashboard> {
  // Dummy attendees list with extended data
  final List<Map<String, dynamic>> _attendees = [
    {'id': '1', 'name': 'Лев М.', 'status': 'coach.status_expected'.tr(), 'level': 'Pro', 'avatarColor': Colors.purpleAccent},
    {'id': '2', 'name': 'Мія К.', 'status': 'coach.status_present_f'.tr(), 'level': 'coach.level_beginner'.tr(), 'avatarColor': Colors.pinkAccent},
    {'id': '3', 'name': 'Ноа С.', 'status': 'coach.status_present_m'.tr(), 'level': 'coach.level_intermediate'.tr(), 'avatarColor': Colors.orangeAccent},
    {'id': '4', 'name': 'Емма Т.', 'status': 'coach.status_expected'.tr(), 'level': 'Pro', 'avatarColor': Colors.cyanAccent},
    {'id': '5', 'name': 'Артем Д.', 'status': 'coach.status_expected'.tr(), 'level': 'coach.level_intermediate'.tr(), 'avatarColor': Colors.blueAccent},
  ];

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  void _manualCheckIn(int index) {
    setState(() {
      _attendees[index]['status'] = 'coach.status_present_m'.tr();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_attendees[index]['name']} ${'coach.marked_manually'.tr()}'),
        backgroundColor: Colors.greenAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _leaveNote(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'coach.note_added'.tr()}: ${_attendees[index]['name']}'),
        backgroundColor: Colors.cyan.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final presentCount = _attendees.where((a) => a['status'] == 'coach.status_present_m'.tr() || a['status'] == 'coach.status_present_f'.tr()).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('coach.title'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
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
                          radius: 36, // Slightly larger avatar
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'coach.hello'.tr()}, ${user?.name ?? 'Олексій'}!',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                            Text(
                              'coach.group_juniors'.tr(),
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
                      Expanded(child: _buildGlassStat('coach.students'.tr(), '${_attendees.length}', LucideIcons.users, Colors.cyanAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGlassStat('coach.attendance'.tr(), '${((presentCount / _attendees.length) * 100).toInt()}%', LucideIcons.activity, Colors.greenAccent)),
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
                  
                  ref.watch(scheduleControllerProvider).when(
                    data: (classes) {
                      final coachClasses = classes.where((c) => c.coachId == user?.id).toList();
                      if (coachClasses.isEmpty) {
                        return const Text('Немає занять на сьогодні', style: TextStyle(color: Colors.white70));
                      }
                      
                      return SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          children: coachClasses.map((c) {
                            final time = '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildPremiumClassChip(time: time, name: c.title, isActive: true).animate().slideX(begin: 0.2, end: 0, delay: 400.ms).fadeIn(),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => const Text('Помилка завантаження'),
                  ),
                  
                  const SizedBox(height: 40),

                  // Attendees List
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
                          '$presentCount / ${_attendees.length}',
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
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList.builder(
              itemCount: _attendees.length,
              itemBuilder: (context, index) {
                return _buildAttendeeCard(_attendees[index], index).animate().fadeIn(delay: (800 + index * 100).ms).slideX(begin: 0.1, end: 0);
              },
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // padding for bottom nav
        ],
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
              // Glass Background
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
              // Scanning sweep reflection
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
              // Content
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

  Widget _buildAttendeeCard(Map<String, dynamic> attendee, int index) {
    bool isPresent = attendee['status'] == 'coach.status_present_m'.tr() || attendee['status'] == 'coach.status_present_f'.tr();
    Color avatarColor = attendee['avatarColor'];

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
          child: Dismissible(
              key: Key(attendee['id']),
              background: _buildDismissBackground(Colors.greenAccent, LucideIcons.checkSquare, Alignment.centerLeft),
              secondaryBackground: _buildDismissBackground(Colors.cyanAccent, LucideIcons.messageSquarePlus, Alignment.centerRight),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  if (!isPresent) _manualCheckIn(index);
                  return false;
                } else {
                  _leaveNote(index);
                  return false;
                }
              },
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
                        child: Text(attendee['name'][0], style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(attendee['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white, letterSpacing: 0.5)),
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
                                  attendee['status'], 
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
                                child: Text(attendee['level'], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isPresent) 
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 24),
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
                            onPressed: () => _manualCheckIn(index),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
  
  Widget _buildDismissBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: color, size: 32),
    );
  }
}
