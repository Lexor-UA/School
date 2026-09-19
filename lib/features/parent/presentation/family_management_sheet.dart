import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/presentation/edit_child_sheet.dart';

class FamilyManagementSheet extends ConsumerStatefulWidget {
  const FamilyManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FamilyManagementSheet(),
    );
  }

  @override
  ConsumerState<FamilyManagementSheet> createState() => _FamilyManagementSheetState();
}

class _FamilyManagementSheetState extends ConsumerState<FamilyManagementSheet> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _showQrCode = false;
  String? _errorMessage;
  String? _phoneErrorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure family is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider).getOrCreateFamily();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Text('Код $text скопійовано в буфер обміну!'),
          ],
        ),
        backgroundColor: const Color(0xFF0F1E32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitPhoneInvite() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneErrorMessage = 'Введіть номер телефону');
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneErrorMessage = null;
    });

    final result = await ref.read(familyControllerProvider).invitePartnerByPhone(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.error != null) {
      setState(() => _phoneErrorMessage = result.error);
    } else {
      HapticFeedback.heavyImpact();
      _phoneController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.send, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Запрошення надіслано ${result.targetUserName != null ? "користувачу ${result.targetUserName}" : ""}! Партнер побачить сповіщення у додатку.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF064E3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _submitJoinCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Введіть код сім\'ї');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await ref.read(familyControllerProvider).joinFamily(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      HapticFeedback.heavyImpact();
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.heartHandshake, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text('Успішно! Сімейні акаунти об\'єднано.'),
            ],
          ),
          backgroundColor: Color(0xFF064E3B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmUnlink(Family family) async {
    final isDark = ref.read(appThemeControllerProvider).isDark;
    final user = ref.read(authControllerProvider);
    final partnerName = family.getOtherParentName(user?.id ?? '') ?? 'партнера';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F1E32) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Від\'єднати акаунт?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Ви впевнені, що хочете розірвати сімейний зв\'язок з $partnerName? Спільний доступ до дітей та абонементів буде розділено.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Від\'єднати', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await ref.read(familyControllerProvider).leaveOrUnlinkFamily();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сімейний зв\'язок розірвано.'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final user = ref.watch(authControllerProvider);
    final familyAsync = ref.watch(familyStreamProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final children = childrenAsync.value ?? [];

    final family = familyAsync.value;
    final isPaired = family?.isPaired ?? false;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                math.max(MediaQuery.of(context).padding.bottom, 24),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.97),
                isDark ? const Color(0xFF070E1A).withValues(alpha: 0.98) : const Color(0xFFF1F5F9).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
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
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.users, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сімейний акаунт',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isPaired ? 'Спільне керування парою' : 'Підключення другого з батьків',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPaired
                                ? [
                                    const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12),
                                    const Color(0xFF059669).withValues(alpha: isDark ? 0.10 : 0.05),
                                  ]
                                : [
                                    const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.12),
                                    const Color(0xFF0369A1).withValues(alpha: isDark ? 0.10 : 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPaired
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFF0284C7).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPaired ? LucideIcons.checkCircle2 : LucideIcons.info,
                              color: isPaired ? const Color(0xFF10B981) : const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isPaired
                                    ? 'Ваші акаунти об\'єднано. Обидва батьки мають доступ до дітей, розкладу та абонементів.'
                                    : 'Об\'єднайте акаунти з чоловіком або дружиною, щоб разом записувати дітей та користуватися єдиними абонементами.',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      if (familyAsync.isLoading && family == null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00E5FF),
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ] else if (isPaired && family != null) ...[
                        // Paired Family Card
                        _buildPairedCard(context, family, user?.id ?? '', isDark),
                        const SizedBox(height: 18),

                        // Shared Children List
                        _buildChildrenSection(children, isDark),
                        const SizedBox(height: 24),

                        // Unlink Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _isLoading ? null : () => _confirmUnlink(family),
                            icon: const Icon(LucideIcons.userMinus, size: 18),
                            label: const Text(
                              'Від\'єднати другий акаунт',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Unpaired View: 1) My Invite Code
                        _buildInviteCodeCard(family?.inviteCode ?? 'Генерація...', isDark),
                        const SizedBox(height: 18),

                        // Divider with OR
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'АБО',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 2) Join Existing Family
                        _buildJoinCodeCard(isDark),
                        const SizedBox(height: 18),

                        // Divider with OR
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'АБО',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 3) Invite Partner by Phone
                        _buildPhoneInviteCard(isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPairedCard(BuildContext context, Family family, String currentUserId, bool isDark) {
    final user = ref.watch(authControllerProvider);
    final currentUserName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (family.parentNames[currentUserId]?.trim().isNotEmpty == true
            ? family.parentNames[currentUserId]!.trim()
            : 'Ви');
    final currentUserPhone = (user?.phone != null && user!.phone!.trim().isNotEmpty)
        ? user.phone!.trim()
        : (family.parentPhones[currentUserId]?.trim() ?? '');
    final partnerName = family.getOtherParentName(currentUserId) ?? 'Другий з батьків';
    final partnerPhone = family.getOtherParentPhone(currentUserId) ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.heartHandshake, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                'Батьки родини',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Current User Tile
          _buildParentTile(
            name: currentUserName,
            phone: currentUserPhone,
            roleBadge: 'Ви',
            badgeColor: const Color(0xFF00E5FF),
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.link2, size: 12, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'Спільний доступ',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Partner Tile
          _buildParentTile(
            name: partnerName,
            phone: partnerPhone,
            roleBadge: 'Партнер',
            badgeColor: const Color(0xFFA78BFA),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildParentTile({
    required String name,
    required String phone,
    required String roleBadge,
    required Color badgeColor,
    required bool isDark,
  }) {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Користувач';
    final initialLetter = cleanName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: badgeColor.withValues(alpha: 0.25),
            child: Text(
              initialLetter,
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
            ),
            child: Text(
              roleBadge,
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(List<Child> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 8),
            Text(
              'Спільні діти (${children.length})',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Дітей ще не додано. Натисніть «+ Додати» у профілі.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12.5),
              ),
            ),
          )
        else
          Column(
            children: children.map((child) {
              final childColor = Color(int.tryParse(child.colorHex) ?? 0xFF00E5FF);
              final age = child.currentAge;
              final ageFormatted = age != null ? ' (${formatAgeUk(age)})' : '';
              final displayName = '${child.name}$ageFormatted';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: childColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: childColor,
                      child: Text(
                        child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 16),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInviteCodeCard(String code, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1. Ваш сімейний код',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showQrCode = !_showQrCode),
                child: Row(
                  children: [
                    Icon(
                      _showQrCode ? LucideIcons.eyeOff : LucideIcons.qrCode,
                      size: 14,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showQrCode ? 'Приховати QR' : 'Показати QR',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Надішліть цей код чоловікові або дружині, щоб вони підключилися до вашої родини:',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Code Display Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF00E5FF).withValues(alpha: 0.16),
                        const Color(0xFF0284C7).withValues(alpha: 0.10),
                      ]
                    : [
                        const Color(0xFFE0F2FE),
                        const Color(0xFFBAE6FD),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0369A1),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0F1E32),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _copyToClipboard(code),
                  icon: const Icon(LucideIcons.copy, size: 15),
                  label: const Text(
                    'Копіювати',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),

          // Optional QR Code Box
          if (_showQrCode) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinCodeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Приєднатися до сім\'ї',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Якщо ваш чоловік або дружина вже мають код сім\'ї, введіть його сюди:',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Code Input Field
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Введіть код (наприклад FAM-123456)',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
                letterSpacing: 0,
              ),
              prefixIcon: Icon(
                LucideIcons.keyRound,
                size: 18,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),

          // Submit Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitJoinCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.userCheck, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Об\'єднати акаунти',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, height: 1.25),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInviteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.phoneForwarded, color: Color(0xFF10B981), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '3. Запросити за номером телефону',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Введіть номер телефону чоловіка або дружини. Ми надішлемо інтерактивне сповіщення з кнопкою швидкого підключення:',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Phone Input Field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '+380 або 0...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                LucideIcons.phone,
                size: 18,
                color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
            ),
          ),

          if (_phoneErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _phoneErrorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),

          // Submit Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPhoneInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.send, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Надіслати запрошення',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, height: 1.25),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
