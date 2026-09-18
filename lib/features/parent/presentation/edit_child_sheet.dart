import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/parent/controllers/children_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';

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

String formatUkDate(DateTime date) {
  return '${date.day} ${_ukMonths[date.month - 1]} ${date.year} р.';
}

String formatAgeUk(int years) {
  if (years % 10 == 1 && years % 100 != 11) {
    return '$years рік';
  } else if ([2, 3, 4].contains(years % 10) && ![12, 13, 14].contains(years % 100)) {
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
    final first = DateTime(now.year - 17, 1, 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Оберіть дату народження дитини',
      cancelText: 'Скасувати',
      confirmText: 'Обрати',
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
          _errors[i] = "Введіть ім'я дитини";
        });
        hasError = true;
      } else if (bDate == null) {
        setState(() {
          _errors[i] = 'Оберіть дату народження дитини';
        });
        hasError = true;
      } else {
        final age = calculateAgeFromDate(bDate);
        if (age < 1 || age > 17) {
          setState(() {
            _errors[i] = 'Вік дитини має бути від 1 до 17 років';
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
        const SnackBar(
          content: Text('Будь ласка, заповніть ім\'я та дату народження для кожної дитини',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = DateTime.now();
    final yearList = List.generate(17, (i) => now.year - 1 - i);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Text(
                        'Додати дитину',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_childCount > 1)
                        IconButton(
                          icon: const Icon(LucideIcons.minusCircle, color: Colors.redAccent, size: 22),
                          tooltip: 'Прибрати дитину',
                          onPressed: _removeChild,
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF10B981), size: 22),
                        tooltip: 'Додати ще одну дитину',
                        onPressed: _addChild,
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
                                      _childCount > 1 ? 'Дитина #${index + 1}' : 'Дані дитини',
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
                                          formatAgeUk(age),
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
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: "Ім'я дитини",
                                hintText: 'Наприклад: Максим',
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
                              'Дата народження (день, місяць, рік)',
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
                                            bDate != null ? formatUkDate(bDate) : 'Оберіть дату народження',
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
                                            bDate != null ? 'Натисніть, щоб змінити' : 'Швидкий вибір року або точна дата',
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
                                  'Швидкий вибір року:',
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
                                      setState(() {
                                        _birthDates[index] = DateTime(year, current.month, current.day);
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
                              'Колір аватара дитини:',
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

              // Save button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _childCount > 1 ? 'Зберегти дітей ($_childCount)' : 'Зберегти профіль дитини',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final initial = _birthDate ?? DateTime(now.year - 7, now.month, now.day);
    final first = DateTime(now.year - 17, 1, 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Оберіть дату народження дитини',
      cancelText: 'Скасувати',
      confirmText: 'Обрати',
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
      setState(() => _error = "Введіть ім'я дитини");
      return;
    }

    if (_birthDate == null) {
      setState(() => _error = 'Оберіть дату народження');
      return;
    }

    final age = calculateAgeFromDate(_birthDate!);
    if (age < 1 || age > 17) {
      setState(() => _error = 'Вік дитини має бути від 1 до 17 років');
      return;
    }

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
      Navigator.pop(context);
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
            const Expanded(
              child: Text(
                'Видалити профіль?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Ви дійсно бажаєте видалити профіль "${widget.child.name}"? '
          'Усі майбутні записи та історія для цієї дитини будуть видалені з вашого облікового запису.',
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
              'Скасувати',
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
            child: const Text('Видалити', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      await ref.read(childrenControllerProvider.notifier).deleteChild(widget.child.id);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final now = DateTime.now();
    final yearList = List.generate(17, (i) => now.year - 1 - i);
    final age = _birthDate != null ? calculateAgeFromDate(_birthDate!) : widget.child.currentAge;
    final childColor = Color(int.tryParse(_selectedColorHex) ?? 0xFF00E5FF);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Text(
                        'Редагувати дитину',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22),
                    tooltip: 'Видалити профіль дитини',
                    onPressed: _isLoading ? null : _confirmDelete,
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
                                          formatAgeUk(age),
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
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                labelText: "Ім'я дитини",
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
                              'Дата народження (день, місяць, рік)',
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
                                            _birthDate != null ? formatUkDate(_birthDate!) : 'Оберіть дату народження',
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
                                            'Натисніть, щоб обрати іншу дату',
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
                                  'Швидкий вибір року:',
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
                                      setState(() {
                                        _birthDate = DateTime(year, current.month, current.day);
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
                              'Колір аватара дитини:',
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
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _confirmDelete,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      label: const Text('Видалити', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [childColor, childColor.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: childColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Зберегти зміни', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
