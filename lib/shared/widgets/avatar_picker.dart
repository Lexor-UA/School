import 'dart:typed_data';
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        ref.read(authControllerProvider.notifier).updateAvatar(bytes);
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    ImageProvider imageProvider;
    if (user.avatarBytes != null) {
      imageProvider = MemoryImage(user.avatarBytes!);
    } else if (user.avatarUrl.startsWith('assets/')) {
      imageProvider = AssetImage(user.avatarUrl);
    } else {
      imageProvider = NetworkImage(user.avatarUrl);
    }

    return GestureDetector(
      onTap: _pickImage,
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
                // Ignore errors to avoid red screen crashes
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
