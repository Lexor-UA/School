import 'dart:ui';
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
import 'add_client_sheet.dart';
import 'payment_sheet.dart';
import 'booking_sheet.dart';
import 'chat_sheet.dart';

class AdminMain extends ConsumerStatefulWidget {
  const AdminMain({super.key});

  @override
  ConsumerState<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends ConsumerState<AdminMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, ref),
                
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildSearchBar().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      
                      // Live Status Banner
                      _buildLiveStatusBanner().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      
                      Text(
                        'admin.quick_actions'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),
                      
                      // Quick Actions Grid
                      Row(
                        children: [
                          Expanded(child: _buildActionCard(LucideIcons.userPlus, 'admin.new_client'.tr(), Colors.cyanAccent, 400, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AddClientSheet(),
                            );
                          })),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActionCard(LucideIcons.calendarPlus, 'admin.booking'.tr(), Colors.greenAccent, 500, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const BookingSheet(),
                            );
                          })),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildActionCard(LucideIcons.messageCircle, 'admin.chat'.tr(), Colors.orangeAccent, 600, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ChatSheet(),
                            );
                          })),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActionCard(LucideIcons.wallet, 'admin.payment'.tr(), Colors.purpleAccent, 700, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PaymentSheet(),
                            );
                          })),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Text(
                        'admin.tasks_today'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 16),
                      
                      _buildTaskItem('admin.task_payment'.tr(), 'admin.task_payment_desc'.tr(), true).animate().fadeIn(delay: 900.ms).slideX(begin: 0.1),
                      const SizedBox(height: 12),
                      _buildTaskItem('admin.task_call'.tr(), 'admin.task_call_desc'.tr(), false, isUrgent: true).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.1),
                      const SizedBox(height: 12),
                      _buildTaskItem('admin.task_schedule'.tr(), 'admin.task_schedule_desc'.tr(), false).animate().fadeIn(delay: 1100.ms).slideX(begin: 0.1),
                      
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 15)],
                  ),
                  child: const AvatarPicker(
                    heroTag: 'hero_avatar_Адміністраторам',
                    radius: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'admin.hello'.tr()}, ${user?.name ?? "Адмін"}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('CitySwim CRM', style: TextStyle(color: Colors.cyanAccent, fontSize: 13, letterSpacing: 1)),
                  ],
                ),
              ],
            ).animate().fadeIn(),
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: Colors.white70),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'admin.search_hint'.tr(),
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatusBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.activity, color: Colors.cyanAccent, size: 24)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('admin.in_pool'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('admin.clients_count'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 16, color: Colors.white24),
                    const SizedBox(width: 12),
                    Text('admin.coaches_count'.tr(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color accentColor, int delay, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 10)],
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1);
  }

  Widget _buildTaskItem(String title, String subtitle, bool isCompleted, {bool isUrgent = false}) {
    Color statusColor = isCompleted ? Colors.greenAccent : (isUrgent ? Colors.orangeAccent : Colors.cyanAccent);
    
    return Dismissible(
      key: Key(title),
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(LucideIcons.checkSquare, color: Colors.black, size: 28),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(LucideIcons.clock, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(direction == DismissDirection.startToEnd ? 'admin.task_done'.tr() : 'admin.task_postponed'.tr()),
            backgroundColor: direction == DismissDirection.startToEnd ? Colors.greenAccent.shade700 : Colors.orangeAccent.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isUrgent ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isCompleted ? LucideIcons.check : LucideIcons.clock, 
                    color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
