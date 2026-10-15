import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/features/parent/presentation/graduate_child_sheet.dart';
import 'package:swimming_school_app/shared/utils/app_snack_bar.dart';

const List<String> _ukMonths = [
  'січня',
  'лютого',
  'березня',
  'квітня',
  'травня',
  'червня',
  'липня',
  'серпня',
  'вересня',
  'жовтня',
  'листопада',
  'грудня',
];

String formatUkDate(DateTime date, [String? langCode]) {
  if (langCode == 'de') {
    const deMonths = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${date.day}. ${deMonths[date.month - 1]} ${date.year}';
  } else if (langCode == 'en') {
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${enMonths[date.month - 1]} ${date.day}, ${date.year}';
  } else if (langCode == 'ru') {
    const ruMonths = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${ruMonths[date.month - 1]} ${date.year} г.';
  }
  return '${date.day} ${_ukMonths[date.month - 1]} ${date.year} р.';
}

String formatAgeUk(int years, [String? langCode]) {
  if (langCode == 'de') {
    return years == 1 ? '1 Jahr' : '$years Jahre';
  } else if (langCode == 'en') {
    return years == 1 ? '1 year' : '$years years';
  } else if (langCode == 'ru') {
    final mod10 = years % 10;
    final mod100 = years % 100;
    if (mod10 == 1 && mod100 != 11) {
      return '$years год';
    } else if ([2, 3, 4].contains(mod10) && ![12, 13, 14].contains(mod100)) {
      return '$years года';
    } else {
      return '$years лет';
    }
  }
  final mod10 = years % 10;
  final mod100 = years % 100;
  if (mod10 == 1 && mod100 != 11) {
    return '$years рік';
  } else if ([2, 3, 4].contains(mod10) && ![12, 13, 14].contains(mod100)) {
    return '$years роки';
  } else {
    return '$years років';
  }
}

int calculateAgeFromDate(DateTime birthDate) {
  final now = DateTime.now();
  int years = now.year - birthDate.year;
  if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
    years--;
  }
  return years >= 0 ? years : 0;
}

const List<String> _childColorOptions = [
  '0xFF00E5FF', // Cyan
  '0xFF10B981', // Emerald
  '0xFFF59E0B', // Amber
  '0xFFA855F7', // Purple
  '0xFFEC4899', // Pink
  '0xFF3B82F6', // Royal Blue
];

/// Bottom sheet for adding one or multiple children with full birth date
class AddChildSheet extends ConsumerStatefulWidget {
  final bool isDark;
  const AddChildSheet({super.key, required this.isDark});

  @override
  ConsumerState<AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<AddChildSheet> {
  int _childCount = 1;
  final List<TextEditingController> _nameControllers = [TextEditingController()];
  final List<DateTime?> _birthDates = [null];
  final List<String> _selectedColors = ['0xFF00E5FF'];
  final List<String?> _errors = [null];
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addChild() {
    setState(() {
      _childCount++;
      _nameControllers.add(TextEditingController());
      _birthDates.add(null);
      final nextColorIndex = (_childCount - 1) % _childColorOptions.length;
      _selectedColors.add(_childColorOptions[nextColorIndex]);
      _errors.add(null);
    });
  }

  void _removeChild() {
    if (_childCount > 1) {
      setState(() {
        _childCount--;
        _nameControllers.last.dispose();
        _nameControllers.removeLast();
        _birthDates.removeLast();
        _selectedColors.removeLast();
        _errors.removeLast();
      });
    }
  }

  Future<void> _pickDate(int index) async {
    final now = DateTime.now();
    final initial = _birthDates[index] ?? DateTime(now.year - 7, now.month, now.day);
    final first = DateTime(now.year - 16, now.month, now.day + 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'parent.choose_child_dob'.tr(),
      cancelText: 'parent.cancel'.tr(),
      confirmText: 'parent.select'.tr(),
      builder: (context, child) {
        return Theme(
          data: (widget.isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: widget.isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF00E5FF),
                    onPrimary: Colors.black,
                    surface: Color(0xFF0F1E32),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0284C7),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: widget.isDark ? const Color(0xFF0F1E32) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDates[index] = picked;
        _errors[index] = null;
      });
    }
  }

  Future<void> _save() async {
    bool hasError = false;

    for (int i = 0; i < _childCount; i++) {
      final name = _nameControllers[i].text.trim();
      final bDate = _birthDates[i];

      if (name.isEmpty) {
        setState(() {
          _errors[i] = 'parent.enter_child_name_err'.tr();
        });
        hasError = true;
      } else if (bDate == null) {
        setState(() {
          _errors[i] = 'parent.select_child_dob_err'.tr();
        });
        hasError = true;
      } else {
        final age = calculateAgeFromDate(bDate);
        if (age < 1 || age > 15) {
          setState(() {
            _errors[i] = age > 15
                ? 'parent.child_age_over_15_err'.tr()
                : 'parent.child_age_range_err'.tr();
          });
          hasError = true;
        } else {
          setState(() {
            _errors[i] = null;
          });
        }
      }
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('parent.fill_all_children_err'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final futures = <Future>[];
      for (int i = 0; i < _childCount; i++) {
        final name = _nameControllers[i].text.trim();
        final bDate = _birthDates[i]!;
        final age = calculateAgeFromDate(bDate);
        final color = _selectedColors[i];

        futures.add(ref.read(childrenControllerProvider.notifier).addChild(
              name,
              age: age,
              birthDate: bDate,
              colorHex: color,
            ));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showSuccess(context, _childCount > 1 ? 'parent.children_added_success'.tr() : 'parent.child_added_success'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'common.save_error'.tr(args: [e.toString()]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = DateTime.now();
    final yearList = List.generate(16, (i) => now.year - 1 - i);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + math.max(MediaQuery.of(context).padding.bottom, 24),
            top: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.97),
                isDark ? const Color(0xFF070E1A).withValues(alpha: 0.98) : const Color(0xFFF1F5F9).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.baby, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'parent.add_child_title'.tr(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'parent.up_to_15_years_desc'.tr(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_childCount > 1)
                        IconButton(
                          icon: const Icon(LucideIcons.minusCircle, color: Colors.redAccent, size: 21),
                          tooltip: 'parent.remove_child'.tr(),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _removeChild();
                          },
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF10B981), size: 21),
                        tooltip: 'parent.add_another_child'.tr(),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _addChild();
                        },
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                        tooltip: 'parent.close'.tr(),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Scrollable children forms
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(_childCount, (index) {
                      final bDate = _birthDates[index];
                      final age = bDate != null ? calculateAgeFromDate(bDate) : null;
                      final selectedColorHex = _selectedColors[index];
                      final selectedColor = Color(int.tryParse(selectedColorHex) ?? 0xFF00E5FF);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selectedColor.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: 1.2,
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
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: selectedColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _childCount > 1 ? 'parent.child_number'.tr(args: ['${index + 1}']) : 'parent.child_data'.tr(),
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (age != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [selectedColor.withValues(alpha: 0.25), selectedColor.withValues(alpha: 0.12)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: selectedColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🎂 ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          formatAgeUk(age, context.locale.languageCode),
                                          style: TextStyle(
                                            color: isDark ? Colors.white : selectedColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Name field
                            TextField(
                              controller: _nameControllers[index],
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: "parent.child_name".tr(),
                                hintText: 'parent.child_name_hint'.tr(),
                                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                                prefixIcon: Icon(LucideIcons.user, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: selectedColor, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Date of Birth Card with Quick Year Picker
                            Text(
                              'parent.dob_label'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: () => _pickDate(index),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: bDate != null
                                        ? selectedColor.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: isDark ? 0.15 : 0.35),
                                    width: bDate != null ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: selectedColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(LucideIcons.calendar, size: 18, color: selectedColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bDate != null ? formatUkDate(bDate, context.locale.languageCode) : 'parent.select_dob'.tr(),
                                            style: TextStyle(
                                              color: bDate != null
                                                  ? (isDark ? Colors.white : Colors.black87)
                                                  : (isDark ? Colors.white54 : Colors.black45),
                                              fontSize: 15,
                                              fontWeight: bDate != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            bDate != null ? 'parent.tap_to_change'.tr() : 'parent.quick_year_or_date'.tr(),
                                            style: TextStyle(
                                              color: isDark ? Colors.white38 : Colors.black38,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 18,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Quick year selector chips
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'parent.quick_year_select'.tr(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black45,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: yearList.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 6),
                                itemBuilder: (context, yearIdx) {
                                  final year = yearList[yearIdx];
                                  final isCurrentYearSelected = bDate?.year == year;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final current = _birthDates[index] ?? DateTime(year, now.month, now.day);
                                      var target = DateTime(year, current.month, current.day);
                                      if (calculateAgeFromDate(target) > 15) {
                                        target = DateTime(year, 12, 31);
                                      }
                                      setState(() {
                                        _birthDates[index] = target;
                                        _errors[index] = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isCurrentYearSelected
                                            ? selectedColor.withValues(alpha: 0.25)
                                            : Colors.white.withValues(alpha: isDark ? 0.06 : 0.4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCurrentYearSelected
                                              ? selectedColor
                                              : Colors.white.withValues(alpha: isDark ? 0.12 : 0.25),
                                          width: isCurrentYearSelected ? 1.3 : 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$year',
                                          style: TextStyle(
                                            color: isCurrentYearSelected
                                                ? (isDark ? Colors.white : selectedColor)
                                                : (isDark ? Colors.white70 : Colors.black54),
                                            fontSize: 12,
                                            fontWeight: isCurrentYearSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Color picker row
                            const SizedBox(height: 14),
                            Text(
                              'parent.child_avatar_color'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: _childColorOptions.map((hex) {
                                final color = Color(int.parse(hex));
                                final isSelected = selectedColorHex == hex;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedColors[index] = hex);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.transparent,
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Center(
                                              child: Icon(Icons.check, size: 16, color: Colors.white),
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            // Error text if any
                            if (_errors[index] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errors[index]!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save button (Emerald VIP CTA)
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF064E3B), Color(0xFF022C22)]
                        : const [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.70 : 0.40),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _save();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2.2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.check, size: 19, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Text(
                              _childCount > 1 ? 'parent.save_children_count'.tr(args: ['$_childCount']) : 'parent.save_child_profile'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for editing an existing child's details or deleting them
class EditChildSheet extends ConsumerStatefulWidget {
  final Child child;
  final bool isDark;
  const EditChildSheet({super.key, required this.child, required this.isDark});

  @override
  ConsumerState<EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends ConsumerState<EditChildSheet> {
  late final TextEditingController _nameController;
  DateTime? _birthDate;
  late String _selectedColorHex;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _selectedColorHex = widget.child.colorHex;

    if (widget.child.birthDate != null) {
      _birthDate = widget.child.birthDate;
    } else if (widget.child.age != null) {
      // Approximate birth date from age if not set yet
      final now = DateTime.now();
      _birthDate = DateTime(now.year - widget.child.age!, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - (widget.child.currentAge ?? 7), now.month, now.day);
    final first = DateTime(now.year - 16, now.month, now.day + 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'parent.choose_child_dob'.tr(),
      cancelText: 'parent.cancel'.tr(),
      confirmText: 'parent.select'.tr(),
      builder: (context, child) {
        return Theme(
          data: (widget.isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: widget.isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF00E5FF),
                    onPrimary: Colors.black,
                    surface: Color(0xFF0F1E32),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0284C7),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: widget.isDark ? const Color(0xFF0F1E32) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'parent.enter_child_name_err'.tr());
      return;
    }

    if (_birthDate == null) {
      setState(() => _error = 'parent.select_child_dob_err'.tr());
      return;
    }

    final age = calculateAgeFromDate(_birthDate!);
    if (age < 1 || age > 15) {
      setState(() => _error = age > 15
          ? 'parent.child_age_over_15_err'.tr()
          : 'parent.child_age_range_err'.tr());
      return;
    }

    try {
      setState(() => _isLoading = true);
      await ref.read(childrenControllerProvider.notifier).updateChild(
            widget.child.id,
            name,
            age: age,
            birthDate: _birthDate,
            colorHex: _selectedColorHex,
          );

      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showSuccess(context, 'parent.child_updated_success'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'common.save_error'.tr(args: [e.toString()]));
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF0F1E32) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'parent.delete_child_title'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'parent.delete_child_confirm'.tr(args: [widget.child.name]),
          style: TextStyle(
            color: widget.isDark ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: widget.isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('parent.delete'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await ref.read(childrenControllerProvider.notifier).deleteChild(widget.child.id);
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackBar.showSuccess(context, 'parent.child_deleted_success'.tr());
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackBar.showError(context, 'common.error_msg'.tr(args: [e.toString()]));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = DateTime.now();
    final yearList = List.generate(16, (i) => now.year - 1 - i);
    final age = _birthDate != null ? calculateAgeFromDate(_birthDate!) : widget.child.currentAge;
    final childColor = Color(int.tryParse(_selectedColorHex) ?? 0xFF00E5FF);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + math.max(MediaQuery.of(context).padding.bottom, 24),
            top: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF0F1E32).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.97),
                isDark ? const Color(0xFF070E1A).withValues(alpha: 0.98) : const Color(0xFFF1F5F9).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [childColor, childColor.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: childColor.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'parent.edit_child_title'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                        tooltip: 'parent.delete'.tr(),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _confirmDelete();
                              },
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                        tooltip: 'parent.close'.tr(),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent Graduation Callout if child reached 16+
                      if (widget.child.isAdultAge || (age != null && age >= 16)) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'parent.adult_account_time_title'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'parent.adult_account_time_desc'.tr(args: [widget.child.name]),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final res = await GraduateChildSheet.show(context, widget.child);
                                    if (res == true && context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF047857),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.sparkles, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${'graduate.submit_btn'.tr()} 🎓',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: childColor.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Age badge
                            if (age != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [childColor.withValues(alpha: 0.25), childColor.withValues(alpha: 0.12)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: childColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🎂 ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          formatAgeUk(age, context.locale.languageCode),
                                          style: TextStyle(
                                            color: isDark ? Colors.white : childColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),

                            // Name field
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: "parent.child_name".tr(),
                                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                                prefixIcon: Icon(LucideIcons.user, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: childColor, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date of Birth Card
                            Text(
                              'parent.dob_label'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _birthDate != null
                                        ? childColor.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: isDark ? 0.15 : 0.35),
                                    width: _birthDate != null ? 1.4 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: childColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(LucideIcons.calendar, size: 18, color: childColor),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _birthDate != null ? formatUkDate(_birthDate!, context.locale.languageCode) : 'parent.select_dob'.tr(),
                                            style: TextStyle(
                                              color: _birthDate != null
                                                  ? (isDark ? Colors.white : Colors.black87)
                                                  : (isDark ? Colors.white54 : Colors.black45),
                                              fontSize: 15,
                                              fontWeight: _birthDate != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'parent.tap_to_change'.tr(),
                                            style: TextStyle(
                                              color: isDark ? Colors.white38 : Colors.black38,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 18,
                                      color: isDark ? Colors.white38 : Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Quick year selector chips
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'parent.quick_year_select'.tr(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black45,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: yearList.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 6),
                                itemBuilder: (context, yearIdx) {
                                  final year = yearList[yearIdx];
                                  final isCurrentYearSelected = _birthDate?.year == year;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final current = _birthDate ?? DateTime(year, now.month, now.day);
                                      var target = DateTime(year, current.month, current.day);
                                      if (calculateAgeFromDate(target) > 15) {
                                        target = DateTime(year, 12, 31);
                                      }
                                      setState(() {
                                        _birthDate = target;
                                        _error = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isCurrentYearSelected
                                            ? childColor.withValues(alpha: 0.25)
                                            : Colors.white.withValues(alpha: isDark ? 0.06 : 0.4),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCurrentYearSelected
                                              ? childColor
                                              : Colors.white.withValues(alpha: isDark ? 0.12 : 0.25),
                                          width: isCurrentYearSelected ? 1.3 : 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$year',
                                          style: TextStyle(
                                            color: isCurrentYearSelected
                                                ? (isDark ? Colors.white : childColor)
                                                : (isDark ? Colors.white70 : Colors.black54),
                                            fontSize: 12,
                                            fontWeight: isCurrentYearSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Color picker row
                            const SizedBox(height: 14),
                            Text(
                              'parent.child_avatar_color'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: _childColorOptions.map((hex) {
                                final color = Color(int.parse(hex));
                                final isSelected = _selectedColorHex == hex;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedColorHex = hex);
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.transparent,
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Center(
                                              child: Icon(Icons.check, size: 16, color: Colors.white),
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            // Error text
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: Delete and Save
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _confirmDelete();
                              },
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        label: Text(
                          'parent.delete'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [childColor, childColor.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: childColor.withValues(alpha: isDark ? 0.75 : 0.45),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: childColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _save();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.check, size: 19, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'parent.save_changes'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
