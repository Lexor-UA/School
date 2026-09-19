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
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

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
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final dialogsAsync = ref.watch(adminChatDialogsStreamProvider);
    final userRolesAsync = ref.watch(usersRoleMapProvider);
    final userRoles = userRolesAsync.value ?? const <String, String>{};
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.84;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    const Color(0xFF0284C7).withValues(alpha: 0.26),
                    const Color(0xFF0A223D).withValues(alpha: 0.52),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFF8FAFC),
                  ],
                ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
            if (isDark)
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
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
                  data: (rawDialogs) {
                    // Deduplicate non-recovery dialogs by clientId to keep the list clean
                    final Map<String, ChatDialog> deduplicatedMap = {};
                    for (final d in rawDialogs) {
                      final role = _getDialogRole(d, userRoles);
                      final isRecovery = role == 'recovery';
                      final key = isRecovery ? d.id : '${d.clientId}_$role';
                      if (!deduplicatedMap.containsKey(key)) {
                        deduplicatedMap[key] = d;
                      } else {
                        final existing = deduplicatedMap[key]!;
                        if (d.lastMessageTime.isAfter(existing.lastMessageTime)) {
                          deduplicatedMap[key] = d.copyWith(
                            unreadAdminCount: d.unreadAdminCount + existing.unreadAdminCount,
                          );
                        } else {
                          deduplicatedMap[key] = existing.copyWith(
                            unreadAdminCount: existing.unreadAdminCount + d.unreadAdminCount,
                          );
                        }
                      }
                    }
                    final dialogs = deduplicatedMap.values.toList();
                    dialogs.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

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
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : const Color(0xFF94A3B8),
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
                                  colors: isDark
                                      ? [
                                          const Color(0xFF38BDF8).withValues(alpha: 0.30),
                                          const Color(0xFF0077B6).withValues(alpha: 0.18),
                                        ]
                                      : const [
                                          Color(0xFF00D2FF),
                                          Color(0xFF0077B6),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.40),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withValues(alpha: isDark ? 0.25 : 0.30),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.headset,
                                  color: Colors.white,
                                  size: 22,
                                ),
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
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
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
                                          ? LinearGradient(
                                              colors: isDark
                                                  ? const [Color(0xFF00E5FF), Color(0xFF0284C7)]
                                                  : const [Color(0xFF0284C7), Color(0xFF0369A1)],
                                            )
                                          : null,
                                      color: _onlyUnread
                                          ? null
                                          : (isDark
                                              ? const Color(0xFF38BDF8).withValues(alpha: 0.20)
                                              : const Color(0xFFE0F2FE)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _onlyUnread
                                            ? Colors.white
                                            : (isDark
                                                ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                                                : const Color(0xFFBAE6FD)),
                                        width: _onlyUnread ? 1.4 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: _onlyUnread ? 0.35 : 0.10),
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
                                          color: _onlyUnread
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _onlyUnread ? 'Тільки нові' : '$unreadCount нових',
                                          style: TextStyle(
                                            color: _onlyUnread
                                                ? Colors.white
                                                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
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
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.20)
                                      : const Color(0xFFBAE6FD),
                                ),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: isDark ? Colors.white : const Color(0xFF334155),
                                  size: 18,
                                ),
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
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : const Color(0xFFBAE6FD),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.10 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'admin.chat_search_hint'.tr(),
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFFB0D4EC).withValues(alpha: 0.70)
                                    : const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              isDense: true,
                              prefixIcon: Icon(
                                LucideIcons.search,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                size: 18,
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3 Compact Proportional Category Tabs on full width
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildCategoryTab(
                                label: 'Всі',
                                count: dialogs.length,
                                isSelected: _selectedCategoryIndex == 0,
                                isDark: isDark,
                                currentTheme: currentTheme,
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
                                isDark: isDark,
                                currentTheme: currentTheme,
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
                                isDark: isDark,
                                currentTheme: currentTheme,
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFFF59E0B).withValues(alpha: 0.30),
                                              const Color(0xFFD97706).withValues(alpha: 0.20),
                                            ]
                                          : const [
                                              Color(0xFFFFFBEB),
                                              Color(0xFFFEF3C7),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.80)
                                          : const Color(0xFFFCD34D),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.25 : 0.12),
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
                                          color: isDark
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.30)
                                              : const Color(0xFFFDE68A),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFFFDE68A).withValues(alpha: 0.5)
                                                : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                            width: 1,
                                          ),
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
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              _searchQuery == 'відновлення'
                                                  ? 'Фільтр застосовано (натисніть для скасування)'
                                                  : 'Потребує швидкої реакції адміністратора',
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFFB45309),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                                        decoration: BoxDecoration(
                                          gradient: _searchQuery == 'відновлення'
                                              ? null
                                              : const LinearGradient(
                                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                          color: _searchQuery == 'відновлення'
                                              ? (isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0))
                                              : null,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: _searchQuery == 'відновлення'
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.4 : 0.3),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                        ),
                                        child: Text(
                                          _searchQuery == 'відновлення' ? 'Скинути' : 'Показати',
                                          style: TextStyle(
                                            color: _searchQuery == 'відновлення'
                                                ? (isDark ? Colors.white : currentTheme.textPrimary)
                                                : Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // 4. Dialog List
                        Flexible(
                          child: filteredDialogs.isEmpty
                              ? _buildEmptyState(isDark, currentTheme)
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredDialogs.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    return _buildChatItem(index, filteredDialogs[index], userRoles, isDark, currentTheme);
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
    required bool isDark,
    required AppThemeConfig currentTheme,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? (isDark ? const Color(0xFF38BDF8) : currentTheme.accentPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? (isDark
                    ? null
                    : LinearGradient(
                        colors: [
                          color,
                          Color.lerp(color, const Color(0xFF0369A1), 0.25)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ))
                : null,
            color: isSelected
                ? (isDark ? color.withValues(alpha: 0.30) : null)
                : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? color.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.40))
                  : (isDark ? Colors.white.withValues(alpha: 0.20) : const Color(0xFFBAE6FD)),
              width: isSelected ? 1.4 : 1.1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.25 : 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]),
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
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155)),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? color.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.25))
                      : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569)),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppThemeConfig currentTheme) {
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
                color: isDark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                    : const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
                      : const Color(0xFFBAE6FD),
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.messageSquareDashed,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'admin.chat_no_messages'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'admin.chat_nothing_found'.tr()
                  : 'admin.chat_all_processed'.tr(),
              style: TextStyle(
                color: isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.75) : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
    int index,
    ChatDialog dialog,
    Map<String, String> userRoles,
    bool isDark,
    AppThemeConfig currentTheme,
  ) {
    final bool isUnread = dialog.unreadAdminCount > 0;
    final timeString =
        "${dialog.lastMessageTime.hour.toString().padLeft(2, '0')}:${dialog.lastMessageTime.minute.toString().padLeft(2, '0')}";
    final role = _getDialogRole(dialog, userRoles);
    final isRecovery = role == 'recovery';
    final isCoach = role == 'coach';

    String displayName = dialog.clientName;
    if (isRecovery) {
      displayName = displayName
          .replaceFirst(RegExp(r'^🔑\s*'), '')
          .replaceFirst(RegExp(r'^Відновлення пароля:\s*', caseSensitive: false), '')
          .trim();
      if (displayName.isEmpty) displayName = 'Запит відновлення';
    }

    // Role-specific card background gradient
    final List<Color> cardGradientColors = isDark
        ? (isUnread
            ? (isRecovery
                ? [
                    Colors.white.withValues(alpha: 0.24),
                    const Color(0xFFF59E0B).withValues(alpha: 0.26),
                    const Color(0xFF451A03).withValues(alpha: 0.50),
                  ]
                : (isCoach
                    ? [
                        Colors.white.withValues(alpha: 0.24),
                        const Color(0xFF10B981).withValues(alpha: 0.24),
                        const Color(0xFF064E3B).withValues(alpha: 0.50),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.26),
                        const Color(0xFF0284C7).withValues(alpha: 0.26),
                        const Color(0xFF0B2B4C).withValues(alpha: 0.50),
                      ]))
            : [
                Colors.white.withValues(alpha: 0.16),
                const Color(0xFF0284C7).withValues(alpha: 0.10),
                const Color(0xFF081C30).withValues(alpha: 0.40),
              ])
        : (isUnread
            ? (isRecovery
                ? const [
                    Colors.white,
                    Color(0xFFFFFBEB),
                  ]
                : (isCoach
                    ? const [
                        Colors.white,
                        Color(0xFFF0FDF4),
                      ]
                    : const [
                        Colors.white,
                        Color(0xFFF0F9FF),
                      ]))
            : const [
                Colors.white,
                Color(0xFFF8FAFC),
              ]);

    final Color cardBorderColor = isUnread
        ? (isRecovery
            ? const Color(0xFFF59E0B)
            : (isCoach
                ? const Color(0xFF10B981)
                : const Color(0xFF0284C7)))
        : (isDark ? Colors.white.withValues(alpha: 0.32) : const Color(0xFFBAE6FD));

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
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
                    : (isCoach ? const Color(0xFF10B981) : const Color(0xFF0284C7)))
                .withValues(alpha: 0.15),
            highlightColor: (isRecovery
                    ? const Color(0xFFF59E0B)
                    : (isCoach ? const Color(0xFF10B981) : const Color(0xFF0284C7)))
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
                  width: isUnread ? 1.4 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: isUnread ? 0.25 : 0.10)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (isUnread)
                    BoxShadow(
                      color: (isRecovery
                              ? const Color(0xFFF59E0B)
                              : (isCoach ? const Color(0xFF10B981) : const Color(0xFF0284C7)))
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                      blurRadius: 14,
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
                                    ? const Color(0xFF10B981).withValues(alpha: isUnread ? 0.9 : 0.6)
                                    : (isUnread
                                        ? const Color(0xFF0284C7).withValues(alpha: 0.85)
                                        : (isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFBAE6FD)))),
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
                                color: (isCoach ? const Color(0xFF10B981) : const Color(0xFF0284C7))
                                    .withValues(alpha: 0.35),
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

                                  // Only show NetworkImage if it's a real user photo and not generic ui-avatars
                                  if (avatarUrl.isNotEmpty &&
                                      avatarUrl.startsWith('http') &&
                                      !avatarUrl.contains('ui-avatars.com')) {
                                    return CircleAvatar(
                                      radius: 22,
                                      backgroundImage: NetworkImage(avatarUrl),
                                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                    );
                                  }

                                  // Jewel Avatar gradient from app theme palette
                                  final avatarGradient = isCoach
                                      ? const [Color(0xFF10B981), Color(0xFF0284C7)]
                                      : currentTheme.actionCardGradients[name.hashCode.abs() % currentTheme.actionCardGradients.length];

                                  // Extract 2-letter bold initials
                                  final parts = name.trim().split(RegExp(r'\s+'));
                                  final initials = parts.length > 1
                                      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                                      : (name.length >= 2 ? name.substring(0, 2).toUpperCase() : (name.isNotEmpty ? name[0].toUpperCase() : '?'));

                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: avatarGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: avatarGradient.first.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 0.4,
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
                              color: isDark ? const Color(0xFF0A1422) : Colors.white,
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
                                      displayName,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                                        fontSize: 15.5,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Role Badge with strict WCAG AAA contrast
                                  if (isRecovery)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.22)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFFF59E0B).withValues(alpha: 0.60)
                                              : const Color(0xFFFDE68A),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🔑 ', style: TextStyle(fontSize: 8.5)),
                                          Text(
                                            'ВІДНОВЛЕННЯ',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isCoach)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF10B981).withValues(alpha: 0.22)
                                            : const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF10B981).withValues(alpha: 0.60)
                                              : const Color(0xFFA7F3D0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('🏊 ', style: TextStyle(fontSize: 8.5)),
                                          Text(
                                            'ТРЕНЕР',
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF38BDF8).withValues(alpha: 0.18)
                                            : const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF38BDF8).withValues(alpha: 0.45)
                                              : const Color(0xFFBAE6FD),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('👤 ', style: TextStyle(fontSize: 8.5)),
                                          Text(
                                            'admin.chat_client_badge'.tr(),
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
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
                                        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                                        : (isCoach
                                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                            : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))))
                                    : (isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.75) : const Color(0xFF64748B)),
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
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
                                  color: isUnread
                                      ? (isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF0F172A))
                                      : (isDark ? const Color(0xFFB0D4EC).withValues(alpha: 0.80) : const Color(0xFF475569)),
                                  fontSize: 13,
                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
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
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                    size: 13,
                                  ),
                                ),
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
        ),
      ),
    ).animate().fadeIn(delay: (40 * index).ms).slideX(begin: 0.04);
  }
}
