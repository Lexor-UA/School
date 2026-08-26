import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme/theme.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'dart:ui';
import 'package:swimming_school_app/features/parent/presentation/pool_map_screen.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_booking_screen.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_main.dart';

class ParentHomeTab extends ConsumerWidget {
  const ParentHomeTab({super.key});

  void _showNotifications(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('parent.notifications'.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildNotificationItem('Тренування перенесено', 'Сьогодні · 16:15', LucideIcons.clock, isDark),
                  _buildNotificationItem('Абонемент', 'Залишилось 2 заняття', LucideIcons.creditCard, isDark),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('parent.close'.tr(), style: TextStyle(color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    ref.watch(subscriptionControllerProvider);
    final currentSub = user != null ? ref.read(subscriptionControllerProvider.notifier).getSubscriptionForUser(user.id) : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;

    // TODO: Connect to real schedule data. Using mock for UI redesign.
    bool hasNextClass = DateTime.now().millisecond > -1; // Hack to make it dynamic for UI preview

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: -5),
                  ],
                ),
                child: const AvatarPicker(
                  heroTag: 'hero_avatar_Клієнтам_home',
                  radius: 28,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Привіт, ${user?.name ?? 'Гість'} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.bell, color: textColor, size: 24),
                      onPressed: () => _showNotifications(context, isDark),
                    ),
                  ).animate().fade(delay: 200.ms),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.3,1.3), duration: 1.seconds),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // 2. MAIN CLASS CARD
          Text('Наступне заняття', style: TextStyle(color: textSubColor, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          
          if (hasNextClass)
            _buildNextClassCard(context, isDark, accentColor, textColor, textSubColor)
          else
            _buildEmptyStateCard(context, isDark, accentColor, textColor),
          
          const SizedBox(height: 24),

          // 3. PROGRESS ROW
          _buildActionRow(
            context: context,
            title: 'Мій прогрес',
            subtitle: '24 тренування · 15 км',
            icon: LucideIcons.trendingUp,
            isDark: isDark,
            onTap: () {
              ref.read(parentTabProvider.notifier).setTab(2); // Jump to Progress Tab
            }
          ),
          const SizedBox(height: 16),

          // 4. SUBSCRIPTION ROW
          _buildActionRow(
            context: context,
            title: 'Абонемент',
            subtitle: currentSub != null ? 'Залишилось ${currentSub.remainingClasses} заняття' : 'Немає активного абонемента',
            icon: LucideIcons.creditCard,
            isDark: isDark,
            onTap: () {
              ref.read(parentTabProvider.notifier).setTab(3); // Jump to Profile Tab for Subscription info
            }
          ),
          const SizedBox(height: 32),

          // 5. 3D POOL SIMPLIFIED BUTTON
          _build3DPoolButton(context, isDark, accentColor),

          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildNextClassCard(BuildContext context, bool isDark, Color accentColor, Color textColor, Color textSubColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(LucideIcons.waves, color: accentColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text('СЬОГОДНІ', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              ),
                              const Spacer(),
                              Text('16:00 - 17:00', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('🏊 Кроль', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('HappyLand · Доріжка 3', style: TextStyle(color: textSubColor, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Деталі заняття будуть доступні незабаром")));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
                      border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Відкрити заняття', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                        Icon(LucideIcons.arrowRight, color: accentColor, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms).fadeIn();
  }

  Widget _buildEmptyStateCard(BuildContext context, bool isDark, Color accentColor, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), width: 1.5),
            // Dashed border effect could be cool here but standard border is safer
          ),
          child: Column(
            children: [
              Icon(LucideIcons.calendarX2, color: Colors.white54, size: 40),
              const SizedBox(height: 16),
              Text('У вас поки немає запланованих занять', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParentBookingScreen(date: DateTime.now()))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Записатися', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildActionRow({required BuildContext context, required String title, required String subtitle, required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54, size: 20),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _build3DPoolButton(BuildContext context, bool isDark, Color accentColor) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoolMapScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.box, size: 20, color: accentColor),
              const SizedBox(width: 12),
              Text('3D Карта Басейну', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
