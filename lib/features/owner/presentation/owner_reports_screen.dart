import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/features/admin/presentation/widgets/branch_selector_pill.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/owner/controllers/owner_analytics_controller.dart';
import 'package:go_router/go_router.dart';

class OwnerReportsScreen extends ConsumerStatefulWidget {
  const OwnerReportsScreen({super.key});

  @override
  ConsumerState<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends ConsumerState<OwnerReportsScreen> {
  String _selectedTimeframe = 'Місяць';

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    final analytics = ref.watch(ownerAnalyticsControllerProvider);
    final isDark = themeConfig.isDark;

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          if (isDark) const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, themeConfig),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalRevenueCard(themeConfig, tenancyState, analytics)
                            .animate()
                            .fadeIn()
                            .slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildTimeframeSelector(themeConfig).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 24),
                        Text(
                          'СТРУКТУРА ДОХОДІВ',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 16),
                        _buildRevenueBreakdown(themeConfig).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),
                        Text(
                          'КЛЮЧОВІ МЕТРИКИ',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : themeConfig.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          LucideIcons.users,
                          'Клієнтська база',
                          tenancyState.isAllLocations
                              ? '${analytics.totalClients}'
                              : (analytics.isViennaSelected
                                  ? '${analytics.vienna.clientCount}'
                                  : '${analytics.kyiv.clientCount}'),
                          '+12%',
                          Colors.cyanAccent,
                          LucideIcons.userMinus,
                          'Відтік (Churn)',
                          tenancyState.isAllLocations
                              ? '2.2%'
                              : (analytics.isViennaSelected
                                  ? '${analytics.vienna.churnPercent}%'
                                  : '${analytics.kyiv.churnPercent}%'),
                          '-0.5%',
                          Colors.greenAccent,
                          themeConfig,
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                        const SizedBox(height: 16),
                        _buildMetricRow(
                          LucideIcons.trendingUp,
                          'LTV Клієнта',
                          tenancyState.isAllLocations
                              ? '₴ 12.4k / € 850'
                              : (analytics.isViennaSelected
                                  ? analytics.vienna.formatLtv()
                                  : analytics.kyiv.formatLtv()),
                          '+8%',
                          Colors.orangeAccent,
                          LucideIcons.shoppingCart,
                          'Нові абонементи',
                          tenancyState.isAllLocations
                              ? '${analytics.totalNewSubscriptions}'
                              : (analytics.isViennaSelected
                                  ? '${analytics.vienna.newSubscriptions}'
                                  : '${analytics.kyiv.newSubscriptions}'),
                          '+15%',
                          Colors.purpleAccent,
                          themeConfig,
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeConfig themeConfig) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 20.0, 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: themeConfig.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Фінансові Звіти',
              style: TextStyle(
                color: themeConfig.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const BranchSelectorPill(),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    final isDark = themeConfig.isDark;

    // Режим "Всі локації": окремі показники для кожної філії без змішування валют (ТЗ п. 26)
    if (tenancyState.isAllLocations) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? const Color(0xFF818CF8).withValues(alpha: 0.35) : themeConfig.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ЧИСТИЙ ПРИБУТОК ЗА ФІЛІЯМИ',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+14.8% заг.',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                        color: isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🇺🇦', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('Київ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₴ 84,200',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Витрати: ₴ 40,300',
                          style: TextStyle(color: Colors.pinkAccent, fontSize: 12),
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
                        color: isDark ? const Color(0xFF818CF8).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('🇦🇹', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('Відень', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '€ 9,650',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Витрати: € 5,200',
                          style: TextStyle(color: Colors.pinkAccent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 13,
                  color: isDark ? Colors.white38 : themeConfig.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ТЗ п. 26: Розділення за філіями без конвертації та сумування різних валют',
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

    // Режим однієї філії (Київ або Відень)
    final summary = analytics.currentBranchSummary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.blueAccent.withValues(alpha: 0.3) : themeConfig.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.blueAccent.withValues(alpha: 0.1) : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'ЧИСТИЙ ПРИБУТОК',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : themeConfig.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${summary.flagEmoji} ${summary.branchName}',
                      style: TextStyle(
                        color: themeConfig.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${summary.revenueGrowth}%',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary.formatNetProfit(),
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Витрати: ${summary.formatExpenses()}',
            style: const TextStyle(color: Colors.pinkAccent, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(AppThemeConfig themeConfig) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Тиждень', 'Місяць', 'Квартал', 'Рік'].map((period) {
        final isSelected = _selectedTimeframe == period;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeframe = period),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeConfig.accentPrimary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? themeConfig.accentPrimary
                    : (themeConfig.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
              ),
            ),
            child: Text(
              period,
              style: TextStyle(
                color: isSelected
                    ? themeConfig.accentPrimary
                    : (themeConfig.isDark ? Colors.white54 : themeConfig.textSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRevenueBreakdown(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : themeConfig.cardBorder,
        ),
      ),
      child: Column(
        children: [
          _buildBreakdownItem('Групові тренування', 65, Colors.cyanAccent, themeConfig),
          const SizedBox(height: 16),
          _buildBreakdownItem('Індивідуальні тренування', 25, Colors.purpleAccent, themeConfig),
          const SizedBox(height: 16),
          _buildBreakdownItem('Разові візити', 10, Colors.orangeAccent, themeConfig),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int percentage, Color color, AppThemeConfig themeConfig) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: themeConfig.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    IconData icon1,
    String label1,
    String val1,
    String change1,
    Color color1,
    IconData icon2,
    String label2,
    String val2,
    String change2,
    Color color2,
    AppThemeConfig themeConfig,
  ) {
    return Row(
      children: [
        Expanded(child: _buildSmallMetricCard(icon1, label1, val1, change1, color1, themeConfig)),
        const SizedBox(width: 16),
        Expanded(child: _buildSmallMetricCard(icon2, label2, val2, change2, color2, themeConfig)),
      ],
    );
  }

  Widget _buildSmallMetricCard(
    IconData icon,
    String label,
    String value,
    String change,
    Color color,
    AppThemeConfig themeConfig,
  ) {
    final isPositive = change.startsWith('+');
    final isDark = themeConfig.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : themeConfig.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.pinkAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: themeConfig.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : themeConfig.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
