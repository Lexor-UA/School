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
  int _selectedFilterIndex = 0; // 0: Всі, 1: Непрочитані
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogsAsync = ref.watch(adminChatDialogsStreamProvider);
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

                    // Filter dialogs
                    List<ChatDialog> filteredDialogs = dialogs.where((d) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          d.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          d.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesUnread = _selectedFilterIndex == 0 || d.unreadAdminCount > 0;
                      return matchesSearch && matchesUnread;
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
                            // Unread count pill
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF38BDF8).withValues(alpha: 0.25),
                                      const Color(0xFF0077B6).withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                                  ),
                                ),
                                child: Text(
                                  '$unreadCount ${unreadCount == 1 ? 'admin.chat_new_one'.tr() : 'admin.chat_new_many'.tr()}',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
                              hintText: 'admin.chat_search_hint'.tr(),
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

                        // Filter chips (Всі, Непрочитані)
                        Row(
                          children: [
                            _buildFilterChip(
                              label: 'admin.chat_all_dialogs'.tr(),
                              count: dialogs.length,
                              isSelected: _selectedFilterIndex == 0,
                              onTap: () => setState(() => _selectedFilterIndex = 0),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: 'admin.chat_unread'.tr(),
                              count: unreadCount,
                              isSelected: _selectedFilterIndex == 1,
                              accentColor: const Color(0xFF38BDF8),
                              onTap: () => setState(() => _selectedFilterIndex = 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                                    return _buildChatItem(index, filteredDialogs[index]);
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

  Widget _buildFilterChip({
    required String label,
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
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.3)
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

  Widget _buildChatItem(int index, ChatDialog dialog) {
    final bool isUnread = dialog.unreadAdminCount > 0;
    final timeString =
        "${dialog.lastMessageTime.hour.toString().padLeft(2, '0')}:${dialog.lastMessageTime.minute.toString().padLeft(2, '0')}";

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
        splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.15),
        highlightColor: const Color(0xFF38BDF8).withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnread
                  ? [
                      const Color(0xFF162E4A).withValues(alpha: 0.9),
                      const Color(0xFF0E1C30).withValues(alpha: 0.92),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: isUnread ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUnread ? 0.3 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (isUnread)
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with live Firestore lookup
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnread
                            ? const Color(0xFF38BDF8).withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: isUnread
                          ? [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
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
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0A1422),
                          width: 2.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF10B981),
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
                                child: Text(
                                  'admin.chat_client_badge'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isUnread ? const Color(0xFF38BDF8) : Colors.white38,
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D2FF), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D2FF).withValues(alpha: 0.4),
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
