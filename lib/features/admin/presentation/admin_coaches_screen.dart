import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:swimming_school_app/shared/widgets/theme_header_button.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'add_coach_sheet.dart';
import 'edit_coach_sheet.dart';
import 'admin_calendar_screen.dart';

class AdminCoachesScreen extends ConsumerStatefulWidget {
  const AdminCoachesScreen({super.key});

  @override
  ConsumerState<AdminCoachesScreen> createState() => _AdminCoachesScreenState();
}

class _AdminCoachesScreenState extends ConsumerState<AdminCoachesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _recentlyCopiedCoachId;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'ТР';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final first = parts[0].characters.isNotEmpty ? parts[0].characters.first : '';
      final second = parts[1].characters.isNotEmpty ? parts[1].characters.first : '';
      return (first + second).toUpperCase();
    }
    final camelMatches = RegExp(r'[A-ZА-ЯІЇЄҐ]').allMatches(trimmed);
    if (camelMatches.length >= 2) {
      final chars = camelMatches.map((m) => m.group(0)!).take(2).join();
      return chars.toUpperCase();
    }
    if (trimmed.characters.length >= 2) {
      return trimmed.characters.take(2).toString().toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _coachesStream;

  @override
  void initState() {
    super.initState();
    _coachesStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCredentials(String coachId, String loginId, String name) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: '${'admin.clients_login_label'.tr()}$loginId\n${'admin.clients_password_label'.tr()}1'));
    setState(() => _recentlyCopiedCoachId = coachId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _recentlyCopiedCoachId == coachId) {
        setState(() => _recentlyCopiedCoachId = null);
      }
    });
  }

  void _deleteCoach(String coachId, String name, AppThemeConfig currentTheme) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('admin.coaches_delete_title'.tr(), style: TextStyle(color: currentTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'admin.coaches_delete_confirm'.tr(args: [name]),
          style: TextStyle(color: currentTheme.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin.cancel'.tr(), style: TextStyle(color: currentTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('admin.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentFbUser = FirebaseAuth.instance.currentUser;
        if (currentFbUser != null) {
          await FirebaseFirestore.instance.collection('users').doc(currentFbUser.uid).set({
            'id': currentFbUser.uid,
            'role': 'admin',
            'branchId': 'kyiv',
            'name': 'Адміністратор',
            'aliasOf': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)).catchError((_) {});
        }

        await FirebaseFirestore.instance.collection('users').doc(coachId).delete();

        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Видалено тренера "$name"', admin.id);
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text('Тренера "$name" успішно видалено'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('${'common.error'.tr()}: $e'), backgroundColor: const Color(0xFFF43F5E)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(appThemeControllerProvider);

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBg,
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddCoachSheet(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.userPlus, color: Colors.white, size: 19),
                  const SizedBox(width: 9),
                  Text(
                    'admin.add_coach_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
      body: Stack(
        children: [
          // 1. Full-fidelity animated water ripples
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),

          // 2. Fluid aquatic gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentTheme.bgGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Theme-tailored 3D animated water bubbles
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 3. Ambient volumetric glow orbs
          Positioned(
            top: 40,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb1Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    currentTheme.orb2Color,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Custom Glassmorphic Header
                _buildHeader(context, currentTheme),

                // 2. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: _buildSearchBar(currentTheme),
                ),

                // 3. Coaches List
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _coachesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: currentTheme.accentPrimary));
                      }

                      final tenancyState = ref.watch(tenancyControllerProvider);
                      final activeBranchId = tenancyState.activeBranchId;
                      final isAllLocations = tenancyState.isAllLocationsSelected;
                      final branchName = isAllLocations ? 'Всі локації' : tenancyState.effectiveBranch.name;

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(currentTheme, activeBranchId: activeBranchId, branchName: branchName);
                      }

                      final rawCoaches = snapshot.data!.docs;
                      var coaches = isAllLocations
                          ? rawCoaches
                          : rawCoaches.where((c) {
                              final d = c.data();
                              final bId = d['branchId'] as String? ?? 'kyiv';
                              final bIds = (d['branchIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [bId];
                              return bId == activeBranchId || bIds.contains(activeBranchId);
                            }).toList();

                      if (_searchQuery.isNotEmpty) {
                        coaches = coaches.where((c) {
                          final data = c.data();
                          final name = data['name']?.toString().toLowerCase() ?? '';
                          final loginId = data['loginId']?.toString().toLowerCase() ?? '';
                          final phone = data['phone']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery) ||
                              loginId.contains(_searchQuery) ||
                              phone.contains(_searchQuery);
                        }).toList();
                      }

                      if (coaches.isEmpty) {
                        return _searchQuery.isNotEmpty
                            ? _buildNoSearchResults(currentTheme)
                            : _buildEmptyState(currentTheme, activeBranchId: activeBranchId, branchName: branchName);
                      }

                      return RepaintBoundary(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          physics: const BouncingScrollPhysics(),
                          itemCount: coaches.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = coaches[index];
                            final data = doc.data();
                            final coachId = doc.id;
                            final name = data['name'] ?? 'Невідомо';
                            final phone = data['phone'] ?? 'Немає номеру';
                            final loginId = data['loginId'] ?? 'Не призначено';
                            final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? 400;
                            final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? 450;
                            final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? 600;

                            final branchId = data['branchId'] as String? ?? 'kyiv';
                            final branchIds = data['branchIds'] as List<dynamic>?;

                            return _buildCoachCard(
                              coachId: coachId,
                              name: name,
                              phone: phone,
                              loginId: loginId,
                              rateGroup: rateGroup,
                              rateIndividual: rateIndividual,
                              rateSplit: rateSplit,
                              branchId: branchId,
                              branchIds: branchIds,
                              index: index,
                              currentTheme: currentTheme,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeConfig currentTheme) {
    final tenancyState = ref.watch(tenancyControllerProvider);
    final effectiveBranch = tenancyState.effectiveBranch;
    final isAllLocations = tenancyState.isAllLocationsSelected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: currentTheme.isDark
                  ? const Color(0xFF0C2238).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.90),
              shape: BoxShape.circle,
              border: Border.all(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                    : const Color(0xFFBAE6FD),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.15 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                LucideIcons.arrowLeft,
                color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'admin.coaches_title'.tr(),
                      style: TextStyle(
                        color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5FF).withValues(alpha: 0.18),
                            const Color(0xFF0284C7).withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                          width: 1.1,
                        ),
                      ),
                      child: Text(
                        'admin.coaches_team_badge'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: currentTheme.isDark
                            ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: currentTheme.isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.40)
                              : const Color(0xFF0284C7).withValues(alpha: 0.35),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAllLocations ? LucideIcons.globe : LucideIcons.mapPin,
                            size: 9.5,
                            color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            isAllLocations ? 'Всі локації' : effectiveBranch.name,
                            style: TextStyle(
                              color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'admin.coaches_subtitle'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const ThemeHeaderButton(size: 38),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppThemeConfig currentTheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: currentTheme.isDark
              ? [
                  const Color(0xFF0C2238).withValues(alpha: 0.85),
                  const Color(0xFF061424).withValues(alpha: 0.90),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: currentTheme.isDark
              ? const Color(0xFF00E5FF).withValues(alpha: 0.30)
              : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.08 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: currentTheme.isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: currentTheme.isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'admin.coaches_search_hint'.tr(),
          hintStyle: TextStyle(
            color: currentTheme.isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.65) : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            color: Color(0xFF00E5FF),
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: currentTheme.isDark ? const Color(0xFF00E5FF) : currentTheme.textSecondary,
                    size: 16,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBranchBadge(String? branchId, List<dynamic>? branchIds, AppThemeConfig currentTheme) {
    String label = '🇺🇦 Київ';
    Color accentColor = const Color(0xFF00E5FF);

    final ids = branchIds?.map((e) => e.toString().toLowerCase()).toList() ?? [];
    final bId = branchId?.toLowerCase() ?? 'kyiv';

    if (ids.contains('vienna') && ids.contains('kyiv')) {
      label = '🌐 Всі філії';
      accentColor = const Color(0xFF38BDF8);
    } else if (bId == 'vienna' || ids.contains('vienna')) {
      label = '🇦🇹 Відень';
      accentColor = const Color(0xFFF43F5E);
    } else if (bId == 'all') {
      label = '🌐 Всі філії';
      accentColor = const Color(0xFF38BDF8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCoachCard({
    required String coachId,
    required String name,
    required String phone,
    required String loginId,
    required int rateGroup,
    required int rateIndividual,
    required int rateSplit,
    required int index,
    required AppThemeConfig currentTheme,
    String? branchId,
    List<dynamic>? branchIds,
  }) {
    final isCopied = _recentlyCopiedCoachId == coachId;

    return RepaintBoundary(
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: currentTheme.isDark
                  ? [
                      const Color(0xFF0C2238).withValues(alpha: 0.92),
                      const Color(0xFF061424).withValues(alpha: 0.96),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.94),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.90),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: currentTheme.isDark
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.28)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.08)
                    : const Color(0xFF0284C7).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: currentTheme.isDark ? 0.35 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 50x50 Jewel Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: currentTheme.isDark ? 0.45 : 0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length].first.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info with Smart Adaptive Layout
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 5,
                          children: [
                            _buildBranchBadge(branchId, branchIds, currentTheme),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Clipboard.setData(ClipboardData(text: phone));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Номер $phone скопійовано!'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.phone,
                                      size: 12.5,
                                      color: Color(0xFF00E5FF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
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
                  ),
                  const SizedBox(width: 10),

                  // Action Buttons (Jewel Edit & Delete, 36x36)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentTheme.isDark
                                ? [
                                    const Color(0xFF00E5FF).withValues(alpha: 0.16),
                                    const Color(0xFF0284C7).withValues(alpha: 0.10),
                                  ]
                                : [
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFFF0F9FF),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                : const Color(0xFFBAE6FD),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.12 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.pencil,
                            color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EditCoachSheet(
                                coachId: coachId,
                                initialName: name,
                                initialPhone: phone,
                                initialRateGroup: rateGroup,
                                initialRateIndividual: rateIndividual,
                                initialRateSplit: rateSplit,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentTheme.isDark
                                ? [
                                    const Color(0xFFF43F5E).withValues(alpha: 0.18),
                                    const Color(0xFF881337).withValues(alpha: 0.12),
                                  ]
                                : [
                                    const Color(0xFFFFF1F2),
                                    const Color(0xFFFFE4E6),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? const Color(0xFFF43F5E).withValues(alpha: 0.40)
                                : const Color(0xFFFECDD3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withValues(alpha: currentTheme.isDark ? 0.12 : 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            color: currentTheme.isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                            size: 16,
                          ),
                          tooltip: 'admin.delete'.tr(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _deleteCoach(coachId, name, currentTheme);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Rates Row (Group, Individual, Split) in Obsidian Glass Pod
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: currentTheme.isDark
                      ? const Color(0xFF040D18).withValues(alpha: 0.60)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentTheme.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                        : const Color(0xFFBAE6FD),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRateChip(
                        label: 'ГРУПОВІ',
                        amount: '$rateGroup ₴',
                        icon: LucideIcons.users,
                        color: const Color(0xFF00E5FF),
                        currentTheme: currentTheme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: currentTheme.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                    ),
                    Expanded(
                      child: _buildRateChip(
                        label: 'ІНДИВІД.',
                        amount: '$rateIndividual ₴',
                        icon: LucideIcons.user,
                        color: const Color(0xFFA855F7),
                        currentTheme: currentTheme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: currentTheme.isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : const Color(0xFFCBD5E1),
                    ),
                    Expanded(
                      child: _buildRateChip(
                        label: 'СПЛІТ',
                        amount: '$rateSplit ₴',
                        icon: LucideIcons.userCheck,
                        color: const Color(0xFFF59E0B),
                        currentTheme: currentTheme,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Credentials Pod with Instant Copy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: currentTheme.isDark
                      ? const Color(0xFF040D18).withValues(alpha: 0.70)
                      : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentTheme.isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                        : const Color(0xFFBAE6FD),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: currentTheme.isDark ? 0.20 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.keyRound,
                        color: Color(0xFF00E5FF),
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'admin.clients_login_label'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                loginId,
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  color: currentTheme.isDark ? Colors.white24 : Colors.black26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'admin.clients_password_label'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                                  width: 0.9,
                                ),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _copyCredentials(coachId, loginId, name),
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isCopied
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isCopied ? const Color(0xFF10B981) : const Color(0xFF00E5FF)).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCopied ? LucideIcons.check : LucideIcons.copy,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCopied ? 'Скопійовано' : 'admin.clients_copy'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action: Manage Coach Schedule (VisionOS Action Banner)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminCalendarScreen(
                            initialCoachId: coachId,
                            initialCoachName: name,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentTheme.isDark
                              ? [
                                  const Color(0xFF00E5FF).withValues(alpha: 0.18),
                                  const Color(0xFF0284C7).withValues(alpha: 0.08),
                                ]
                              : [
                                  const Color(0xFFE0F2FE),
                                  const Color(0xFFF0F9FF),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentTheme.isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.38)
                              : const Color(0xFFBAE6FD),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: currentTheme.isDark ? 0.10 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.calendarClock,
                              size: 15,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'admin.manage_schedule'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentTheme.isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 17,
                            color: currentTheme.isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.8)
                                : const Color(0xFF0284C7).withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (60 * (index < 6 ? index : 0)).ms, duration: 250.ms).slideY(begin: 0.05);
  }

  Widget _buildRateChip({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
    required AppThemeConfig currentTheme,
  }) {
    final isDark = currentTheme.isDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                amount,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeConfig currentTheme, {String? activeBranchId, String? branchName}) {
    final effectiveBranchName = branchName ?? 'поточної філії';
    final isVienna = activeBranchId == 'vienna';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentTheme.isDark
                    ? [
                        const Color(0xFF0C2238).withValues(alpha: 0.90),
                        const Color(0xFF061424).withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.88),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                    : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(LucideIcons.users, size: 40, color: Color(0xFF00E5FF)),
                ),
                const SizedBox(height: 18),
                Text(
                  'admin.coaches_empty_title'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isVienna
                      ? 'У філії CitySwim Vienna ще немає створених тренерів.\nВи можете завантажити тренерів Maria Huber та Stefan Gruber автоматично або додати нового тренера вручну.'
                      : (activeBranchId != null && activeBranchId != 'all'
                          ? 'У філії $effectiveBranchName ще немає зареєстрованих тренерів.'
                          : 'admin.coaches_empty_desc'.tr()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await _seedBranchCoaches(activeBranchId);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isVienna
                                ? 'Завантажити тренерів Відня'
                                : 'Завантажити базових тренерів',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Future<void> _seedBranchCoaches(String? branchId) async {
    try {
      await ensureDefaultCoachInFirestore(force: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(branchId == 'vienna' ? 'Тренери Відня успішно завантажені!' : 'Тренери успішно завантажені!'),
            backgroundColor: const Color(0xFF00E5FF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildNoSearchResults(AppThemeConfig currentTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentTheme.isDark
                    ? [
                        const Color(0xFF0C2238).withValues(alpha: 0.90),
                        const Color(0xFF061424).withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFF0F9FF).withValues(alpha: 0.88),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: currentTheme.isDark
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                    : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(LucideIcons.userX, size: 40, color: Color(0xFF00E5FF)),
                ),
                const SizedBox(height: 18),
                Text(
                  'admin.coaches_not_found'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? Colors.white : currentTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'admin.coaches_not_found_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
