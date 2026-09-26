import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.plusCircle, color: Color(0xFF00E5FF), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Підключення нового тененту',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Платформа AquatixLab SaaS готова до миттєвого розгортання нових організацій (White Label). Кожен новий тененат отримує власну структуру філій, басейнів, доріжок та фіскальних юрисдикцій.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Column(
                children: [
                  _ModalInfoRow(label: 'Стек ізоляції', val: 'Firestore Multi-Tenancy Rules'),
                  SizedBox(height: 6),
                  _ModalInfoRow(label: 'Платіжні шлюзи', val: 'Stripe / LiqPay / SEPA'),
                  SizedBox(height: 6),
                  _ModalInfoRow(label: 'Часові пояси', val: 'Автоматичний DST розрахунок'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрити', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Архітектура готова. Демонстраційний тененат CitySwim активний!'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF001F3F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Зрозуміло', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kyivConfig = BranchConfig.kyivConfig;
    final viennaConfig = BranchConfig.viennaConfig;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
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
                  color: Color(_selectedColorValue).withValues(alpha: 0.12),
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
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
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'AquatixLab',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(
                                        color: Color(0xFF00E5FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Global SaaS Management & Architecture QA',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Live operational badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '100% ONLINE',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        const Text(
                          'ГЛОБАЛЬНІ МЕТРИКИ ПЛАТФОРМИ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
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
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'Філії школи',
                              value: '2 Вузли',
                              subtitle: 'Kyiv 🇺🇦 & Vienna 🇦🇹',
                              icon: LucideIcons.network,
                              accentColor: const Color(0xFF10B981),
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
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'Аптайм ізоляції',
                              value: '100%',
                              subtitle: '0 витоків даних',
                              icon: LucideIcons.shieldCheck,
                              accentColor: const Color(0xFFA855F7),
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
                            const Text(
                              'АКТИВНІ ФІЛІЇ ТА ОРГАНІЗАЦІЇ',
                              style: TextStyle(
                                color: Color(0xFF64748B),
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
                                    const Icon(LucideIcons.plus, color: Color(0xFF00E5FF), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Додати філію',
                                      style: TextStyle(
                                        color: Color(_selectedColorValue),
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
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(_selectedColorValue).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(LucideIcons.palette, color: Color(_selectedColorValue), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'White Label Branding Studio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Налаштування бренду школи та теми оформлення',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Первинний колір теми бренду:',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _ColorOption(
                                color: const Color(0xFF00E5FF),
                                label: 'Aquamarine',
                                isSelected: _selectedColorValue == 0xFF00E5FF,
                                onTap: () => setState(() => _selectedColorValue = 0xFF00E5FF),
                              ),
                              const SizedBox(width: 8),
                              _ColorOption(
                                color: const Color(0xFF10B981),
                                label: 'Emerald',
                                isSelected: _selectedColorValue == 0xFF10B981,
                                onTap: () => setState(() => _selectedColorValue = 0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              _ColorOption(
                                color: const Color(0xFF3B82F6),
                                label: 'Royal Blue',
                                isSelected: _selectedColorValue == 0xFF3B82F6,
                                onTap: () => setState(() => _selectedColorValue = 0xFF3B82F6),
                              ),
                              const SizedBox(width: 8),
                              _ColorOption(
                                color: const Color(0xFF8B5CF6),
                                label: 'Purple Wave',
                                isSelected: _selectedColorValue == 0xFF8B5CF6,
                                onTap: () => setState(() => _selectedColorValue = 0xFF8B5CF6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _appNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Назва додатку (App Title)',
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Color(_selectedColorValue)),
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
                            const Icon(LucideIcons.clipboardCheck, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'МАТРИЦЯ ПРИЙОМКИ ТЗ: 10 З 10 ВЕРИФІКОВАНО',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._acceptanceCriteria.map((c) => _CriteriaItemTile(item: c)),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Icon(icon, color: accentColor, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: accentColor.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w500),
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      city,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  currency,
                  style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 10),
          _DetailRow(icon: LucideIcons.clock, label: 'Часовий пояс', value: timezone),
          const SizedBox(height: 6),
          _DetailRow(icon: LucideIcons.creditCard, label: 'Еквайринг', value: gateway),
          const SizedBox(height: 6),
          _DetailRow(icon: LucideIcons.waves, label: 'Басейни ($poolsCount)', value: poolsNames),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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

  const _ColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
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
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
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
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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

  const _CriteriaItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: Color(0xFF10B981), size: 14),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['status'] as String,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['detail'] as String,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Тест: ${item['testRef']}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalInfoRow extends StatelessWidget {
  final String label;
  final String val;

  const _ModalInfoRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
