import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:swimming_school_app/shared/widgets/subscription_front_card.dart';
import 'package:swimming_school_app/shared/widgets/interactive_3d_card.dart';

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _showFullScreenQr(BuildContext context, String qrData) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                label: const Text(
                  'Закрити',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 3D Perspective Matrix for the 180 flip
        final flipMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0018)
          ..rotateY(_animation.value * math.pi);

        // Smooth elevation scale dip during the flip
        final scale = 1.0 - (0.12 * math.sin(_animation.value * math.pi));

        final isFrontSide = _animation.value < 0.5;

        return Transform(
          transform: flipMatrix,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: isFrontSide
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          ),
        );
      },
    ).animate().slideY(begin: 0.08, end: 0, duration: 500.ms, curve: Curves.easeOutQuart).fadeIn();
  }

  Widget _buildFront() {
    return SubscriptionFrontCard(
      currentSub: widget.currentSub,
      isInteractive: true,
      onTap: _toggleFlip,
    );
  }

  Widget _buildBack() {
    final qrData = widget.currentSub?.userId ?? 'Unknown_User_ID';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: AspectRatio(
          aspectRatio: 1.58,
          child: Interactive3DCard(
            enableHologram: false,
            onTap: _toggleFlip,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/modern_matte_texture.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1.5),
              ),
              child: Stack(
                children: [
                  // Ambient back glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0284C7).withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CITY SWIM PASS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 2.8,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1))],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.shieldCheck, color: Colors.cyanAccent, size: 12),
                                  SizedBox(width: 4),
                                  Text('ВЕРИФІКОВАНО', style: TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Center QR Code with Glowing Frame
                        Center(
                          child: GestureDetector(
                            onTap: () => _showFullScreenQr(context, qrData),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 84.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Торкніться для перевороту · Натисніть QR для збільшення',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          'Ця цифрова картка є власністю басейну. Пред\'явіть QR-код тренеру або адміністратору на ресепшені.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 8.5,
                            height: 1.3,
                            shadows: const [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(1, 1))],
                          ),
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
