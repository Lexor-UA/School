import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
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
          Align(
            alignment: const Alignment(0, -0.1), // Shift slightly up to avoid bottom panel
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationZ -= details.delta.dx * 0.01;
                  _rotationX += details.delta.dy * 0.01;
                  _rotationX = _rotationX.clamp(0.0, 1.1); // Limit tilt to avoid extreme side angles
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
          // 1. POOL BOTTOM (Deep)
          Transform(
            transform: Matrix4.translationValues(0, 0, -20),
            child: _buildPoolBottom(),
          ),
          
          // 2. WATER SURFACE & ROPES
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
          
          // 3.5 POOL WALLS (To hide the Z-gaps)
          _buildPoolWalls(),
          
          // 4. POOL BORDER (Tiles on top to hide edges and add depth)
          Transform(
            transform: Matrix4.translationValues(0, 0, 4),
            child: Container(
              width: 260, height: 440,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.shade600, width: 8),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2), // Outer glow
                ],
              ),
              // Inner shadow effect using gradient
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade900.withValues(alpha: 0.3), width: 2),
                ),
              ),
            ),
          ),

          // 5. STARTING BLOCKS
          Positioned(
            top: -12, left: 8, right: 8, // Fit inside the border
            child: Transform(
              transform: Matrix4.translationValues(0, 0, 10),
              child: _buildStartingBlocks(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolWalls() {
    final Color wallColor = Colors.blue.shade900.withValues(alpha: 0.95); // Dark basin walls
    const double poolDepth = 24.0; // Distance between -20 and 4
    const double poolWidth = 260.0;
    const double poolHeight = 440.0;
    const double borderZ = 4.0; // The Z of the top border
    const double inset = 6.0; // Inset to hide sharp corners under the rounded border

    return Stack(
      children: [
        // Left Wall
        Positioned(
          left: inset,
          top: inset,
          child: Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(0.0, 0.0, borderZ)
              ..rotateY(pi / 2),
            alignment: Alignment.centerLeft,
            child: Container(
              width: poolDepth,
              height: poolHeight - (inset * 2),
              color: wallColor,
            ),
          ),
        ),
        // Right Wall
        Positioned(
          right: inset,
          top: inset,
          child: Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(0.0, 0.0, borderZ)
              ..rotateY(-pi / 2),
            alignment: Alignment.centerRight,
            child: Container(
              width: poolDepth,
              height: poolHeight - (inset * 2),
              color: wallColor,
            ),
          ),
        ),
        // Top Wall
        Positioned(
          left: inset,
          top: inset,
          child: Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(0.0, 0.0, borderZ)
              ..rotateX(-pi / 2),
            alignment: Alignment.topCenter,
            child: Container(
              width: poolWidth - (inset * 2),
              height: poolDepth,
              color: wallColor,
            ),
          ),
        ),
        // Bottom Wall
        Positioned(
          left: inset,
          bottom: inset,
          child: Transform(
            transform: Matrix4.identity()
              ..setTranslationRaw(0.0, 0.0, borderZ)
              ..rotateX(pi / 2),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: poolWidth - (inset * 2),
              height: poolDepth,
              color: wallColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartingBlocks() {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Center(
            child: Container(
              width: 22,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade200, // Lighter plastic/metal blocks
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                border: Border.all(color: Colors.black54, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 4)),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPoolBottom() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0096C7), // Bright azure
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.15), blurRadius: 50, spreadRadius: 15),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Base gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.shade400,
                      Colors.blue.shade600,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Animated Water Base
            const Positioned.fill(
              child: AnimatedWaterBackground(),
            ),
            // T-shaped lane markers
            Positioned.fill(
              child: CustomPaint(
                painter: PoolBottomPainter(),
              ),
            ),
            // Inner shadow for depth
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                  radius: 1.5,
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
        color: Colors.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
            children: [
              // Ropes (5 ropes for 6 lanes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8), // Keep ropes from touching border directly
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return CustomPaint(
                      size: const Size(4, 500),
                      painter: RopePainter(),
                    );
                  }),
                ),
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      'ДОРІЖКА ${(widget.targetLane ?? 0) + 1} • МАРІЯ',
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.groupName ?? '', 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedLane = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.user, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text(widget.coachName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.clock, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text(widget.timeSlot ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              )
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
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
      children: List.generate(6, (index) { // 6 Lanes
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
                  ? Colors.white.withValues(alpha: 0.15) 
                  : (isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
                border: Border(
                  left: BorderSide(
                    color: isTarget ? Colors.white.withValues(alpha: 0.6) : (isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent), 
                    width: isTarget ? 2 : (isSelected ? 1 : 0)
                  ),
                  right: BorderSide(
                    color: isTarget ? Colors.white.withValues(alpha: 0.6) : (isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent), 
                    width: isTarget ? 2 : (isSelected ? 1 : 0)
                  ),
                ),
                boxShadow: isTarget ? [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 0)
                ] : [],
              ),
              child: isTarget ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.5),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5,0.5), end: const Offset(1.5,1.5)).fade(begin: 1, end: 0, duration: 2.seconds),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.cyanAccent, width: 2),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.8), blurRadius: 20)],
                        ),
                        child: const Icon(LucideIcons.user, color: Colors.cyanAccent, size: 20),
                      ),
                    ],
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.15, end: 0.15, duration: 2.seconds),
                  Container(
                    width: 2, height: 70,
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

class PoolBottomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003049).withValues(alpha: 0.6) // Dark deep blue T-markers
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double laneWidth = size.width / 6; // 6 lanes
    for (int i = 0; i < 6; i++) {
      double centerX = (i * laneWidth) + (laneWidth / 2);
      // Main central line
      canvas.drawLine(Offset(centerX, 40), Offset(centerX, size.height - 40), paint);
      // Top T-bar
      canvas.drawLine(Offset(centerX - 8, 40), Offset(centerX + 8, 40), paint);
      // Bottom T-bar
      canvas.drawLine(Offset(centerX - 8, size.height - 40), Offset(centerX + 8, size.height - 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Drop shadow for the rope
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(size.width / 2 + 2, 0), Offset(size.width / 2 + 2, size.height), shadowPaint);

    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final redPaint = Paint()
      ..color = Colors.red.shade600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    double startY = 0;
    bool isRed = false;
    
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        isRed ? redPaint : whitePaint,
      );
      startY += dashWidth;
      isRed = !isRed;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
