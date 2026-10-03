import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/features/tenancy/models/branch.dart';
import 'package:swimming_school_app/features/tenancy/controllers/tenancy_controller.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

class CreateBranchSheet extends ConsumerStatefulWidget {
  const CreateBranchSheet({super.key});

  @override
  ConsumerState<CreateBranchSheet> createState() => _CreateBranchSheetState();
}

class _CreateBranchSheetState extends ConsumerState<CreateBranchSheet> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _city = '';
  String _country = 'UA';
  String _currency = 'UAH';
  String _timezone = 'Europe/Kyiv';
  String _paymentProvider = 'liqpay';
  String _defaultLanguage = 'uk';
  String _adminName = '';
  late final TextEditingController _adminSalaryController;
  
  bool _isLoading = false;

  final List<String> _countries = ['UA', 'AT', 'PL', 'DE', 'US', 'GB'];
  final List<String> _currencies = ['UAH', 'EUR', 'PLN', 'USD', 'GBP'];
  final List<String> _timezones = [
    'Europe/Kyiv', 'Europe/Vienna', 'Europe/Warsaw', 'Europe/Berlin', 'Europe/London', 'America/New_York'
  ];
  final List<String> _paymentProviders = ['liqpay', 'stripe'];
  final List<String> _languages = ['uk', 'en', 'de', 'pl'];

  @override
  void initState() {
    super.initState();
    _adminSalaryController = TextEditingController(text: '20000');
  }

  @override
  void dispose() {
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
      case 'UAH': return '₴';
      case 'EUR': return '€';
      case 'PLN': return 'zł';
      case 'USD': return '\$';
      case 'GBP': return '£';
      default: return currency;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      final id = _name.trim().toLowerCase().replaceAll(' ', '_');
      final parsedSalary = int.tryParse(_adminSalaryController.text.trim()) ?? 
          (_currency == 'UAH' ? 20000 : 1800);
      
      final branch = Branch(
        id: id.isEmpty ? 'new_branch_${DateTime.now().millisecondsSinceEpoch}' : id,
        organizationId: 'cityswim',
        name: _name.trim(),
        country: _country,
        city: _city.trim(),
        timezone: _timezone,
        currency: _currency,
        currencySymbol: _getCurrencySymbol(_currency),
        defaultLanguage: _defaultLanguage,
        paymentProvider: _paymentProvider,
        createdAt: DateTime.now(),
      );
      
      await ref.read(tenancyControllerProvider.notifier).createBranch(
        branch,
        adminSalary: parsedSalary,
        adminName: _adminName.trim().isNotEmpty ? _adminName.trim() : null,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Філію ${_name.trim()} та адміністратора успішно створено!')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
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
                    Text(
                      'Створення нової філії',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? Colors.white54 : const Color(0xFF0284C7),
                      ),
                      style: isDark
                          ? null
                          : IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.90),
                              side: const BorderSide(color: Color(0xFFBAE6FD), width: 1),
                              shape: const CircleBorder(),
                            ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name
                _buildTextField(
                  label: 'Назва філії (напр. Warsaw)',
                  icon: LucideIcons.building,
                  onSaved: (val) => _name = val ?? '',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Введіть назву' : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                
                // City
                _buildTextField(
                  label: 'Місто (для відображення)',
                  icon: LucideIcons.mapPin,
                  onSaved: (val) => _city = val ?? '',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Введіть місто' : null,
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
                        onChanged: (val) => setState(() => _paymentProvider = val!),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Основна мова',
                        value: _defaultLanguage,
                        items: _languages,
                        onChanged: (val) => setState(() => _defaultLanguage = val!),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 22),

                // Administrator configuration section
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'АДМІНІСТРАТОР ФІЛІЇ',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.9)
                            : const Color(0xFF0284C7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                _buildTextField(
                  label: 'Ім\'я адміністратора (необов\'язково)',
                  icon: LucideIcons.user,
                  onSaved: (val) => _adminName = val ?? '',
                  validator: (_) => null,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _adminSalaryController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Початковий місячний оклад (${_getCurrencySymbol(_currency)})',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.landmark,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      size: 18,
                    ),
                    suffixText: _getCurrencySymbol(_currency),
                    suffixStyle: TextStyle(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFBAE6FD),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFBAE6FD),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                
                Container(
                  decoration: isDark
                      ? null
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF00E5FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00E5FF) : Colors.transparent,
                      foregroundColor: isDark ? const Color(0xFF001F3F) : Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? const Color(0xFF001F3F) : Colors.white,
                            ),
                          )
                        : const Text(
                            'Розгорнути філію та адміністратора',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
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
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    required bool isDark,
  }) {
    return TextFormField(
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7),
          size: 18,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFBAE6FD),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFBAE6FD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
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
      dropdownColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14,
      ),
      icon: Icon(
        LucideIcons.chevronDown,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7),
        size: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFBAE6FD),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFBAE6FD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

