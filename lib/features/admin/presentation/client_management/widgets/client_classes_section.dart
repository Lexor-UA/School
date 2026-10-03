import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/presentation/admin_booking_sheet.dart';

class ClientClassesSection extends ConsumerWidget {
  final String clientId;
  final String clientName;
  final bool isDark;

  const ClientClassesSection({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'admin.client_classes'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .where('parentId', isEqualTo: clientId)
              .snapshots(),
          builder: (context, childSnap) {
            List<String> allRelatedIds = [clientId];
            Map<String, String> idToName = {clientId: clientName};
            if (childSnap.hasData) {
              for (var doc in childSnap.data!.docs) {
                allRelatedIds.add(doc.id);
                final cData = doc.data() as Map<String, dynamic>;
                idToName[doc.id] = (cData['name'] as String? ?? 'Дитина')
                    .trim();
              }
            }

            if (allRelatedIds.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .where('enrolledChildIds', arrayContainsAny: allRelatedIds)
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  )
                  .snapshots(),
              builder: (context, classSnap) {
                if (!classSnap.hasData || classSnap.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F1E32).withValues(alpha: 0.6)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Немає активних записів',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                }

                final classes = classSnap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return GroupClass.fromJson(data);
                }).toList();

                classes.sort((a, b) => a.startTime.compareTo(b.startTime));

                return Column(
                  children: classes.map((session) {
                    final enrolledHere = session.enrolledChildIds
                        .where((id) => allRelatedIds.contains(id))
                        .toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F1E32).withValues(alpha: 0.7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                              : const Color(0xFFBAE6FD),
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF003B73,
                                  ).withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
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
                                  '${DateFormat('dd.MM.yyyy').format(session.startTime)} о ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blueAccent.withValues(alpha: 0.2)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.blueAccent.withValues(
                                            alpha: 0.4,
                                          )
                                        : const Color(0xFFBAE6FD),
                                  ),
                                ),
                                child: Text(
                                  session.category,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.blueAccent
                                        : const Color(0xFF0284C7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...enrolledHere.map((enrolledId) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    idToName[enrolledId] ?? 'Дитина',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      try {
                                        final targetName =
                                            idToName[enrolledId] ?? clientName;
                                        final success = await ref
                                            .read(
                                              scheduleControllerProvider
                                                  .notifier,
                                            )
                                            .cancelClass(
                                              session.id,
                                              enrolledId,
                                              targetUserId: clientId,
                                              targetOwnerName: targetName,
                                            );
                                        if (success && context.mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'admin.booking_cancelled_success'
                                                    .tr(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${'common.error'.tr()}: $e',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 24),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'admin.cancel_booking'.tr(),
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .where('parentId', isEqualTo: clientId)
              .snapshots(),
          builder: (context, snapshot) {
            List<String> availableIds = [clientId];
            List<String> availableNames = [clientName];

            if (snapshot.hasData) {
              for (var d in snapshot.data!.docs) {
                availableIds.add(d.id);
                availableNames.add(
                  (d.data() as Map<String, dynamic>)['name'] as String? ??
                      'Дитина',
                );
              }
            }

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: Icon(
                  LucideIcons.calendarPlus,
                  color: isDark
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF0284C7),
                ),
                label: Text(
                  'admin.book_class'.tr(),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? null : const Color(0xFFE0F2FE),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF0284C7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AdminBookingSheet(
                      clientId: clientId,
                      clientName: clientName,
                      availableIds: availableIds,
                      availableNames: availableNames,
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
