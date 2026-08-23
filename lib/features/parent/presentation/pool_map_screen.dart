import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';

class PoolMapScreen extends StatefulWidget {
  final int? targetLane;
  final String? groupName;
  final String? coachName;
  final String? timeSlot;

  const PoolMapScreen({
    super.key,
    this.targetLane = 2, // Defaulting to 2 for demonstration
    this.groupName = 'Юніори Pro',
    this.coachName = 'Олександр В.',
    this.timeSlot = '16:00 - 17:00',
  });

  @override
  State<PoolMapScreen> createState() => _PoolMapScreenState();
}

class _PoolMapScreenState extends State<PoolMapScreen> {
  double _rotationX = 1.0;
  double _rotationZ = -0.5;
  int? _selectedLane;

  @override
  void initState() {
    super.initState();
    _selectedLane = widget.targetLane;
  }

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
          // UI Overlay Header

          // UI Overlay Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 32,
                left: 16,
                right: 24
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3D Карта Басейну',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ).animate().fadeIn().slideY(begin: -0.2),
                        const SizedBox(height: 4),
                        const Text(
                          'Проведіть пальцем для обертання',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Legend (Floating)
          if (_selectedLane != widget.targetLane)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: _buildLegend(),
            ),
            
          // Bottom Info Panel (Floating)
          if (_selectedLane == widget.targetLane)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: _buildPremiumClassInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMapStat(LucideIcons.mapPin, 'Доріжка ${(widget.targetLane ?? 0) + 1}', 'Локація'),
                _buildMapStat(LucideIcons.clock, '16:00', 'Час'),
                _buildMapStat(LucideIcons.thermometer, '28°C', 'Вода'),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: 0.5, end: 0, delay: 400.ms);
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



  Widget _buildPremiumClassInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 20)],
                    ),
                    child: const Icon(LucideIcons.waves, color: Colors.cyanAccent, size: 28)
                      .animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.seconds),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
                            ],
                          ),
                          child: Text(
                            'ДОРІЖКА ${(widget.targetLane ?? 0) + 1}  •  МАРІЯ',
                            style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.groupName ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => setState(() => _selectedLane = null),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(LucideIcons.user, 'Тренер', widget.coachName ?? ''),
                    Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1)),
                    _buildInfoItem(LucideIcons.clock, 'Час', widget.timeSlot ?? ''),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        )
      ],
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
        bool isTarget = widget.targetLane == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLane = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isTarget 
                  ? Colors.cyanAccent.withValues(alpha: 0.2) 
                  : (isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                border: Border(
                  left: BorderSide(
                    color: isTarget ? Colors.cyanAccent.withValues(alpha: 0.8) : (isSelected ? Colors.white.withValues(alpha: 0.4) : Colors.transparent), 
                    width: isTarget ? 2 : (isSelected ? 1 : 0)
                  ),
                  right: BorderSide(
                    color: isTarget ? Colors.cyanAccent.withValues(alpha: 0.8) : (isSelected ? Colors.white.withValues(alpha: 0.4) : Colors.transparent), 
                    width: isTarget ? 2 : (isSelected ? 1 : 0)
                  ),
                ),
                boxShadow: isTarget ? [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 0)
                ] : [],
              ),
              child: isTarget ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5,0.5), end: const Offset(1.5,1.5)).fade(begin: 1, end: 0, duration: 2.seconds),
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.cyanAccent, width: 2),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 20)],
                        ),
                        child: const Icon(LucideIcons.user, color: Colors.cyanAccent, size: 24),
                      ),
                    ],
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.15, end: 0.15, duration: 2.seconds),
                  Container(
                    width: 3, height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.cyanAccent, Colors.cyanAccent.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      )
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1, duration: 2.seconds)
                ],
              ) : null,
            ),
          ),
        );
      }),
    );
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
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke;
      
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Glowing beam line
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), glowPaint);
    
    // Core dashed line to mimic hi-tech ropes
    const double dashWidth = 15;
    const double dashSpace = 15;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        corePaint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
