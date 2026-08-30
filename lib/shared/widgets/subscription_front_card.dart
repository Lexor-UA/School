import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

class SubscriptionFrontCard extends StatelessWidget {
  final Subscription? currentSub;
  final VoidCallback? onTap;

  const SubscriptionFrontCard({super.key, this.currentSub, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
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
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
                          begin: const Offset(-1.2, -1.2),
                          end: const Offset(1.2, 1.2),
                          duration: 3.seconds,
                          curve: Curves.easeInOutSine),
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
                                    BoxShadow(
                                        color: Colors.cyan.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4)),
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
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentSub?.expiryDate != null
                                        ? DateFormat('dd.MM.yyyy').format(currentSub!.expiryDate!)
                                        : '00.00.0000',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
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
      ),
    );
  }
}
