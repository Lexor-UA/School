import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/parent/models/family.dart';
import 'package:swimming_school_app/features/parent/controllers/family_controller.dart';

class ClientFamilySection extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? initialBranchId;
  final Family? family;
  final List<String> parentIds;
  final bool isDark;

  const ClientFamilySection({
    super.key,
    required this.clientId,
    required this.clientName,
    this.initialBranchId,
    required this.family,
    required this.parentIds,
    required this.isDark,
  });

  @override
  ConsumerState<ClientFamilySection> createState() =>
      _ClientFamilySectionState();
}

class _ClientFamilySectionState extends ConsumerState<ClientFamilySection> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final family = widget.family;
    final isPaired = family?.isPaired ?? false;
    final partnerName = family?.getOtherParentName(widget.clientId);
    final partnerPhone = family?.getOtherParentPhone(widget.clientId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    LucideIcons.heartHandshake,
                    color: isDark
                        ? const Color(0xFF10B981)
                        : const Color(0xFF059669),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Сімейний зв\'язок (CRM)',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isPaired)
              TextButton.icon(
                onPressed: () => _showLinkParentDialog(
                  context,
                  isDark: isDark,
                  existingFamily: family,
                ),
                icon: Icon(
                  LucideIcons.userPlus,
                  color: isDark
                      ? const Color(0xFF10B981)
                      : const Color(0xFF059669),
                  size: 15,
                ),
                label: const Text(
                  'Зв\'язати пару',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF10B981,
                  ).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (isPaired && family != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(
                  0xFF10B981,
                ).withValues(alpha: isDark ? 0.35 : 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.users,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Партнер: ${partnerName ?? "Невідомо"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                if (partnerPhone != null &&
                                    partnerPhone.isNotEmpty)
                                  Text(
                                    partnerPhone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        family.inviteCode,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Обидва батьки мають спільний доступ до дітей та абонементів.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _confirmUnlinkFamily(family, isDark: isDark),
                      icon: const Icon(
                        LucideIcons.userX,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Розірвати',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.userMinus,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Акаунт не має зв\'язку з другим із батьків',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (family != null)
                        Text(
                          'Код сім\'ї: ${family.inviteCode}',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmUnlinkFamily(
    Family family, {
    required bool isDark,
  }) async {
    final partnerName =
        family.getOtherParentName(widget.clientId) ?? 'партнера';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Розірвати зв\'язок?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Ви впевнені, що хочете розірвати сімейний зв\'язок клієнта "${widget.clientName}" з $partnerName? Спільний доступ до дітей та абонементів буде розділено.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Розірвати',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(familyControllerProvider).adminUnlinkFamily(family.id);
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction(
          'Розірвано сімейний зв\'язок клієнтів "${widget.clientName}" та "$partnerName"',
          admin.id,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сімейний зв\'язок успішно розірвано.'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLinkParentDialog(
    BuildContext context, {
    required bool isDark,
    required Family? existingFamily,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        String searchQuery = '';
        String? selectedClientId;
        String? selectedClientName;
        bool isLinking = false;

        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.98),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.heartHandshake,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Зв\'язати у спільну сім\'ю',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Клієнт: ${widget.clientName}',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF059669),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      TextField(
                        onChanged: (val) => setModalState(
                          () => searchQuery = val.trim().toLowerCase(),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Пошук за ім\'ям або телефоном...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Client List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'parent')
                              .snapshots(),
                          builder: (context, userSnap) {
                            if (!userSnap.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final candidateDocs = userSnap.data!.docs.where((
                              doc,
                            ) {
                              if (doc.id == widget.clientId) return false;
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['name'] as String? ?? '')
                                  .toLowerCase();
                              final phone = (data['phone'] as String? ?? '')
                                  .toLowerCase();
                              if (searchQuery.isNotEmpty) {
                                return name.contains(searchQuery) ||
                                    phone.contains(searchQuery);
                              }
                              return true;
                            }).toList();

                            if (candidateDocs.isEmpty) {
                              return Center(
                                child: Text(
                                  'Клієнтів не знайдено',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: candidateDocs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, idx) {
                                final doc = candidateDocs[idx];
                                final data = doc.data() as Map<String, dynamic>;
                                final cId = doc.id;
                                final cName =
                                    data['name'] as String? ?? 'Клієнт';
                                final cPhone = data['phone'] as String? ?? '';
                                final isSelected = selectedClientId == cId;

                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      selectedClientId = cId;
                                      selectedClientName = cName;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF10B981).withValues(
                                              alpha: isDark ? 0.25 : 0.12,
                                            )
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.04,
                                                  )
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : (isDark
                                                  ? Colors.white12
                                                  : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isSelected
                                              ? const Color(0xFF10B981)
                                              : (isDark
                                                    ? Colors.white12
                                                    : const Color(0xFFE2E8F0)),
                                          child: Text(
                                            cName.isNotEmpty
                                                ? cName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black87),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (cPhone.isNotEmpty)
                                                Text(
                                                  cPhone,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            LucideIcons.checkCircle2,
                                            color: Color(0xFF10B981),
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (selectedClientId == null || isLinking)
                              ? null
                              : () async {
                                  setModalState(() => isLinking = true);
                                  final error = await ref
                                      .read(familyControllerProvider)
                                      .adminLinkParents(
                                        widget.clientId,
                                        selectedClientId!,
                                      );
                                  setModalState(() => isLinking = false);

                                  if (error != null) {
                                    if (builderCtx.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    final admin = ref.read(
                                      authControllerProvider,
                                    );
                                    if (admin != null) {
                                      await logAdminAction(
                                        'Об\'єднано у сім\'ю клієнтів "${widget.clientName}" та "$selectedClientName"',
                                        admin.id,
                                      );
                                    }
                                    if (modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Акаунти "${widget.clientName}" та "$selectedClientName" успішно об\'єднано у спільну сім\'ю!',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF064E3B,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isLinking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.heartHandshake,
                                  size: 18,
                                ),
                          label: Text(
                            isLinking
                                ? 'Об\'єднання...'
                                : 'Об\'єднати з ${selectedClientName ?? "обраним клієнтом"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
