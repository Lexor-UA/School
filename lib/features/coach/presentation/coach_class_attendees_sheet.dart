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
import 'package:swimming_school_app/features/auth/models/app_user.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

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
    final List<String> orphanedIds = [];

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
          } else {
            // Neither child nor user exists - orphaned ID
            orphanedIds.add(id);
          }
        }
      } catch (e) {
        debugPrint('Error resolving attendee $id: $e');
      }
    }

    // Auto-heal orphaned enrollments in background
    if (orphanedIds.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('classes').doc(_currentClass.id).update({
          'enrolledChildIds': FieldValue.arrayRemove(orphanedIds),
        });
        final updatedEnrolled = List<String>.from(_currentClass.enrolledChildIds)
          ..removeWhere((id) => orphanedIds.contains(id));
        _currentClass = _currentClass.copyWith(enrolledChildIds: updatedEnrolled);
        ref.invalidate(scheduleControllerProvider);
      } catch (e) {
        debugPrint('Failed to auto-heal orphaned attendees: $e');
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
    HapticFeedback.mediumImpact();
    final currentUser = ref.read(authControllerProvider);
    final isMyClass = currentUser != null && (
      currentUser.id == _currentClass.coachId ||
      currentUser.name.trim().toLowerCase() == _currentClass.coachName.trim().toLowerCase() ||
      currentUser.role == UserRole.admin ||
      currentUser.role == UserRole.owner ||
      currentUser.role == UserRole.superAdmin
    );

    if (currentUser != null && currentUser.role == UserRole.coach) {
      final coachBranch = currentUser.branchId;
      final coachBranches = currentUser.branchIds;
      final classBranch = _currentClass.branchId;
      final hasAccess = isMyClass ||
          coachBranch.isEmpty ||
          classBranch.isEmpty ||
          coachBranch == classBranch ||
          coachBranches.contains(classBranch);
      if (!hasAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('У вас немає доступу до відмітки відвідування в іншій філії'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final isPresent = _currentClass.attendedChildIds.contains(attendee.id);
    final updatedAttended = isPresent
        ? (List<String>.from(_currentClass.attendedChildIds)..remove(attendee.id))
        : (List<String>.from(_currentClass.attendedChildIds)..add(attendee.id));

    final prevClass = _currentClass;
    final prevAttendees = List<CoachAttendeeInfo>.from(_attendees);

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
      final classDocRef = FirebaseFirestore.instance.collection('classes').doc(_currentClass.id);
      final docSnap = await classDocRef.get();
      if (docSnap.exists) {
        await classDocRef.update({
          'attendedChildIds': updatedAttended,
        });
      } else {
        // Document doesn't exist yet in Firestore (e.g. seed/cached class)
        // Persist full class document with updated attended list!
        final classData = {
          'id': _currentClass.id,
          'title': _currentClass.title,
          'category': _currentClass.category,
          'startTime': _currentClass.startTime.toIso8601String(),
          'endTime': _currentClass.endTime.toIso8601String(),
          'coachId': _currentClass.coachId,
          'coachName': _currentClass.coachName,
          'lane': _currentClass.lane,
          'maxCapacity': _currentClass.maxCapacity,
          'enrolledChildIds': _currentClass.enrolledChildIds,
          'attendedChildIds': updatedAttended,
          'branchId': _currentClass.branchId,
          'organizationId': _currentClass.organizationId,
          'timezone': _currentClass.timezone,
          'locationId': _currentClass.locationId,
          'poolId': _currentClass.poolId,
        };
        await classDocRef.set(classData, SetOptions(merge: true));
      }

      // Update cached classes in ScheduleController so schedule tab immediately reflects attendance
      if (ScheduleController.cachedClasses != null) {
        ScheduleController.cachedClasses = ScheduleController.cachedClasses!.map((c) {
          if (c.id == _currentClass.id) {
            return c.copyWith(attendedChildIds: updatedAttended);
          }
          return c;
        }).toList();
      }
      ref.invalidate(scheduleControllerProvider);

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
      if (mounted) {
        setState(() {
          _currentClass = prevClass;
          _attendees = prevAttendees;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не вдалося зберегти відвідуваність для ${attendee.name}. Перевірте зв’язок.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
    final currentTheme = ref.watch(appThemeControllerProvider);
    final isDark = currentTheme.isDark;
    final currentUser = ref.watch(authControllerProvider);
    final isMyClass = currentUser != null && (
      currentUser.id == _currentClass.coachId ||
      currentUser.name.trim().toLowerCase() == _currentClass.coachName.trim().toLowerCase() ||
      currentUser.role == UserRole.admin ||
      currentUser.role == UserRole.owner ||
      currentUser.role == UserRole.superAdmin
    );

    final startTimeStr = '${_currentClass.startTime.hour.toString().padLeft(2, '0')}:${_currentClass.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${_currentClass.endTime.hour.toString().padLeft(2, '0')}:${_currentClass.endTime.minute.toString().padLeft(2, '0')}';
    final enrolledCount = _currentClass.enrolledChildIds.length;
    final maxCap = _currentClass.maxCapacity > 0 ? _currentClass.maxCapacity : 8;
    final freeSlots = (maxCap - enrolledCount).clamp(0, maxCap);
    final fillFraction = (enrolledCount / maxCap).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF0F9FF)],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.50)
                : const Color(0xFF0284C7).withValues(alpha: 0.10),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
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
                            color: isDark ? Colors.white24 : const Color(0xFFBAE6FD),
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
                              Text(
                                'ДЕТАЛІ ГРУПИ ТА УЧНІ',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F9FF),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFBAE6FD),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    LucideIcons.x,
                                    color: isDark ? Colors.white70 : const Color(0xFF0284C7),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
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
                        colors: isDark
                            ? [
                                const Color(0xFF00E5FF).withValues(alpha: 0.16),
                                const Color(0xFF0284C7).withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFFF0F9FF),
                                Colors.white,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : const Color(0xFFBAE6FD),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currentClass.title.replaceFirst(
                                  RegExp(r'^(Групове плавання|Індивідуальне тренування|Спліт-тренування|Групове|Індивідуальне|Спліт)\s*:\s*', caseSensitive: false),
                                  '',
                                ).trim().isNotEmpty
                                    ? _currentClass.title.replaceFirst(
                                        RegExp(r'^(Групове плавання|Індивідуальне тренування|Спліт-тренування|Групове|Індивідуальне|Спліт)\s*:\s*', caseSensitive: false),
                                        '',
                                      ).trim()
                                    : _currentClass.title,
                                style: TextStyle(
                                  color: isDark ? Colors.white : currentTheme.textPrimary,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.45) : const Color(0xFFBAE6FD),
                                ),
                              ),
                              child: Text(
                                '$startTimeStr - $endTimeStr',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                icon: LucideIcons.waves,
                                lightBg: const Color(0xFFE0F2FE),
                                lightBorder: const Color(0xFFBAE6FD),
                                isDark: isDark,
                              ),
                            if (_currentClass.lane.isNotEmpty)
                              _buildPill(
                                label: _currentClass.lane,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                icon: LucideIcons.mapPin,
                                lightBg: const Color(0xFFF8FAFC),
                                lightBorder: const Color(0xFFE2E8F0),
                                isDark: isDark,
                              ),
                            _buildPill(
                              label: freeSlots > 0 ? 'Вільно: $freeSlots місць' : 'Місць немає (заповнено)',
                              color: freeSlots > 0
                                  ? (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
                                  : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)),
                              icon: freeSlots > 0 ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                              lightBg: freeSlots > 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                              lightBorder: freeSlots > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                              isDark: isDark,
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
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(fillFraction * 100).toInt()}% заповнено',
                              style: TextStyle(
                                color: fillFraction > 0.85
                                    ? const Color(0xFFF59E0B)
                                    : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
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
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fillFraction > 0.85
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
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
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      Text(
                        'Присутні: ${_currentClass.attendedChildIds.length} з $enrolledCount',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
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
                      ? Center(
                          child: CircularProgressIndicator(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
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
                                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFBAE6FD),
                                        ),
                                      ),
                                      child: Icon(
                                        LucideIcons.users,
                                        color: isDark ? Colors.white38 : const Color(0xFF0284C7),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'У цій групі ще немає записаних учнів',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : currentTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Вільні місця будуть зайняті після бронювання клієнтами або запису адміністратором',
                                      style: TextStyle(
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
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
                                return _buildAttendeeCard(_attendees[index], index, currentTheme, isDark, isMyClass: isMyClass);
                              },
                            ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildAttendeeCard(CoachAttendeeInfo attendee, int index, AppThemeConfig currentTheme, bool isDark, {bool isMyClass = false}) {
    final isPresent = attendee.isPresent;

    return Container(
      decoration: BoxDecoration(
        color: isPresent
            ? (isDark ? const Color(0xFF0F2922) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF1E2638) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.60) : const Color(0xFF86EFAC))
              : (isDark ? const Color(0xFF334155).withValues(alpha: 0.70) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                          Text(
                            attendee.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : currentTheme.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3.5),
                          Row(
                            children: [
                              if (attendee.age != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                        : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                          : const Color(0xFFBAE6FD),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${attendee.age} р.',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (attendee.parentName != null && attendee.parentName!.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    'Батьки: ${attendee.parentName}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Quick Attendance Button (Capsule Style)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleAttendance(attendee),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : const Color(0xFFE0F2FE)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPresent
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFFBAE6FD)),
                              width: 1.1,
                            ),
                            boxShadow: isPresent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.40),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPresent ? LucideIcons.check : LucideIcons.userCheck,
                                size: 14.5,
                                color: isPresent
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 5.5),
                              Text(
                                isPresent ? 'Присутній' : 'Відмітити',
                                style: TextStyle(
                                  color: isPresent
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Phone contact row with 1-tap call/copy and chat
                if (isMyClass && attendee.phone != null && attendee.phone!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161F30) : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.phone, size: 14, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _copyPhone(attendee.phone!),
                            child: Text(
                              attendee.phone!,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.16)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.transparent : const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.copy, size: 12, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  'Копіювати',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
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
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.transparent : const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: Icon(LucideIcons.messageCircle, size: 13, color: isDark ? Colors.white70 : const Color(0xFF0284C7)),
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
                    color: isDark ? const Color(0xFF161F30) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: attendee.isExpired
                          ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                          : (attendee.isExhausted
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD))),
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
                              Icon(LucideIcons.ticket, size: 13, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                              const SizedBox(width: 6),
                              Text(
                                'Залишок: ${attendee.remainingClasses}${attendee.totalClasses > 0 ? " з ${attendee.totalClasses}" : ""} занять',
                                style: TextStyle(
                                  color: attendee.isExhausted
                                      ? const Color(0xFFF59E0B)
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          // Booked future count
                          Row(
                            children: [
                              Icon(LucideIcons.calendarCheck, size: 13, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                              const SizedBox(width: 5),
                              Text(
                                'Заброньовано: ${attendee.bookedClassesCount}',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                            Icon(LucideIcons.checkCircle2, size: 13, color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                attendee.expiryDate != null
                                    ? 'Абонемент діє до ${DateFormat("dd.MM.yyyy").format(attendee.expiryDate!)}'
                                    : 'Абонемент активний',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
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
        ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildPill({
    required String label,
    required Color color,
    required IconData icon,
    Color? lightBg,
    Color? lightBorder,
    bool isDark = true,
  }) {
    final bgColor = isDark ? color.withValues(alpha: 0.14) : (lightBg ?? color.withValues(alpha: 0.10));
    final borderColor = isDark ? color.withValues(alpha: 0.35) : (lightBorder ?? color.withValues(alpha: 0.30));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
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
