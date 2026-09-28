import 'dart:ui';
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
            content: Text('admin.clients_deleted_success'.tr(args: [name])),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: currentTheme.accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: currentTheme.accentPrimary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.userPlus, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'admin.add_coach_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'coach')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: currentTheme.accentPrimary));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState(currentTheme);
                      }

                      final tenancyState = ref.watch(tenancyControllerProvider);
                      final activeBranchId = tenancyState.activeBranchId;
                      final isAllLocations = tenancyState.isAllLocationsSelected;

                      final rawCoaches = snapshot.data!.docs;
                      var coaches = isAllLocations
                          ? rawCoaches
                          : rawCoaches.where((c) {
                              final d = c.data() as Map<String, dynamic>;
                              final bId = d['branchId'] as String? ?? 'kyiv';
                              final bIds = (d['branchIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [bId];
                              return bId == activeBranchId || bIds.contains(activeBranchId);
                            }).toList();

                      if (_searchQuery.isNotEmpty) {
                        coaches = coaches.where((c) {
                          final data = c.data() as Map<String, dynamic>;
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
                            : _buildEmptyState(currentTheme);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: coaches.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = coaches[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final coachId = doc.id;
                          final name = data['name'] ?? 'Невідомо';
                          final phone = data['phone'] ?? 'Немає номеру';
                          final loginId = data['loginId'] ?? 'Не призначено';
                          final rateGroup = (data['rateGroup'] as num?)?.toInt() ?? 400;
                          final rateIndividual = (data['rateIndividual'] as num?)?.toInt() ?? 450;
                          final rateSplit = (data['rateSplit'] as num?)?.toInt() ?? 600;

                          return _buildCoachCard(
                            coachId: coachId,
                            name: name,
                            phone: phone,
                            loginId: loginId,
                            rateGroup: rateGroup,
                            rateIndividual: rateIndividual,
                            rateSplit: rateSplit,
                            index: index,
                            currentTheme: currentTheme,
                          );
                        },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentTheme.glassCardBg,
              shape: BoxShape.circle,
              border: Border.all(color: currentTheme.cardBorder),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: currentTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'admin.coaches_title'.tr(),
                      style: TextStyle(
                        color: currentTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentTheme.accentPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentTheme.accentPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'admin.coaches_team_badge'.tr(),
                        style: TextStyle(
                          color: currentTheme.accentPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'admin.coaches_subtitle'.tr(),
                  style: TextStyle(
                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                    fontSize: 12,
                  ),
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
        color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: currentTheme.isDark
            ? [
                BoxShadow(
                  color: currentTheme.accentPrimary.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF003B73).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
          prefixIcon: Icon(
            LucideIcons.search,
            color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: currentTheme.textSecondary, size: 16),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
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
  }) {
    final isCopied = _recentlyCopiedCoachId == coachId;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: currentTheme.isDark
                  ? [
                      Colors.white.withValues(alpha: 0.18),
                      const Color(0xFF0284C7).withValues(alpha: 0.18),
                      const Color(0xFF0D2542).withValues(alpha: 0.45),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.92),
                      const Color(0xFFF0F9FF).withValues(alpha: 0.88),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: currentTheme.isDark
                  ? Colors.white.withValues(alpha: 0.30)
                  : currentTheme.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: currentTheme.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.35) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length].first.withValues(alpha: currentTheme.isDark ? 0.35 : 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: currentTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
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
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.phone, size: 12.5, color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: currentTheme.isDark ? const Color(0xFFB0D4EC) : currentTheme.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: currentTheme.isDark
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.10) : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : const Color(0xFFBAE6FD),
                            width: 1.1,
                          ),
                          boxShadow: currentTheme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.pencil,
                            color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
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
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: currentTheme.isDark
                              ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                              : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentTheme.isDark
                                ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                                : const Color(0xFFFECDD3),
                            width: 1.1,
                          ),
                          boxShadow: currentTheme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
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

              const SizedBox(height: 12),

              // Rates Row (Group, Individual, Split)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: currentTheme.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentTheme.isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRateChip(
                        label: 'Групові',
                        amount: '$rateGroup ₴',
                        icon: LucideIcons.users,
                        color: const Color(0xFF00E5FF),
                        currentTheme: currentTheme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                    ),
                    Expanded(
                      child: _buildRateChip(
                        label: 'Індивід.',
                        amount: '$rateIndividual ₴',
                        icon: LucideIcons.user,
                        color: const Color(0xFFA855F7),
                        currentTheme: currentTheme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: currentTheme.isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                    ),
                    Expanded(
                      child: _buildRateChip(
                        label: 'Спліт',
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

              // Credentials Card with Instant Copy
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: currentTheme.isDark
                      ? Colors.black.withValues(alpha: 0.28)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentTheme.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFCBD5E1),
                    width: 1.1,
                  ),
                  boxShadow: currentTheme.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF003B73).withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.keyRound,
                      color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'admin.clients_login_label'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: currentTheme.isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              loginId,
                              style: TextStyle(
                                color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                                fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyCredentials(coachId, loginId, name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isCopied
                              ? const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                )
                              : LinearGradient(
                                  colors: currentTheme.accentGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (isCopied ? const Color(0xFF10B981) : currentTheme.accentPrimary).withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCopied ? LucideIcons.check : LucideIcons.copy,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCopied ? 'Скопійовано' : 'admin.clients_copy'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action: Manage Coach Schedule
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: currentTheme.isDark
                            ? LinearGradient(
                                colors: [
                                  currentTheme.accentPrimary.withValues(alpha: 0.20),
                                  currentTheme.accentSecondary.withValues(alpha: 0.10),
                                ],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: currentTheme.isDark
                              ? currentTheme.accentPrimary.withValues(alpha: 0.35)
                              : const Color(0xFFBAE6FD),
                          width: 1.2,
                        ),
                        boxShadow: currentTheme.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.calendarClock,
                            size: 15,
                            color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'admin.manage_schedule'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentTheme.isDark ? currentTheme.accentPrimary : const Color(0xFF0284C7),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: currentTheme.isDark
                                ? currentTheme.accentPrimary.withValues(alpha: 0.7)
                                : const Color(0xFF0284C7).withValues(alpha: 0.7),
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
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06);
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
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
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                amount,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
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

  Widget _buildEmptyState(AppThemeConfig currentTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 50, color: currentTheme.textMuted),
          const SizedBox(height: 16),
          Text('admin.coaches_empty_title'.tr(), style: TextStyle(color: currentTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('admin.coaches_empty_desc'.tr(), style: TextStyle(color: currentTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(AppThemeConfig currentTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 44, color: currentTheme.textMuted),
          const SizedBox(height: 14),
          Text('admin.coaches_not_found'.tr(), style: TextStyle(color: currentTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('admin.coaches_not_found_desc'.tr(), style: TextStyle(color: currentTheme.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}
