import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FamilyQrScannerDialog extends StatefulWidget {
  const FamilyQrScannerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'FamilyQrScanner',
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const FamilyQrScannerDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<FamilyQrScannerDialog> createState() => _FamilyQrScannerDialogState();
}

class _FamilyQrScannerDialogState extends State<FamilyQrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    var clean = raw.trim().toUpperCase().replaceAll(' ', '');
    // If it's a URL or text containing FAM-, extract the FAM- part
    final famRegex = RegExp(r'FAM-?\d{4,8}');
    final match = famRegex.firstMatch(clean);
    if (match != null) {
      clean = match.group(0)!;
      if (!clean.startsWith('FAM-')) {
        clean = 'FAM-${clean.substring(3).replaceAll('-', '')}';
      }
    }

    setState(() => _isScanned = true);
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(clean);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: size.width * 0.90,
              height: size.height * 0.70,
              constraints: const BoxConstraints(
                maxWidth: 420,
                maxHeight: 560,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E32).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.scanLine, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Сканувати QR-код',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Підключення до сім\'ї',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (!kIsWeb)
                              IconButton(
                                icon: Icon(
                                  _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                                  color: _isTorchOn ? const Color(0xFF00E5FF) : Colors.white60,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _controller.toggleTorch();
                                  setState(() => _isTorchOn = !_isTorchOn);
                                },
                              ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scanner Body
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Camera Feed
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: MobileScanner(
                              controller: _controller,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) {
                                return Container(
                                  color: const Color(0xFF091424),
                                  padding: const EdgeInsets.all(20),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.cameraOff, color: Colors.white54, size: 40),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Камера недоступна',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Надайте доступ до камери у налаштуваннях пристрою для сканування QR-коду.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Animated Target Reticle
                        const _ScannerTargetReticle(),
                      ],
                    ),
                  ),

                  // Footer instruction
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.info, color: Color(0xFF00E5FF), size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Наведіть камеру на сімейний QR-код партнера',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

class _ScannerTargetReticle extends StatefulWidget {
  const _ScannerTargetReticle();

  @override
  State<_ScannerTargetReticle> createState() => _ScannerTargetReticleState();
}

class _ScannerTargetReticleState extends State<_ScannerTargetReticle> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const boxSize = 220.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          // 4 Glowing Corner Accents
          Positioned.fill(
            child: CustomPaint(
              painter: _ReticleCornersPainter(),
            ),
          ),

          // Animated Scanning Laser Bar
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final topOffset = _animController.value * (boxSize - 4);
              return Positioned(
                top: topOffset,
                left: 10,
                right: 10,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x0000E5FF),
                        Color(0xFF00E5FF),
                        Color(0xFF10B981),
                        Color(0xFF00E5FF),
                        Color(0x0000E5FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReticleCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 22.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
