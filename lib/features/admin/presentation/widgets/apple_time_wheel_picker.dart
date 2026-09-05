import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An ultra-premium Apple Alarm-style dual drum wheel time picker.
/// Allows smooth vertical scrolling for hours and minutes with iOS physics,
/// glassmorphic glowing aquatic lens, and 1-tap quick presets.
class AppleTimeWheelPicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const AppleTimeWheelPicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<AppleTimeWheelPicker> createState() => _AppleTimeWheelPickerState();
}

class _AppleTimeWheelPickerState extends State<AppleTimeWheelPicker> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  final List<String> _quickPresets = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void didUpdateWidget(covariant AppleTimeWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      if (_selectedHour != widget.initialTime.hour) {
        _selectedHour = widget.initialTime.hour;
        if (_hourController.hasClients) {
          _hourController.jumpToItem(_selectedHour);
        }
      }
      if (_selectedMinute != widget.initialTime.minute) {
        _selectedMinute = widget.initialTime.minute;
        if (_minuteController.hasClients) {
          _minuteController.jumpToItem(_selectedMinute);
        }
      }
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onHourChanged(int hour) {
    setState(() => _selectedHour = hour);
    widget.onTimeChanged(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  void _onMinuteChanged(int minute) {
    setState(() => _selectedMinute = minute);
    widget.onTimeChanged(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  void _jumpToPreset(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    setState(() {
      _selectedHour = hour;
      _selectedMinute = minute;
    });

    if (_hourController.hasClients) {
      _hourController.animateToItem(
        hour,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    if (_minuteController.hasClients) {
      _minuteController.animateToItem(
        minute,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    widget.onTimeChanged(TimeOfDay(hour: hour, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Digital Pill + Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      color: Color(0xFF00E5FF),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Час початку',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              // Luminous Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0077B6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal Quick Presets Carousel
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _quickPresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = _quickPresets[index];
                final isSelected = preset == formattedTime;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _jumpToPreset(preset),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.2 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          preset,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Column Labels (ГОДИНИ | ХВИЛИНИ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'ГОДИНИ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Center(
                    child: Text(
                      'ХВИЛИНИ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Dual Apple Drum Wheels
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection Lens (Glowing Aquatic Bar)
                Positioned(
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Wheels Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours Wheel
                    Expanded(
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(brightness: Brightness.dark),
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 40,
                          diameterRatio: 1.15,
                          useMagnifier: true,
                          magnification: 1.2,
                          squeeze: 1.1,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: _onHourChanged,
                          children: List.generate(24, (hour) {
                            final isSelected = hour == _selectedHour;
                            return Center(
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                                  fontSize: isSelected ? 22 : 17,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // Colon separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    // Minutes Wheel
                    Expanded(
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(brightness: Brightness.dark),
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 40,
                          diameterRatio: 1.15,
                          useMagnifier: true,
                          magnification: 1.2,
                          squeeze: 1.1,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: _onMinuteChanged,
                          children: List.generate(60, (minute) {
                            final isSelected = minute == _selectedMinute;
                            return Center(
                              child: Text(
                                minute.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.35),
                                  fontSize: isSelected ? 22 : 17,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
