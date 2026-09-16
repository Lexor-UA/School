import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String clientId;
  const AdminChatScreen({super.key, required this.clientName, required this.clientId});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (widget.clientId.isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);
    repo.sendMessage(
      dialogId: widget.clientId, // using clientId as dialogId
      clientId: widget.clientId,
      clientName: widget.clientName,
      clientAvatar: '',
      senderId: 'admin',
      text: text,
    );
    
    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Mark messages as read by admin
    if (widget.clientId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(widget.clientId, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.clientId));

    final idLower = widget.clientId.toLowerCase();
    final nameLower = widget.clientName.toLowerCase();
    final isRecovery = idLower.startsWith('recovery_') || nameLower.contains('відновлення') || nameLower.contains('🔑');

    String cleanDisplayName = widget.clientName;
    if (isRecovery) {
      cleanDisplayName = cleanDisplayName
          .replaceAll('🔑', '')
          .replaceFirst(RegExp(r'^Відновлення пароля:\s*', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^Запит на відновлення:\s*', caseSensitive: false), '')
          .trim();
      if (cleanDisplayName.isEmpty) cleanDisplayName = 'Запит на відновлення';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark, currentTheme),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return _buildEmptyState(isDark, currentTheme, displayName: cleanDisplayName);
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == 'admin';
                          final timeString = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          return _buildMessageBubble(msg.text, isMe, timeString, index, isDark, currentTheme);
                        },
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: isDark ? const Color(0xFF38BDF8) : currentTheme.accentPrimary,
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Помилка: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
                _buildQuickRepliesBar(isDark, isRecovery),
                _buildInputArea(isDark, currentTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  void _showContactInfo(BuildContext context, String clientId, String name, bool isDark, AppThemeConfig theme) async {
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
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F2644), const Color(0xFF0A192F)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
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
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
                          _getInitials(name),
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
                            name,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Контактні дані клієнта',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF0284C7)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Телефон',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                        IconButton(
                          icon: const Icon(LucideIcons.copy, size: 18, color: Color(0xFF0284C7)),
                          onPressed: () {
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
                        ),
                    ],
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.mail, size: 18, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                        IconButton(
                          icon: const Icon(LucideIcons.copy, size: 18, color: Color(0xFF0284C7)),
                          onPressed: () {
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
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Закрити', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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

  Widget _buildEmptyState(bool isDark, AppThemeConfig currentTheme, {required String displayName}) {
    final quickTemplates = [
      '👋 Вітаємо у школі плавання CitySwim! Чим можемо допомогти?',
      '📅 Нагадуємо про розклад вашого наступного тренування.',
      '🏊 Бажаєте записатись на індивідуальне заняття з тренером?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE0F2FE),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.12),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.messageSquare,
                size: 40,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Початок діалогу з $displayName',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Напишіть повідомлення або оберіть швидкий шаблон нижче:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ...quickTemplates.map((template) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _messageController.text = template;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: template.length),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFBAE6FD),
                          width: 1.15,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              template,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF334155),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.arrowUpRight, size: 15, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AppThemeConfig currentTheme) {
    final userRoles = ref.watch(usersRoleMapProvider).value ?? {};

    String role = 'parent';
    final idLower = widget.clientId.toLowerCase();
    final nameLower = widget.clientName.toLowerCase();
    if (idLower.startsWith('recovery_') || nameLower.contains('відновлення') || nameLower.contains('🔑')) {
      role = 'recovery';
    } else if (userRoles[widget.clientId] == 'coach' ||
               userRoles['name_${widget.clientName}'] == 'coach' ||
               nameLower.contains('антон') ||
               nameLower.contains('тренер')) {
      role = 'coach';
    }

    final isRecovery = role == 'recovery';
    final isCoach = role == 'coach';

    String displayName = widget.clientName;
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
                        .doc(widget.clientId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final avatarUrl = data?['avatarUrl'] as String?;
                      if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
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
                  onPressed: () => _showContactInfo(context, widget.clientId, displayName, isDark, currentTheme),
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

  Widget _buildMessageBubble(
    String text,
    bool isMe,
    String time,
    int index,
    bool isDark,
    AppThemeConfig currentTheme,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.copy, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Повідомлення скопійовано: "$text"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0284C7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isMe
                  ? (isDark
                      ? [const Color(0xFF00E5FF), const Color(0xFF0077B6)]
                      : [const Color(0xFF0284C7), const Color(0xFF0369A1)])
                  : (isDark
                      ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.12)]
                      : [Colors.white, const Color(0xFFF8FAFC)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMe ? 22 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 22),
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          .withValues(alpha: isDark ? 0.40 : 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
            border: Border.all(
              color: isMe
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.35))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.30)
                      : const Color(0xFFBAE6FD)),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isMe ? 22 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 22),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontSize: 15,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.82)
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.08),
    );
  }

  Widget _buildInputArea(bool isDark, AppThemeConfig currentTheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.94),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
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
                    LucideIcons.paperclip,
                    color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                    size: 19,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Прикріплення файлів буде доступно у наступному оновленні'),
                        backgroundColor: Color(0xFF0284C7),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFBAE6FD),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.10 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Повідомлення...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF00E5FF), Color(0xFF0077B6)]
                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 19),
                  onPressed: _sendMessage,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar(bool isDark, bool isRecovery) {
    final recoveryChips = [
      '✅ Доступ відновлено!',
      '🔑 Тимчасовий пароль: 1',
      '📞 Надішліть ваш контактний телефон',
      '📩 Інструкцію надіслано на пошту',
    ];

    final defaultChips = [
      '👋 Вітаємо у CitySwim!',
      '📅 Нагадуємо про розклад',
      '🏊 Чекаємо на тренуванні!',
      '💳 Інформація про оплату',
      '👌 Домовились!',
    ];

    final chips = isRecovery ? recoveryChips : defaultChips;

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _messageController.text = chip;
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: chip.length),
                );
              },
              borderRadius: BorderRadius.circular(19),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isRecovery
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.12))
                      : (isRecovery
                          ? const Color(0xFFFEF3C7)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: isDark
                        ? (isRecovery
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.22))
                        : (isRecovery
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFFBAE6FD)),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRecovery ? const Color(0xFFD97706) : const Color(0xFF0284C7))
                          .withValues(alpha: isDark ? 0.15 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecovery ? LucideIcons.keyRound : LucideIcons.sparkles,
                      size: 13,
                      color: isRecovery
                          ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                          : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip,
                      style: TextStyle(
                        color: isRecovery
                            ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                            : (isDark ? Colors.white : const Color(0xFF334155)),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
