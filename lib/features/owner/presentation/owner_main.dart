import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/shared/widgets/avatar_picker.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/owner/controllers/owner_analytics_controller.dart';
import 'package:swimming_school_app/features/owner/presentation/owner_staff_screen.dart';
import 'package:swimming_school_app/features/owner/presentation/owner_payouts_screen.dart';
import 'package:swimming_school_app/features/admin/presentation/payment_sheet.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';

/// Головний екран Власника (CitySwim CEO)
/// Виконано за стандартом Apple VisionOS Deep Sapphire Glass:
/// - 4 роздільні вкладки: Пульс, Фінанси, Команда, Виплати
/// - Плаваючий навігаційний бар з сапфіровим неоновим підсвічуванням
/// - Швидкий сегментований перемикач філій (Вся мережа / Київ / Відень)
/// - Фінансовий пульс мережі з ізоляцією валют (₴ та €)
/// - Операційні метрики здоров'я клубів + Швидкий перехід до боржників
class OwnerMain extends ConsumerStatefulWidget {
  const OwnerMain({super.key});

  @override
  ConsumerState<OwnerMain> createState() => _OwnerMainState();
}

class _OwnerMainState extends ConsumerState<OwnerMain> {
  int _selectedTabIndex = 0;
  String _selectedTimeframe = 'Місяць';

  String _formatClientsCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) {
      return '$count клієнтів';
    }
    if (mod10 == 1) {
      return '$count клієнт';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count клієнти';
    }
    return '$count клієнтів';
  }

  String _formatCoachesCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 19) {
      return '$count тренерів';
    }
    if (mod10 == 1) {
      return '$count тренер';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count тренери';
    }
    return '$count тренерів';
  }

  void _showOwnerDevSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPaymentAttentionSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentSheet(initialTabIndex: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(appThemeControllerProvider);
    final tenancyState = ref.watch(tenancyControllerProvider);
    final analytics = ref.watch(ownerAnalyticsControllerProvider);
    final adminDashboard = ref.watch(adminDashboardProvider);
    final isDark = themeConfig.isDark;

    return Scaffold(
      backgroundColor: themeConfig.scaffoldBg,
      extendBody: true,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          if (isDark) const Positioned.fill(child: WaterParticles()),
          IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildPulseTab(context, ref, themeConfig, tenancyState, analytics, adminDashboard),
              _buildFinanceTab(context, ref, themeConfig, tenancyState, analytics),
              const OwnerStaffScreen(isEmbedded: true),
              const OwnerPayoutsScreen(isEmbedded: true),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(themeConfig),
    );
  }

  // ==========================================
  // TAB 0: ПУЛЬС (EXECUTIVE COCKPIT)
  // ==========================================
  Widget _buildPulseTab(
    BuildContext context,
    WidgetRef ref,
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
    AdminDashboardState adminDashboard,
  ) {
    final isDark = themeConfig.isDark;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Executive Top Bar
          _buildAppBar(context, ref, themeConfig),

          // 2. Segmented Branch Switcher
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 12.0),
              child: _buildSegmentedBranchSwitcher(tenancyState, themeConfig),
            ),
          ),

          // 3. Compact Main Dashboard Body
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'owner.business_overview'.tr(),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'owner.financial_metrics'.tr(),
                            style: TextStyle(
                              color: themeConfig.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Live Indicator Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.45),
                          width: 1,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE PULSE',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 250.ms),

                const SizedBox(height: 18),

                // Financial Pulse Hero Section
                _buildFinancialPulseSection(themeConfig, tenancyState, analytics)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.08),

                const SizedBox(height: 22),

                // Operational Pulse Grid (4 KPI Cards)
                _buildOperationalPulseGrid(themeConfig, tenancyState, analytics, adminDashboard)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.08),

                const SizedBox(height: 180),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ФІНАНСИ (ANALYTICS & DYNAMICS)
  // ==========================================
  Widget _buildFinanceTab(
    BuildContext context,
    WidgetRef ref,
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Finance Header
          SliverToBoxAdapter(
            child: _buildFinanceHeader(context, themeConfig),
          ),

          // 2. Segmented Branch Switcher
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 12.0),
              child: _buildSegmentedBranchSwitcher(tenancyState, themeConfig),
            ),
          ),

          // 3. Finance Body
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Glowing Spline Chart
                _buildGlowingChart(themeConfig)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.08),

                const SizedBox(height: 24),

                // Revenue Structure Breakdown
                _buildRevenueBreakdownCard(themeConfig, tenancyState, analytics)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.08),

                const SizedBox(height: 24),

                // Key Financial KPIs
                _buildFinancialKpiGrid(themeConfig, tenancyState, analytics)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.08),

                const SizedBox(height: 24),

                // Live Activity Feed
                _buildLiveActivitySection(themeConfig, tenancyState, analytics)
                    .animate()
                    .fadeIn(delay: 400.ms),

                const SizedBox(height: 180),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceHeader(BuildContext context, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.trendingUp, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ФІНАНСИ ТА АНАЛІТИКА',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Динаміка мережі',
                    style: TextStyle(
                      color: themeConfig.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const ThemeHeaderButton(size: 38),
        ],
      ),
    );
  }


  // ==========================================
  // 1. EXECUTIVE TOP BAR
  // ==========================================
  Widget _buildAppBar(BuildContext context, WidgetRef ref, AppThemeConfig themeConfig) {
    final user = ref.watch(authControllerProvider);
    final isDark = themeConfig.isDark;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // CEO Avatar & Greeting
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.35 : 0.20),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const AvatarPicker(
                      heroTag: 'hero_avatar_Власникам',
                      radius: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'owner.hello'.tr()}, ${user?.name ?? "Власник"}',
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.crown, color: Colors.white, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    'CitySwim CEO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Action Buttons: SuperAdmin, Theme Toggle, Logout
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SuperAdmin Access
                IconButton(
                  tooltip: 'AquatixLab SaaS SuperAdmin',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/superadmin');
                  },
                  icon: Icon(
                    LucideIcons.shieldCheck,
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    size: 19,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                        : const Color(0xFFE0F2FE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(8),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                          : const Color(0xFFBAE6FD),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Theme Toggle
                const ThemeHeaderButton(size: 38),
                const SizedBox(width: 4),

                // Logout
                IconButton(
                  icon: Icon(
                    LucideIcons.logOut,
                    color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                    size: 18,
                  ),
                  tooltip: 'Вийти з акаунту',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFF43F5E).withValues(alpha: 0.16)
                        : const Color(0xFFFFF1F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(8),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                          : const Color(0xFFFECDD3),
                      width: 1,
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
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
      ),
    );
  }

  // ==========================================
  // 2. SEGMENTED BRANCH SWITCHER (Variant 1)
  // ==========================================
  Widget _buildSegmentedBranchSwitcher(TenancyState tenancyState, AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    final tabs = [
      {'id': 'all', 'label': 'Вся мережа', 'flag': '🌐', 'currency': '₴ / €'},
      {'id': 'kyiv', 'label': 'Київ', 'flag': '🇺🇦', 'currency': '₴'},
      {'id': 'vienna', 'label': 'Відень', 'flag': '🇦🇹', 'currency': '€'},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07182C).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.40) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: tabs.map((tab) {
              final tabId = tab['id']!;
              final isSelected = (tabId == 'all' && tenancyState.isAllLocations) ||
                  (!tenancyState.isAllLocations && tenancyState.activeBranch?.id == tabId);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(tenancyControllerProvider.notifier).switchBranch(tabId);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? (tabId == 'all'
                              ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                )
                              : (tabId == 'kyiv'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                    )))
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1,
                            )
                          : Border.all(color: Colors.transparent),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (tabId == 'all'
                                        ? const Color(0xFF6366F1)
                                        : (tabId == 'kyiv' ? const Color(0xFF00E5FF) : const Color(0xFFA855F7)))
                                    .withValues(alpha: isDark ? 0.38 : 0.24),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (tabId == 'all')
                          Icon(
                            LucideIcons.globe,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0284C7)),
                          )
                        else
                          Text(
                            tab['flag']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          tab['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. FINANCIAL PULSE HERO SECTION
  // ==========================================
  Widget _buildFinancialPulseSection(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    if (tenancyState.isAllLocations) {
      return _buildDualBranchPulseCards(themeConfig, analytics);
    }
    return _buildSingleBranchDeepCard(themeConfig, analytics);
  }

  /// Режим «Вся мережа»: Дві паралельні преміальні картки для Києва та Відня
  Widget _buildDualBranchPulseCards(AppThemeConfig themeConfig, OwnerAnalyticsState analytics) {
    final isDark = themeConfig.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kyiv Card
        _buildBranchPulseCard(
          themeConfig: themeConfig,
          flag: analytics.kyiv.flagEmoji,
          branchName: analytics.kyiv.branchName,
          currencyCode: '${analytics.kyiv.currencyCode} (${analytics.kyiv.currencySymbol})',
          revenueText: analytics.kyiv.formatRevenue(),
          profitText: analytics.kyiv.formatNetProfit(),
          expensesText: analytics.kyiv.formatExpenses(),
          growthText: '+${analytics.kyiv.revenueGrowth}%',
          statusText: '🟢 Стабільна робота • ${_formatClientsCount(analytics.kyiv.clientCount)} • ${_formatCoachesCount(analytics.kyiv.coachCount)}',
          primaryGradient: isDark
              ? [const Color(0xFF0C2442), const Color(0xFF051222)]
              : [Colors.white, const Color(0xFFF0F9FF)],
          accentColor: const Color(0xFF00E5FF),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(tenancyControllerProvider.notifier).switchBranch('kyiv');
          },
        ),

        const SizedBox(height: 12),

        // Vienna Card
        _buildBranchPulseCard(
          themeConfig: themeConfig,
          flag: analytics.vienna.flagEmoji,
          branchName: analytics.vienna.branchName,
          currencyCode: '${analytics.vienna.currencyCode} (${analytics.vienna.currencySymbol})',
          revenueText: analytics.vienna.formatRevenue(),
          profitText: analytics.vienna.formatNetProfit(),
          expensesText: analytics.vienna.formatExpenses(),
          growthText: '+${analytics.vienna.revenueGrowth}%',
          statusText: '🟢 Активне зростання • ${_formatClientsCount(analytics.vienna.clientCount)} • ${_formatCoachesCount(analytics.vienna.coachCount)}',
          primaryGradient: isDark
              ? [const Color(0xFF1E1742), const Color(0xFF0A0C22)]
              : [Colors.white, const Color(0xFFFAF5FF)],
          accentColor: const Color(0xFFA855F7),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(tenancyControllerProvider.notifier).switchBranch('vienna');
          },
        ),

        const SizedBox(height: 10),

        // Multi-currency compliance note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C1F38).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.90),
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF0F9FF)],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Мультивалютний контроль: кожна філія має ізольований баланс (₴ та €)',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: isDark ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchPulseCard({
    required AppThemeConfig themeConfig,
    required String flag,
    required String branchName,
    required String currencyCode,
    required String revenueText,
    required String profitText,
    required String expensesText,
    required String growthText,
    required String statusText,
    required List<Color> primaryGradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = themeConfig.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? accentColor.withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Text(flag, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branchName,
                                style: TextStyle(
                                  color: themeConfig.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                currencyCode,
                                style: TextStyle(
                                  color: isDark
                                      ? accentColor
                                      : (accentColor == const Color(0xFF00E5FF)
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFF7C3AED)),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Growth pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.20)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.40 : 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              size: 13,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              growthText,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Large Revenue
                  Text(
                    'МІСЯЧНИЙ ДОХІД',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    revenueText,
                    style: TextStyle(
                      color: themeConfig.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Telemetry Pod
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.arrowUpRight,
                              size: 14,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Прибуток: $profitText',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Витрати: $expensesText',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                            fontSize: 12,
                            fontWeight: isDark ? FontWeight.w600 : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Status line
                  Text(
                    statusText,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155),
                      fontSize: 11.5,
                      fontWeight: isDark ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Режим однієї філії (Київ або Відень)
  Widget _buildSingleBranchDeepCard(AppThemeConfig themeConfig, OwnerAnalyticsState analytics) {
    final summary = analytics.currentBranchSummary;
    final isVienna = analytics.isViennaSelected;
    final isDark = themeConfig.isDark;

    final primaryAccent = isVienna ? const Color(0xFFA855F7) : const Color(0xFF00E5FF);

    final marginRatio = summary.totalRevenue > 0
        ? (summary.netProfit / summary.totalRevenue)
        : 0.0;
    final marginPercentStr = summary.totalRevenue > 0
        ? '${(marginRatio * 100).toStringAsFixed(1)}%'
        : '0.0%';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? (isVienna
                      ? [const Color(0xFF1C133B), const Color(0xFF0B071A)]
                      : [const Color(0xFF0C2442), const Color(0xFF061426)])
                  : [Colors.white, isVienna ? const Color(0xFFFAF5FF) : const Color(0xFFF0F9FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? primaryAccent.withValues(alpha: 0.38) : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryAccent.withValues(alpha: isDark ? 0.16 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(summary.flagEmoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        summary.branchName,
                        style: TextStyle(
                          color: themeConfig.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.trendingUp, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          '+${summary.revenueGrowth}%',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Large Revenue
              Text(
                'owner.total_revenue'.tr().toUpperCase(),
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.formatRevenue(),
                style: TextStyle(
                  color: themeConfig.textPrimary,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 16),

              // Margin Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Маржинальність бізнесу',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$marginPercentStr чистий прибуток',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 7,
                  child: LinearProgressIndicator(
                    value: marginRatio.clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFFE0F2FE),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Financial Breakdown Pod
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Чистий прибуток',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.formatNetProfit(),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Витрати школи',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.formatExpenses(),
                              style: TextStyle(
                                color: themeConfig.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LTV Клієнта',
                              style: TextStyle(
                                color: isDark
                                    ? primaryAccent
                                    : (primaryAccent == const Color(0xFF00E5FF)
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFF7C3AED)),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary.formatLtv(),
                              style: TextStyle(
                                color: isDark
                                    ? primaryAccent
                                    : (primaryAccent == const Color(0xFF00E5FF)
                                        ? const Color(0xFF0284C7)
                                        : const Color(0xFF7C3AED)),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4. OPERATIONAL PULSE GRID (4 KPI Cards)
  // ==========================================
  Widget _buildOperationalPulseGrid(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
    AdminDashboardState adminDashboard,
  ) {
    final isAll = tenancyState.isAllLocations;
    final isVienna = analytics.isViennaSelected;
    final activeBranchId = tenancyState.activeBranchId;

    final branchMetrics = adminDashboard.branchMetrics;
    final int clientsValue = isAll
        ? adminDashboard.activeClientsCount
        : (branchMetrics[activeBranchId]?.activeClientsCount ?? 0);
    final int coachesValue = isAll
        ? adminDashboard.totalCoachesCount
        : (branchMetrics[activeBranchId]?.totalCoachesCount ?? 0);
    final int unpaidValue = isAll
        ? adminDashboard.unpaidSubscriptions
        : (branchMetrics[activeBranchId]?.unpaidSubscriptions ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'ОПЕРАЦІЙНА СИТУАЦІЯ',
            style: TextStyle(
              color: themeConfig.isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: themeConfig.isDark
                  ? null
                  : [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ),
        Row(
          children: [
            // Card 1: Clients
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.users,
                title: 'owner.clients'.tr(),
                value: '$clientsValue',
                sublabel: isAll ? '🇺🇦 ${branchMetrics['kyiv']?.activeClientsCount ?? 0} • 🇦🇹 ${branchMetrics['vienna']?.activeClientsCount ?? 0}' : 'Активні відвідувачі',
                accentColor: const Color(0xFF00E5FF),
                themeConfig: themeConfig,
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Occupancy
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.calendarCheck,
                title: 'owner.occupancy'.tr(),
                value: isAll
                    ? '${analytics.averageOccupancy}%'
                    : (isVienna ? '${analytics.vienna.occupancyPercent}%' : '${analytics.kyiv.occupancyPercent}%'),
                sublabel: isAll ? '🇺🇦 ${analytics.kyiv.occupancyPercent}% • 🇦🇹 ${analytics.vienna.occupancyPercent}%' : 'Завантаженість',
                accentColor: const Color(0xFFF59E0B),
                themeConfig: themeConfig,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Coaches
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.userCheck,
                title: 'Тренери',
                value: _formatCoachesCount(coachesValue),
                sublabel: isAll ? '🇺🇦 ${branchMetrics['kyiv']?.totalCoachesCount ?? 0} • 🇦🇹 ${branchMetrics['vienna']?.totalCoachesCount ?? 0} ➔' : 'Штат у нормі ➔',
                accentColor: const Color(0xFF10B981),
                themeConfig: themeConfig,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 2);
                },
              ),
            ),
            const SizedBox(width: 12),

            // Card 4: ATTENTION POD (Direct link to PaymentSheet!)
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.alertTriangle,
                title: 'Потребує уваги',
                value: '$unpaidValue без оплати',
                sublabel: 'Без оплати ➔',
                accentColor: const Color(0xFFF43F5E),
                themeConfig: themeConfig,
                isAttention: unpaidValue > 0,
                onTap: _openPaymentAttentionSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExecutiveKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String sublabel,
    required Color accentColor,
    required AppThemeConfig themeConfig,
    bool isAttention = false,
    VoidCallback? onTap,
  }) {
    final isDark = themeConfig.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? (isAttention
                          ? [const Color(0xFF2D121D), const Color(0xFF14080E)]
                          : [const Color(0xFF0C2038), const Color(0xFF061220)])
                      : (isAttention
                          ? [const Color(0xFFFFF1F2), Colors.white]
                          : [Colors.white, const Color(0xFFF8FAFC)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAttention
                      ? const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.45 : 0.35)
                      : (isDark ? accentColor.withValues(alpha: 0.25) : const Color(0xFFBAE6FD)),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      if (isAttention)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.20 : 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.30 : 0.25),
                            ),
                          ),
                          child: const Text(
                            'УВАГА',
                            style: TextStyle(
                              color: Color(0xFFF43F5E),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isAttention ? const Color(0xFFF43F5E) : themeConfig.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: isAttention
                          ? const Color(0xFFF43F5E)
                          : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF0284C7)),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 5. REVENUE STRUCTURE & FINANCIAL KPIS
  // ==========================================
  Widget _buildRevenueBreakdownCard(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    final isDark = themeConfig.isDark;
    final isVienna = analytics.isViennaSelected;

    double childRevenue = 0.0;
    double adultRevenue = 0.0;
    
    if (tenancyState.isAllLocations) {
      childRevenue = analytics.kyiv.childRevenue + analytics.vienna.childRevenue;
      adultRevenue = analytics.kyiv.adultRevenue + analytics.vienna.adultRevenue;
    } else if (isVienna) {
      childRevenue = analytics.vienna.childRevenue;
      adultRevenue = analytics.vienna.adultRevenue;
    } else {
      childRevenue = analytics.kyiv.childRevenue;
      adultRevenue = analytics.kyiv.adultRevenue;
    }
    
    final totalRevenue = childRevenue + adultRevenue;
    
    double childPercent = totalRevenue > 0 ? childRevenue / totalRevenue : 0.0;
    double adultPercent = totalRevenue > 0 ? adultRevenue / totalRevenue : 0.0;
    
    final childPercentStr = '${(childPercent * 100).round()}%';
    final adultPercentStr = '${(adultPercent * 100).round()}%';

    final childAmountStr = tenancyState.isAllLocations
        ? '${analytics.kyiv.formatMoney(analytics.kyiv.childRevenue)} / ${analytics.vienna.formatMoney(analytics.vienna.childRevenue)}'
        : (isVienna ? analytics.vienna.formatMoney(childRevenue) : analytics.kyiv.formatMoney(childRevenue));

    final adultAmountStr = tenancyState.isAllLocations
        ? '${analytics.kyiv.formatMoney(analytics.kyiv.adultRevenue)} / ${analytics.vienna.formatMoney(analytics.vienna.adultRevenue)}'
        : (isVienna ? analytics.vienna.formatMoney(adultRevenue) : analytics.kyiv.formatMoney(adultRevenue));


    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
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
                  Text(
                    tenancyState.isAllLocations ? 'СТРУКТУРА ДОХОДІВ МЕРЕЖІ' : 'СТРУКТУРА ДОХОДІВ',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Item 1
              _buildBreakdownItem(
                label: 'Дитячі абонементи',
                percent: childPercentStr,
                value: childPercent,
                amount: childAmountStr,
                gradient: const [Color(0xFF00E5FF), Color(0xFF0284C7)],
                themeConfig: themeConfig,
              ),

              const SizedBox(height: 14),

              // Item 2
              _buildBreakdownItem(
                label: 'Дорослі абонементи',
                percent: adultPercentStr,
                value: adultPercent,
                amount: adultAmountStr,
                gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                themeConfig: themeConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required String percent,
    required double value,
    required String amount,
    required List<Color> gradient,
    required AppThemeConfig themeConfig,
  }) {
    final isDark = themeConfig.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: themeConfig.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: gradient.first,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percent,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            child: Row(
              children: [
                if ((value * 100).round() > 0)
                  Expanded(
                    flex: (value * 100).round(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                if (100 - (value * 100).round() > 0)
                  Expanded(
                    flex: (100 - (value * 100)).round(),
                    child: const SizedBox(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialKpiGrid(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    final isAll = tenancyState.isAllLocations;
    final isVienna = analytics.isViennaSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'КЛЮЧОВІ ФІНАНСОВІ МЕТРИКИ',
            style: TextStyle(
              color: themeConfig.isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: themeConfig.isDark
                  ? null
                  : [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.trendingUp,
                title: 'LTV Клієнта',
                value: isAll
                    ? '${analytics.kyiv.formatLtv()} / ${analytics.vienna.formatLtv()}'
                    : (isVienna ? analytics.vienna.formatLtv() : analytics.kyiv.formatLtv()),
                sublabel: 'Середній дохід на клієнта',
                accentColor: const Color(0xFF00E5FF),
                themeConfig: themeConfig,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.userMinus,
                title: 'Відтік (Churn)',
                value: isAll
                    ? '${analytics.kyiv.churnPercent}% / ${analytics.vienna.churnPercent}%'
                    : (isVienna ? '${analytics.vienna.churnPercent}%' : '${analytics.kyiv.churnPercent}%'),
                sublabel: 'За поточний місяць',
                accentColor: const Color(0xFF10B981),
                themeConfig: themeConfig,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.shoppingCart,
                title: 'Нові абонементи',
                value: isAll
                    ? '${analytics.kyiv.newSubscriptions} / ${analytics.vienna.newSubscriptions}'
                    : (isVienna ? '${analytics.vienna.newSubscriptions}' : '${analytics.kyiv.newSubscriptions}'),
                sublabel: 'За поточний місяць',
                accentColor: const Color(0xFFA855F7),
                themeConfig: themeConfig,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExecutiveKpiCard(
                icon: LucideIcons.receipt,
                title: 'Середній чек',
                value: isAll
                    ? '${analytics.kyiv.formatMoney(analytics.kyiv.averageCheck)} / ${analytics.vienna.formatMoney(analytics.vienna.averageCheck)}'
                    : (isVienna ? analytics.vienna.formatMoney(analytics.vienna.averageCheck) : analytics.kyiv.formatMoney(analytics.kyiv.averageCheck)),
                sublabel: 'Абонементи та разові',
                accentColor: const Color(0xFFF59E0B),
                themeConfig: themeConfig,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // FLOATING APPLE VISIONOS BOTTOM NAV BAR
  // ==========================================
  Widget _buildBottomNav(AppThemeConfig themeConfig) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: themeConfig.isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                    blurRadius: 28,
                    spreadRadius: -1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: themeConfig.isDark
                    ? const [Color(0xFF0E2C4D), Color(0xFF07192C)]
                    : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
              ),
              border: Border.all(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                    : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: GNav(
              rippleColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
              hoverColor: themeConfig.accentPrimary.withValues(alpha: 0.1),
              gap: 6,
              activeColor: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
              iconSize: 20,
              textStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: themeConfig.isDark ? Colors.white : const Color(0xFF0284C7),
                letterSpacing: 0.2,
              ),
              tabBorderRadius: 20,
              tabActiveBorder: Border.all(
                color: themeConfig.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.50)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.50),
                width: 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: themeConfig.isDark
                  ? themeConfig.accentPrimary.withValues(alpha: 0.30)
                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
              color: themeConfig.isDark ? Colors.white60 : const Color(0xFF64748B),
              tabs: const [
                GButton(icon: LucideIcons.layoutDashboard, text: 'Пульс'),
                GButton(icon: LucideIcons.trendingUp, text: 'Фінанси'),
                GButton(icon: LucideIcons.users, text: 'Команда'),
                GButton(icon: LucideIcons.banknote, text: 'Виплати'),
              ],
              selectedIndex: _selectedTabIndex,
              onTabChange: (i) {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = i);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 6. PROFIT DYNAMICS CHART
  // ==========================================
  Widget _buildGlowingChart(AppThemeConfig themeConfig) {
    final isDark = themeConfig.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF081C30).withValues(alpha: 0.85) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : const Color(0xFFBAE6FD),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'owner.profit_dynamics'.tr(),
                          style: TextStyle(
                            color: themeConfig.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          'Тренд надходжень',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      {'key': 'owner.day'.tr(), 'val': 'День'},
                      {'key': 'owner.week'.tr(), 'val': 'Тиждень'},
                      {'key': 'owner.month'.tr(), 'val': 'Місяць'},
                    ].map((item) {
                      final periodLabel = item['key']!;
                      final periodVal = item['val']!;
                      final isSelected = _selectedTimeframe == periodVal;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTimeframe = periodVal);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(left: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                                    : const Color(0xFF0284C7).withValues(alpha: 0.12))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            periodLabel,
                            style: TextStyle(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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
                child: CustomPaint(
                  key: ValueKey(_selectedTimeframe),
                  painter: SplineChartPainter(isDark: isDark),
                ).animate().fadeIn(duration: 350.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 7. LIVE ACTIVITY FEED
  // ==========================================
  Widget _buildLiveActivitySection(
    AppThemeConfig themeConfig,
    TenancyState tenancyState,
    OwnerAnalyticsState analytics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'ОСТАННІ ОПЕРАЦІЇ В МЕРЕЖІ',
            style: TextStyle(
              color: themeConfig.isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              shadows: themeConfig.isDark
                  ? null
                  : [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ),
        if (analytics.recentTransactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Немає недавніх операцій',
              style: TextStyle(
                color: themeConfig.isDark ? Colors.white54 : Colors.black54,
                fontSize: 13,
              ),
            ),
          )
        else
          ...analytics.recentTransactions.take(4).map((tx) {
            return _buildActivityItem(
              icon: LucideIcons.arrowDownCircle,
              title: '${tx.clientName}: ${tx.packageName}',
              amount: '+ ${tx.currencySymbol == '€' ? '€ ' : ''}${tx.amount.toStringAsFixed(0)}${tx.currencySymbol != '€' ? ' ${tx.currencySymbol}' : ''}',
              color: const Color(0xFF10B981),
              themeConfig: themeConfig,
              flagEmoji: tx.branchId == 'vienna' ? '🇦🇹' : '🇺🇦',
            );
          }),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String amount,
    required Color color,
    required AppThemeConfig themeConfig,
    String? flagEmoji,
  }) {
    final isDark = themeConfig.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showOwnerDevSnackbar('${'owner.transaction_details'.tr()}: $title');
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF08182B).withValues(alpha: 0.75) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
              width: 1,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplineChartPainter extends CustomPainter {
  final bool isDark;

  SplineChartPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 8.0;
    final double w = size.width - (padding * 2);
    final double h = size.height;

    final lineColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Smooth curve points with padding
    path.moveTo(padding, h * 0.8);
    path.cubicTo(
        padding + (w * 0.2), h * 0.8, padding + (w * 0.2), h * 0.3, padding + (w * 0.4), h * 0.4);
    path.cubicTo(
        padding + (w * 0.6), h * 0.5, padding + (w * 0.7), h * 0.1, padding + (w * 0.8), h * 0.2);
    path.cubicTo(padding + (w * 0.9), h * 0.3, padding + (w * 0.95), h * 0.1, padding + w, 0);

    // Glow effect
    if (isDark) {
      canvas.drawShadow(path, const Color(0xFF00E5FF), 15, true);
    } else {
      canvas.drawShadow(path, const Color(0xFF0284C7).withValues(alpha: 0.4), 10, true);
    }

    // Gradient fill below line
    final fillPath = Path.from(path)
      ..lineTo(padding + w, h)
      ..lineTo(padding, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF00E5FF).withValues(alpha: 0.30),
                const Color(0xFF00E5FF).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFF0284C7).withValues(alpha: 0.18),
                const Color(0xFF0284C7).withValues(alpha: 0.0),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPoints = [
      Offset(padding + (w * 0.4), h * 0.4),
      Offset(padding + (w * 0.8), h * 0.2),
      Offset(padding + w, 0),
    ];

    if (isDark) {
      final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      for (final pt in dotPoints) {
        canvas.drawCircle(pt, 4, dotPaint);
      }
    } else {
      final outerDotPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final innerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      for (final pt in dotPoints) {
        canvas.drawCircle(pt, 4.5, innerDotPaint);
        canvas.drawCircle(pt, 4.5, outerDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SplineChartPainter oldDelegate) => oldDelegate.isDark != isDark;
}
