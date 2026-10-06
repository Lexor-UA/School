import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/models/branch_config.dart';

/// Віджет вибору басейну та доріжки/зони проведення заняття
class ClassPoolLaneSelector extends StatelessWidget {
  final Branch activeBranch;
  final BranchLocation? location;
  final List<BranchPool> pools;
  final BranchPool? activePool;
  final List<String> currentLanes;
  final String selectedLane;
  final bool isDark;
  final ValueChanged<BranchPool> onPoolSelected;
  final ValueChanged<String> onLaneSelected;
  final bool Function(String lane)? isLaneConflict;
  final Widget? activeConflictBanner;

  const ClassPoolLaneSelector({
    super.key,
    required this.activeBranch,
    required this.location,
    required this.pools,
    required this.activePool,
    required this.currentLanes,
    required this.selectedLane,
    required this.isDark,
    required this.onPoolSelected,
    required this.onLaneSelected,
    this.isLaneConflict,
    this.activeConflictBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Басейн та місце проведення',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.90) : const Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            // Branch badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.14) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.40) : const Color(0xFF7DD3FC),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeBranch.flagEmoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    location?.name ?? activeBranch.name,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 1. Primary Pool Selector (Tabs / Pills)
        if (pools.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A1625) : const Color(0xFFE2E8F0).withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: pools.map((pool) {
                final isSelected = activePool?.id == pool.id;
                final isWellen = pool.id.contains('wellen') ||
                    pool.name.toLowerCase().contains('дитяч') ||
                    pool.name.toLowerCase().contains('baby');

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPoolSelected(pool);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1)),
                          width: isSelected ? 1.3 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isWellen ? LucideIcons.baby : LucideIcons.waves,
                            size: 16,
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              pool.name,
                              maxLines: 2,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF64748B)),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. Sub-section: Lanes / Zones Selector
        if (currentLanes.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Оберіть доріжку / зону:',
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0D4EC) : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedLane.isNotEmpty ? selectedLane : (currentLanes.first),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentLanes.map((lane) {
                final isSelected = selectedLane == lane;
                final isLaneBusy = isLaneConflict?.call(lane) ?? false;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onLaneSelected(lane);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? (isLaneBusy
                                  ? const LinearGradient(
                                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF0E3D64), Color(0xFF082038)],
                                    ))
                              : null,
                          color: isSelected
                              ? null
                              : (isLaneBusy
                                  ? Colors.orangeAccent.withValues(alpha: isDark ? 0.16 : 0.12)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isLaneBusy ? const Color(0xFFF87171) : const Color(0xFF00E5FF))
                                : (isLaneBusy
                                    ? Colors.orangeAccent.withValues(alpha: 0.6)
                                    : (isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1))),
                            width: isSelected || isLaneBusy ? 1.3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isLaneBusy ? const Color(0xFFEF4444) : const Color(0xFF00E5FF)).withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(LucideIcons.check, size: 13, color: isLaneBusy ? Colors.white : const Color(0xFF00E5FF)),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              isLaneBusy ? '$lane ⚠️' : lane,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isLaneBusy
                                        ? (isDark ? Colors.orangeAccent : const Color(0xFFD97706))
                                        : (isDark ? const Color(0xFFB0D4EC) : const Color(0xFF334155))),
                                fontSize: 13,
                                fontWeight: (isSelected || isLaneBusy) ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B385D).withValues(alpha: 0.55) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.30) : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Басейн без додаткового поділу на доріжки',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF0369A1),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ?activeConflictBanner,
      ],
    );
  }
}
