import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:easy_localization/easy_localization.dart';

enum ClassAudienceFilter { all, adults, kids, split }

class AdminBookingSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final List<String> availableIds;
  final List<String> availableNames;

  const AdminBookingSheet({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.availableIds,
    required this.availableNames,
  });

  @override
  ConsumerState<AdminBookingSheet> createState() => _AdminBookingSheetState();
}

class _AdminBookingSheetState extends ConsumerState<AdminBookingSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClassId;
  String? _selectedChildId;
  bool _isBooking = false;
  ClassAudienceFilter _audienceFilter = ClassAudienceFilter.all;

  bool get _isCurrentSelectionAdult => _selectedChildId == widget.clientId;

  void _updateAudienceFilterForSelection() {
    if (_isCurrentSelectionAdult) {
      _audienceFilter = ClassAudienceFilter.adults;
    } else {
      _audienceFilter = ClassAudienceFilter.kids;
    }
  }

  void _book() async {
    if (_selectedClassId == null || _selectedChildId == null) return;
    
    setState(() => _isBooking = true);
    
    String? targetName;
    if (_selectedChildId != null) {
      final idx = widget.availableIds.indexOf(_selectedChildId!);
      if (idx != -1 && idx < widget.availableNames.length) {
        targetName = widget.availableNames[idx];
      }
    }

    try {
      final result = await ref.read(scheduleControllerProvider.notifier).bookClass(
        _selectedClassId!, 
        _selectedChildId!,
        targetUserId: widget.clientId,
        targetOwnerName: targetName,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => const BookingResult(
          isSuccess: false,
          message: 'Час очікування вичерпано. Перевірте зʼєднання або спробуйте ще раз.',
          status: BookingStatus.error,
        ),
      );
      
      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'common.error'.tr()}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.availableIds.isNotEmpty) {
      _selectedChildId = widget.availableIds.first;
      _updateAudienceFilterForSelection();
    }
  }

  Widget _badgeContainer({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceBadge(GroupClass c) {
    if (c.isSplit) {
      return _badgeContainer(
        icon: LucideIcons.users,
        label: 'Спліт (2 ос.)',
        color: const Color(0xFF38BDF8),
      );
    }
    if (c.isAdultOnly) {
      return _badgeContainer(
        icon: LucideIcons.user,
        label: 'Доросла група',
        color: const Color(0xFFA5B4FC),
      );
    }
    if (c.isChildOnly) {
      final range = c.ageRange;
      final rangeStr = range != null ? ' (${range.$1}-${range.$2} р.)' : '';
      return _badgeContainer(
        icon: LucideIcons.baby,
        label: 'Дитяча$rangeStr',
        color: const Color(0xFF34D399),
      );
    }
    return _badgeContainer(
      icon: LucideIcons.waves,
      label: 'Загальна',
      color: const Color(0xFF2DD4BF),
    );
  }

  bool _isClassIncompatible(GroupClass c) {
    if (c.isSplit) return false;
    if (_isCurrentSelectionAdult && c.isChildOnly) return true;
    if (!_isCurrentSelectionAdult && c.isAdultOnly) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final allSubs = ref.watch(subscriptionControllerProvider);
    final clientSubs = allSubs.where((s) => s.userId == widget.clientId && s.isActive && s.remainingClasses > 0).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.book_class'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Selector
          Text('admin.select_date'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
                
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = date;
                    _selectedClassId = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E', context.locale.languageCode).format(date).toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.cyanAccent : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.cyanAccent : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 16),
          // Participant Dropdown
          Text('admin.select_client_child'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E293B),
                value: _selectedChildId,
                isExpanded: true,
                icon: const Icon(LucideIcons.chevronDown, color: Colors.cyanAccent, size: 18),
                items: List.generate(widget.availableIds.length, (index) {
                  final isAdult = widget.availableIds[index] == widget.clientId;
                  return DropdownMenuItem(
                    value: widget.availableIds[index],
                    child: Row(
                      children: [
                        Icon(
                          isAdult ? LucideIcons.user : LucideIcons.baby,
                          size: 16,
                          color: isAdult ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.availableNames[index],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAdult ? '(Дорослий)' : '(Дитина)',
                          style: TextStyle(
                            color: isAdult ? const Color(0xFFA5B4FC) : const Color(0xFF34D399),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedChildId = val;
                      _selectedClassId = null;
                      _updateAudienceFilterForSelection();
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subscription status badge
          if (clientSubs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.creditCard, size: 14, color: Color(0xFF34D399)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Абонемент: ${clientSubs.first.serviceName ?? 'Активний'} (${clientSubs.first.remainingClasses} занять)',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: 14, color: Colors.amber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'У клієнта немає активного абонемента. Для запису призначте абонемент.',
                      style: TextStyle(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 14),

          // Audience Filter Chips
          Row(
            children: [
              _buildFilterChip('Всі', ClassAudienceFilter.all),
              const SizedBox(width: 6),
              _buildFilterChip('👤 Дорослі', ClassAudienceFilter.adults),
              const SizedBox(width: 6),
              _buildFilterChip('🧒 Дитячі', ClassAudienceFilter.kids),
              const SizedBox(width: 6),
              _buildFilterChip('👥 Спліт', ClassAudienceFilter.split),
            ],
          ),

          const SizedBox(height: 10),
          
          // Available Classes List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                
                final allClasses = snapshot.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return GroupClass.fromJson(data);
                }).where((c) {
                  final d1 = c.startTime;
                  final d2 = _selectedDate;
                  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
                }).toList();
                
                allClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

                final filteredClasses = allClasses.where((c) {
                  switch (_audienceFilter) {
                    case ClassAudienceFilter.all:
                      return true;
                    case ClassAudienceFilter.adults:
                      return c.isAdultOnly || c.isUniversal;
                    case ClassAudienceFilter.kids:
                      return c.isChildOnly || c.isUniversal;
                    case ClassAudienceFilter.split:
                      return c.isSplit;
                  }
                }).toList();
                
                if (filteredClasses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.calendarX, size: 36, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('admin.no_classes_day'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final c = filteredClasses[index];
                    final isFull = c.enrolledChildIds.length >= c.maxCapacity;
                    final isSelected = _selectedClassId == c.id;
                    final isIncompatible = _isClassIncompatible(c);
                    
                    final displayTitle = c.title.trim().isNotEmpty ? c.title : c.category;

                    return GestureDetector(
                      onTap: isFull
                          ? null
                          : isIncompatible
                              ? () {
                                  final msg = _isCurrentSelectionAdult
                                      ? 'Це тренування лише для дітей. Оберіть дитину або доросле тренування.'
                                      : 'Це тренування призначене лише для дорослих.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(msg), backgroundColor: Colors.amber.shade900),
                                  );
                                }
                              : () => setState(() => _selectedClassId = c.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isIncompatible
                              ? Colors.white.withValues(alpha: 0.02)
                              : (isSelected
                                  ? Colors.cyanAccent.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.cyanAccent
                                : (isIncompatible
                                    ? Colors.amber.withValues(alpha: 0.25)
                                    : (isFull
                                        ? Colors.redAccent.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.08))),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${c.startTime.hour.toString().padLeft(2, '0')}:${c.startTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.cyanAccent : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildAudienceBadge(c),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isFull ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${c.enrolledChildIds.length} / ${c.maxCapacity}',
                                    style: TextStyle(
                                      color: isFull ? Colors.redAccent : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayTitle,
                              style: TextStyle(
                                color: isIncompatible ? Colors.white54 : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.mapPin, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  c.lane.isNotEmpty ? c.lane : 'admin.main_pool'.tr(),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                if (c.coachName.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Icon(LucideIcons.userCheck, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.coachName,
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            if (isIncompatible) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.triangleAlert, size: 12, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isCurrentSelectionAdult ? 'Тільки для дітей' : 'Тільки для дорослих',
                                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

          // Booking button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedClassId != null && _selectedChildId != null && !_isBooking ? _book : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
                    )
                  : Text(
                      'admin.book_btn'.tr(),
                      style: TextStyle(
                        color: _selectedClassId != null ? Colors.black87 : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ClassAudienceFilter filter) {
    final isSelected = _audienceFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _audienceFilter = filter;
          _selectedClassId = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.cyanAccent : Colors.white70,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
