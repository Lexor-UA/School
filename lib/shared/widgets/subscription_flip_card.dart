import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:swimming_school_app/shared/widgets/subscription_front_card.dart';

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

  void _showFullScreenQr(BuildContext context, String qrData) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 280.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрити', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
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
    return SubscriptionFrontCard(currentSub: widget.currentSub);
  }

  Widget _buildBack() {
    final qrData = widget.currentSub?.userId ?? 'Unknown_User_ID';
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                        
                        Center(
                          child: GestureDetector(
                            onTap: () => _showFullScreenQr(context, qrData),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 90.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        const Text(
                          'Ця віртуальна картка є власністю City Swim і не підлягає передачі третім особам.',
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
