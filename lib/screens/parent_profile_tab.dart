import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/core/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/achievement_card.dart';
import '../utils/page_transitions.dart';
import 'trophy_room_screen.dart';
import 'anatomy_progress_screen.dart';

class ParentProfileTab extends ConsumerStatefulWidget {
  const ParentProfileTab({super.key});

  @override
  ConsumerState<ParentProfileTab> createState() => _ParentProfileTabState();
}

class _ParentProfileTabState extends ConsumerState<ParentProfileTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adaptive colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSubColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : AppTheme.primaryBlue;
    final cardBgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.6);
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);
    final anatomyBannerBg = isDark ? const Color(0xFF030D1B) : Colors.white.withValues(alpha: 0.8);
    final anatomyBannerBorder = isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : AppTheme.primaryBlue.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Мій Профіль', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeControllerProvider) ? LucideIcons.moon : LucideIcons.sun,
              color: ref.watch(themeControllerProvider) ? Colors.white : Colors.orange,
            ),
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                // Parallax effect: avatar moves at half the scroll speed
                double offset = 0;
                if (_scrollController.hasClients) {
                  offset = _scrollController.offset * 0.5;
                }
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.accentTeal, isDark ? Colors.white : Colors.blue.shade100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accentTeal.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: const Hero(
                      tag: 'hero_avatar_Клієнтам',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400'),
                      ),
                    ),
                  ).animate().scale(duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Мія К.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 200.ms),
                  Text(
                    'Група: Юніори Pro',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 24),
                  
                  // EXP Bar
                  if (user != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Рівень ${user.level}: Дельфін', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        Text('${user.xp} / ${user.maxXp} XP', style: TextStyle(color: textSubColor, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: user.xp / user.maxXp,
                        minHeight: 12,
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Child Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('24', 'Занять', LucideIcons.calendar, textColor, textSubColor, accentColor, cardBgColor),
              _buildStatItem('15 км', 'Дистанція', LucideIcons.waves, textColor, textSubColor, accentColor, cardBgColor),
              _buildStatItem('Кроль', 'Улюблений', LucideIcons.heart, textColor, textSubColor, accentColor, cardBgColor),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          
          // Anatomy Progress Banner
          GestureDetector(
            onTap: () {
              Navigator.push(context, FadeScaleRoute(page: const AnatomyProgressScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: anatomyBannerBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: anatomyBannerBorder),
                boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.activity, color: accentColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Анатомія Прогресу', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Переглянути розвиток м\'язів', style: TextStyle(color: isDark ? Colors.cyanAccent.withValues(alpha: 0.8) : AppTheme.primaryBlue, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: textSubColor),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 32),

          // Badges / Achievements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Вітрина Трофеїв',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, FadeScaleRoute(page: const TrophyRoomScreen()));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Увійти в 3D Кімнату', style: TextStyle(color: isDark ? Colors.amber : Colors.orange.shade700, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.cuboid, color: isDark ? Colors.amber : Colors.orange.shade700, size: 16),
                  ],
                ),
              )
            ],
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 16),
          
          if (user != null && user.achievements.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: user.achievements.length,
                itemBuilder: (context, index) {
                  return AchievementCard(achievement: user.achievements[index])
                      .animate().slideX(begin: 0.2, end: 0, delay: (600 + index * 100).ms).fadeIn();
                },
              ),
            )
          else
            Center(child: Text('Немає досягнень', style: TextStyle(color: textSubColor))),

          const SizedBox(height: 48),

          _buildSettingsTile(LucideIcons.settings, 'Налаштування акаунту', textColor, textSubColor, cardBgColor, cardBorderColor).animate().slideX(delay: 700.ms),
          _buildSettingsTile(LucideIcons.creditCard, 'Оплата та підписки', textColor, textSubColor, cardBgColor, cardBorderColor).animate().slideX(delay: 800.ms),
          _buildSettingsTile(LucideIcons.bell, 'Сповіщення', textColor, textSubColor, cardBgColor, cardBorderColor).animate().slideX(delay: 900.ms),
          _buildSettingsTile(LucideIcons.shieldQuestion, 'Допомога та Підтримка', textColor, textSubColor, cardBgColor, cardBorderColor).animate().slideX(delay: 1000.ms),
          const SizedBox(height: 32),
          _buildLogoutButton(context, ref, isDark).animate().fadeIn(delay: 1100.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color textColor, Color textSubColor, Color accentColor, Color bg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: textSubColor, fontSize: 12)),
      ],
    );
  }


  Widget _buildSettingsTile(IconData icon, String title, Color textColor, Color subColor, Color bg, Color border) {
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
            onTap: () {},
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isDark) {
    final bg = isDark ? Colors.redAccent.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.05);
    final border = isDark ? Colors.redAccent.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.2);
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
            Navigator.pop(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, color: textCol),
              const SizedBox(width: 8),
              Text('Вийти з акаунту', style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
