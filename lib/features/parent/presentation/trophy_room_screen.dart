import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart'; 
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';

class TrophyRoomScreen extends ConsumerStatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  ConsumerState<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends ConsumerState<TrophyRoomScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;

  // Default static trophies if none are earned yet
  final List<Map<String, dynamic>> _defaultTrophies = [
    {
      'title': 'parent.master_of_depths'.tr(),
      'description': 'parent.breath_holding_passed'.tr(),
      'date': 'parent.locked'.tr(),
      'colors': [Colors.grey.shade400, Colors.grey.shade700],
      'icon': LucideIcons.lock,
      'unlocked': false,
    },
    {
      'title': 'parent.iron_endurance'.tr(),
      'description': 'parent.10_trainings_without_skips'.tr(),
      'date': 'parent.locked'.tr(),
      'colors': [Colors.grey.shade400, Colors.grey.shade700],
      'icon': LucideIcons.shieldAlert,
      'unlocked': false,
    }
  ];

  IconData _getIcon(String iconType) {
    switch (iconType) {
      case '🏆': return LucideIcons.trophy;
      case '🥷': return LucideIcons.sword;
      case '⭐': return LucideIcons.star;
      default: return LucideIcons.medal;
    }
  }

  List<Color> _getColors(String iconType) {
    switch (iconType) {
      case '🏆': return [Colors.amberAccent, Colors.orange];
      case '🥷': return [Colors.cyanAccent, Colors.blueAccent];
      case '⭐': return [Colors.yellowAccent, Colors.amber];
      default: return [Colors.purpleAccent, Colors.deepPurple];
    }
  }

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _rotationController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenControllerProvider);
    List<Map<String, dynamic>> _trophies = [];

    if (childrenAsync.value != null) {
      for (var child in childrenAsync.value!) {
        for (var achievement in child.achievements) {
          _trophies.add({
            'title': achievement.name,
            'description': achievement.description,
            'date': child.name, // Display child name instead of date
            'colors': _getColors(achievement.iconType),
            'icon': _getIcon(achievement.iconType),
            'unlocked': achievement.isUnlocked,
          });
        }
      }
    }
    
    if (_trophies.isEmpty) {
      _trophies = _defaultTrophies;
    }

    final int shelfCount = (_trophies.length / 2).ceil();

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),
          // Fluid transition overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.2), 
                    const Color(0xFF0F172A).withValues(alpha: 0.75)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                      Text(
                        'parent.trophy_showcase'.tr(),
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 8),
                      Text(
                        'parent.click_trophy_for_details'.tr(),
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 3D Cabinet View
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 40, bottom: 100),
                    itemCount: shelfCount,
                    itemBuilder: (context, index) {
                      int firstIndex = index * 2;
                      int secondIndex = firstIndex + 1;
                      
                      return _buildShelf(
                        context,
                        _trophies[firstIndex],
                        secondIndex < _trophies.length ? _trophies[secondIndex] : null,
                        index
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelf(BuildContext context, Map<String, dynamic> item1, Map<String, dynamic>? item2, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // The Shelf itself (3D glass platform)
          Positioned(
            bottom: -20,
            left: 16,
            right: 16,
            child: Container(
              height: 25,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.5)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5, offset: const Offset(0, -10)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 20, offset: const Offset(0, 25)),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          
          // The items on the shelf
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildCabinetTrophy(context, item1, index * 2),
              if (item2 != null) 
                _buildCabinetTrophy(context, item2, index * 2 + 1) 
              else 
                const SizedBox(width: 140),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 200).ms).slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildCabinetTrophy(BuildContext context, Map<String, dynamic> trophy, int index) {
    bool isUnlocked = trophy['unlocked'];
    List<Color> colors = trophy['colors'];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF071426),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: isUnlocked ? colors[0].withValues(alpha: 0.5) : Colors.white24, width: 2),
            ),
            title: Text(
              trophy['title'], 
              style: TextStyle(color: isUnlocked ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trophy['icon'], size: 80, color: isUnlocked ? colors[0] : Colors.white24),
                const SizedBox(height: 24),
                Text(trophy['description'], style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnlocked ? colors[0].withValues(alpha: 0.2) : Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isUnlocked ? colors[0].withValues(alpha: 0.5) : Colors.transparent),
                  ),
                  child: Text(
                    isUnlocked ? 'parent.unlocked_date'.tr(args: [trophy['date'].toString()]) : trophy['date'],
                    style: TextStyle(
                      color: isUnlocked ? colors[0] : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('parent.close'.tr(), style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating Trophy/Shield
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(isUnlocked ? (math.sin((_rotationController.value * math.pi * 2) + (index * 0.5)) * 0.25) : 0),
            alignment: Alignment.center,
            child: SizedBox(
              width: 140,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Base glow shadow on the shelf
                  if (isUnlocked)
                    Positioned(
                      bottom: -15,
                      child: Container(
                        width: 100,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(color: colors[0].withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 5),
                          ],
                        ),
                      ),
                    ),
                  
                  // The Glass Shield
                  Container(
                    width: 110,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isUnlocked ? colors[1].withValues(alpha: 0.8) : Colors.white24, width: 1.5),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          isUnlocked ? colors[0].withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: isUnlocked ? [
                        BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 15, spreadRadius: -5),
                      ] : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                                top: -20,
                                right: -20,
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors[0].withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                            
                            // The Trophy Icon
                            Center(
                              child: Icon(
                                trophy['icon'],
                                size: 55,
                                color: isUnlocked ? Colors.white : Colors.white38,
                                shadows: isUnlocked ? [
                                  Shadow(color: colors[0], blurRadius: 10),
                                  Shadow(color: colors[1], blurRadius: 20),
                                ] : [],
                              ).animate(onPlay: (c) => isUnlocked ? c.repeat(reverse: true) : null)
                               .moveY(begin: -5, end: 5, duration: 2.seconds),
                            ),
                            
                            // Level Stars at the bottom of the card
                            if (isUnlocked)
                              Positioned(
                                bottom: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Icon(LucideIcons.star, color: Colors.amberAccent, size: 12, shadows: const [Shadow(color: Colors.amber, blurRadius: 5)])
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
          ),
          const SizedBox(height: 12),
          // Name Plate
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              border: Border.all(color: isUnlocked ? colors[0].withValues(alpha: 0.5) : Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isUnlocked ? [BoxShadow(color: colors[0].withValues(alpha: 0.2), blurRadius: 5)] : [],
            ),
            child: Text(
              trophy['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
