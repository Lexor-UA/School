import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/subscription_controller.dart';
import 'pool_map_screen.dart';

class ParentHomeTab extends ConsumerWidget {
  const ParentHomeTab({super.key});

  void _showNotifications(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1)),
            ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Сповіщення', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildNotificationItem('Тренування перенесено', 'Сьогоднішнє заняття о 16:00 перенесено на 16:15.', LucideIcons.clock, isDark),
                  _buildNotificationItem('Нове досягнення!', 'Ваша дитина отримала бейдж "Акула басейну".', LucideIcons.award, isDark),
                  _buildNotificationItem('Абонемент', 'Залишилось 2 заняття. Не забудьте подовжити.', LucideIcons.creditCard, isDark),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Закрити', style: TextStyle(color: isDark ? Colors.cyanAccent : AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
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
    );;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    ref.watch(subscriptionControllerProvider);
    final currentSub = user != null ? ref.read(subscriptionControllerProvider.notifier).getSubscriptionForUser(user.id) : null;

    final int level = user?.level ?? 1;
    final int xp = user?.xp ?? 0;
    final int maxXp = user?.maxXp ?? 1000;
    final double xpPercent = (xp / maxXp).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adaptive Colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6);
    final cardBorderColor = isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : AppTheme.primaryBlue.withValues(alpha: 0.3);
    final shadowColor = isDark ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GAMIFIED HEADER
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: accentColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: -5),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=400'),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 10)],
                      ),
                      child: Text('Lvl $level', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привіт, ${user?.name ?? 'Олено'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                height: 10,
                                width: MediaQuery.of(context).size.width * 0.4 * xpPercent,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.yellowAccent]),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.8), blurRadius: 10)],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('XP', style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ).animate().fade(duration: 400.ms).slideX(begin: 0.1, end: 0),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
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
          
          // 2. NEXT CLASS TICKET (Boarding Pass Style)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(color: shadowColor, blurRadius: 20, spreadRadius: 2),
                ],
              ),
                child: Row(
                  children: [
                    // Ticket stub (Left side)
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : AppTheme.primaryBlue.withValues(alpha: 0.1),
                        border: Border(right: BorderSide(color: cardBorderColor, width: 2, style: BorderStyle.solid)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.clock, color: accentColor, size: 36),
                          const SizedBox(height: 12),
                          Text('16:00', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    // Ticket body (Right side)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text('СЬОГОДНІ', style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ),
                            const SizedBox(height: 12),
                            Text('Батерфляй (Юніори)', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(LucideIcons.user, color: accentColor, size: 16),
                                const SizedBox(width: 6),
                                Text('Тренер: Олександр В.', style: TextStyle(color: textSubColor, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideX(begin: -0.2, end: 0, duration: 500.ms).fadeIn(),
          const SizedBox(height: 24),

          // 3. HOLOGRAPHIC SUBSCRIPTION CARD (Keep this one dark/colorful always as it's a solid card)
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E90FF).withValues(alpha: 0.8),
                    const Color(0xFF00BFFF).withValues(alpha: 0.6),
                    const Color(0xFFFF00FF).withValues(alpha: 0.4), // Holographic pink tint
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E90FF).withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 5),
                ],
              ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: 0, top: 0,
                      child: Icon(LucideIcons.wifi, color: Colors.white, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                          child: const Text('АКТИВНИЙ АБОНЕМЕНТ', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Aqua Pro Elite', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${currentSub?.remainingClasses ?? 8}', style: const TextStyle(color: Colors.white, fontSize: 56, height: 1.0, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Text('/ ${currentSub?.totalClasses ?? 12} занять', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ДІЄ ДО', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            const Text('15 ЛИСТ 2026', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuart).fadeIn(),
          const SizedBox(height: 24),

          // 4. ANIMATED 3D MAP BUTTON
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blueAccent, Colors.cyanAccent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).slide(begin: const Offset(-1, -1), end: const Offset(1, 1), duration: 2.seconds),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PoolMapScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.map, size: 32, color: Colors.white),
                            SizedBox(width: 16),
                            Text('ВІДКРИТИ 3D КАРТУ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds),
          ),
          const SizedBox(height: 48),

          // 5. VIP PASS (QR CODE)
          Center(
            child: Column(
              children: [
                Text('ВАША ПЕРЕПУСТКА', style: TextStyle(color: textSubColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: cardBorderColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('VIP ACCESS', style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: QrImageView(
                              data: user?.id ?? 'invalid_user',
                              version: QrVersions.auto,
                              size: 180.0,
                              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.primaryBlue),
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(user?.name.toUpperCase() ?? 'ОЛЕНА', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Прикладіть код до турнікета',
                  style: TextStyle(color: accentColor, fontSize: 14, letterSpacing: 1.1),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 1000.ms),
              ],
            ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }
}

