import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_isScanned || _isProcessing) return;
    setState(() {
      _isScanned = true;
      _isProcessing = true;
    });

    final success = await ref.read(subscriptionControllerProvider.notifier).deductClass(code.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('coach.qr_accepted'.tr(args: [code]))),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('coach.qr_error'.tr())),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isScanned = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09182B),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'coach.qr_access_control'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'coach.qr_scan_sub'.tr(),
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (!kIsWeb)
                    GestureDetector(
                      onTap: () {
                        cameraController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isTorchOn
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isTorchOn ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Icon(
                          _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                          color: _isTorchOn ? const Color(0xFF00E5FF) : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scanner Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: MobileScanner(
                          controller: cameraController,
                          onDetect: (capture) {
                            if (_isScanned) return;
                            final barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final code = barcodes.first.rawValue;
                              if (code != null && code.isNotEmpty) {
                                _processCode(code);
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    // Aim Reticle Overlay
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Sweeping laser animation
                          Positioned.fill(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveY(begin: -100, end: 100, duration: 1500.ms),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessing)
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFF09182B).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Manual Code Entry Sheet for Web / Fallback
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1D33).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'coach.qr_manual_heading'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: TextField(
                            controller: _manualCodeController,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'coach.qr_manual_hint'.tr(),
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              prefixIcon: const Icon(LucideIcons.keyRound, color: Color(0xFF00E5FF), size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) _processCode(val.trim());
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          final code = _manualCodeController.text.trim();
                          if (code.isNotEmpty) _processCode(code);
                        },
                        child: Text('coach.qr_enter'.tr(), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
