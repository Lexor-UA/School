import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnatomyProgressScreen extends StatefulWidget {
  const AnatomyProgressScreen({super.key});

  @override
  State<AnatomyProgressScreen> createState() => _AnatomyProgressScreenState();
}

class _AnatomyProgressScreenState extends State<AnatomyProgressScreen> with TickerProviderStateMixin {
  String _selectedStyle = 'parent.style_crawl';
  late AnimationController _pulseController;
  late AnimationController _scanController;
  
  final Map<String, List<String>> _styleMuscles = {
    'parent.style_crawl': ['shoulders', 'arms', 'core'],
    'parent.style_breaststroke': ['legs', 'core', 'arms'],
    'parent.style_butterfly': ['shoulders', 'core', 'arms', 'legs'],
    'parent.style_backstroke': ['shoulders', 'legs'],
  };

  final Map<String, double> _progress = {
    'shoulders': 0.85,
    'core': 0.70,
    'arms': 0.60,
    'legs': 0.90,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A14), // Extremely deep tech blue
      body: Stack(
        children: [
          // Futuristic HUD Grid & Scanning Line Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return CustomPaint(painter: HUDPainter(_scanController.value));
              },
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(24),
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.cyanAccent, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(right: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.activity, color: Colors.cyanAccent, size: 16),
                            SizedBox(width: 8),
                            Text('parent.sensors_active'.tr(), style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1.seconds),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'parent.anatomy_progress_upper'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ).animate().fadeIn().slideX(begin: -0.1),
                        const SizedBox(height: 8),
                        Text(
                          'parent.biometric_analysis'.tr(),
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 10, letterSpacing: 2, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ).animate().fadeIn(delay: 200.ms).then().shimmer(duration: 2000.ms, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Style Selector (Tech Tabs)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _styleMuscles.keys.map((style) => _buildTechTab(style)).toList(),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 32),
                  
                  // 3D Hologram Area
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/sci_fi_swimmer_anatomy.jpg',
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: MediaQuery.of(context).size.width * 0.85,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Stats Panel
                  _buildTechStatsPanel().animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Moving Scanning Line over everything
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return CustomPaint(painter: ScanLinePainter(_scanController.value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechTab(String style) {
    bool isSelected = _selectedStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12), // Tech square look
          boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 15)] : [],
        ),
        child: Text(
          style.tr().toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTechStatsPanel() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF071426).withValues(alpha: 0.8),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.target, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 12),
                  Text('parent.active_muscle_groups'.tr(), style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              ..._styleMuscles[_selectedStyle]!.map((muscle) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('parent.$muscle'.tr().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          Text('${(_progress[muscle]! * 100).toInt()}%', style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4), // Tech sharp edges
                        child: LinearProgressIndicator(
                          value: _progress[muscle],
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
    );
  }
}

class AnatomyPainter extends CustomPainter {
  final List<String> activeMuscles;
  final Map<String, double> progress;
  final double pulseValue;

  AnatomyPainter({required this.activeMuscles, required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    
    void drawNode(String id, Offset position, double radius) {
      if (!activeMuscles.contains(id)) return;
      
      Paint outerGlow = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.2 + (pulseValue * 0.4))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        
      Paint innerRing = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (pulseValue * 1.5);
        
      Paint coreDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      double currentRadius = radius + (pulseValue * 5);
      
      canvas.drawCircle(position, currentRadius * 1.5, outerGlow);
      canvas.drawCircle(position, currentRadius, innerRing);
      canvas.drawCircle(position, 4, coreDot);
      
      Paint crosshair = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
        
      canvas.drawLine(Offset(position.dx - currentRadius, position.dy), Offset(position.dx + currentRadius, position.dy), crosshair);
      canvas.drawLine(Offset(position.dx, position.dy - currentRadius), Offset(position.dx, position.dy + currentRadius), crosshair);
    }
    
    // Left and right shoulders
    drawNode('shoulders', Offset(size.width * 0.25, h * 0.32), 15);
    drawNode('shoulders', Offset(size.width * 0.75, h * 0.32), 15);
    
    // Biceps / Arms
    drawNode('arms', Offset(size.width * 0.18, h * 0.55), 18);
    drawNode('arms', Offset(size.width * 0.82, h * 0.55), 18);
    
    // Core
    drawNode('core', Offset(size.width * 0.5, h * 0.75), 22);
    
    // Legs (Bottom)
    drawNode('legs', Offset(size.width * 0.40, h * 0.95), 16);
    drawNode('legs', Offset(size.width * 0.60, h * 0.95), 16);
  }

  @override
  bool shouldRepaint(covariant AnatomyPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.activeMuscles != activeMuscles;
  }
}

class HUDPainter extends CustomPainter {
  final double scanProgress;
  HUDPainter(this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Background Grid
    Paint gridPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    double step = 40;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // High-tech circular radar in the background
    Paint ringPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawCircle(center, size.width * 0.3, ringPaint);
    canvas.drawCircle(center, size.width * 0.5, ringPaint);
    canvas.drawCircle(center, size.width * 0.8, ringPaint);
    
    // Corner Tech Brackets (Crosshairs)
    Paint bracketPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    double bLen = 30; // bracket length
    // Top Left
    canvas.drawLine(const Offset(20, 20), Offset(20 + bLen, 20), bracketPaint);
    canvas.drawLine(const Offset(20, 20), Offset(20, 20 + bLen), bracketPaint);
    // Top Right
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20 - bLen, 20), bracketPaint);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20, 20 + bLen), bracketPaint);


  }


  @override
  bool shouldRepaint(covariant HUDPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}

class ScanLinePainter extends CustomPainter {
  final double scanProgress;
  ScanLinePainter(this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    double scanY = size.height * scanProgress;
    
    Paint scanLinePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, scanY, size.width, 2), scanLinePaint);
    
    // Laser Glow Trailing
    Paint scanGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.cyanAccent.withValues(alpha: 0.15), Colors.transparent]
      ).createShader(Rect.fromLTWH(0, scanY - 80, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 80, size.width, 80), scanGlowPaint);
  }

  @override
  bool shouldRepaint(covariant ScanLinePainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
