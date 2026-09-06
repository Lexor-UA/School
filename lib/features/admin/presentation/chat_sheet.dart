import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/chat/providers/chat_providers.dart';
import 'package:swimming_school_app/features/chat/models/chat_dialog.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatSheet extends ConsumerStatefulWidget {
  const ChatSheet({super.key});

  @override
  ConsumerState<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<ChatSheet> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0; // 0: Всі, 1: Тренери, 2: Клієнти
  bool _onlyUnread = false; // Тільки непрочитані (перемикач по тапу на плашку)
  final TextEditingController _searchController = TextEditingController();

  String _getDialogRole(ChatDialog dialog, Map<String, String> userRoles) {
    final lowerName = dialog.clientName.toLowerCase();
    // 1. Password recovery
    if (dialog.id.startsWith('recovery_') ||
        lowerName.contains('відновлення') ||
        dialog.clientName.contains('🔑')) {
      return 'recovery';
    }
    // 2. Check users collection by ID or name
    final role = userRoles[dialog.clientId] ?? userRoles['name_${dialog.clientName.trim().toLowerCase()}'];
    if (role == 'coach' || lowerName.startsWith('тренер') || lowerName.contains('антон')) {
      return 'coach';
    }
    return 'parent';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogsAsync = ref.watch(adminChatDialogsStreamProvider);
    final userRolesAsync = ref.watch(usersRoleMapProvider);
    final userRoles = userRolesAsync.value ?? const <String, String>{};
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.82;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF13233C).withValues(alpha: 0.95),
              const Color(0xFF0A1422).withValues(alpha: 0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              blurRadius: 36,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  mediaQuery.viewInsets.bottom + 20,
                ),
                child: dialogsAsync.when(
                  data: (dialogs) {
                    final unreadCount = dialogs.where((d) => d.unreadAdminCount > 0).length;
                    final coachesCount = dialogs.where((d) => _getDialogRole(d, userRoles) == 'coach').length;
                    final clientsCount = dialogs.where((d) => _getDialogRole(d, userRoles) == 'parent').length;
                    final recoveryCount = dialogs.where((d) => _getDialogRole(d, userRoles) == 'recovery').length;

                    // Filter dialogs
                    List<ChatDialog> filteredDialogs = dialogs.where((d) {
                      final role = _getDialogRole(d, userRoles);
                      final matchesSearch = _searchQuery.isEmpty ||
                          d.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          d.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesUnread = !_onlyUnread || d.unreadAdminCount > 0;
                      final matchesCategory = _selectedCategoryIndex == 0 ||
                          (_selectedCategoryIndex == 1 && role == 'coach') ||
                          (_selectedCategoryIndex == 2 && role == 'parent');
                      return matchesSearch && matchesUnread && matchesCategory;
                    }).toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Draggable handle bar
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // 2. Header
                        Row(
                          children: [
                            // Support icon badge
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                    const Color(0xFF0077B6).withValues(alpha: 0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.headset, color: Color(0xFF38BDF8), size: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Title and subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'admin.support_center'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF10B981),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'admin.chat_dialogs_online'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Interactive Unread Count Pill / Toggle
                            if (unreadCount > 0 || _onlyUnread)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() => _onlyUnread = !_onlyUnread),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: _onlyUnread
                                          ? const LinearGradient(
                                              colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                                const Color(0xFF0077B6).withValues(alpha: 0.15),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _onlyUnread ? Colors.white : const Color(0xFF38BDF8).withValues(alpha: 0.55),
                                        width: _onlyUnread ? 1.4 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: _onlyUnread ? 0.45 : 0.15),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _onlyUnread ? LucideIcons.check : LucideIcons.bell,
                                          size: 13,
                                          color: _onlyUnread ? Colors.white : const Color(0xFF38BDF8),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _onlyUnread ? 'Тільки нові' : '$unreadCount нових',
                                          style: TextStyle(
                                            color: _onlyUnread ? Colors.white : const Color(0xFF38BDF8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // Close button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                                onPressed: () => Navigator.pop(context),
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Пошук клієнта, тренера чи повідомлення...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
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
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3 Compact Proportional Category Tabs on full width (Zero horizontal scroll, full labels)
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildCategoryTab(
                                label: 'Всі',
                                count: dialogs.length,
                                isSelected: _selectedCategoryIndex == 0,
                                onTap: () => setState(() => _selectedCategoryIndex = 0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 7,
                              child: _buildCategoryTab(
                                label: 'Тренери',
                                icon: '🏊',
                                count: coachesCount,
                                isSelected: _selectedCategoryIndex == 1,
                                accentColor: const Color(0xFF10B981),
                                onTap: () => setState(() => _selectedCategoryIndex = 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 7,
                              child: _buildCategoryTab(
                                label: 'Клієнти',
                                icon: '👤',
                                count: clientsCount,
                                isSelected: _selectedCategoryIndex == 2,
                                accentColor: const Color(0xFF38BDF8),
                                onTap: () => setState(() => _selectedCategoryIndex = 2),
                              ),
                            ),
                          ],
                        ),

                        // VIP Golden Alert Banner for Password Recovery Requests
                        if (recoveryCount > 0 && _selectedCategoryIndex == 0) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_searchQuery == 'відновлення') {
                                  _searchQuery = '';
                                  _searchController.clear();
                                } else {
                                  _searchQuery = 'відновлення';
                                  _searchController.text = 'відновлення';
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF59E0B).withValues(alpha: 0.22),
                                    const Color(0xFFD97706).withValues(alpha: 0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('🔑', style: TextStyle(fontSize: 17)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Запит на відновлення пароля ($recoveryCount)',
                                          style: const TextStyle(
                                            color: Color(0xFFFBBF24),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _searchQuery == 'відновлення'
                                              ? 'Фільтр застосовано (натисніть для скасування)'
                                              : 'Потребує швидкої реакції адміністратора',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _searchQuery == 'відновлення'
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _searchQuery == 'відновлення' ? 'Скинути' : 'Показати',
                                      style: TextStyle(
                                        color: _searchQuery == 'відновлення' ? Colors.white : Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // 4. Dialog List
                        Flexible(
                          child: filteredDialogs.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredDialogs.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _buildChatItem(index, filteredDialogs[index], userRoles);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Помилка завантаження: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    String? icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFF38BDF8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Text(icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 3.5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                ),
              ),
              child: const Center(
                child: Icon(LucideIcons.messageSquareDashed, color: Color(0xFF38BDF8), size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'admin.chat_no_messages'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'admin.chat_nothing_found'.tr()
                  : 'admin.chat_all_processed'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(int index, ChatDialog dialog, Map<String, String> userRoles) {
    final bool isUnread = dialog.unreadAdminCount > 0;
    final timeString =
        "${dialog.lastMessageTime.hour.toString().padLeft(2, '0')}:${dialog.lastMessageTime.minute.toString().padLeft(2, '0')}";
    final role = _getDialogRole(dialog, userRoles);
    final isRecovery = role == 'recovery';
    final isCoach = role == 'coach';

    // Role-specific colors
    final List<Color> cardGradientColors = isUnread
        ? (isRecovery
            ? [
                const Color(0xFF3B2005).withValues(alpha: 0.92),
                const Color(0xFF221102).withValues(alpha: 0.94),
              ]
            : (isCoach
                ? [
                    const Color(0xFF063326).withValues(alpha: 0.92),
                    const Color(0xFF031E17).withValues(alpha: 0.94),
                  ]
                : [
                    const Color(0xFF162E4A).withValues(alpha: 0.9),
                    const Color(0xFF0E1C30).withValues(alpha: 0.92),
                  ]))
        : (isRecovery
            ? [
                const Color(0xFFF59E0B).withValues(alpha: 0.09),
                const Color(0xFFF59E0B).withValues(alpha: 0.03),
              ]
            : (isCoach
                ? [
                    const Color(0xFF10B981).withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.02),
                  ]));

    final Color cardBorderColor = isUnread
        ? (isRecovery
            ? const Color(0xFFF59E0B).withValues(alpha: 0.75)
            : (isCoach
                ? const Color(0xFF10B981).withValues(alpha: 0.7)
                : const Color(0xFF38BDF8).withValues(alpha: 0.55)))
        : (isRecovery
            ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
            : (isCoach
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1)));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.go(
            '/admin/chat?clientName=${Uri.encodeComponent(dialog.clientName)}&clientId=${dialog.clientId}',
          );
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: (isRecovery
                ? const Color(0xFFF59E0B)
                : (isCoach ? const Color(0xFF10B981) : const Color(0xFF38BDF8)))
            .withValues(alpha: 0.15),
        highlightColor: (isRecovery
                ? const Color(0xFFF59E0B)
                : (isCoach ? const Color(0xFF10B981) : const Color(0xFF38BDF8)))
            .withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardGradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorderColor,
              width: isUnread ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUnread ? 0.3 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (isUnread)
                BoxShadow(
                  color: (isRecovery
                          ? const Color(0xFFF59E0B)
                          : (isCoach ? const Color(0xFF10B981) : const Color(0xFF38BDF8)))
                      .withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isRecovery
                            ? const Color(0xFFFDE68A)
                            : (isCoach
                                ? const Color(0xFF10B981).withValues(alpha: isUnread ? 0.9 : 0.45)
                                : (isUnread
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.2))),
                        width: 2,
                      ),
                      boxShadow: [
                        if (isRecovery)
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                            blurRadius: 12,
                          )
                        else if (isUnread)
                          BoxShadow(
                            color: (isCoach ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: isRecovery
                        ? Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Text('🔑', style: TextStyle(fontSize: 22)),
                            ),
                          )
                        : StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(dialog.clientId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data() as Map<String, dynamic>?;
                              final avatarUrl = (data?['avatarUrl'] as String?) ?? dialog.clientAvatar;
                              final name = (data?['name'] as String?) ?? dialog.clientName;

                              if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
                                return CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(avatarUrl),
                                  backgroundColor: Colors.white12,
                                );
                              }

                              // Gradient Monogram fallback
                              return CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isCoach
                                          ? const [Color(0xFF10B981), Color(0xFF0284C7)]
                                          : const [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Online beacon dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isRecovery
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0A1422),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isRecovery ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Content: Client name, role badge, last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  dialog.clientName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Role Badge
                              if (isRecovery)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🔑 ', style: TextStyle(fontSize: 8.5)),
                                      Text(
                                        'ВІДНОВЛЕННЯ',
                                        style: TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isCoach)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🏊 ', style: TextStyle(fontSize: 8.5)),
                                      Text(
                                        'ТРЕНЕР',
                                        style: TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('👤 ', style: TextStyle(fontSize: 8.5)),
                                      Text(
                                        'admin.chat_client_badge'.tr(),
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isUnread
                                ? (isRecovery
                                    ? const Color(0xFFFBBF24)
                                    : (isCoach ? const Color(0xFF34D399) : const Color(0xFF38BDF8)))
                                : Colors.white38,
                            fontSize: 11.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dialog.lastMessage.isNotEmpty ? dialog.lastMessage : 'admin.chat_no_msgs_yet'.tr(),
                            style: TextStyle(
                              color: isUnread ? Colors.white.withValues(alpha: 0.95) : Colors.white60,
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isRecovery
                                    ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                                    : (isCoach
                                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                                        : const [Color(0xFF00D2FF), Color(0xFF0077B6)]),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isRecovery
                                          ? const Color(0xFFF59E0B)
                                          : (isCoach ? const Color(0xFF10B981) : const Color(0xFF00D2FF)))
                                      .withValues(alpha: 0.45),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              '${dialog.unreadAdminCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.chevronRight,
                            color: Colors.white.withValues(alpha: 0.25),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms).slideX(begin: 0.04);
  }
}
