import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/animated_water_background.dart';
import '../widgets/lane_booking_sheet.dart';

class PoolMapScreen extends StatefulWidget {
  const PoolMapScreen({super.key});

  @override
  State<PoolMapScreen> createState() => _PoolMapScreenState();
}

class _PoolMapScreenState extends State<PoolMapScreen> {
  double _rotationX = 1.0;
  double _rotationZ = -0.5;
  String? _selectedSwimmer;
  int? _selectedLane;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Water
          const Positioned.fill(
            child: AnimatedWaterBackground(),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          // Interactive 3D Map
          Center(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationZ -= details.delta.dx * 0.01;
                  _rotationX += details.delta.dy * 0.01;
                  _rotationX = _rotationX.clamp(0.0, 1.5); // Limit tilt
                });
              },
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(_rotationX)
                  ..rotateZ(_rotationZ),
                alignment: Alignment.center,
                child: _build3DPoolVolumetric(),
              ),
            ),
          ),
          // Swimmer Tooltip Overlay (if selected)
          if (_selectedSwimmer != null) _buildSwimmerTooltip(),

          // UI Overlay Header
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: const EdgeInsets.all(24),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3D Карта Басейну',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'Проведіть пальцем для обертання',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Legend/Status
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMapStat(LucideIcons.thermometer, '28°C', 'Вода'),
                      _buildMapStat(LucideIcons.users, '12', 'Зараз'),
                      _buildMapStat(LucideIcons.droplets, '1.5-2m', 'Глибина'),
                    ],
                  ),
                ),
              ).animate().slideY(begin: 0.5, end: 0, delay: 400.ms),
          ),
        ],
      ),
    );
  }

  Widget _build3DPoolVolumetric() {
    return SizedBox(
      width: 260,
      height: 440,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. POOL STRUCTURE & BOTTOM
          Transform(
            transform: Matrix4.translationValues(0, 0, -20),
            child: _buildPoolBottom(),
          ),
          
          // 2. WATER SURFACE (Glassy)
          Transform(
            transform: Matrix4.translationValues(0, 0, 0),
            child: _buildWaterSurface(),
          ),
          
          // 3. INTERACTIVE LANES
          Transform(
            transform: Matrix4.translationValues(0, 0, 2),
            child: SizedBox(
              width: 260, height: 440,
              child: _buildInteractiveLanes(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolBottom() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
          BoxShadow(color: Colors.blue.shade900.withValues(alpha: 0.5), blurRadius: 60, spreadRadius: -10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Animated Water Base for extreme realism
            const Positioned.fill(
              child: AnimatedWaterBackground(),
            ),
            // Deep gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade900.withValues(alpha: 0.7),
                      Colors.cyan.shade800.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Lanes (Glowing pulsing lines)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return Container(
                  width: 3,
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  margin: const EdgeInsets.symmetric(vertical: 20),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.4, end: 1.0, duration: 2.seconds);
              }),
            ),
            // Inner shadow for depth
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  radius: 1.8,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSurface() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
            children: [
              // Ropes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return CustomPaint(
                    size: const Size(4, 500),
                    painter: RopePainter(),
                  );
                }),
              ),
              // Subtle reflections
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).slide(
                begin: const Offset(-1.0, -1.0),
                end: const Offset(1.0, 1.0),
                duration: 6.seconds,
              ),
            ],
          ),
        ),
    );
  }



  Widget _buildSwimmerTooltip() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSwimmer ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Швидкість: 1.2 м/с  |  Пульс: 120 bpm',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () {
                    setState(() => _selectedSwimmer = null);
                  },
                )
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.2),
    );
  }

  Widget _buildMapStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildInteractiveLanes() {
    return Row(
      children: List.generate(5, (index) {
        bool isSelected = _selectedLane == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLane = index;
                _selectedSwimmer = null; // deselect swimmer
              });
              _showBookingSheet(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.cyanAccent.withValues(alpha: 0.2) 
                  : Colors.transparent,
                border: Border(
                  left: BorderSide(color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.8) : Colors.transparent, width: 2),
                  right: BorderSide(color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.8) : Colors.transparent, width: 2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)
                ] : [],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showBookingSheet(int laneIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LaneBookingSheet(laneIndex: laneIndex),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _selectedLane = null);
      }
    });
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background base (Deep Teal/Blue gradient)
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.cyan.shade900, const Color(0xFF001524)],
        center: Alignment.center,
        radius: 1.5,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final tilePaint = Paint()..style = PaintingStyle.fill;
    const double tileSize = 12;
    const double spacing = 2;

    for (double i = 0; i < size.width; i += (tileSize + spacing)) {
      for (double j = 0; j < size.height; j += (tileSize + spacing)) {
        // Pseudo-random light variations for mosaic effect
        int randomVal = ((i * 17) + (j * 11)).toInt() % 100;
        
        if (randomVal < 10) {
          tilePaint.color = Colors.cyanAccent.withValues(alpha: 0.6); // Bright highlights
        } else if (randomVal < 35) {
          tilePaint.color = Colors.blue.shade400.withValues(alpha: 0.3); // Mid tones
        } else {
          tilePaint.color = Colors.transparent; // Let deep background show through
        }
        
        // Use RRect for softer, premium looking tiles
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(i, j, tileSize, tileSize), const Radius.circular(2)), 
          tilePaint
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    // Draw dashed line
    const double dashWidth = 10;
    const double dashSpace = 10;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        wirePaint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
