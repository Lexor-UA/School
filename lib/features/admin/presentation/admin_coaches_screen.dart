import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCredentials(String loginId, String name) {
    Clipboard.setData(ClipboardData(text: '${'admin.clients_login_label'.tr()}$loginId\n${'admin.clients_password_label'.tr()}1'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('admin.coaches_copied_msg'.tr(args: [name]))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          SnackBar(content: Text('Помилка: $e'), backgroundColor: const Color(0xFFF43F5E)),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: currentTheme.accentPrimary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: currentTheme.accentPrimary,
          foregroundColor: currentTheme.isDark ? const Color(0xFF061426) : Colors.white,
          elevation: 0,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: Text('admin.add_coach_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddCoachSheet(),
            );
          },
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

                      var coaches = snapshot.data!.docs;
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
                        return _buildNoSearchResults(currentTheme);
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
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
                    color: currentTheme.textSecondary,
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
        color: currentTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: currentTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: currentTheme.textPrimary, fontSize: 13.5),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'admin.coaches_search_hint'.tr(),
          hintStyle: TextStyle(color: currentTheme.textMuted, fontSize: 13),
          prefixIcon: Icon(LucideIcons.search, color: currentTheme.accentPrimary, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: currentTheme.textMuted, size: 16),
                  onPressed: () {
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: currentTheme.cardBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTheme.cardShadow,
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
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTheme.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'Т',
                        style: TextStyle(
                          color: currentTheme.isDark ? const Color(0xFF061426) : Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: currentTheme.cardBg, width: 2),
                      ),
                    ),
                  ),
                ],
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
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(LucideIcons.phone, size: 12, color: currentTheme.textMuted),
                        const SizedBox(width: 5),
                        Text(
                          phone,
                          style: TextStyle(
                            color: currentTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: currentTheme.glassCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: currentTheme.cardBorder),
                    ),
                    child: IconButton(
                      icon: Icon(LucideIcons.pencil, color: currentTheme.accentPrimary, size: 16),
                      onPressed: () {
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
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF3B30).withValues(alpha: 0.24),
                          const Color(0xFFFF1744).withValues(alpha: 0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.60),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3B30), size: 16),
                      tooltip: 'admin.delete'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteCoach(coachId, name, currentTheme),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Credentials Card with Instant Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: currentTheme.glassCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentTheme.cardBorder),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.keyRound, color: currentTheme.accentPrimary, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: currentTheme.textSecondary),
                      children: [
                        TextSpan(text: 'admin.clients_login_label'.tr()),
                        TextSpan(
                          text: loginId,
                          style: TextStyle(
                            color: currentTheme.accentPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(text: '   |   ${'admin.clients_password_label'.tr()}'),
                        const TextSpan(
                          text: '1',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyCredentials(loginId, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentTheme.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, color: currentTheme.accentPrimary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'admin.clients_copy'.tr(),
                          style: TextStyle(
                            color: currentTheme.accentPrimary,
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
            child: ElevatedButton.icon(
              onPressed: () {
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
              icon: const Icon(LucideIcons.calendarClock, size: 14),
              label: const Text(
                'Керувати розкладом тренера',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.accentPrimary.withValues(alpha: 0.12),
                foregroundColor: currentTheme.accentPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: currentTheme.accentPrimary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06);
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
