import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:intl/intl.dart';
import 'package:swimming_school_app/features/admin/presentation/admin_booking_sheet.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';

class EditClientSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String initialName;
  final String initialPhone;
  final String initialLoginId;

  const EditClientSheet({
    super.key,
    required this.clientId,
    required this.initialName,
    required this.initialPhone,
    required this.initialLoginId,
  });

  @override
  ConsumerState<EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends ConsumerState<EditClientSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _loginIdController;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  final List<Map<String, dynamic>> _services = [
    {'name': 'Абонемент на 4 тренування', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренуваннь', 'classes': 8, 'validityDays': 30},
    {'name': 'Абонемент на 12 тренуваннь', 'classes': 12, 'validityDays': 30},
    {'name': 'Разове тренування у групі', 'classes': 1, 'validityDays': 1},
    {'name': 'Разове відвідування/доросла група', 'classes': 1, 'validityDays': 2},
    {'name': 'Абонемент на 4 тренування(ДОРОСЛА ГРУПА)', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренувань(ДОРОСЛА ГРУПА)', 'classes': 8, 'validityDays': 30},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _loginIdController = TextEditingController(text: widget.initialLoginId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _loginIdController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _loginIdController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Заповніть всі поля');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.clientId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'loginId': _loginIdController.text.trim(),
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateSubscriptionClasses(Subscription sub, int delta) async {
    final newClasses = sub.remainingClasses + delta;
    if (newClasses < 0) return;
    
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
        'remainingClasses': newClasses,
        'isActive': newClasses > 0,
      });
    } catch (e) {
      debugPrint('Error updating subscription classes: $e');
    }
  }

  void _deleteSubscription(Subscription sub) async {
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).delete();
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
    }
  }

  void _showAddSubscriptionDialog(List<String> availableOwners) {
    String selectedService = _services.first['name'];
    String selectedOwner = availableOwners.isNotEmpty ? availableOwners.first : widget.initialName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              title: const Text('Призначити абонемент', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Абонемент:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1E293B),
                        value: selectedService,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, color: Colors.cyanAccent),
                        items: _services.map((s) {
                          return DropdownMenuItem<String>(
                            value: s['name'],
                            child: Text(s['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedService = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Для кого:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  if (availableOwners.isEmpty)
                    const Text('Немає дітей, буде призначено на клієнта', style: TextStyle(color: Colors.white54))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E293B),
                          value: selectedOwner,
                          isExpanded: true,
                          icon: const Icon(LucideIcons.chevronDown, color: Colors.cyanAccent),
                          items: availableOwners.map((owner) {
                            return DropdownMenuItem<String>(
                              value: owner,
                              child: Text(owner, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => selectedOwner = val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Скасувати', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    final serviceDetails = _services.firstWhere((s) => s['name'] == selectedService);
                    final classes = serviceDetails['classes'] as int;
                    final validityDays = serviceDetails['validityDays'] as int;
                    final expiry = DateTime.now().add(Duration(days: validityDays));
                    
                    final newSub = Subscription(
                      id: 'sub_${DateTime.now().microsecondsSinceEpoch}_${selectedOwner.hashCode}',
                      userId: widget.clientId,
                      totalClasses: classes,
                      remainingClasses: classes,
                      isActive: true,
                      serviceName: selectedService,
                      expiryDate: expiry,
                      ownerName: selectedOwner,
                    );
                    
                    try {
                      await FirebaseFirestore.instance.collection('subscriptions').doc(newSub.id).set(newSub.toJson());
                    } catch (e) {
                      debugPrint('Error assigning sub: $e');
                    }
                  },
                  child: const Text('Призначити', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Row(
              children: [
                const Icon(LucideIcons.edit2, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Text(
                  'Редагувати клієнта',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isSuccess)
              _buildSuccessState()
            else
              _buildFormState(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    final userSubs = ref.watch(subscriptionControllerProvider).where((s) => s.userId == widget.clientId).toList();
    
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Ім\'я та Прізвище',
          icon: LucideIcons.user,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _phoneController,
          label: 'Номер телефону',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _loginIdController,
          label: 'Логін для входу (наприклад, Client1)',
          icon: LucideIcons.key,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
        const SizedBox(height: 32),

        // SUBSCRIPTION MANAGEMENT
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Управління абонементами', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 12),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, snapshot) {
            List<String> availableOwners = [widget.initialName];
            List<String> allRelatedIds = [widget.clientId];
            
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              availableOwners.addAll(snapshot.data!.docs.map((d) => (d.data() as Map<String, dynamic>)['name'] as String? ?? 'Дитина'));
              allRelatedIds.addAll(snapshot.data!.docs.map((d) => d.id));
            }

            return Column(
              children: [
                if (userSubs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('У клієнта немає абонементів', style: TextStyle(color: Colors.white54)),
                    ),
                  )
                else
                  ...userSubs.map((sub) {
                    final isActive = sub.isActive;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isActive ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sub.serviceName ?? 'Абонемент',
                                  style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'Активний' : 'Неактивний',
                                  style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Для: ${sub.ownerName ?? 'Не вказано'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          
                          if (sub.expiryDate != null && sub.isActive)
                            Builder(
                              builder: (context) {
                                final daysLeft = sub.expiryDate!.difference(DateTime.now()).inDays;
                                if (daysLeft >= 0 && daysLeft <= 5) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '⚠️ Закінчується через $daysLeft ${daysLeft == 1 ? 'день' : 'днів'}',
                                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Залишилось: ${sub.remainingClasses} / ${sub.totalClasses}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.minusCircle, color: Colors.orangeAccent),
                                    onPressed: () => _updateSubscriptionClasses(sub, -1),
                                    tooltip: 'Відняти 1 заняття',
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.plusCircle, color: Colors.cyanAccent),
                                    onPressed: () => _updateSubscriptionClasses(sub, 1),
                                    tooltip: 'Додати 1 заняття',
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.refreshCw, color: Colors.yellowAccent),
                                    onPressed: () => _updateSubscriptionClasses(sub, -sub.remainingClasses),
                                    tooltip: 'Обнулити абонемент',
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                                    onPressed: () => _deleteSubscription(sub),
                                    tooltip: 'Видалити абонемент',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(LucideIcons.plus, color: Colors.greenAccent),
                    label: const Text('Призначити новий абонемент', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.greenAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showAddSubscriptionDialog(availableOwners),
                  ),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Заняття клієнта', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, childSnap) {
            List<String> allRelatedIds = [widget.clientId];
            if (childSnap.hasData) {
              allRelatedIds.addAll(childSnap.data!.docs.map((d) => d.id));
            }
            
            if (allRelatedIds.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('classes')
                .where('enrolledChildIds', arrayContainsAny: allRelatedIds)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
                .snapshots(),
              builder: (context, classSnap) {
                if (!classSnap.hasData || classSnap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Немає активних записів', style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }

                final classes = classSnap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return GroupClass.fromJson(data);
                }).toList();
                
                classes.sort((a, b) => a.date.compareTo(b.date));

                return Column(
                  children: classes.map((session) {
                    final enrolledHere = session.enrolledChildIds.where((id) => allRelatedIds.contains(id)).toList();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd.MM.yyyy').format(session.date)} о ${session.time}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  session.category,
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...enrolledHere.map((enrolledId) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(enrolledId == widget.clientId ? widget.initialName : 'Дитина', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        final success = await ref.read(scheduleControllerProvider.notifier).cancelClass(session.id, enrolledId);
                                        if (success && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Запис скасовано', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Помилка: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 24),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Скасувати запис', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
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
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, snapshot) {
            List<String> availableIds = [widget.clientId];
            List<String> availableNames = [widget.initialName];
            
            if (snapshot.hasData) {
              for (var d in snapshot.data!.docs) {
                availableIds.add(d.id);
                availableNames.add((d.data() as Map<String, dynamic>)['name'] as String? ?? 'Дитина');
              }
            }
            
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(LucideIcons.calendarPlus, color: Colors.blueAccent),
                label: const Text('Записати на заняття', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => AdminBookingSheet(
                      clientId: widget.clientId,
                      clientName: widget.initialName,
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

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Помилка: $_errorMessage',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Зберегти зміни профілю', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 64).animate().scale().fadeIn(),
        const SizedBox(height: 24),
        const Text(
          'Дані оновлено!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
