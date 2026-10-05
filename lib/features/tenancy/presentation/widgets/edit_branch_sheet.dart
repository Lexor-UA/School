import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBranchSheet extends ConsumerStatefulWidget {
  final Branch branch;

  const EditBranchSheet({
    super.key,
    required this.branch,
  });

  @override
  ConsumerState<EditBranchSheet> createState() => _EditBranchSheetState();
}

class _EditBranchSheetState extends ConsumerState<EditBranchSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _city;
  late String _country;
  late String _currency;
  late String _timezone;
  late String _paymentProvider;
  late String _defaultLanguage;
  late bool _isProtected;
  late final TextEditingController _adminNameController;
  late final TextEditingController _adminSalaryController;

  bool _isLoading = false;

  final List<String> _countries = ['UA', 'AT', 'PL', 'DE', 'US', 'GB'];
  final List<String> _currencies = ['UAH', 'EUR', 'PLN', 'USD', 'GBP'];
  final List<String> _timezones = [
    'Europe/Kyiv',
    'Europe/Vienna',
    'Europe/Warsaw',
    'Europe/Berlin',
    'Europe/London',
    'America/New_York',
  ];
  final List<String> _paymentProviders = ['liqpay', 'stripe'];
  final List<String> _languages = ['uk', 'en', 'de', 'pl'];

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = b.name;
    _city = b.city;
    _country = _countries.contains(b.country.toUpperCase())
        ? b.country.toUpperCase()
        : 'UA';
    _currency = _currencies.contains(b.currency) ? b.currency : 'UAH';
    _timezone = _timezones.contains(b.timezone) ? b.timezone : 'Europe/Kyiv';
    _paymentProvider = b.paymentProvider;
    _defaultLanguage =
        _languages.contains(b.defaultLanguage) ? b.defaultLanguage : 'uk';
    _isProtected = b.isProtected || b.isSystemDefault;

    _adminNameController = TextEditingController();
    _adminSalaryController = TextEditingController(
      text: b.currency == 'UAH' ? '20000' : '1800',
    );

    _fetchAdminDetails();
  }

  Future<void> _fetchAdminDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc('admin_${widget.branch.id}')
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['name'] != null) {
              _adminNameController.text = data['name'].toString();
            }
            if (data['adminSalary'] != null) {
              _adminSalaryController.text = data['adminSalary'].toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminSalaryController.dispose();
    super.dispose();
  }

  void _onCurrencyChanged(String newCurrency) {
    setState(() {
      _currency = newCurrency;
      if (newCurrency == 'UAH') {
        _adminSalaryController.text = '20000';
      } else if (newCurrency == 'EUR') {
        _adminSalaryController.text = '1800';
      } else if (newCurrency == 'PLN') {
        _adminSalaryController.text = '8000';
      } else if (newCurrency == 'USD') {
        _adminSalaryController.text = '2000';
      } else if (newCurrency == 'GBP') {
        _adminSalaryController.text = '1600';
      }
    });
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'UAH':
        return '₴';
      case 'EUR':
        return '€';
      case 'PLN':
        return 'zł';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final parsedSalary = int.tryParse(_adminSalaryController.text.trim()) ??
          (_currency == 'UAH' ? 20000 : 1800);

      final updated = widget.branch.copyWith(
        name: _name.trim(),
        country: _country,
        city: _city.trim(),
        timezone: _timezone,
        currency: _currency,
        currencySymbol: _getCurrencySymbol(_currency),
        defaultLanguage: _defaultLanguage,
        paymentProvider: _paymentProvider,
        isProtected: widget.branch.isSystemDefault ? true : _isProtected,
      );

      await ref.read(tenancyControllerProvider.notifier).updateBranch(
            updated,
            adminSalary: parsedSalary,
            adminName: _adminNameController.text.trim().isNotEmpty
                ? _adminNameController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Філію "${_name.trim()}" успішно оновлено!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка оновлення: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final themeConfig = ref.watch(appThemeControllerProvider);
    final isDark = themeConfig.isDark;
    final isSystemDefault = widget.branch.isSystemDefault;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F9FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? null
            : const Border(
                top: BorderSide(color: Color(0xFFBAE6FD), width: 1.2),
                left: BorderSide(color: Color(0xFFBAE6FD), width: 1.2),
                right: BorderSide(color: Color(0xFFBAE6FD), width: 1.2),
              ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding > 0 ? bottomPadding + 20 : 40,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.branch.flagEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Редагування філії',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? Colors.white54 : const Color(0xFF0284C7),
                      ),
                      style: isDark
                          ? null
                          : IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.90),
                              side: const BorderSide(
                                  color: Color(0xFFBAE6FD), width: 1),
                              shape: const CircleBorder(),
                            ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                _buildTextField(
                  label: 'Назва філії',
                  icon: LucideIcons.building,
                  initialValue: _name,
                  onSaved: (val) => _name = val ?? '',
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Введіть назву' : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // City
                _buildTextField(
                  label: 'Місто (для відображення)',
                  icon: LucideIcons.mapPin,
                  initialValue: _city,
                  onSaved: (val) => _city = val ?? '',
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Введіть місто' : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Країна',
                        value: _country,
                        items: _countries,
                        onChanged: (val) => setState(() => _country = val!),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Валюта',
                        value: _currency,
                        items: _currencies,
                        onChanged: (val) {
                          if (val != null) _onCurrencyChanged(val);
                        },
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Часовий пояс',
                  value: _timezone,
                  items: _timezones,
                  onChanged: (val) => setState(() => _timezone = val!),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Провайдер оплат',
                        value: _paymentProvider,
                        items: _paymentProviders,
                        onChanged: (val) =>
                            setState(() => _paymentProvider = val!),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Основна мова',
                        value: _defaultLanguage,
                        items: _languages,
                        onChanged: (val) =>
                            setState(() => _defaultLanguage = val!),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Admin Settings Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.userCheck,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Text(
                            'Адміністратор філії',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adminNameController,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: "Ім'я адміністратора",
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                          prefixIcon: Icon(LucideIcons.user,
                              size: 16,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF0284C7)),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFBAE6FD),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adminSalaryController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          labelText: 'Ставка / зарплата на місяць',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                          prefixIcon: Icon(LucideIcons.banknote,
                              size: 16,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF0284C7)),
                          suffixText: _getCurrencySymbol(_currency),
                          suffixStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFBAE6FD),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Protection from accidental deletion switch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isProtected
                        ? (isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFECFDF5))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isProtected
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : (isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isProtected
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isProtected
                              ? LucideIcons.shieldCheck
                              : LucideIcons.shieldAlert,
                          color: _isProtected
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Захист від видалення',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSystemDefault
                                  ? 'Базова системна філія (завжди захищена від видалення).'
                                  : (_isProtected
                                      ? 'Філія заблокована від випадкового видалення.'
                                      : 'Захист вимкнено. Філію можна буде видалити.'),
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isSystemDefault)
                        Switch(
                          value: _isProtected,
                          activeThumbColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _isProtected = val),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.save, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Зберегти зміни',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    required bool isDark,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B)),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white54 : const Color(0xFF0284C7), size: 18),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFBAE6FD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFBAE6FD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
