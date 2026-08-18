import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/water_particles.dart'; 

class TrophyRoomScreen extends StatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.75);
  double _currentPage = 0.0;
  late AnimationController _rotationController;

  final List<Map<String, dynamic>> _trophies = [
    {
      'title': 'Золотий Дельфін',
      'description': 'За ідеальну техніку Батерфляй',
      'date': '15 Серпня 2026',
      'colors': [Colors.amberAccent, Colors.orange],
      'icon': LucideIcons.trophy,
      'unlocked': true,
    },
    {
      'title': 'Швидка Акула',
      'description': '100 метрів Кролем менш ніж за 1:20',
      'date': '2 Вересня 2026',
      'colors': [Colors.cyanAccent, Colors.blueAccent],
      'icon': LucideIcons.medal,
      'unlocked': true,
    },
    {
      'title': 'Майстер Глибин',
      'description': 'Здано норматив із затримки дихання (2 хвилини)',
      'date': 'Заблоковано',
      'colors': [Colors.grey.shade400, Colors.grey.shade700],
      'icon': LucideIcons.lock,
      'unlocked': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _rotationController.addListener(() {
      if (mounted) setState(() {});
    });
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B), 
      body: Stack(
        children: [
          // Background ambient light
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.indigo.shade900.withValues(alpha: 0.3),
                    const Color(0xFF030D1B),
                  ],
                  center: Alignment.center,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          // Confetti / Particles
          const Positioned.fill(
            child: WaterParticles(), 
          ),
          
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
                        'Кімната Трофеїв',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'Ваші досягнення та нагороди',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // 3D Carousel
                Expanded(
                  child: PageView.builder(
                    physics: const BouncingScrollPhysics(),
                      controller: _pageController,
                      itemCount: _trophies.length,
                      itemBuilder: (context, index) {
                        double difference = index - _currentPage;
                        double scale = 1.0 - (difference.abs() * 0.2);
                        double opacity = 1.0 - (difference.abs() * 0.5);
                        opacity = opacity.clamp(0.0, 1.0);
                        scale = scale.clamp(0.8, 1.0);

                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: _buildTrophyItem(_trophies[index], index == _currentPage.round()),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyItem(Map<String, dynamic> trophy, bool isActive) {
    bool isUnlocked = trophy['unlocked'];
    List<Color> colors = trophy['colors'];

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateY(isActive ? (math.sin(_rotationController.value * math.pi * 2) * 0.35) : 0),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Holographic Glass Shield
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Aura Behind Shield
                if (isUnlocked)
                  Container(
                    width: 200,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(color: colors[0].withValues(alpha: 0.5), blurRadius: 60, spreadRadius: 10),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 2.seconds),
                
                // The Shield itself
                Container(
                  width: 220,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isUnlocked ? colors[1].withValues(alpha: 0.8) : Colors.white24, width: 2),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        isUnlocked ? colors[0].withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: isUnlocked ? [
                      BoxShadow(color: colors[0].withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
                    ] : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Sweeping holographic reflection
                          if (isUnlocked)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.5),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).slide(begin: const Offset(-1, -1), end: const Offset(1, 1), duration: 3.seconds),
                            ),
                          
                          // Inner flare
                          if (isUnlocked)
                            Positioned(
                              top: -40,
                              right: -40,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors[0].withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          
                          // The Trophy Icon
                          Center(
                            child: Icon(
                              trophy['icon'],
                              size: 110,
                              color: isUnlocked ? Colors.white : Colors.white38,
                              shadows: isUnlocked ? [
                                Shadow(color: colors[0], blurRadius: 20),
                                Shadow(color: colors[1], blurRadius: 40),
                              ] : [],
                            ).animate(onPlay: (c) => isUnlocked ? c.repeat(reverse: true) : null)
                             .moveY(begin: -5, end: 5, duration: 2.seconds),
                          ),
                          
                          // Level Stars at the bottom of the card
                          if (isUnlocked)
                            Positioned(
                              bottom: 24,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Icon(LucideIcons.star, color: Colors.amberAccent, size: 20, shadows: [Shadow(color: Colors.amber, blurRadius: 10)])
                                    .animate(delay: (i * 200).ms, onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 1.seconds),
                                )),
                              ),
                            )
                        ],
                      ),
                    ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // The Pedestal (moved under the shield and made more elegant)
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(1.3), // Lay it flat
            alignment: Alignment.center,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [isUnlocked ? colors[0].withValues(alpha: 0.5) : Colors.white10, Colors.transparent],
                ),
                border: Border.all(color: isUnlocked ? colors[1].withValues(alpha: 0.4) : Colors.white24, width: 2),
                boxShadow: isUnlocked ? [
                  BoxShadow(color: colors[1].withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                ] : [],
              ),
            ),
          ).animate().slideY(begin: -0.5, end: 0, duration: 1.seconds, curve: Curves.easeOutBack),
          
          const SizedBox(height: 24),
          
          // Info Card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      trophy['title'],
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white54,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      trophy['description'],
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUnlocked ? colors[0].withValues(alpha: 0.2) : Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isUnlocked ? colors[0].withValues(alpha: 0.5) : Colors.transparent),
                      ),
                      child: Text(
                        isUnlocked ? 'Здобуто: ${trophy['date']}' : trophy['date'],
                        style: TextStyle(
                          color: isUnlocked ? colors[0] : Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
