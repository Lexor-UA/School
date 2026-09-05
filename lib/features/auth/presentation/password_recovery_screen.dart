import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/chat/models/chat_message.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  final String initialLogin;

  const PasswordRecoveryScreen({
    super.key,
    this.initialLogin = '',
  });

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _dialogId = '';
  bool _isInit = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _identifierController.text = widget.initialLogin.trim();
    _initDialogId();
  }

  Future<void> _initDialogId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('password_recovery_dialog_id');

    if (storedId == null || storedId.isEmpty) {
      final randSuffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      storedId = 'recovery_$randSuffix';
      await prefs.setString('password_recovery_dialog_id', storedId);
    }

    if (mounted) {
      setState(() {
        _dialogId = storedId!;
        _isInit = true;
      });

      // Mark messages as read by client
      ref.read(chatRepositoryProvider).markMessagesAsRead(_dialogId, false);

      // If user had a prefilled login, prepare a helpful opening draft message if input is empty
      if (widget.initialLogin.trim().isNotEmpty && _messageController.text.isEmpty) {
        _messageController.text =
            'Добрий день! Допоможіть, будь ласка, відновити доступ до акаунта ${widget.initialLogin.trim()}.';
      }
    }
  }

  String _t(
    String key, {
    required String uk,
    required String en,
    required String de,
    required String ru,
  }) {
    final res = key.tr();
    if (res != key && !res.startsWith('auth.')) {
      return res;
    }
    try {
      final lang = context.locale.languageCode;
      switch (lang) {
        case 'en':
          return en;
        case 'de':
          return de;
        case 'ru':
          return ru;
        case 'uk':
        default:
          return uk;
      }
    } catch (_) {
      return uk;
    }
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _messageController.text).trim();
    if (text.isEmpty || _dialogId.isEmpty) return;

    final clientIdentifier = _identifierController.text.trim().isNotEmpty
        ? _identifierController.text.trim()
        : (widget.initialLogin.trim().isNotEmpty
            ? widget.initialLogin.trim()
            : 'Клієнт');

    setState(() => _isSending = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.sendMessage(
        dialogId: _dialogId,
        clientId: _dialogId,
        clientName: '🔑 Відновлення пароля: $clientIdentifier',
        clientAvatar: '',
        senderId: _dialogId, // sender is client
        text: text,
      );

      if (overrideText == null) {
        _messageController.clear();
      }

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
            content: Text('Помилка відправки: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _identifierController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildInfoCard(),
                Expanded(
                  child: !_isInit
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                          ),
                        )
                      : _buildMessagesStream(),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1828).withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),

          // Key badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  const Color(0xFF0288D1).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.keyRound,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t(
                    'auth.password_recovery_title',
                    uk: 'Відновлення пароля',
                    en: 'Password Recovery',
                    de: 'Passwort-Wiederherstellung',
                    ru: 'Восстановление пароля',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _t(
                        'auth.admin_support_subtitle',
                        uk: 'Діалог з адміністратором',
                        en: 'Chat with Administrator',
                        de: 'Chat mit Administrator',
                        ru: 'Диалог с администратором',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action to return to login directly
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
              ),
            ),
            icon: const Icon(LucideIcons.logIn, size: 14),
            label: Text(
              _t(
                'auth.back_to_login',
                uk: 'До входу',
                en: 'To Login',
                de: 'Zum Login',
                ru: 'Ко входу',
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A223D).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.info,
                color: Color(0xFF00E5FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(
                    'auth.recovery_info_card',
                    uk: 'Вкажіть ваш телефон, Email або ПІБ. Адміністратор перевірить профіль і надішле вам логін або відновить пароль прямо сюди.',
                    en: 'Provide your phone, email, or full name. The administrator will verify your profile and send login credentials right here.',
                    de: 'Geben Sie Telefon, E-Mail oder Namen an. Der Administrator prüft Ihr Profil und sendet Login-Daten direkt hierher.',
                    ru: 'Укажите ваш телефон, Email или ФИО. Администратор проверит профиль и пришлет логин или восстановит пароль прямо сюда.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Action inquiry chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickChip(
                  label: '🔑 Забув пароль',
                  onTap: () {
                    _messageController.text =
                        'Я забув(-ла) свій пароль. Підкажіть, будь ласка, як увійти або скиньте тимчасовий пароль.';
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: '👤 Не пам\'ятаю логін',
                  onTap: () {
                    _messageController.text =
                        'Я не пам\'ятаю свій логін до акаунта. Мої контактні дані: ';
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: '📞 Вказати контакти',
                  onTap: () {
                    _messageController.text =
                        'Мій контактний номер телефону: ';
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesStream() {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(_dialogId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.messageSquareQuote,
                      color: Color(0xFF00E5FF),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Повідомлень поки немає',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Напишіть повідомлення нижче, щоб адміністратор розпочав відновлення.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Auto-scroll on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          physics: const BouncingScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final bool isMe = msg.senderId != 'admin';
            final timeString =
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
            return _buildMessageBubble(msg, isMe, timeString, index);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Помилка завантаження чату: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isMe,
    String time,
    int index,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe
                ? [
                    const Color(0xFF00C6FF),
                    const Color(0xFF0072FF),
                  ]
                : [
                    const Color(0xFF102742).withValues(alpha: 0.95),
                    const Color(0xFF091728).withValues(alpha: 0.95),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? const Color(0xFF00C6FF).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isMe
                ? const Color(0xFF00E5FF).withValues(alpha: 0.6)
                : const Color(0xFF00E5FF).withValues(alpha: 0.25),
            width: 1.1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shield,
                      color: Color(0xFF00E5FF),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Адміністратор',
                      style: TextStyle(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              if (!isMe) const SizedBox(height: 4),
              SelectableText(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _t(
                                'auth.copied_to_clipboard',
                                uk: 'Скопійовано в буфер обміну',
                                en: 'Copied to clipboard',
                                de: 'In die Zwischenablage kopiert',
                                ru: 'Скопировано в буфер обмена',
                              ),
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.copy,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Копіювати',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF071424).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1E33).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: _t(
                    'auth.type_message_hint',
                    uk: 'Повідомлення адміністратору...',
                    en: 'Message to administrator...',
                    de: 'Nachricht an Administrator...',
                    ru: 'Сообщение администратору...',
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      LucideIcons.sendHorizontal,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isSending ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
