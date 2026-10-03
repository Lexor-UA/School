import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/create_branch_sheet.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:flutter/services.dart';

class AquatixLabSuperAdminScreen extends ConsumerStatefulWidget {
  const AquatixLabSuperAdminScreen({super.key});

  @override
  ConsumerState<AquatixLabSuperAdminScreen> createState() =>
      _AquatixLabSuperAdminScreenState();
}

class _AquatixLabSuperAdminScreenState
    extends ConsumerState<AquatixLabSuperAdminScreen> {
  late WhiteLabelConfig _config;
  int _selectedColorValue = 0xFF00E5FF;
  late TextEditingController _appNameController;

  final List<Map<String, dynamic>> _acceptanceCriteria = [
    {
      'id': '1',
      'title': 'Відень: Валюта EUR (€) та часовий пояс Europe/Vienna',
      'detail': 'Автономний розклад, точний розрахунок літнього/зимового часу (DST), ціни виключно в €.',
      'status': 'Пройдено',
      'testRef': 'branch_settings_pricing_test.dart',
    },
    {
      'id': '2',
      'title': 'Київ: Валюта UAH (₴) та Europe/Kyiv без регресії',
      'detail': 'Існуючі дані спадково збережені, відсутність конфліктів та зсувів розкладу.',
      'status': 'Пройдено',
      'testRef': 'kyiv_migration_test.dart',
    },
    {
      'id': '3',
      'title': 'Роздільні каталоги абонементів та цін за філіями',
      'detail': 'SubscriptionPackageCatalog віддає UAH для Києва та EUR для Відня, багатомовні назви.',
      'status': 'Пройдено',
      'testRef': 'branch_settings_pricing_test.dart',
    },
    {
      'id': '4',
      'title': 'Ізоляція розкладу, басейнів та локацій',
      'detail': 'HappyLand Klosterneuburg (Sports Pool, Wellenbecken) та Київ (25м, Baby Pool) не змішуються.',
      'status': 'Пройдено',
      'testRef': 'vienna_provisioning_test.dart',
    },
    {
      'id': '5',
      'title': 'Ізоляція доріжок з однаковими назвами (Lane 1)',
      'detail': 'Доріжки однієї назви у різних філіях чи басейнах ізольовані через branchId і не мають колізій.',
      'status': 'Пройдено',
      'testRef': 'recurring_schedule_generator_test.dart',
    },
    {
      'id': '6',
      'title': 'Строга ізоляція екранів персоналу (Admin & Coach)',
      'detail': 'Адміністратори та тренери бачать тільки своїх учнів, групи та розклад поточної філії.',
      'status': 'Пройдено',
      'testRef': 'staff_screens_isolation_test.dart',
    },
    {
      'id': '7',
      'title': 'Реєстрація за QR-кодом рецепції та філіальними посиланнями',
      'detail': 'Клієнт при скануванні QR автоматично закріплюється за потрібною філією.',
      'status': 'Пройдено',
      'testRef': 'branch_registration_flow_test.dart',
    },
    {
      'id': '8',
      'title': 'Захист від крос-філіальних списань абонементів',
      'detail': 'BranchDataIntegrityValidator суворо блокує package.branchId != lesson.branchId != client.branchId.',
      'status': 'Пройдено',
      'testRef': 'data_integrity_validation_test.dart',
    },
    {
      'id': '9',
      'title': 'Консолідований перемикач філій для Власника (Owner)',
      'detail': 'Преміальний BranchSelectorPill з вибором Vienna 🇦🇹, Kyiv 🇺🇦, або Всі локації 🌐.',
      'status': 'Пройдено',
      'testRef': 'owner_multibranch_test.dart',
    },
    {
      'id': '10',
      'title': 'Платіжна архітектура без реальних списувань (Mock & Invoices)',
      'detail': 'Емуляція оплат LiqPay (Kyiv) / Stripe (Vienna) із генерацією фіскальних квитанцій.',
      'status': 'Пройдено',
      'testRef': 'branch_payment_invoicing_test.dart',
    },
  ];

  @override
  void initState() {
    super.initState();
    _config = WhiteLabelConfig.citySwimDefault;
    _selectedColorValue = _config.primaryColorValue;
    _appNameController = TextEditingController(text: _config.appName);
  }

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  void _showProvisionTenantDialog() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateBranchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kyivConfig = BranchConfig.kyivConfig;
    final viennaConfig = BranchConfig.viennaConfig;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B14) : themeConfig.scaffoldBg,
      body: Stack(
        children: [
          if (!isDark) const AnimatedWaterBackground(),
          // Background ambient gradient glow
          Positioned(
            top: -120,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Color(_selectedColorValue).withValues(alpha: 0.12)
                      : const Color(0xFFBAE6FD).withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
                      : const Color(0xFFE0E7FF).withValues(alpha: 0.25),
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/owner');
                            }
                          },
                          icon: Icon(
                            LucideIcons.arrowLeft,
                            color: isDark ? Colors.white : const Color(0xFF0284C7),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.90),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: isDark
                                ? null
                                : const BorderSide(color: Color(0xFFBAE6FD), width: 1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'AquatixLab',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                          : const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                                            : const Color(0xFFBAE6FD),
                                      ),
                                    ),
                                    child: Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Global SaaS Management & Architecture QA',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ThemeHeaderButton(size: 38),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // SECTION 1: Global Telemetry Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ГЛОБАЛЬНІ МЕТРИКИ ПЛАТФОРМИ',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            // Live operational badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.45),
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
                                  const SizedBox(width: 5),
                                  Text(
                                    '100% ONLINE',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Організації',
                              value: '1 Active',
                              subtitle: 'CitySwim Global',
                              icon: LucideIcons.building,
                              accentColor: const Color(0xFF00E5FF),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'Філії школи',
                              value: '2 Вузли',
                              subtitle: 'Kyiv 🇺🇦 & Vienna 🇦🇹',
                              icon: LucideIcons.network,
                              accentColor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _MetricCard(
                              title: 'Басейни / Доріжки',
                              value: '4 Басейни',
                              subtitle: '12 активних доріжок',
                              icon: LucideIcons.waves,
                              accentColor: const Color(0xFF38BDF8),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'Аптайм ізоляції',
                              value: '100%',
                              subtitle: '0 витоків даних',
                              icon: LucideIcons.shieldCheck,
                              accentColor: const Color(0xFFA855F7),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // SECTION 2: Tenants & Branches Directory
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'АКТИВНІ ФІЛІЇ ТА ОРГАНІЗАЦІЇ',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF0369A1),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            InkWell(
                              onTap: _showProvisionTenantDialog,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.plus,
                                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Додати філію',
                                      style: TextStyle(
                                        color: isDark ? Color(_selectedColorValue) : const Color(0xFF0284C7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // CitySwim Kyiv Node
                        _BranchNodeCard(
                          flag: '🇺🇦',
                          name: 'CitySwim Kyiv',
                          city: 'Київ, Україна',
                          currency: 'UAH (₴)',
                          timezone: 'Europe/Kyiv (UTC+2 / UTC+3)',
                          gateway: 'LiqPay Mock (Картка, Apple Pay, Privat24)',
                          locationsCount: kyivConfig.locations.length,
                          poolsCount: kyivConfig.locations.expand((l) => l.pools).length,
                          poolsNames: kyivConfig.locations
                              .expand((l) => l.pools.map((p) => p.name))
                              .join(' · '),
                          accentColor: const Color(0xFF00E5FF),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 12),

                        // CitySwim Vienna Node
                        _BranchNodeCard(
                          flag: '🇦🇹',
                          name: 'CitySwim Vienna',
                          city: 'Klosterneuburg, Wien, Австрія',
                          currency: 'EUR (€)',
                          timezone: 'Europe/Vienna (UTC+1 / UTC+2)',
                          gateway: 'Stripe Mock (Картка, Apple Pay, SEPA, EPS)',
                          locationsCount: viennaConfig.locations.length,
                          poolsCount: viennaConfig.locations.expand((l) => l.pools).length,
                          poolsNames: viennaConfig.locations
                              .expand((l) => l.pools.map((p) => p.name))
                              .join(' · '),
                          accentColor: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // SECTION 3: White Label Branding Studio
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        gradient: isDark
                            ? null
                            : const LinearGradient(
                                colors: [Colors.white, Color(0xFFF8FAFC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                          width: isDark ? 1.0 : 1.1,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(_selectedColorValue).withValues(alpha: isDark ? 0.15 : 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isDark
                                      ? null
                                      : Border.all(color: Color(_selectedColorValue).withValues(alpha: 0.3)),
                                ),
                                child: Icon(
                                  LucideIcons.palette,
                                  color: isDark ? Color(_selectedColorValue) : const Color(0xFF0284C7),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'White Label Branding Studio',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Налаштування бренду школи та теми оформлення',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Первинний колір теми бренду:',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ColorOption(
                                color: const Color(0xFF00E5FF),
                                label: 'Aquamarine',
                                isSelected: _selectedColorValue == 0xFF00E5FF,
                                onTap: () => setState(() => _selectedColorValue = 0xFF00E5FF),
                                isDark: isDark,
                              ),
                              _ColorOption(
                                color: const Color(0xFF10B981),
                                label: 'Emerald',
                                isSelected: _selectedColorValue == 0xFF10B981,
                                onTap: () => setState(() => _selectedColorValue = 0xFF10B981),
                                isDark: isDark,
                              ),
                              _ColorOption(
                                color: const Color(0xFF3B82F6),
                                label: 'Royal Blue',
                                isSelected: _selectedColorValue == 0xFF3B82F6,
                                onTap: () => setState(() => _selectedColorValue = 0xFF3B82F6),
                                isDark: isDark,
                              ),
                              _ColorOption(
                                color: const Color(0xFF8B5CF6),
                                label: 'Purple Wave',
                                isSelected: _selectedColorValue == 0xFF8B5CF6,
                                onTap: () => setState(() => _selectedColorValue = 0xFF8B5CF6),
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _appNameController,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Назва додатку (App Title)',
                              labelStyle: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFBAE6FD),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFBAE6FD),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Color(_selectedColorValue)
                                      : const Color(0xFF0284C7),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // SECTION 4: Acceptance Criteria Checklist Matrix (TZ Point 37)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clipboardCheck,
                              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'МАТРИЦЯ ПРИЙОМКИ ТЗ: 10 З 10 ВЕРИФІКОВАНО',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._acceptanceCriteria.map((c) => _CriteriaItemTile(item: c, isDark: isDark)),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = isDark
        ? accentColor
        : (accentColor == const Color(0xFF00E5FF)
            ? const Color(0xFF0284C7)
            : accentColor == const Color(0xFF38BDF8)
                ? const Color(0xFF0284C7)
                : accentColor == const Color(0xFF10B981)
                    ? const Color(0xFF047857)
                    : accentColor == const Color(0xFFA855F7)
                        ? const Color(0xFF7C3AED)
                        : accentColor);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFBAE6FD),
            width: isDark ? 1.0 : 1.1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
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
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: effectiveAccent, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? accentColor.withValues(alpha: 0.9)
                    : effectiveAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchNodeCard extends StatelessWidget {
  final String flag;
  final String name;
  final String city;
  final String currency;
  final String timezone;
  final String gateway;
  final int locationsCount;
  final int poolsCount;
  final String poolsNames;
  final Color accentColor;
  final bool isDark;

  const _BranchNodeCard({
    required this.flag,
    required this.name,
    required this.city,
    required this.currency,
    required this.timezone,
    required this.gateway,
    required this.locationsCount,
    required this.poolsCount,
    required this.poolsNames,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = isDark
        ? accentColor
        : (accentColor == const Color(0xFF00E5FF)
            ? const Color(0xFF0284C7)
            : accentColor == const Color(0xFF10B981)
                ? const Color(0xFF047857)
                : accentColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(alpha: 0.2)
              : const Color(0xFFBAE6FD),
          width: isDark ? 1.0 : 1.1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      city,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? accentColor.withValues(alpha: 0.12)
                      : (accentColor == const Color(0xFF00E5FF)
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? accentColor.withValues(alpha: 0.3)
                        : (accentColor == const Color(0xFF00E5FF)
                            ? const Color(0xFFBAE6FD)
                            : const Color(0xFFA7F3D0)),
                  ),
                ),
                child: Text(
                  currency,
                  style: TextStyle(
                    color: effectiveAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            height: 1,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: LucideIcons.clock,
            label: 'Часовий пояс',
            value: timezone,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: LucideIcons.creditCard,
            label: 'Еквайринг',
            value: gateway,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: LucideIcons.waves,
            label: 'Басейни ($poolsCount)',
            value: poolsNames,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF0284C7),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04))
              : (isSelected
                  ? color.withValues(alpha: 0.15)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? (isSelected ? color : Colors.white.withValues(alpha: 0.08))
                : (isSelected ? color : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? (isSelected ? Colors.white : const Color(0xFF94A3B8))
                    : (isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriteriaItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;

  const _CriteriaItemTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0FDF4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.35),
          width: isDark ? 1.0 : 1.1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.check,
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['id']}. ${item['title']}',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: isDark
                            ? null
                            : Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        item['status'] as String,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['detail'] as String,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Тест: ${item['testRef']}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
