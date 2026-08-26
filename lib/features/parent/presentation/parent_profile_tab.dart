import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/utils/page_transitions.dart';
import 'package:swimming_school_app/features/parent/presentation/trophy_room_screen.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';

class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF0A2540);
    final textSubColor = isDark ? Colors.white70 : const Color(0xFF4A6572);
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('parent.my_profile'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // 1. Header (Avatar + Name)
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 46),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Андрій',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 200.ms),
                Text(
                  'Батьківський акаунт',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // 3. Navigation List
          _buildSettingsTile(LucideIcons.userPlus, 'Додати дитину', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            _showAddChildDialog(context, ref, isDark);
          }),
          _buildSettingsTile(LucideIcons.trendingUp, 'Мій прогрес', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            ref.read(parentTabProvider.notifier).state = 2;
          }),
          _buildSettingsTile(LucideIcons.trophy, 'Мої досягнення', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            Navigator.push(context, FadeScaleRoute(page: const TrophyRoomScreen()));
          }),
          _buildSettingsTile(LucideIcons.creditCard, 'Абонемент', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Керування абонементом буде доступне незабаром')));
          }),
          _buildSettingsTile(LucideIcons.settings, 'Налаштування', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Налаштування в розробці')));
          }),
          _buildSettingsTile(LucideIcons.helpCircle, 'Допомога', textColor, textSubColor, cardBgColor, cardBorderColor, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Допомога в розробці')));
          }),
          
          const SizedBox(height: 32),
          _buildLogoutButton(context, ref, isDark).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final nameController = TextEditingController();
    String selectedColor = '0xFF40C4FF'; // Default Cyan
    final colors = {
      '0xFF40C4FF': Colors.cyanAccent,
      '0xFF448AFF': Colors.blueAccent,
      '0xFFE040FB': Colors.purpleAccent,
      '0xFFFF4081': Colors.pinkAccent,
      '0xFF69F0AE': Colors.greenAccent,
      '0xFFFFAB40': Colors.orangeAccent,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Додати дитину', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Ім'я дитини",
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Колір профілю', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.entries.map((entry) {
                    final isSelected = selectedColor == entry.key;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = entry.key),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        ref.read(childrenControllerProvider.notifier).addChild(nameController.text.trim(), selectedColor);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Зберегти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, Color textColor, Color subColor, Color bg, Color border, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: Icon(icon, color: textColor),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            trailing: Icon(LucideIcons.chevronRight, color: subColor),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDark) {
    final bg = isDark ? Colors.redAccent.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05);
    final border = isDark ? Colors.redAccent.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2);
    final textCol = isDark ? Colors.redAccent : Colors.red;

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(authControllerProvider.notifier).logout();
            context.go('/');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, color: textCol),
              const SizedBox(width: 8),
              Text('Вийти', style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
