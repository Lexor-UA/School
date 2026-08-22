import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;

class SubscriptionFlipCard extends StatefulWidget {
  final dynamic currentSub;

  const SubscriptionFlipCard({super.key, this.currentSub});

  @override
  State<SubscriptionFlipCard> createState() => _SubscriptionFlipCardState();
}

class _SubscriptionFlipCardState extends State<SubscriptionFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Increase perspective depth
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.002) // more 3D depth
            ..rotateY(_animation.value * math.pi);

          // Add a subtle scale effect that shrinks the card slightly in the middle of the flip
          final scale = 1.0 - (0.15 * math.sin(_animation.value * math.pi));

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                child: _animation.value < 0.5
                    ? _buildFront()
                    : Transform(
                        transform: Matrix4.identity()..rotateY(math.pi),
                        alignment: Alignment.center,
                        child: _buildBack(),
                      ),
              ),
            ),
          );
        },
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart).fadeIn();
  }

  Widget _buildFront() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AspectRatio(
          aspectRatio: 1.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/modern_matte_texture.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Glossy Glass Reflection
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Sweeping sheen
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(begin: const Offset(-1.2, -1.2), end: const Offset(1.2, 1.2), duration: 3.seconds, curve: Curves.easeInOutSine),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: PREMIUM PASS badge and NFC icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.cyan.shade600, Colors.cyan.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.cyan.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: const Text(
                                'PREMIUM PASS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: const Icon(LucideIcons.radio, color: Colors.white70, size: 20)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .fade(begin: 0.5, end: 1.0, duration: 1.seconds),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        const Text(
                          'Aqua Pro Elite',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Remaining Classes
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${widget.currentSub?.remainingClasses ?? 8}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 2))],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/ ${widget.currentSub?.totalClasses ?? 10} занять',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))],
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Bottom row: Valid until
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ДІЄ ДО',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 9,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1))],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '15 ЛИСТ 2026',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AspectRatio(
          aspectRatio: 1.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/modern_matte_texture.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CITY SWIM', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 3.0, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))])),
                            Icon(LucideIcons.shieldCheck, color: Colors.cyan, size: 18),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            // Barcode simulation
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(35, (index) => Container(
                                width: index % 4 == 0 ? 3 : (index % 3 == 0 ? 2 : (index % 5 == 0 ? 5 : 1)),
                                height: 45,
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                color: Colors.black,
                              )),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text('9283 4812 0001 8421', 
                            style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 4.0, fontFamily: 'monospace', fontWeight: FontWeight.w600)
                          ),
                        ),
                        
                        const Spacer(),
                        
                        const Text(
                          'Ця картка є власністю City Swim і не підлягає передачі третім особам. При знахідці або втраті зверніться до адміністратора клубу.',
                          style: TextStyle(color: Colors.white70, fontSize: 9, height: 1.4, shadows: [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1))]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
