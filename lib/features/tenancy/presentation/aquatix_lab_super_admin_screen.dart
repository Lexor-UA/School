import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/white_label_config.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/create_branch_sheet.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/edit_branch_sheet.dart';
import 'package:swimming_school_app/features/tenancy/presentation/widgets/delete_branch_dialog.dart';
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

  List<Map<String, dynamic>> get _acceptanceCriteria => [
    {
      'id': '1',
      'title': 'tenancy.qa_1_title'.tr(),
      'detail': 'tenancy.qa_1_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'branch_settings_pricing_test.dart',
    },
    {
      'id': '2',
      'title': 'tenancy.qa_2_title'.tr(),
      'detail': 'tenancy.qa_2_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'kyiv_migration_test.dart',
    },
    {
      'id': '3',
      'title': 'tenancy.qa_3_title'.tr(),
      'detail': 'tenancy.qa_3_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'branch_settings_pricing_test.dart',
    },
    {
      'id': '4',
      'title': 'tenancy.qa_4_title'.tr(),
      'detail': 'tenancy.qa_4_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'vienna_provisioning_test.dart',
    },
    {
      'id': '5',
      'title': 'tenancy.qa_5_title'.tr(),
      'detail': 'tenancy.qa_5_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'recurring_schedule_generator_test.dart',
    },
    {
      'id': '6',
      'title': 'tenancy.qa_6_title'.tr(),
      'detail': 'tenancy.qa_6_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'staff_screens_isolation_test.dart',
    },
    {
      'id': '7',
      'title': 'tenancy.qa_7_title'.tr(),
      'detail': 'tenancy.qa_7_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'branch_registration_flow_test.dart',
    },
    {
      'id': '8',
      'title': 'tenancy.qa_8_title'.tr(),
      'detail': 'tenancy.qa_8_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'data_integrity_validation_test.dart',
    },
    {
      'id': '9',
      'title': 'tenancy.qa_9_title'.tr(),
      'detail': 'tenancy.qa_9_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'owner_multibranch_test.dart',
    },
    {
      'id': '10',
      'title': 'tenancy.qa_10_title'.tr(),
      'detail': 'tenancy.qa_10_detail'.tr(),
      'status': 'tenancy.qa_status_passed'.tr(),
      'testRef': 'branch_payment_invoicing_test.dart',
    },
  ];

  @override
  void initState() {
    super.initState();
    _config = ref.read(tenancyControllerProvider).organization.whiteLabelConfig;
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
    final availableBranches = ref.watch(availableBranchesProvider);
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;

    int totalPools = 0;
    int totalLanes = 0;
    for (final b in availableBranches) {
      final cfg = BranchConfig.forBranch(b.id, b.name, b.city);
      final pools = cfg.locations.expand((l) => l.pools);
      totalPools += pools.length;
      totalLanes += pools.expand((p) => p.lanes).length;
    }

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
                              'tenancy.global_platform_metrics'.tr(),
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
                              title: 'tenancy.organizations_title'.tr(),
                              value: '1 Active',
                              subtitle: 'CitySwim Global',
                              icon: LucideIcons.building2,
                              accentColor: const Color(0xFF00E5FF),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'tenancy.school_branches_title'.tr(),
                              value: 'tenancy.nodes_count'.tr(namedArgs: {'count': '${availableBranches.length}'}),
                              subtitle: availableBranches.map((b) => '${b.name} ${b.flagEmoji}').join(' · '),
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
                              title: 'tenancy.pools_lanes_title'.tr(),
                              value: 'tenancy.pools_count'.tr(namedArgs: {'count': '$totalPools'}),
                              subtitle: 'tenancy.active_lanes_count'.tr(namedArgs: {'count': '$totalLanes'}),
                              icon: LucideIcons.waves,
                              accentColor: const Color(0xFF38BDF8),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 12),
                            _MetricCard(
                              title: 'tenancy.isolation_uptime_title'.tr(),
                              value: '100%',
                              subtitle: 'tenancy.zero_data_leaks'.tr(),
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
                              'tenancy.active_branches_orgs'.tr(),
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
                                      'tenancy.add_branch_btn'.tr(),
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

                        // Dynamic Branches Listing
                        for (final branch in availableBranches) ...[
                          Builder(builder: (context) {
                            final config = BranchConfig.forBranch(branch.id, branch.name, branch.city);
                            final accentColor = branch.id == 'kyiv'
                                ? const Color(0xFF00E5FF)
                                : (branch.id == 'vienna'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFA855F7));
                            return _BranchNodeCard(
                              branch: branch,
                              flag: branch.flagEmoji,
                              name: branch.name.startsWith('CitySwim')
                                  ? branch.name
                                  : 'CitySwim ${branch.name}',
                              city: '${branch.city}, ${branch.country}',
                              currency: '${branch.currency} (${branch.currencySymbol})',
                              timezone: branch.timezone,
                              gateway: branch.paymentProvider == 'liqpay'
                                  ? 'tenancy.gateway_liqpay_mock'.tr()
                                  : 'tenancy.gateway_stripe_mock'.tr(),
                              locationsCount: config.locations.length,
                              poolsCount: config.locations.expand((l) => l.pools).length,
                              poolsNames: config.locations
                                  .expand((l) => l.pools.map((p) => p.name))
                                  .join(' · '),
                              accentColor: accentColor,
                              isDark: isDark,
                              onEdit: () {
                                HapticFeedback.lightImpact();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => EditBranchSheet(branch: branch),
                                );
                              },
                              onDelete: () {
                                DeleteBranchDialog.show(context, branch);
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
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
                                      'tenancy.white_label_subtitle'.tr(),
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
                            'tenancy.primary_brand_color'.tr(),
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
                              labelText: 'tenancy.app_title_label'.tr(),
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
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await ref
                                    .read(tenancyControllerProvider.notifier)
                                    .updateWhiteLabelBranding(
                                      appName: _appNameController.text,
                                      primaryColorValue: _selectedColorValue,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'tenancy.branding_saved_msg'.tr(namedArgs: {
                                          'name': _appNameController.text.trim().isEmpty
                                              ? 'CitySwim'
                                              : _appNameController.text.trim(),
                                        }),
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: Text(
                                'tenancy.save_brand_config_btn'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(_selectedColorValue),
                                foregroundColor: _selectedColorValue == 0xFF00E5FF
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'tenancy.acceptance_matrix_title'.tr(),
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF10B981) : const Color(0xFF047857),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
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
  final Branch branch;
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchNodeCard({
    required this.branch,
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
    required this.onEdit,
    required this.onDelete,
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
              if (branch.isProtected || branch.isSystemDefault)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 11,
                        color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        branch.isSystemDefault ? 'tenancy.base_badge'.tr() : 'tenancy.protected_badge'.tr(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
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
            label: 'tenancy.timezone_label'.tr(),
            value: timezone,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: LucideIcons.creditCard,
            label: 'tenancy.acquiring_label'.tr(),
            value: gateway,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: LucideIcons.waves,
            label: 'tenancy.pools_label_count'.tr(namedArgs: {'count': '$poolsCount'}),
            value: poolsNames,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Divider(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            height: 1,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Edit Button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFBAE6FD),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 13,
                        color: isDark ? Colors.white : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'common.edit'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button (Locked for system defaults, active for custom)
              if (branch.isSystemDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.lock,
                        size: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'tenancy.system_badge'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.trash2,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'common.delete'.tr(),
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
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
                        '${item['title']}',
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
                  '${'tenancy.test_ref_prefix'.tr()}: ${item['testRef']}',
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
