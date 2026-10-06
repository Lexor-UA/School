import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';

class AdminChatHeader extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final String? coachId;
  final String? coachName;
  final String? childName;
  final bool isMonitoring;
  final bool isDark;
  final AppThemeConfig currentTheme;

  const AdminChatHeader({
    super.key,
    required this.clientId,
    required this.clientName,
    this.coachId,
    this.coachName,
    this.childName,
    required this.isMonitoring,
    required this.isDark,
    required this.currentTheme,
  });

  String _getInitials(String name) {
    final clean = name.replaceAll('🔑', '').replaceAll('🏊', '').replaceAll('👤', '').trim();
    if (clean.isEmpty) return '??';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean.toUpperCase();
  }

  void _showMonitoringInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1E1035), const Color(0xFF0F0A1E)]
                    : [Colors.white, const Color(0xFFFAF5FF)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: const Color(0xFFA78BFA).withValues(alpha: isDark ? 0.40 : 0.30),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.eye, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Скритний нагляд адміністратора',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '100% анонімний контроль якості',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFA78BFA).withValues(alpha: 0.30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.award, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'Тренер: ',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              coachName ?? 'Тренер',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(
                            'Клієнт: ',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              clientName,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (childName != null && childName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(LucideIcons.baby, size: 16, color: Color(0xFFEC4899)),
                            const SizedBox(width: 8),
                            Text(
                              'Дитина: ',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                childName!,
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Security note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Учасники діалогу не мають жодних сповіщень чи позначок про присутність адміністратора.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Зрозуміло', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactInfo(BuildContext context, String displayName) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(clientId).get();
    final data = doc.data();
    final phone = (data?['phone'] as String?) ?? '';
    final email = (data?['email'] as String?) ?? '';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, math.max(bottomInset, 16) + 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0F1E32).withValues(alpha: 0.96),
                          const Color(0xFF070E1A).withValues(alpha: 0.98),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.98),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.96),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.12 : 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Draggable handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // 2. Header with Avatar, Details and Close 'X' Button
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Контактні дані клієнта',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : const Color(0xFFBAE6FD),
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: isDark ? Colors.white : const Color(0xFF334155),
                            size: 18,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(ctx);
                          },
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phone Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D2137) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                            : const Color(0xFFBAE6FD),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.12 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                  : Colors.transparent,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.phone,
                            size: 18,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Телефон',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone.isNotEmpty ? phone : 'Номер не вказано',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (phone.isNotEmpty)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: phone));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Номер скопійовано в буфер!'),
                                    backgroundColor: Color(0xFF0284C7),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  LucideIcons.copy,
                                  size: 18,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Email Card
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D2137) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                              : const Color(0xFFBAE6FD),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.12 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                    : Colors.transparent,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.mail,
                              size: 18,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: email));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email скопійовано!'),
                                    backgroundColor: Color(0xFF0284C7),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  LucideIcons.copy,
                                  size: 18,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sapphire VIP CTA Button (54px, gradient, neon border, glow, crisp white text)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF0E3D64), Color(0xFF082038)]
                                : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.30 : 0.20),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Закрити',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMonitoring) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF140C26).withValues(alpha: 0.90)
                  : Colors.white.withValues(alpha: 0.94),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFE9D5FF),
                      width: 1.15,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.eye, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${coachName ?? 'Тренер'} ↔ $clientName',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 15.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFA78BFA), width: 0.8),
                            ),
                            child: const Text(
                              'НАГЛЯД',
                              style: TextStyle(
                                color: Color(0xFFA78BFA),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              childName != null && childName!.isNotEmpty
                                  ? 'Дитина: $childName • Тільки читання'
                                  : 'Скритний режим • Тільки читання',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF6B21A8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFE9D5FF),
                      width: 1.15,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.info,
                      color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      size: 19,
                    ),
                    onPressed: () => _showMonitoringInfo(context),
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userRoles = ref.watch(usersRoleMapProvider).value ?? {};

    String role = 'parent';
    final idLower = clientId.toLowerCase();
    final nameLower = clientName.toLowerCase();
    if (idLower.startsWith('recovery_') || nameLower.contains('відновлення') || nameLower.contains('🔑')) {
      role = 'recovery';
    } else if (userRoles[clientId] == 'coach' ||
               userRoles['name_$clientName'] == 'coach' ||
               nameLower.contains('антон') ||
               nameLower.contains('тренер')) {
      role = 'coach';
    }

    final isRecovery = role == 'recovery';
    final isCoach = role == 'coach';

    String displayName = clientName;
    if (isRecovery) {
      displayName = displayName
          .replaceAll('🔑', '')
          .replaceFirst(RegExp(r'^Відновлення пароля:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^Запит на відновлення:\s*', caseSensitive: false), '')
          .trim();
      if (displayName.isEmpty) displayName = 'Запит на відновлення';
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(
                color: isRecovery
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                    : (isCoach
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : (isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBAE6FD))),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                    width: 1.15,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              // Role-specific avatar
              if (isRecovery)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.keyRound, color: Colors.white, size: 20),
                  ),
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCoach
                          ? const Color(0xFFA7F3D0)
                          : (isDark ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD)),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isCoach
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)))
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(clientId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final avatarUrl = data?['avatarUrl'] as String?;
                      if (avatarUrl != null &&
                          avatarUrl.isNotEmpty &&
                          avatarUrl.startsWith('http') &&
                          !avatarUrl.contains('ui-avatars.com')) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(avatarUrl),
                          backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        );
                      }

                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isCoach
                                  ? const [Color(0xFF059669), Color(0xFF0284C7)]
                                  : (isDark
                                      ? const [Color(0xFF00D2FF), Color(0xFF0077B6)]
                                      : const [Color(0xFF0284C7), Color(0xFF0369A1)]),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role Badge
                        if (isRecovery)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                                    : const Color(0xFFFCD34D),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔑 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  'ВІДНОВЛЕННЯ',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isCoach)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                    : const Color(0xFFA7F3D0),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏊 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  'ТРЕНЕР',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                                    : const Color(0xFFBAE6FD),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('👤 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  'КЛІЄНТ',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2.5),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRecovery ? const Color(0xFFD97706) : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isRecovery ? const Color(0xFFD97706) : const Color(0xFF10B981),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRecovery
                              ? 'Запит на відновлення доступу'
                              : (isCoach ? 'В мережі • Тренер школи' : 'В мережі'),
                          style: TextStyle(
                            color: isRecovery
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                    width: 1.15,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.phone,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    size: 19,
                  ),
                  onPressed: () => _showContactInfo(context, displayName),
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
