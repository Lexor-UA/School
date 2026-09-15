import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium interactive 3D card that tilts in space on touch/drag/hover,
/// featuring a dynamic holographic iridescent sheen and specular lighting.
class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle; // In radians, default ~18 degrees (0.30 rad)
  final double perspective;
  final BorderRadius? borderRadius;
  final bool enableHologram;
  final VoidCallback? onTap;
  final Duration springDuration;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.28,
    this.perspective = 0.0015,
    this.borderRadius,
    this.enableHologram = false,
    this.onTap,
    this.springDuration = const Duration(milliseconds: 650),
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  // Normalized tilt coordinates from -1.0 to 1.0
  Offset _currentTilt = Offset.zero;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: widget.springDuration,
    );

    _springAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ))..addListener(() {
        setState(() {
          _currentTilt = _springAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event, BoxConstraints constraints) {
    _springController.stop();
    _isInteracting = true;
    _updateTilt(event.localPosition, constraints);
  }

  void _onPointerMove(PointerMoveEvent event, BoxConstraints constraints) {
    _updateTilt(event.localPosition, constraints);
  }

  void _onPointerUp(PointerUpEvent event) {
    _isInteracting = false;
    _releaseSpring();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isInteracting = false;
    _releaseSpring();
  }

  void _updateTilt(Offset localPosition, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    if (width <= 0 || height <= 0) return;

    // Convert to normalized space: (-1.0, -1.0) top-left, (1.0, 1.0) bottom-right
    final normalizedX = ((localPosition.dx / width) * 2.0 - 1.0).clamp(-1.0, 1.0);
    final normalizedY = ((localPosition.dy / height) * 2.0 - 1.0).clamp(-1.0, 1.0);

    setState(() {
      _currentTilt = Offset(normalizedX, normalizedY);
    });
  }

  void _releaseSpring() {
    _springAnimation = Tween<Offset>(
      begin: _currentTilt,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ));

    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rotX = -_currentTilt.dy * widget.maxTiltAngle;
        final rotY = _currentTilt.dx * widget.maxTiltAngle;

        // Dynamic 3D Matrix
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, widget.perspective)
          ..rotateX(rotX)
          ..rotateY(rotY);

        // Dynamic cast shadow shifting opposite to the tilt
        final shadowDx = -_currentTilt.dx * 16.0;
        final shadowDy = 10.0 - _currentTilt.dy * 12.0;
        final shadowBlur = 24.0 + (_isInteracting ? 8.0 : 0.0);

        return Listener(
          onPointerDown: (e) => _onPointerDown(e, constraints),
          onPointerMove: (e) => _onPointerMove(e, constraints),
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isInteracting ? 0.45 : 0.28),
                    blurRadius: shadowBlur,
                    offset: Offset(shadowDx, shadowDy),
                    spreadRadius: _isInteracting ? 2.0 : -2.0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: _isInteracting ? 0.22 : 0.10),
                    blurRadius: 28,
                    offset: Offset(shadowDx * 0.5, shadowDy * 0.5),
                  ),
                ],
              ),
              child: Transform(
                transform: matrix,
                alignment: FractionalOffset.center,
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      // 1. Base Child Content
                      widget.child,

                      // 2. Prismatic Holographic Sheen Layer
                      if (widget.enableHologram)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _HolographicOverlay(tilt: _currentTilt),
                          ),
                        ),

                      // 3. Specular Gloss Reflection Spot
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _SpecularReflectionOverlay(tilt: _currentTilt),
                        ),
                      ),

                      // 4. Ultra-Crisp Polished Glass Chamfer Border
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: 0.18 + (_currentTilt.distance * 0.18).clamp(0.0, 0.35),
                                ),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Holographic foil rainbow shimmer that glides dynamically with tilt angles
class _HolographicOverlay extends StatelessWidget {
  final Offset tilt;

  const _HolographicOverlay({required this.tilt});

  @override
  Widget build(BuildContext context) {
    final angle = math.atan2(tilt.dy, tilt.dx) + (math.pi / 4);
    final intensity = (0.22 + (tilt.distance * 0.28)).clamp(0.0, 0.55);

    final shiftX = -tilt.dx * 0.4;
    final shiftY = -tilt.dy * 0.4;

    return CustomPaint(
      painter: _HoloFoilPainter(
        angle: angle,
        intensity: intensity,
        shift: Offset(shiftX, shiftY),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _HoloFoilPainter extends CustomPainter {
  final double angle;
  final double intensity;
  final Offset shift;

  _HoloFoilPainter({
    required this.angle,
    required this.intensity,
    required this.shift,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;

    final rect = Offset.zero & size;

    // Prismatic spectral rainbow gradient
    final colors = [
      Colors.purpleAccent.withValues(alpha: intensity * 0.7),
      Colors.blueAccent.withValues(alpha: intensity * 0.85),
      Colors.cyanAccent.withValues(alpha: intensity * 0.95),
      const Color(0xFF10B981).withValues(alpha: intensity * 0.85),
      Colors.amberAccent.withValues(alpha: intensity * 0.95),
      Colors.redAccent.withValues(alpha: intensity * 0.8),
      Colors.purpleAccent.withValues(alpha: intensity * 0.7),
    ];

    final stops = [0.0, 0.18, 0.35, 0.52, 0.68, 0.85, 1.0];

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        begin: Alignment(
          math.cos(angle) - (shift.dx * 0.8),
          math.sin(angle) - (shift.dy * 0.8),
        ),
        end: Alignment(
          -math.cos(angle) - (shift.dx * 0.8),
          -math.sin(angle) - (shift.dy * 0.8),
        ),
        colors: colors,
        stops: stops,
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _HoloFoilPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.intensity != intensity ||
        oldDelegate.shift != shift;
  }
}

/// Specular glass gloss hotspot that tracks the light source
class _SpecularReflectionOverlay extends StatelessWidget {
  final Offset tilt;

  const _SpecularReflectionOverlay({required this.tilt});

  @override
  Widget build(BuildContext context) {
    final lightX = 0.5 + (tilt.dx * 0.5);
    final lightY = 0.5 + (tilt.dy * 0.5);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: FractionalOffset(lightX, lightY),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.24 + (tilt.distance * 0.12)),
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
    );
  }
}
