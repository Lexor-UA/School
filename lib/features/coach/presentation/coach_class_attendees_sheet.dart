import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/coach/models/coach_attendee_info.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/parent/presentation/parent_chat_screen.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

void showCoachClassAttendeesSheet(BuildContext context, GroupClass gClass) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => CoachClassAttendeesSheet(groupClass: gClass),
  );
}

class CoachClassAttendeesSheet extends ConsumerStatefulWidget {
  final GroupClass groupClass;

  const CoachClassAttendeesSheet({
    super.key,
    required this.groupClass,
  });

  @override
  ConsumerState<CoachClassAttendeesSheet> createState() => _CoachClassAttendeesSheetState();
}

class _CoachClassAttendeesSheetState extends ConsumerState<CoachClassAttendeesSheet> {
  bool _isLoading = true;
  List<CoachAttendeeInfo> _attendees = [];
  late GroupClass _currentClass;

  @override
  void initState() {
    super.initState();
    _currentClass = widget.groupClass;
    _resolveAttendees();
  }

  Future<void> _resolveAttendees() async {
    setState(() => _isLoading = true);

    final enrolledIds = _currentClass.enrolledChildIds;
    if (enrolledIds.isEmpty) {
      if (mounted) {
        setState(() {
          _attendees = [];
          _isLoading = false;
        });
      }
      return;
    }

    final subscriptions = ref.read(subscriptionControllerProvider);
    final allClasses = ref.read(scheduleControllerProvider).value ?? [];
    final now = DateTime.now();

    final List<CoachAttendeeInfo> resolved = [];

    for (final id in enrolledIds) {
      try {
        // 1. Try to find child
        final childDoc = await FirebaseFirestore.instance.collection('children').doc(id).get();

        if (childDoc.exists) {
          final childData = childDoc.data()!;
          final childName = (childData['name'] as String? ?? 'Учень').trim();
          final childAge = childData['age'] as int?;
          final parentId = childData['parentId'] as String? ?? '';

          String? parentName;
          String? parentPhone;

          if (parentId.isNotEmpty) {
            final parentDoc = await FirebaseFirestore.instance.collection('users').doc(parentId).get();
            if (parentDoc.exists) {
              final parentData = parentDoc.data()!;
              parentName = (parentData['name'] as String?)?.trim();
              parentPhone = (parentData['phone'] as String?)?.trim();
            }
          }

          // Find subscription
          Subscription? sub;
          for (final s in subscriptions) {
            if (s.userId == parentId) {
              if (s.ownerName == childName || s.ownerName == null || s.ownerName == parentName) {
                sub = s;
                break;
              }
              sub ??= s;
            }
          }

          final remaining = sub?.remainingClasses ?? 0;
          final total = sub?.totalClasses ?? 0;
          final expiry = sub?.expiryDate;
          final isExpired = expiry != null && now.isAfter(expiry);
          final isExhausted = sub == null || remaining <= 0;

          // Count booked future classes
          final bookedCount = allClasses.where((c) {
            final isEnrolled = c.enrolledChildIds.contains(id);
            final isFutureOrCurrent = c.startTime.isAfter(now.subtract(const Duration(hours: 1)));
            return isEnrolled && isFutureOrCurrent;
          }).length;

          final isPresent = _currentClass.attendedChildIds.contains(id);

          resolved.add(CoachAttendeeInfo(
            id: id,
            name: childName,
            parentId: parentId.isNotEmpty ? parentId : null,
            parentName: parentName,
            age: childAge,
            phone: parentPhone,
            remainingClasses: remaining,
            totalClasses: total,
            bookedClassesCount: bookedCount,
            isExpired: isExpired,
            isExhausted: isExhausted,
            expiryDate: expiry,
            subscriptionTitle: sub?.serviceName,
            isPresent: isPresent,
            isChild: true,
          ));
        } else {
          // 2. Direct adult client in 'users'
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userName = (userData['name'] as String? ?? 'Клієнт').trim();
            final userPhone = (userData['phone'] as String?)?.trim();
            final userAge = userData['age'] as int?;

            Subscription? sub;
            for (final s in subscriptions) {
              if (s.userId == id) {
                sub = s;
                break;
              }
            }

            final remaining = sub?.remainingClasses ?? 0;
            final total = sub?.totalClasses ?? 0;
            final expiry = sub?.expiryDate;
            final isExpired = expiry != null && now.isAfter(expiry);
            final isExhausted = sub == null || remaining <= 0;

            final bookedCount = allClasses.where((c) {
              final isEnrolled = c.enrolledChildIds.contains(id);
              final isFutureOrCurrent = c.startTime.isAfter(now.subtract(const Duration(hours: 1)));
              return isEnrolled && isFutureOrCurrent;
            }).length;

            final isPresent = _currentClass.attendedChildIds.contains(id);

            resolved.add(CoachAttendeeInfo(
              id: id,
              name: userName,
              parentName: null,
              age: userAge,
              phone: userPhone,
              remainingClasses: remaining,
              totalClasses: total,
              bookedClassesCount: bookedCount,
              isExpired: isExpired,
              isExhausted: isExhausted,
              expiryDate: expiry,
              subscriptionTitle: sub?.serviceName,
              isPresent: isPresent,
              isChild: false,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error resolving attendee $id: $e');
      }
    }

    if (mounted) {
      setState(() {
        _attendees = resolved;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAttendance(CoachAttendeeInfo attendee) async {
    final isPresent = _currentClass.attendedChildIds.contains(attendee.id);
    final updatedAttended = isPresent
        ? (List<String>.from(_currentClass.attendedChildIds)..remove(attendee.id))
        : (List<String>.from(_currentClass.attendedChildIds)..add(attendee.id));

    setState(() {
      _currentClass = _currentClass.copyWith(attendedChildIds: updatedAttended);
      _attendees = _attendees.map((a) {
        if (a.id == attendee.id) {
          return a.copyWith(isPresent: !isPresent);
        }
        return a;
      }).toList();
    });

    try {
      await FirebaseFirestore.instance.collection('classes').doc(_currentClass.id).update({
        'attendedChildIds': updatedAttended,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !isPresent ? 'Відмічено: ${attendee.name} присутній(-ня)' : 'Відмітку для ${attendee.name} знято',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: !isPresent ? const Color(0xFF10B981) : const Color(0xFF334155),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling attendance: $e');
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.phoneCall, color: Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Номер $phone скопійовано',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F2644),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openChat(CoachAttendeeInfo attendee) {
    final nav = Navigator.of(context);
    final coach = ref.read(authControllerProvider);
    final targetClientId = attendee.isChild ? (attendee.parentId ?? attendee.id) : attendee.id;
    final targetClientName = attendee.isChild ? (attendee.parentName ?? 'Батьки (${attendee.name})') : attendee.name;
    final dialogId = 'coach_${coach?.id}_client_$targetClientId';

    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => ParentChatScreen(
          dialogId: dialogId,
          recipientId: targetClientId,
          recipientName: targetClientName,
          coachId: coach?.id,
          coachName: coach?.name,
          coachAvatar: coach?.avatarUrl,
          clientId: targetClientId,
          clientName: targetClientName,
          childName: attendee.isChild ? attendee.name : null,
          type: 'coach_client',
          title: attendee.isChild ? attendee.name : targetClientName,
          subtitle: attendee.isChild ? 'Батьки: $targetClientName' : 'Клієнт • Онлайн',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTimeStr = '${_currentClass.startTime.hour.toString().padLeft(2, '0')}:${_currentClass.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_currentClass.endTime.hour.toString().padLeft(2, '0')}:${_currentClass.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = _currentClass.enrolledChildIds.length;
    final maxCap = _currentClass.maxCapacity > 0 ? _currentClass.maxCapacity : 8;
    final freeSlots = (maxCap - enrolledCount).clamp(0, maxCap);
    final fillFraction = (enrolledCount / maxCap).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09182B).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.90,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag bar & close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.users, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'ДЕТАЛІ ГРУПИ ТА УЧНІ',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Class summary hero header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withValues(alpha: 0.16),
                          const Color(0xFF0284C7).withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currentClass.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.45)),
                              ),
                              child: Text(
                                '$startTimeStr - $endTimeStr',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Badges: Category & Lane
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_currentClass.category.isNotEmpty)
                              _buildPill(
                                label: _currentClass.category,
                                color: const Color(0xFF38BDF8),
                                icon: LucideIcons.waves,
                              ),
                            if (_currentClass.lane.isNotEmpty)
                              _buildPill(
                                label: _currentClass.lane,
                                color: Colors.white70,
                                icon: LucideIcons.mapPin,
                              ),
                            _buildPill(
                              label: freeSlots > 0 ? 'Вільно: $freeSlots місць' : 'Місць немає (заповнено)',
                              color: freeSlots > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              icon: freeSlots > 0 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Capacity progress bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Записано: $enrolledCount з $maxCap учнів',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(fillFraction * 100).toInt()}% заповнено',
                              style: TextStyle(
                                color: fillFraction > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fillFraction,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fillFraction > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Attendees list section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'СПИСОК УЧНІВ ($enrolledCount)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      Text(
                        'Присутні: ${_currentClass.attendedChildIds.length} з $enrolledCount',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Scrollable attendees roster
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                        )
                      : _attendees.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: const Icon(LucideIcons.users, color: Colors.white38, size: 40),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'У цій групі ще немає записаних учнів',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Вільні місця будуть зайняті після бронювання клієнтами або запису адміністратором',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                              itemCount: _attendees.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildAttendeeCard(_attendees[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(CoachAttendeeInfo attendee, int index) {
    final isPresent = attendee.isPresent;

    return Container(
      decoration: BoxDecoration(
        color: isPresent
            ? const Color(0xFF10B981).withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: isPresent
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  blurRadius: 14,
                  spreadRadius: -1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name + Age badge + Attendance toggle
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isPresent
                              ? [const Color(0xFF10B981), const Color(0xFF047857)]
                              : [const Color(0xFF00E5FF), const Color(0xFF0284C7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPresent ? const Color(0xFF10B981) : const Color(0xFF00E5FF))
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name, Parent & Age
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  attendee.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (attendee.age != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    '${attendee.age} р.',
                                    style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (attendee.parentName != null && attendee.parentName!.isNotEmpty)
                            Text(
                              'Батьки: ${attendee.parentName}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Quick Attendance Button
                    GestureDetector(
                      onTap: () => _toggleAttendance(attendee),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPresent ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent
                                ? const Color(0xFF10B981)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPresent ? LucideIcons.check : LucideIcons.userCheck,
                              size: 14,
                              color: isPresent ? Colors.black : Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPresent ? 'Присутній' : 'Відмітити',
                              style: TextStyle(
                                color: isPresent ? Colors.black : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Phone contact row with 1-tap call/copy and chat
                if (attendee.phone != null && attendee.phone!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 14, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _copyPhone(attendee.phone!),
                            child: Text(
                              attendee.phone!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        // Copy / Call action
                        GestureDetector(
                          onTap: () => _copyPhone(attendee.phone!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(LucideIcons.copy, size: 12, color: Color(0xFF00E5FF)),
                                SizedBox(width: 4),
                                Text(
                                  'Копіювати',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Chat action
                        GestureDetector(
                          onTap: () => _openChat(attendee),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.messageCircle, size: 13, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Subscription telemetry section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: attendee.isExpired
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : (attendee.isExhausted
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remaining classes
                          Row(
                            children: [
                              const Icon(LucideIcons.ticket, size: 13, color: Color(0xFF00E5FF)),
                              const SizedBox(width: 6),
                              Text(
                                'Залишок: ${attendee.remainingClasses}${attendee.totalClasses > 0 ? " з ${attendee.totalClasses}" : ""} занять',
                                style: TextStyle(
                                  color: attendee.isExhausted ? const Color(0xFFF59E0B) : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          // Booked future count
                          Row(
                            children: [
                              const Icon(LucideIcons.calendarCheck, size: 13, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 5),
                              Text(
                                'Заброньовано: ${attendee.bookedClassesCount}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Expiry date / Warning badge
                      Row(
                        children: [
                          if (attendee.isExpired) ...[
                            const Icon(LucideIcons.alertTriangle, size: 13, color: Color(0xFFEF4444)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                attendee.expiryDate != null
                                    ? '⚠️ Абонемент прострочено (${DateFormat("dd.MM.yyyy").format(attendee.expiryDate!)})'
                                    : '⚠️ Абонемент прострочено',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (attendee.isExhausted) ...[
                            const Icon(LucideIcons.alertCircle, size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 5),
                            const Expanded(
                              child: Text(
                                '⚠️ Занять немає (абонемент вичерпано)',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const Icon(LucideIcons.checkCircle2, size: 13, color: Color(0xFF10B981)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                attendee.expiryDate != null
                                    ? 'Абонемент діє до ${DateFormat("dd.MM.yyyy").format(attendee.expiryDate!)}'
                                    : 'Абонемент активний',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPill({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
