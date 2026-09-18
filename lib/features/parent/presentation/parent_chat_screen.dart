import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class ParentChatScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? subtitle;
  const ParentChatScreen({super.key, this.title, this.subtitle});

  @override
  ConsumerState<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends ConsumerState<ParentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploadingAttachment = false;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final repo = ref.read(chatRepositoryProvider);
    repo.sendMessage(
      dialogId: user.id, // Client ID is used as Dialog ID
      clientId: user.id,
      clientName: user.name,
      clientAvatar: user.avatarUrl,
      senderId: user.id,
      clientRole: user.role == UserRole.coach ? 'coach' : 'parent',
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

  Future<void> _pickImage(ImageSource source, AppThemeConfig theme, {bool isMedicalDoc = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      _showSendPreviewDialog(bytes, theme, isMedicalDoc: isMedicalDoc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка відкриття фото: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions(BuildContext context, AppThemeConfig theme) {
    final isDark = theme.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0F2E52).withValues(alpha: 0.94),
                          const Color(0xFF07192F).withValues(alpha: 0.98),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.96),
                          const Color(0xFFF0F9FF).withValues(alpha: 0.94),
                        ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                      : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                        .withValues(alpha: isDark ? 0.20 : 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull pill bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Header
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
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.paperclip, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Прикріпити до повідомлення',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Options
                  _buildAttachmentOptionTile(
                    icon: LucideIcons.camera,
                    title: 'Зробити фото',
                    subtitle: 'Сфотографувати камерою пристрою',
                    gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera, theme);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAttachmentOptionTile(
                    icon: LucideIcons.image,
                    title: 'Обрати з медіатеки',
                    subtitle: 'Фотографії та скріншоти з галереї',
                    gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery, theme);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAttachmentOptionTile(
                    icon: LucideIcons.fileText,
                    title: 'Медична довідка / Документ',
                    subtitle: 'Довідка від лікаря або медичний документ',
                    gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery, theme, isMedicalDoc: true);
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required AppThemeConfig theme,
    required VoidCallback onTap,
  }) {
    final isDark = theme.isDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendPreviewDialog(Uint8List bytes, AppThemeConfig theme, {bool isMedicalDoc = false}) {
    final isDark = theme.isDark;
    final TextEditingController captionController = TextEditingController(
      text: isMedicalDoc ? 'Медична довідка для тренувань у басейні' : '',
    );
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color(0xFF0F2E52).withValues(alpha: 0.96),
                                const Color(0xFF07192F).withValues(alpha: 0.98),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.97),
                                const Color(0xFFF0F9FF).withValues(alpha: 0.95),
                              ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                            : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Попередній перегляд',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              icon: Icon(LucideIcons.x, color: theme.textPrimary, size: 20),
                              onPressed: isSending ? null : () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Image preview container
                        Container(
                          height: 230,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Caption input
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.20)
                                  : const Color(0xFFBAE6FD),
                            ),
                          ),
                          child: TextField(
                            controller: captionController,
                            style: TextStyle(color: theme.textPrimary),
                            enabled: !isSending,
                            decoration: InputDecoration(
                              hintText: 'Додати підпис до фото...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white54 : theme.textMuted,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                onPressed: isSending ? null : () => Navigator.pop(ctx),
                                child: Text(
                                  'Скасувати',
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(LucideIcons.send, color: Colors.white, size: 18),
                                  label: Text(
                                    isSending ? 'Надсилання...' : 'Надіслати',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onPressed: isSending
                                      ? null
                                      : () async {
                                          setModalState(() => isSending = true);
                                          final caption = captionController.text.trim();
                                          await _sendAttachmentMessage(bytes, caption);
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                          }
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendAttachmentMessage(Uint8List bytes, String caption) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    setState(() => _isUploadingAttachment = true);

    try {
      String? imageUrl;
      
      // 1. Спроба завантаження у Firebase Storage
      try {
        final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('chats/${user.id}/$fileName');
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = await storageRef.putData(bytes, metadata);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (storageErr) {
        debugPrint('Firebase Storage upload failed: $storageErr. Fallback to Data URI.');
        // 2. Надійний Data URL fallback
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }

      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        dialogId: user.id,
        clientId: user.id,
        clientName: user.name,
        clientAvatar: user.avatarUrl,
        senderId: user.id,
        clientRole: user.role == UserRole.coach ? 'coach' : 'parent',
        text: caption,
        imageUrl: imageUrl,
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не вдалося надіслати фото: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
      }
    }
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.90),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(imageUrl.split(',').last),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00E5FF),
                              ),
                            );
                          },
                        ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 18,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.60),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider);
      if (user != null) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(user.id, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final theme = ref.watch(appThemeControllerProvider);
    final dialogId = user?.id ?? '';
    final messagesAsync = ref.watch(chatMessagesStreamProvider(dialogId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, theme),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Немає повідомлень.\nНапишіть нам, і ми обов\'язково допоможемо!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.isDark ? Colors.white54 : theme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == user?.id;
                          final timeString = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          return _buildMessageBubble(msg, isMe, timeString, index, theme);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    error: (err, stack) => Center(child: Text('Помилка завантаження: $err', style: TextStyle(color: theme.textPrimary))),
                  ),
                ),
                if (_isUploadingAttachment) _buildUploadingBanner(theme),
                _buildInputArea(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingBanner(AppThemeConfig theme) {
    final isDark = theme.isDark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF092842) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
          ),
          SizedBox(width: 8),
          Text(
            'Надсилання фотографії...',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildHeader(BuildContext context, AppThemeConfig theme) {
    final isDark = theme.isDark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.85),
                      const Color(0xFF092842).withValues(alpha: 0.90),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                    : const Color(0xFFBAE6FD),
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                    .withValues(alpha: isDark ? 0.30 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                        : const Color(0xFFBAE6FD),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: theme.textPrimary, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.headset, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Підтримка CitySwim',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle ?? 'Служба турботи про клієнтів',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.85)
                            : theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, String time, int index, AppThemeConfig theme) {
    final isDark = theme.isDark;
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMe ? 22 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: hasImage ? 10 : 18,
                vertical: hasImage ? 10 : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? (isDark
                          ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                          : const [Color(0xFF0284C7), Color(0xFF0369A1)])
                      : (isDark
                          ? [
                              const Color(0xFF0E3D64).withValues(alpha: 0.75),
                              const Color(0xFF092842).withValues(alpha: 0.85),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.95),
                              const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                            ]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 22),
                ),
                border: Border.all(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.35)
                      : (isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                          : const Color(0xFFBAE6FD)),
                  width: 1.1,
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                              .withValues(alpha: isDark ? 0.30 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image presentation if attached
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () => _openFullScreenImage(msg.imageUrl!),
                      child: Container(
                        margin: EdgeInsets.only(bottom: msg.text.isNotEmpty ? 10 : 4),
                        constraints: const BoxConstraints(maxHeight: 250, minWidth: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              msg.imageUrl!.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(msg.imageUrl!.split(',').last),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      msg.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          height: 180,
                                          color: isDark ? const Color(0xFF071B2C) : const Color(0xFFE0F2FE),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF00E5FF),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.maximize2, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Text caption
                  if (msg.text.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hasImage ? 6 : 0),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : theme.textPrimary,
                          fontSize: 15,
                          fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hasImage ? 6 : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.75)
                                : (isDark ? Colors.white60 : theme.textSecondary),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            msg.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.08),
    );
  }

  Widget _buildInputArea(AppThemeConfig theme) {
    final isDark = theme.isDark;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0E3D64).withValues(alpha: 0.85),
                      const Color(0xFF092842).withValues(alpha: 0.92),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                    : const Color(0xFFBAE6FD),
                width: 1.1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? const Color(0xFF003B73) : const Color(0xFF0284C7))
                    .withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.paperclip,
                  color: isDark ? const Color(0xFF00E5FF) : theme.accentPrimary,
                ),
                onPressed: () => _showAttachmentOptions(context, theme),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Повідомлення...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : theme.textMuted,
                      ),
                      border: InputBorder.none,
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
                        ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                        : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                          .withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 19),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
