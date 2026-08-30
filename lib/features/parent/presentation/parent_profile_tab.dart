import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:swimming_school_app/features/parent/presentation/parent_progress_tab.dart';

class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final childrenAsync = ref.watch(childrenControllerProvider);
    final hasChildren = (childrenAsync.value?.isNotEmpty ?? false);
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  child: const AvatarPicker(heroTag: 'hero_avatar_profile', radius: 40),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Андрій',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 200.ms),
                Text(
                  hasChildren ? 'parent.parent_account'.tr() : 'parent.client_account'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 3. Navigation List
          _buildSettingsTile(LucideIcons.userPlus, 'parent.add_child'.tr(), textColor, textSubColor, cardBgColor, cardBorderColor, () {
            _showAddChildDialog(context, ref, isDark);
          }),
          _buildSettingsTile(LucideIcons.trendingUp, 'parent.progress'.tr(), textColor, textSubColor, cardBgColor, cardBorderColor, () {
            ref.read(parentTabProvider.notifier).setTab(0);
          }),
          _buildSettingsTile(LucideIcons.trophy, 'parent.my_achievements'.tr(), textColor, textSubColor, cardBgColor, cardBorderColor, () {
            Navigator.push(context, FadeScaleRoute(page: const TrophyRoomScreen()));
          }),
          _buildSettingsTile(LucideIcons.settings, 'parent.settings'.tr(), textColor, textSubColor, cardBgColor, cardBorderColor, () {
            _showSettingsDialog(context, isDark);
          }),
          _buildSettingsTile(LucideIcons.helpCircle, 'parent.help'.tr(), textColor, textSubColor, cardBgColor, cardBorderColor, () {
            _showHelpDialog(context, isDark);
          }),
          
          const SizedBox(height: 24),
          _buildLogoutButton(context, ref, isDark).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();

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
                Text('parent.add_child'.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "parent.child_name".tr(),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: ageController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "parent.child_age".tr(),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        final age = int.tryParse(ageController.text.trim());
                        ref.read(childrenControllerProvider.notifier).addChild(nameController.text.trim(), age);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('parent.save'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 8),
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
            ref.read(parentTabProvider.notifier).setTab(0);
            ref.read(authControllerProvider.notifier).logout();
            context.go('/');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, color: textCol, size: 20),
              const SizedBox(width: 8),
              Text('parent.logout_short'.tr(), style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Налаштування', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Сповіщення', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: true,
              onChanged: (v) {},
              activeColor: AppTheme.accentTeal,
            ),
            SwitchListTile(
              title: Text('Темна тема', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              value: true,
              onChanged: (v) {},
              activeColor: AppTheme.accentTeal,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрити'),
          )
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkTheme.scaffoldBackgroundColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Допомога', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.messageCircle, color: Colors.blueAccent),
              title: Text('Написати в підтримку', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Відкриття чату підтримки...')));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bookOpen, color: Colors.greenAccent),
              title: Text('Поширені запитання', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрити'),
          )
        ],
      ),
    );
  }
}
