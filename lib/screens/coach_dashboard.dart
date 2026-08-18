import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../controllers/auth_controller.dart';
import 'qr_scanner_screen.dart';

class CoachDashboard extends ConsumerStatefulWidget {
  const CoachDashboard({super.key});

  @override
  ConsumerState<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends ConsumerState<CoachDashboard> {
  // Dummy attendees list with extended data
  final List<Map<String, dynamic>> _attendees = [
    {'id': '1', 'name': 'Лев М.', 'status': 'Очікується', 'level': 'Pro', 'avatarColor': Colors.purpleAccent},
    {'id': '2', 'name': 'Мія К.', 'status': 'Присутня', 'level': 'Початківець', 'avatarColor': Colors.pinkAccent},
    {'id': '3', 'name': 'Ноа С.', 'status': 'Присутній', 'level': 'Середній', 'avatarColor': Colors.orangeAccent},
    {'id': '4', 'name': 'Емма Т.', 'status': 'Очікується', 'level': 'Pro', 'avatarColor': Colors.cyanAccent},
    {'id': '5', 'name': 'Артем Д.', 'status': 'Очікується', 'level': 'Середній', 'avatarColor': Colors.blueAccent},
  ];

  void _scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  void _manualCheckIn(int index) {
    setState(() {
      _attendees[index]['status'] = 'Присутній';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_attendees[index]['name']} відмічено вручну!'),
        backgroundColor: Colors.greenAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _leaveNote(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нотатку додано для: ${_attendees[index]['name']}'),
        backgroundColor: Colors.cyan.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final presentCount = _attendees.where((a) => a['status'] == 'Присутній' || a['status'] == 'Присутня').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Тренерська', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                            BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: -5),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1530549387789-4c1017266635?auto=format&fit=crop&q=80&w=400'),
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Привіт, ${user?.name ?? 'Олексій'}!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Ваша зміна почалася.',
                            style: TextStyle(color: Colors.cyanAccent, letterSpacing: 1),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Top Stats (Glassmorphism)
                  Row(
                    children: [
                      Expanded(child: _buildGlassStat('Учнів', '${_attendees.length}', LucideIcons.users, Colors.cyanAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildGlassStat('Присутність', '${((presentCount / _attendees.length) * 100).toInt()}%', LucideIcons.activity, Colors.greenAccent)),
                    ],
                  ).animate().slideY(begin: 0.2, end: 0, delay: 100.ms).fadeIn(),
                  const SizedBox(height: 32),

                  // Premium Scan Action Button
                  Center(
                    child: _buildPremiumScanButton(),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),

                  // Today's Classes
                  const Text(
                    'РОЗКЛАД НА СЬОГОДНІ',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildPremiumClassChip(time: '16:00', name: 'Юніори (Батерфляй)', isActive: true).animate().slideX(begin: 0.2, end: 0, delay: 400.ms).fadeIn(),
                        _buildPremiumClassChip(time: '17:30', name: 'Підлітки Pro', isActive: false).animate().slideX(begin: 0.2, end: 0, delay: 500.ms).fadeIn(),
                        _buildPremiumClassChip(time: '19:00', name: 'Дорослі', isActive: false).animate().slideX(begin: 0.2, end: 0, delay: 600.ms).fadeIn(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Attendees List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ГРУПА (16:00)',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
    );
  }

  Widget _buildPremiumScanButton() {
    return GestureDetector(
      onTap: _scanQR,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyanAccent.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.scanLine, color: Colors.cyanAccent, size: 28),
            const SizedBox(width: 12),
            const Text(
              'СКАНУВАТИ QR',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02), duration: 2.seconds);
  }

  Widget _buildPremiumClassChip({required String time, required String name, required bool isActive}) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1), width: isActive ? 2 : 1),
        boxShadow: isActive ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 15)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white70),
                    ),
                    if (isActive) 
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle))
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white54, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee, int index) {
    bool isPresent = attendee['status'] == 'Присутній' || attendee['status'] == 'Присутня';
    Color avatarColor = attendee['avatarColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPresent ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        boxShadow: isPresent ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.05), blurRadius: 10)] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: isPresent ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 10)] : [],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor.withValues(alpha: 0.2),
                      child: Text(attendee['name'][0], style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attendee['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(attendee['status'], style: TextStyle(color: isPresent ? Colors.greenAccent : Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(attendee['level'], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isPresent) 
                    const Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 28)
                  else
                    IconButton(
                      icon: const Icon(LucideIcons.userCheck, color: Colors.white54),
                      onPressed: () => _manualCheckIn(index),
                    ),
                ],
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
      child: Icon(icon, color: color, size: 28),
    );
  }
}
