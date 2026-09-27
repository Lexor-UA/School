import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class AvatarPicker extends ConsumerStatefulWidget {
  final double radius;
  final String heroTag;

  final bool showCameraIcon;

  const AvatarPicker({
    super.key,
    required this.heroTag,
    this.radius = 50.0,
    this.showCameraIcon = true,
  });

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _hasImageError = false;
  String? _lastAvatarSource;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Завантаження фотографії...'), duration: Duration(seconds: 1)),
          );
        }
        ref.read(authControllerProvider.notifier).updateAvatar(
          bytes,
          onSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Фото успішно завантажено!'), backgroundColor: Colors.green),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Помилка збереження фото: $error'), backgroundColor: Colors.red),
              );
            }
          }
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Помилка при виборі зображення'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOptions() {
    final user = ref.read(authControllerProvider);
    final fbUser = FirebaseAuth.instance.currentUser;
    final hasCustomAvatar = (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty) ||
        user?.avatarBytes != null ||
        (fbUser?.photoURL != null && fbUser!.photoURL!.isNotEmpty);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bottomInset = MediaQuery.of(ctx).padding.bottom;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, math.max(bottomInset, 16) + 12),
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

                  // 2. Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Фото профілю',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Оберіть дію з вашим аватаром',
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
                  const SizedBox(height: 18),

                  // 3. VIP Action Card 1: Обрати з галереї
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        _pickImage();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF0E3D64).withValues(alpha: 0.70),
                                    const Color(0xFF082038).withValues(alpha: 0.85),
                                  ]
                                : [
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFFF0F9FF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                : const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.20 : 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.imagePlus,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Обрати з галереї',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Завантажити нове фото з пристрою',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronRight,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. VIP Action Card 2: Видалити фото (якщо встановлено)
                  if (hasCustomAvatar) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          ref.read(authControllerProvider.notifier).deleteAvatar();
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      const Color(0xFF450A0A).withValues(alpha: 0.50),
                                      const Color(0xFF1E0707).withValues(alpha: 0.70),
                                    ]
                                  : [
                                      const Color(0xFFFEF2F2),
                                      const Color(0xFFFFF1F2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                                  : const Color(0xFFFECDD3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Видалити фото',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Скинути аватар до ініціалів',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFFCA5A5).withValues(alpha: 0.8) : const Color(0xFF991B1B).withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                LucideIcons.chevronRight,
                                color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final fbUser = FirebaseAuth.instance.currentUser;

    final effectiveName = (user?.name != null && user!.name.trim().isNotEmpty && user.name != 'New User')
        ? user.name.trim()
        : (fbUser?.displayName?.trim().isNotEmpty == true
            ? fbUser!.displayName!.trim()
            : 'Користувач');

    final effectiveAvatarUrl = (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty)
        ? user.avatarUrl
        : (fbUser?.photoURL != null && fbUser!.photoURL!.isNotEmpty
            ? fbUser.photoURL!
            : '');

    final bool isUiAvatar = effectiveAvatarUrl.contains('ui-avatars.com') ||
        effectiveAvatarUrl.contains('example.com');
    final bool hasValidNetworkUrl = effectiveAvatarUrl.isNotEmpty &&
        effectiveAvatarUrl.startsWith('http') &&
        !isUiAvatar;

    final avatarSourceKey = '${user?.avatarBytes != null}_$effectiveAvatarUrl';
    if (_lastAvatarSource != avatarSourceKey) {
      _lastAvatarSource = avatarSourceKey;
      _hasImageError = false;
    }

    ImageProvider? imageProvider;
    if (!_hasImageError) {
      if (user?.avatarBytes != null) {
        imageProvider = MemoryImage(user!.avatarBytes!);
      } else if (effectiveAvatarUrl.startsWith('data:image')) {
        try {
          final base64String = effectiveAvatarUrl.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64String.replaceAll('\n', '').replaceAll('\r', '')));
        } catch (_) {
          imageProvider = null;
        }
      } else if (effectiveAvatarUrl.startsWith('assets/')) {
        imageProvider = AssetImage(effectiveAvatarUrl);
      } else if (hasValidNetworkUrl) {
        imageProvider = NetworkImage(effectiveAvatarUrl);
      }
    }

    return GestureDetector(
      onTap: widget.showCameraIcon ? _showOptions : null,
      child: Hero(
        tag: widget.heroTag,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: widget.radius,
              backgroundImage: imageProvider,
              backgroundColor: const Color(0xFF0F1E32),
              onBackgroundImageError: imageProvider != null
                  ? (exception, stackTrace) {
                      debugPrint('AvatarPicker: image load bypassed for $effectiveAvatarUrl: $exception');
                      if (mounted && !_hasImageError) {
                        setState(() {
                          _hasImageError = true;
                        });
                      }
                    }
                  : null,
              child: imageProvider == null
                  ? (effectiveName.trim().isNotEmpty && effectiveName.trim() != 'User'
                      ? Text(
                          effectiveName.trim().characters.first.toUpperCase(),
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.radius * 0.75,
                          ),
                        )
                      : Icon(LucideIcons.user, size: widget.radius * 0.9, color: Colors.cyanAccent))
                  : null,
            ),
            if (widget.showCameraIcon)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF030D1B),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(widget.radius <= 30 ? 3.5 : 5.5),
                child: Icon(
                  Icons.camera_alt,
                  color: const Color(0xFF030D1B),
                  size: widget.radius <= 30 ? 11 : 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
