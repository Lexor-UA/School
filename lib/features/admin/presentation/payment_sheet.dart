import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  String _paymentMethod = 'Картка';
  bool _isProcessing = false;
  bool _isSuccess = false;
  
  String? _selectedClient;
  
  final List<String> _clients = [
    'Олег (Малюки)',
    'Анна (Юніори)',
    'Іван (Дорослі)',
    'Новий Клієнт',
  ];

  final List<Map<String, dynamic>> _services = [
    {'name': 'Разове тренування', 'price': 300, 'icon': LucideIcons.user},
    {'name': 'Абонемент 8 занять', 'price': 2000, 'icon': LucideIcons.calendarDays},
    {'name': 'Абонемент Безліміт', 'price': 3500, 'icon': LucideIcons.crown},
    {'name': 'Персональне', 'price': 800, 'icon': LucideIcons.dumbbell},
  ];

  final List<Map<String, dynamic>> _selectedServices = [];

  int get _totalAmount {
    return _selectedServices.fold(0, (sum, item) => sum + (item['price'] as int));
  }

  void _toggleService(Map<String, dynamic> service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _submit() {
    if (_totalAmount == 0) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate payment processing/NFC tap
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF030D1B).withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: _isSuccess 
              ? _buildSuccessState() 
              : (_isProcessing ? _buildProcessingState() : _buildFormState()),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.4), blurRadius: 30)],
          ),
          child: const Icon(LucideIcons.check, color: Colors.greenAccent, size: 60),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text(
          'Оплату успішно прийнято!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'Клієнт: ${_selectedClient ?? 'Не обрано'}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 4),
        Text(
          'Сума: $_totalAmount ₴ • $_paymentMethod',
          style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulse rings
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 1500.ms).fadeOut(),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.6), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 1500.ms, delay: 500.ms).fadeOut(),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.4), blurRadius: 30)],
              ),
              child: Icon(_paymentMethod == 'Картка' ? LucideIcons.nfc : LucideIcons.banknote, color: Colors.purpleAccent, size: 50),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 800.ms),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          _paymentMethod == 'Картка' ? 'Прикладіть картку до пристрою...' : 'Обробка готівки...',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 800.ms),
      ],
    );
  }

  Widget _buildFormState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(LucideIcons.wallet, color: Colors.purpleAccent),
            SizedBox(width: 12),
            Text('Міні-Каса', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        
        // 1. Client Selection
        const Text('1. Оберіть клієнта', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _clients.length,
            itemBuilder: (context, index) {
              final client = _clients[index];
              final isSelected = client == _selectedClient;
              return GestureDetector(
                onTap: () => setState(() => _selectedClient = client),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    client,
                    style: TextStyle(
                      color: isSelected ? Colors.purpleAccent : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 2. Service Selection
        const Text('2. Послуги', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final isSelected = _selectedServices.contains(service);
              return GestureDetector(
                onTap: () => _toggleService(service),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(service['icon'], color: isSelected ? Colors.purpleAccent : Colors.white54, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        service['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${service['price']} ₴',
                        style: TextStyle(
                          color: isSelected ? Colors.purpleAccent : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 3. Payment Method
        Row(
          children: [
            Expanded(child: _buildMethodButton('Картка', LucideIcons.creditCard)),
            const SizedBox(width: 16),
            Expanded(child: _buildMethodButton('Готівка', LucideIcons.banknote)),
          ],
        ),
        const SizedBox(height: 24),
        
        // 4. Submit Button with Total
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _totalAmount > 0 ? Colors.purpleAccent : Colors.white24,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: _totalAmount > 0 ? 10 : 0,
              shadowColor: Colors.purpleAccent.withValues(alpha: 0.5),
            ),
            onPressed: _totalAmount > 0 ? _submit : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Сплатити', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _totalAmount > 0 ? Colors.white : Colors.white54)),
                const SizedBox(width: 8),
                Text('$_totalAmount ₴', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _totalAmount > 0 ? Colors.white : Colors.white54)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodButton(String label, IconData icon) {
    final isSelected = _paymentMethod == label;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.purpleAccent : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purpleAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
