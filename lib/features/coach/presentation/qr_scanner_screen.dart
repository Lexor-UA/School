import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/coach/models/qr_check_in_result.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final GroupClass? targetClass;
  const QrScannerScreen({super.key, this.targetClass});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  GroupClass? _selectedClass;
  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  bool _didAttendAny = false;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.targetClass;
  }

  @override
  void dispose() {
    cameraController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (_isScanned || _isProcessing) return;

    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Спочатку оберіть заняття для списання перепустки'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isScanned = true;
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    final coachUser = ref.read(authControllerProvider);
    final result = await ref.read(subscriptionControllerProvider.notifier).processQrCheckIn(
      code: code.trim(),
      targetClass: _selectedClass!,
      scanningCoachBranchId: coachUser?.branchId,
      scanningCoachBranchIds: coachUser?.branchIds,
    );

    if (!mounted) return;

    if (result.status == QrCheckInStatus.success) {
      _didAttendAny = true;
    }

    await _showResultModal(result);
  }

  void _showSelectClassSheet(List<GroupClass> classes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF0C1D33),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Оберіть заняття на сьогодні',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: classes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final c = classes[index];
                    final isSel = _selectedClass?.id == c.id;
                    return ListTile(
                      dense: true,
                      tileColor: isSel
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF00E5FF) : Colors.transparent,
                        ),
                      ),
                      title: Text(
                        c.title,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF00E5FF) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(c.startTime)} - ${DateFormat('HH:mm').format(c.endTime)}${c.lane.isNotEmpty ? ' • ${c.lane}' : ''}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      trailing: isSel ? const Icon(LucideIcons.check, color: Color(0xFF00E5FF), size: 18) : null,
                      onTap: () {
                        setState(() {
                          _selectedClass = c;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResultModal(QrCheckInResult result) async {
    final isSuccess = result.status == QrCheckInStatus.success;

    Color themeColor;
    IconData statusIcon;
    String statusTitle;

    switch (result.status) {
      case QrCheckInStatus.success:
        themeColor = const Color(0xFF10B981); // Emerald
        statusIcon = LucideIcons.checkCircle2;
        statusTitle = 'Заняття успішно зараховано!';
        break;
      case QrCheckInStatus.alreadyAttended:
        themeColor = const Color(0xFFF59E0B); // Amber
        statusIcon = LucideIcons.shieldAlert;
        statusTitle = 'Учень вже на занятті';
        break;
      case QrCheckInStatus.wrongDate:
        themeColor = const Color(0xFFF97316); // Orange
        statusIcon = LucideIcons.calendarClock;
        statusTitle = 'Невідповідна дата';
        break;
      case QrCheckInStatus.wrongService:
        themeColor = const Color(0xFFEF4444); // Red
        statusIcon = LucideIcons.badgeAlert;
        statusTitle = 'Невідповідний абонемент';
        break;
      case QrCheckInStatus.expiredOrEmpty:
        themeColor = const Color(0xFFEF4444);
        statusIcon = LucideIcons.clockAlert;
        statusTitle = 'Абонемент вичерпано';
        break;
      case QrCheckInStatus.notFound:
        themeColor = const Color(0xFFEF4444);
        statusIcon = LucideIcons.alertTriangle;
        statusTitle = 'Перепустку не знайдено';
        break;
    }

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1D33),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: themeColor.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Icon Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withValues(alpha: 0.15),
                  border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: themeColor, size: 32),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                statusTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    if (result.studentName != null && result.studentName!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.user, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          const Text('Клієнт:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          const Spacer(),
                          Text(
                            result.studentName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (result.classTitle != null) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          const Text('Заняття:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              result.classTitle!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (result.subServiceName != null) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.ticket, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          const Text('Абонемент:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              result.subServiceName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (result.remainingClasses != null) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.layers, color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 8),
                          const Text('Залишок занять:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${result.remainingClasses}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status message/explanation
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  result.message,
                  style: TextStyle(
                    color: isSuccess ? Colors.white70 : themeColor.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (isSuccess) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pop(context, true);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Завершити', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _isScanned = false;
                            _isProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Наступний', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _isScanned = false;
                        _isProcessing = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Сканувати інший QR', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allClasses = ref.watch(scheduleControllerProvider).asData?.value ?? [];
    final now = DateTime.now();
    final todayClasses = allClasses.where((c) {
      return c.startTime.year == now.year &&
          c.startTime.month == now.month &&
          c.startTime.day == now.day;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (_selectedClass == null && todayClasses.isNotEmpty) {
      _selectedClass = todayClasses.first;
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
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
                      onTap: () => Navigator.pop(context, _didAttendAny),
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

              // Selected Class Indicator Banner
              if (_selectedClass != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2644),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.calendarCheck, color: Color(0xFF00E5FF), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedClass!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('HH:mm').format(_selectedClass!.startTime)} - ${DateFormat('HH:mm').format(_selectedClass!.endTime)}${_selectedClass!.lane.isNotEmpty ? ' • ${_selectedClass!.lane}' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (todayClasses.length > 1)
                        TextButton(
                          onPressed: () => _showSelectClassSheet(todayClasses),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF00E5FF),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Змінити',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B0E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          todayClasses.isEmpty
                              ? 'Немає запланованих занять на сьогодні'
                              : 'Оберіть заняття для списання перепусток',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (todayClasses.isNotEmpty)
                        TextButton(
                          onPressed: () => _showSelectClassSheet(todayClasses),
                          child: const Text('Обрати', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),

            // Scanner Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scanSize = (constraints.maxWidth * 0.72).clamp(220.0, 270.0);
                    final centerOffset = Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2 - 20,
                    );
                    final cutoutRect = Rect.fromCenter(
                      center: centerOffset,
                      width: scanSize,
                      height: scanSize,
                    );

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                        ),
                        child: Stack(
                          children: [
                            // 1. Full camera feed
                            Positioned.fill(
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

                            // 2. Camera Cutout Dimming Mask
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CameraCutoutPainter(
                                  cutoutRect: cutoutRect,
                                  borderRadius: 22,
                                ),
                              ),
                            ),

                            // 3. Cyber Reticle & Laser in scan area
                            Positioned(
                              left: cutoutRect.left,
                              top: cutoutRect.top,
                              width: scanSize,
                              height: scanSize,
                              child: Stack(
                                children: [
                                  // Reticle corners, subtle frame & center crosshair
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _ScannerReticlePainter(),
                                    ),
                                  ),

                                  // Confined Laser Sweeper
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: _ScannerLaser(height: scanSize),
                                  ),
                                ],
                              ),
                            ),

                            // 4. Sleek HUD Instruction Badge
                            Positioned(
                              left: 20,
                              right: 20,
                              top: cutoutRect.bottom + 20,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF081324).withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E5FF),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'coach.qr_scan_hint'.tr(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 5. Processing overlay
                            if (_isProcessing)
                              Positioned(
                                left: cutoutRect.left,
                                top: cutoutRect.top,
                                width: scanSize,
                                height: scanSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      color: const Color(0xFF09182B).withValues(alpha: 0.82),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'common.loading'.tr(),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
    ),
  );
}
}

/// Darkens camera feed outside the target scanning square
class _CameraCutoutPainter extends CustomPainter {
  final Rect cutoutRect;
  final double borderRadius;

  const _CameraCutoutPainter({
    required this.cutoutRect,
    this.borderRadius = 22,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)));

    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CameraCutoutPainter oldDelegate) =>
      oldDelegate.cutoutRect != cutoutRect || oldDelegate.borderRadius != borderRadius;
}

/// Renders precision cyber reticle corners, outer frame and center crosshair
class _ScannerReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const cornerLength = 32.0;
    const cornerRadius = 22.0;

    // Subtle outer border
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius)), borderPaint);

    // Neon glowing corners (glow layer + crisp core layer)
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final cornerPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final corners = Path();

    // Top-Left
    corners.moveTo(0, cornerLength);
    corners.lineTo(0, cornerRadius);
    corners.arcToPoint(const Offset(cornerRadius, 0), radius: const Radius.circular(cornerRadius));
    corners.lineTo(cornerLength, 0);

    // Top-Right
    corners.moveTo(size.width - cornerLength, 0);
    corners.lineTo(size.width - cornerRadius, 0);
    corners.arcToPoint(Offset(size.width, cornerRadius), radius: const Radius.circular(cornerRadius));
    corners.lineTo(size.width, cornerLength);

    // Bottom-Right
    corners.moveTo(size.width, size.height - cornerLength);
    corners.lineTo(size.width, size.height - cornerRadius);
    corners.arcToPoint(Offset(size.width - cornerRadius, size.height), radius: const Radius.circular(cornerRadius));
    corners.lineTo(size.width - cornerLength, size.height);

    // Bottom-Left
    corners.moveTo(cornerLength, size.height);
    corners.lineTo(cornerRadius, size.height);
    corners.arcToPoint(Offset(0, size.height - cornerRadius), radius: const Radius.circular(cornerRadius));
    corners.lineTo(0, size.height - cornerLength);

    canvas.drawPath(corners, glowPaint);
    canvas.drawPath(corners, cornerPaint);

    // Center Crosshair
    final crosshairPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const chSize = 7.0;

    canvas.drawLine(Offset(cx - chSize, cy), Offset(cx + chSize, cy), crosshairPaint);
    canvas.drawLine(Offset(cx, cy - chSize), Offset(cx, cy + chSize), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cyber laser beam with white-hot core, glowing wings and dynamic directional trailing aura
class _ScannerLaser extends StatefulWidget {
  final double height;

  const _ScannerLaser({required this.height});

  @override
  State<_ScannerLaser> createState() => _ScannerLaserState();
}

class _ScannerLaserState extends State<_ScannerLaser> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final laserY = progress * widget.height;
        final isMovingDown = _controller.status != AnimationStatus.reverse;

        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _LaserPainter(
            laserY: laserY,
            isMovingDown: isMovingDown,
          ),
        );
      },
    );
  }
}

class _LaserPainter extends CustomPainter {
  final double laserY;
  final bool isMovingDown;

  _LaserPainter({required this.laserY, required this.isMovingDown});

  @override
  void paint(Canvas canvas, Size size) {
    const auraHeight = 28.0;

    // Directional trailing aura that trails behind the scan line
    final auraTop = isMovingDown ? (laserY - auraHeight).clamp(0.0, size.height) : laserY;
    final auraBottom = isMovingDown ? laserY : (laserY + auraHeight).clamp(0.0, size.height);

    if (auraBottom > auraTop) {
      final auraRect = Rect.fromLTRB(0, auraTop, size.width, auraBottom);
      final auraPaint = Paint()
        ..shader = LinearGradient(
          begin: isMovingDown ? Alignment.topCenter : Alignment.bottomCenter,
          end: isMovingDown ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.0),
            const Color(0xFF00E5FF).withValues(alpha: 0.2),
          ],
        ).createShader(auraRect);
      canvas.drawRect(auraRect, auraPaint);
    }

    // Laser Glow (Neon halo)
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(Offset(8, laserY), Offset(size.width - 8, laserY), glowPaint);

    // Laser core with white center & cyan gradient wings
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..shader = const LinearGradient(
        colors: [
          Color(0x0000E5FF),
          Color(0xFF00E5FF),
          Colors.white,
          Color(0xFF00E5FF),
          Color(0x0000E5FF),
        ],
        stops: [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, laserY - 1.25, size.width, 2.5));

    canvas.drawLine(Offset(4, laserY), Offset(size.width - 4, laserY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserPainter oldDelegate) =>
      oldDelegate.laserY != laserY || oldDelegate.isMovingDown != isMovingDown;
}
