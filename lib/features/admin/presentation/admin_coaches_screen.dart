import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'add_coach_sheet.dart';
import 'edit_coach_sheet.dart';

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
    Clipboard.setData(ClipboardData(text: 'Логін: $loginId\nПароль: 1'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Дані входу для тренера "$name" скопійовано!')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteCoach(String coachId, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A2C),
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
            const Text('Видалити тренера?', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Ви впевнені, що хочете видалити тренера $name? Його доступ до системи буде скасовано.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити'),
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
            content: Text('Тренера "$name" успішно видалено'),
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
    return Scaffold(
      backgroundColor: const Color(0xFF09182B),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF061426),
          elevation: 0,
          icon: const Icon(LucideIcons.userPlus, size: 18),
          label: const Text('Додати тренера', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
          // 1. Full-fidelity animated water ripples and particles (like in Client screen)
          const Positioned.fill(
            child: RepaintBoundary(child: AnimatedWaterBackground()),
          ),
          const Positioned.fill(
            child: RepaintBoundary(child: WaterParticles()),
          ),

          // 2. Fluid aquatic gradient overlay (harmonized with Client screen)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00B4DB).withValues(alpha: 0.20),
                    const Color(0xFF0284C7).withValues(alpha: 0.12),
                    const Color(0xFF0F172A).withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                    const Color(0xFF38BDF8).withValues(alpha: 0.22),
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
                    const Color(0xFF8B5CF6).withValues(alpha: 0.14),
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
                _buildHeader(context),

                // 2. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: _buildSearchBar(),
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
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
                        return _buildNoSearchResults();
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

                          return _buildCoachCard(
                            coachId: coachId,
                            name: name,
                            phone: phone,
                            loginId: loginId,
                            index: index,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
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
                    const Text(
                      'Всі Тренери',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Команда',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Керування тренерським складом та доступами',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Пошук за ім\'ям, телефоном чи логіном...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
          prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF38BDF8), size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white54, size: 16),
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
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF13233C).withValues(alpha: 0.9),
            const Color(0xFF0E182A).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0096C7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'Т',
                        style: const TextStyle(
                          color: Color(0xFF061426),
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
                        border: Border.all(color: const Color(0xFF0A1220), width: 2),
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
                            style: const TextStyle(
                              color: Colors.white,
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
                        Icon(LucideIcons.phone, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 5),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
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
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 16),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => EditCoachSheet(
                            coachId: coachId,
                            initialName: name,
                            initialPhone: phone,
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
                      tooltip: 'Видалити',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteCoach(coachId, name),
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
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.keyRound, color: Color(0xFF38BDF8), size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      children: [
                        const TextSpan(text: 'Логін: '),
                        TextSpan(
                          text: loginId,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const TextSpan(text: '   |   Пароль: '),
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
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.copy, color: Color(0xFF38BDF8), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Копіювати',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
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
        ],
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 50, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Немає зареєстрованих тренерів', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Натисніть кнопку нижче, щоб додати першого тренера', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 44, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          const Text('Тренерів не знайдено', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Спробуйте змінити пошуковий запит', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5)),
        ],
      ),
    );
  }
}
