import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnatomyProgressScreen extends StatefulWidget {
  const AnatomyProgressScreen({super.key});

  @override
  State<AnatomyProgressScreen> createState() => _AnatomyProgressScreenState();
}

class _AnatomyProgressScreenState extends State<AnatomyProgressScreen> with TickerProviderStateMixin {
  String _selectedStyle = 'Кроль';
  late AnimationController _pulseController;
  late AnimationController _scanController;
  
  final Map<String, List<String>> _styleMuscles = {
    'Кроль': ['shoulders', 'arms', 'core'],
    'Брас': ['legs', 'core', 'arms'],
    'Батерфляй': ['shoulders', 'core', 'arms', 'legs'],
    'На спині': ['shoulders', 'legs'],
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
                      child: const Row(
                        children: [
                          Icon(LucideIcons.activity, color: Colors.cyanAccent, size: 16),
                          SizedBox(width: 8),
                          Text('СЕНСОРИ АКТИВНІ', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                      const Text(
                        'АНАТОМІЯ ПРОГРЕСУ',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2.5),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      const Text(
                        'БІОМЕТРИЧНИЙ АНАЛІЗ...',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 4, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ).animate().fadeIn(delay: 200.ms).then().shimmer(duration: 2000.ms, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Style Selector (Tech Tabs)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: _styleMuscles.keys.map((style) => _buildTechTab(style)).toList(),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                // 3D Hologram Area
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 350,
                      height: 550,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: AnatomyPainter(
                              activeMuscles: _styleMuscles[_selectedStyle]!,
                              progress: _progress,
                              pulseValue: _pulseController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Stats Panel
                _buildTechStatsPanel().animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
              ],
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
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12), // Tech square look
          boxShadow: isSelected ? [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: 15)] : [],
        ),
        child: Text(
          style.toUpperCase(),
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
              const Row(
                children: [
                  Icon(LucideIcons.target, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 12),
                  Text('АКТИВНІ М\'ЯЗОВІ ГРУПИ', style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
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
                          Text(muscle.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
    final center = size.width / 2;
    final h = size.height;
    
    // Helper to mirror paths for symmetry
    Path mirrorPath(Path source) {
      Matrix4 matrix = Matrix4.identity()
        ..translate(size.width, 0.0)
        ..scale(-1.0, 1.0, 1.0);
      return source.transform(matrix.storage);
    }
    
    void drawMuscle(String id, Path path) {
      bool isActive = activeMuscles.contains(id);
      
      Paint fillPaint = Paint()..style = PaintingStyle.fill;
        
      if (isActive) {
        fillPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyanAccent.withValues(alpha: 0.6 + (pulseValue * 0.3)),
            Colors.blueAccent.withValues(alpha: 0.3),
          ]
        ).createShader(path.getBounds());
      } else {
        fillPaint.color = Colors.white.withValues(alpha: 0.03);
      }
        
      Paint strokePaint = Paint()
        ..color = isActive ? Colors.cyanAccent.withValues(alpha: 0.8 + (pulseValue * 0.2)) : Colors.blueGrey.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2.5 : 1.0;
        
      if (isActive) {
        canvas.drawShadow(path, Colors.cyanAccent, 25, true);
      }
      
      canvas.drawPath(path, fillPaint);
      
      if (isActive) {
        // Inner tech lines for active muscles
        Paint innerStroke = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawPath(path, innerStroke);
      }
      canvas.drawPath(path, strokePaint);
    }

    // HEAD (Sleek swimmer cap look)
    Path head = Path()
      ..moveTo(center - 18, h * 0.05)
      ..quadraticBezierTo(center, h * 0.01, center + 18, h * 0.05)
      ..quadraticBezierTo(center + 24, h * 0.10, center + 15, h * 0.16)
      ..quadraticBezierTo(center, h * 0.20, center - 15, h * 0.16)
      ..quadraticBezierTo(center - 24, h * 0.10, center - 18, h * 0.05)
      ..close();
    
    // Head is always a static tech color
    canvas.drawPath(head, Paint()..color=Colors.blueGrey.withValues(alpha: 0.1)..style=PaintingStyle.fill);
    canvas.drawPath(head, Paint()..color=Colors.blueGrey.withValues(alpha: 0.5)..style=PaintingStyle.stroke..strokeWidth=1.5);

    // CHEST/SHOULDERS (Broad V-shape)
    Path shouldersLeft = Path()
      ..moveTo(center - 2, h * 0.19) // Gap in center
      ..lineTo(center - 18, h * 0.18) // Neck base
      ..quadraticBezierTo(center - 60, h * 0.18, center - 95, h * 0.25) // Top shoulder curve
      ..quadraticBezierTo(center - 110, h * 0.32, center - 110, h * 0.36) // Outer deltoid
      ..quadraticBezierTo(center - 80, h * 0.39, center - 55, h * 0.37) // Armpit
      ..quadraticBezierTo(center - 25, h * 0.39, center - 2, h * 0.36) // Under pec
      ..close();
    
    Path shouldersRight = mirrorPath(shouldersLeft);
    Path shoulders = Path()..addPath(shouldersLeft, Offset.zero)..addPath(shouldersRight, Offset.zero);
    drawMuscle('shoulders', shoulders);

    // CORE (Abs/Obliques, narrow waist)
    Path coreLeft = Path()
      ..moveTo(center - 2, h * 0.38)
      ..quadraticBezierTo(center - 25, h * 0.40, center - 52, h * 0.39) // Top edge
      ..quadraticBezierTo(center - 45, h * 0.50, center - 40, h * 0.63) // Outer waist taper
      ..lineTo(center - 2, h * 0.66) // Bottom edge
      ..close();
    
    Path coreRight = mirrorPath(coreLeft);
    Path core = Path()..addPath(coreLeft, Offset.zero)..addPath(coreRight, Offset.zero);
    drawMuscle('core', core);

    // ARMS (Biceps, Forearms)
    Path armsLeft = Path()
      ..moveTo(center - 60, h * 0.39) // Armpit 
      ..quadraticBezierTo(center - 100, h * 0.39, center - 114, h * 0.38) // Top shoulder separation
      ..quadraticBezierTo(center - 135, h * 0.50, center - 140, h * 0.68) // Outer arm curve
      ..quadraticBezierTo(center - 125, h * 0.70, center - 115, h * 0.68) // Wrist
      ..quadraticBezierTo(center - 90, h * 0.55, center - 80, h * 0.48) // Inner elbow
      ..lineTo(center - 60, h * 0.39)
      ..close();
      
    Path armsRight = mirrorPath(armsLeft);
    Path arms = Path()..addPath(armsLeft, Offset.zero)..addPath(armsRight, Offset.zero);
    drawMuscle('arms', arms);

    // LEGS (Thighs to calves)
    Path legsLeft = Path()
      ..moveTo(center - 4, h * 0.68) // Crotch area
      ..lineTo(center - 38, h * 0.65) // Outer hip
      ..quadraticBezierTo(center - 50, h * 0.85, center - 45, h * 1.0) // Outer leg
      ..lineTo(center - 15, h * 1.0) // Ankle
      ..quadraticBezierTo(center - 10, h * 0.85, center - 4, h * 0.68) // Inner leg
      ..close();
      
    Path legsRight = mirrorPath(legsLeft);
    Path legs = Path()..addPath(legsLeft, Offset.zero)..addPath(legsRight, Offset.zero);
    drawMuscle('legs', legs);
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
    // Bottom Left
    canvas.drawLine(Offset(20, size.height - 20), Offset(20 + bLen, size.height - 20), bracketPaint);
    canvas.drawLine(Offset(20, size.height - 20), Offset(20, size.height - 20 - bLen), bracketPaint);
    // Bottom Right
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20 - bLen, size.height - 20), bracketPaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20, size.height - 20 - bLen), bracketPaint);

    // Laser Scanning Line (Sweeping down)
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
  bool shouldRepaint(covariant HUDPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress;
  }
}
