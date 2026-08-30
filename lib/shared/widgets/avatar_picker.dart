import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? Colors.cyanAccent : Colors.blue),
                title: Text('Обрати з галереї', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Видалити фото', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(authControllerProvider.notifier).deleteAvatar();
                },
              ),
            ],
          ),
         ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    ImageProvider imageProvider;
    final displayUrl = (user.avatarUrl.isEmpty) 
        ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}'
        : user.avatarUrl;

    if (user.avatarBytes != null) {
      imageProvider = MemoryImage(user.avatarBytes!);
    } else if (displayUrl.startsWith('data:image')) {
      final base64String = displayUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64String.replaceAll('\n', '').replaceAll('\r', '')));
    } else if (displayUrl.startsWith('assets/')) {
      imageProvider = AssetImage(displayUrl);
    } else {
      imageProvider = NetworkImage(displayUrl);
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
              backgroundColor: Colors.grey.shade800,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('Image load error for $displayUrl: $exception');
              },
            ),
            if (widget.showCameraIcon)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
