import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/chat_date_divider.dart';
import 'package:swimming_school_app/features/chat/utils/chat_image_helper.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_header.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_message_bubble.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_input_bar.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_monitoring_banner.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_empty_state.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/admin_chat_image_preview_sheet.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String clientId;
  final String? dialogId;
  final String? coachId;
  final String? coachName;
  final String? childName;
  final bool isMonitoring;

  const AdminChatScreen({
    super.key,
    required this.clientName,
    required this.clientId,
    this.dialogId,
    this.coachId,
    this.coachName,
    this.childName,
    this.isMonitoring = false,
  });

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploadingAttachment = false;

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

  Future<void> _pickImage(ImageSource source, AppThemeConfig theme) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 65,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      AdminChatImagePreviewSheet.show(
        context: context,
        bytes: bytes,
        theme: theme,
        onSend: (b, caption) => _sendAttachmentMessage(b, caption),
      );
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

  Future<void> _sendAttachmentMessage(Uint8List bytes, String caption) async {
    if (widget.clientId.isEmpty) return;

    setState(() => _isUploadingAttachment = true);

    try {
      String? imageUrl;
      try {
        final fileName = 'admin_chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('chats/${widget.clientId}/$fileName');
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = await storageRef.putData(bytes, metadata);
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (storageErr) {
        debugPrint('Firebase Storage upload failed: $storageErr. Fallback to Safe Data URI.');
        imageUrl = await ChatImageHelper.toSafeDataUri(bytes);
      }

      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        dialogId: widget.clientId,
        clientId: widget.clientId,
        clientName: widget.clientName,
        clientAvatar: '',
        senderId: 'admin',
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

  String get _effectiveDialogId =>
      (widget.dialogId != null && widget.dialogId!.isNotEmpty) ? widget.dialogId! : widget.clientId;

  @override
  void initState() {
    super.initState();
    // Mark messages as read by admin only if NOT in stealth monitoring mode
    if (!widget.isMonitoring && _effectiveDialogId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatRepositoryProvider).markMessagesAsRead(_effectiveDialogId, isAdmin: true);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final messagesAsync = ref.watch(chatMessagesStreamProvider(_effectiveDialogId));

    final idLower = widget.clientId.toLowerCase();
    final nameLower = widget.clientName.toLowerCase();
    final isRecovery = !widget.isMonitoring &&
        (idLower.startsWith('recovery_') || nameLower.contains('відновлення') || nameLower.contains('🔑'));

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
                AdminChatHeader(
                  clientId: widget.clientId,
                  clientName: widget.clientName,
                  coachId: widget.coachId,
                  coachName: widget.coachName,
                  childName: widget.childName,
                  isMonitoring: widget.isMonitoring,
                  isDark: isDark,
                  currentTheme: currentTheme,
                ),
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return AdminChatEmptyState(
                          isMonitoring: widget.isMonitoring,
                          coachName: widget.coachName,
                          clientName: widget.clientName,
                          displayName: cleanDisplayName,
                          isDark: isDark,
                          currentTheme: currentTheme,
                          onTemplateSelected: (template) {
                            _messageController.text = template;
                            _messageController.selection = TextSelection.fromPosition(
                              TextPosition(offset: template.length),
                            );
                          },
                        );
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
                          final isMe = !widget.isMonitoring && msg.senderId == 'admin';
                          final timeString = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          final showDateDivider = index == 0 || !ChatDateDivider.isSameDay(messages[index - 1].timestamp, msg.timestamp);
                          final bubble = AdminChatMessageBubble(
                            msg: msg,
                            isMe: isMe,
                            time: timeString,
                            index: index,
                            isDark: isDark,
                            currentTheme: currentTheme,
                            isMonitoring: widget.isMonitoring,
                            coachId: widget.coachId,
                            coachName: widget.coachName,
                            clientName: widget.clientName,
                          );

                          if (showDateDivider) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChatDateDivider(date: msg.timestamp, isDark: isDark),
                                bubble,
                              ],
                            );
                          }
                          return bubble;
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
                if (widget.isMonitoring)
                  AdminChatMonitoringBanner(
                    isDark: isDark,
                    currentTheme: currentTheme,
                  )
                else
                  AdminChatInputBar(
                    controller: _messageController,
                    isDark: isDark,
                    currentTheme: currentTheme,
                    isRecovery: isRecovery,
                    isUploadingAttachment: _isUploadingAttachment,
                    onSendMessage: _sendMessage,
                    onPickGallery: () => _pickImage(ImageSource.gallery, currentTheme),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
