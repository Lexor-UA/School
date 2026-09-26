import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/branch_selector_pill.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/branch_invitation_qr_button.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/owner/controllers/owner_analytics_controller.dart';

class OwnerMain extends ConsumerStatefulWidget {
  const OwnerMain({super.key});

  @override
  ConsumerState<OwnerMain> createState() => _OwnerMainState();
}

class _OwnerMainState extends ConsumerState<OwnerMain> {
  String _selectedTimeframe = 'Місяць';
  
  void _showOwnerDevSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    final analytics = ref.watch(ownerAnalyticsControllerProvider);

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, ref),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'owner.business_overview'.tr(),
                        style: TextStyle(
                          color: themeConfig.isDark ? Colors.white70 : themeConfig.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      Text(
                        'owner.financial_metrics'.tr(),
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                      
                      const SizedBox(height: 32),
                      
                      // Hero Metric
                      _buildHeroMetricCard(themeConfig, tenancyState, analytics).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 24),
                      
                      // Owner Quick Actions
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildQuickAction(LucideIcons.barChart2, 'owner.reports'.tr(), Colors.blueAccent, 250, () {
                              context.go('/owner/reports');
                            }, themeConfig),
                            const SizedBox(width: 12),
                            _buildQuickAction(LucideIcons.users, 'owner.staff'.tr(), Colors.cyanAccent, 300, () {
                              context.go('/owner/staff');
                            }, themeConfig),
                            const SizedBox(width: 12),
                            _buildQuickAction(LucideIcons.banknote, 'owner.payouts'.tr(), Colors.pinkAccent, 350, () {
                              context.go('/owner/payouts');
                            }, themeConfig),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1),
                      
                      const SizedBox(height: 24),
                      
                      // KPI Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassMetricCard(
                              LucideIcons.users,
                              tenancyState.isAllLocations
                                  ? '${analytics.totalClients}'
                                  : (analytics.isViennaSelected
                                      ? '${analytics.vienna.clientCount}'
                                      : '${analytics.kyiv.clientCount}'),
                              'owner.clients'.tr(),
                              Colors.cyanAccent,
                              300,
                              themeConfig,
                              sublabel: tenancyState.isAllLocations
                                  ? '🇺🇦 ${analytics.kyiv.clientCount} • 🇦🇹 ${analytics.vienna.clientCount}'
                                  : (analytics.isViennaSelected ? '🇦🇹 Відень' : '🇺🇦 Київ'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGlassMetricCard(
                              LucideIcons.calendarCheck,
                              tenancyState.isAllLocations
                                  ? '${analytics.averageOccupancy}%'
                                  : (analytics.isViennaSelected
                                      ? '${analytics.vienna.occupancyPercent}%'
                                      : '${analytics.kyiv.occupancyPercent}%'),
                              'owner.occupancy'.tr(),
                              Colors.orangeAccent,
                              400,
                              themeConfig,
                              sublabel: tenancyState.isAllLocations
                                  ? '🇺🇦 84% • 🇦🇹 76%'
                                  : (analytics.isViennaSelected ? '🇦🇹 Відень' : '🇺🇦 Київ'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Glowing Chart
                      _buildGlowingChart(themeConfig).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 32),
                      
                      // Live Activity Feed
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          'owner.live_status'.tr(),
                          style: TextStyle(
                            color: themeConfig.isDark ? Colors.white70 : themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 16),
                      if (tenancyState.isAllLocations) ...[
                        _buildActivityItem(LucideIcons.arrowDownCircle, 'Новий абонемент Vienna', '+ € 180', Colors.greenAccent, 700, themeConfig, '🇦🇹'),
                        _buildActivityItem(LucideIcons.userPlus, 'Новий клієнт Kyiv', 'owner.today_time'.tr(), Colors.cyanAccent, 800, themeConfig, '🇺🇦'),
                        _buildActivityItem(LucideIcons.wallet, 'Виплата ЗП Kyiv', '- ₴ 12,000', Colors.pinkAccent, 900, themeConfig, '🇺🇦'),
                      ] else if (analytics.isViennaSelected) ...[
                        _buildActivityItem(LucideIcons.arrowDownCircle, 'Новий абонемент Vienna', '+ € 180', Colors.greenAccent, 700, themeConfig, '🇦🇹'),
                        _buildActivityItem(LucideIcons.arrowDownCircle, 'Разове відвідування', '+ € 45', Colors.cyanAccent, 800, themeConfig, '🇦🇹'),
                        _buildActivityItem(LucideIcons.wallet, 'Виплата тренеру', '- € 1,200', Colors.pinkAccent, 900, themeConfig, '🇦🇹'),
                      ] else ...[
                        _buildActivityItem(LucideIcons.arrowDownCircle, 'owner.new_payment'.tr(), '+ ₴ 2,400', Colors.greenAccent, 700, themeConfig, '🇺🇦'),
                        _buildActivityItem(LucideIcons.userPlus, 'owner.new_client'.tr(), 'owner.today_time'.tr(), Colors.cyanAccent, 800, themeConfig, '🇺🇦'),
                        _buildActivityItem(LucideIcons.wallet, 'owner.salary_payout'.tr(), '- ₴ 12,000', Colors.pinkAccent, 900, themeConfig, '🇺🇦'),
                      ],
                      
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: themeConfig.accentPrimary.withValues(alpha: 0.3), blurRadius: 15)],
                        ),
                        child: const AvatarPicker(
                          heroTag: 'hero_avatar_Власникам',
                          radius: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'owner.hello'.tr()}, ${user?.name ?? "Власник"}',
                              style: TextStyle(color: themeConfig.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('CitySwim CEO', style: TextStyle(color: themeConfig.accentPrimary, fontSize: 13, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThemeHeaderButton(size: 38),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.logOut, color: themeConfig.textSecondary),
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/?skipSplash=true');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Селектор філій CitySwim (ТЗ п. 8: Перемикач Київ / Відень / Всі філії)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BranchSelectorPill(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'AquatixLab SaaS SuperAdmin',
                      onPressed: () {
                        context.push('/superadmin');
                      },
                      icon: const Icon(LucideIcons.shieldCheck, color: Color(0xFF00E5FF), size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const BranchInvitationQrButton(),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 80.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMetricCard(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    final isDark = themeConfig.isDark;

    if (tenancyState.isAllLocations) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    Colors.cyanAccent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? const Color(0xFF818CF8).withValues(alpha: 0.35)
                : themeConfig.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.globe, color: Color(0xFF818CF8), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Всі локації • Мережа CitySwim',
                        style: TextStyle(
                          color: Color(0xFF818CF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'UAH (₴) • EUR (€)',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'ДОХІД ЗА ФІЛІЯМИ (РОЗДІЛЬНО)',
              style: TextStyle(
                color: isDark ? Colors.white70 : themeConfig.textSecondary,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            // Два ізольовані блоки: Київ та Відень (ТЗ п. 8: НІКОЛИ не сумувати грн і євро)
            Row(
              children: [
                // Kyiv Box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🇺🇦', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Київ',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '+12.5%',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₴ 124,500',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Прибуток: ₴ 84,200',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : themeConfig.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Vienna Box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF818CF8).withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🇦🇹', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Відень',
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '+18.2%',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '€ 14,850',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Прибуток: € 9,650',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : themeConfig.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  size: 14,
                  color: isDark ? Colors.white38 : themeConfig.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ТЗ п. 8: Валюти відображаються роздільно без сумування різних валют',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : themeConfig.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Обрано конкретну філію (Київ або Відень)
    final summary = analytics.currentBranchSummary;
    final isVienna = analytics.isViennaSelected;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? LinearGradient(
                colors: isVienna
                    ? [const Color(0xFF818CF8).withValues(alpha: 0.2), Colors.purpleAccent.withValues(alpha: 0.05)]
                    : [Colors.blue.withValues(alpha: 0.2), Colors.cyanAccent.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? (isVienna ? const Color(0xFF818CF8).withValues(alpha: 0.4) : Colors.cyanAccent.withValues(alpha: 0.3))
              : themeConfig.cardBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? (isVienna ? const Color(0xFF818CF8).withValues(alpha: 0.12) : Colors.cyanAccent.withValues(alpha: 0.1))
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? null : Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: isDark ? Colors.greenAccent : const Color(0xFF059669), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+${summary.revenueGrowth}%',
                      style: TextStyle(
                        color: isDark ? Colors.greenAccent : const Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${summary.flagEmoji} ${summary.branchName}',
                      style: TextStyle(
                        color: themeConfig.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.wallet, color: isDark ? Colors.white54 : themeConfig.accentPrimary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'owner.total_revenue'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white70 : themeConfig.textSecondary,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.formatRevenue(),
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Прибуток: ${summary.formatNetProfit()} • Витрати: ${summary.formatExpenses()}',
            style: TextStyle(
              color: isDark ? Colors.white60 : themeConfig.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassMetricCard(
    IconData icon,
    String value,
    String label,
    Color accentColor,
    int delay,
    AppThemeConfig themeConfig, {
    String? sublabel,
  }) {
    final isDark = themeConfig.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : themeConfig.cardBorder,
          width: 1.1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 28),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(color: themeConfig.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : themeConfig.textSecondary, fontSize: 14)),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(
                color: accentColor.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    int delay,
    AppThemeConfig themeConfig, [
    String? flagEmoji,
  ]) {
    final isDark = themeConfig.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showOwnerDevSnackbar('${'owner.transaction_details'.tr()}: $title');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : themeConfig.cardBorder,
              width: 1.1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (flagEmoji != null) ...[
                          Text(flagEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(subtitle, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, int delay, VoidCallback onTap, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : themeConfig.cardBorder,
              width: 1.1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: themeConfig.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingChart(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: isDark
            ? LinearGradient(
                colors: [Colors.blue.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : themeConfig.cardBorder,
          width: 1.1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    'owner.profit_dynamics'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : themeConfig.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  {'key': 'owner.day'.tr(), 'val': 'День'}, 
                  {'key': 'owner.week'.tr(), 'val': 'Тиждень'}, 
                  {'key': 'owner.month'.tr(), 'val': 'Місяць'}
                ].map((item) {
                  final periodLabel = item['key']!;
                  final periodVal = item['val']!;
                  final isSelected = _selectedTimeframe == periodVal;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeframe = periodVal),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : themeConfig.accentPrimary.withValues(alpha: 0.12))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.cyanAccent : themeConfig.accentPrimary)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        periodLabel,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.cyanAccent : themeConfig.accentPrimary)
                              : (isDark ? Colors.white54 : themeConfig.textMuted),
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 140,
            width: double.infinity,
            // Rebuild chart when timeframe changes using a key
            child: CustomPaint(
              key: ValueKey(_selectedTimeframe),
              painter: SplineChartPainter(),
            ).animate().fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

class SplineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Add horizontal padding to prevent clipping of the dots
    final double padding = 8.0;
    final double w = size.width - (padding * 2);
    final double h = size.height;
    
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final path = Path();
    
    // Smooth curve points with padding
    path.moveTo(padding, h * 0.8);
    path.cubicTo(padding + (w * 0.2), h * 0.8, padding + (w * 0.2), h * 0.3, padding + (w * 0.4), h * 0.4);
    path.cubicTo(padding + (w * 0.6), h * 0.5, padding + (w * 0.7), h * 0.1, padding + (w * 0.8), h * 0.2);
    path.cubicTo(padding + (w * 0.9), h * 0.3, padding + (w * 0.95), h * 0.1, padding + w, 0);

    // Glow effect
    canvas.drawShadow(path, Colors.cyanAccent, 15, true);
    
    // Draw gradient fill below line
    final fillPath = Path.from(path)
      ..lineTo(padding + w, h)
      ..lineTo(padding, h)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.cyanAccent.withValues(alpha: 0.3), Colors.cyanAccent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(padding + (w * 0.4), h * 0.4), 4, dotPaint);
    canvas.drawCircle(Offset(padding + (w * 0.8), h * 0.2), 4, dotPaint);
    canvas.drawCircle(Offset(padding + w, 0), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
