import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:swimming_school_app/features/schedule/controllers/schedule_controller.dart';
import 'package:swimming_school_app/features/schedule/models/group_class.dart';
import 'package:swimming_school_app/features/admin/presentation/admin_booking_sheet.dart';
import 'package:swimming_school_app/features/subscription/controllers/subscription_controller.dart';
import 'package:swimming_school_app/features/subscription/models/subscription.dart';
import 'package:swimming_school_app/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';

class EditClientSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String initialName;
  final String initialPhone;
  final int? initialAge;
  final String initialLoginId;
  final String? initialPassword;

  const EditClientSheet({
    super.key,
    required this.clientId,
    required this.initialName,
    required this.initialPhone,
    this.initialAge,
    required this.initialLoginId,
    this.initialPassword,
  });

  @override
  ConsumerState<EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends ConsumerState<EditClientSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _loginIdController;
  late TextEditingController _passwordController;
  bool _obscurePassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  final List<Map<String, dynamic>> _services = [
    {'name': 'Абонемент на 4 тренування', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренуваннь', 'classes': 8, 'validityDays': 30},
    {'name': 'Абонемент на 12 тренуваннь', 'classes': 12, 'validityDays': 30},
    {'name': 'Разове тренування у групі', 'classes': 1, 'validityDays': 1},
    {'name': 'Разове відвідування/доросла група', 'classes': 1, 'validityDays': 2},
    {'name': 'Абонемент на 4 тренування (ДОРОСЛА ГРУПА)', 'classes': 4, 'validityDays': 30},
    {'name': 'Абонемент на 8 тренувань (ДОРОСЛА ГРУПА)', 'classes': 8, 'validityDays': 30},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _ageController = TextEditingController(text: widget.initialAge?.toString() ?? '');
    _loginIdController = TextEditingController(text: widget.initialLoginId);
    _passwordController = TextEditingController(text: widget.initialPassword ?? '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetPasswordToDefault() {
    setState(() {
      _passwordController.text = '1';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.greenAccent, size: 18),
            SizedBox(width: 8),
            Text('Пароль скинуто до стандартного: 1', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateRandomPin() {
    final randomPin = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      _passwordController.text = randomPin;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 8),
            Text('Згенеровано новий PIN: $randomPin', style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyCredentials() {
    final login = _loginIdController.text.trim();
    final pass = _passwordController.text.trim();
    Clipboard.setData(ClipboardData(
      text: 'Логін: $login\nПароль: $pass',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.copy, color: Color(0xFF38BDF8), size: 18),
            SizedBox(width: 8),
            Text('Дані для входу скопійовано в буфер обміну!', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _loginIdController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Заповніть всі поля, включаючи пароль');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final age = int.tryParse(_ageController.text.trim());
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'loginId': _loginIdController.text.trim(),
        'password': _passwordController.text.trim(),
      };
      if (age != null) {
        updateData['age'] = age;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.clientId).update(updateData).timeout(const Duration(seconds: 5));

      if (mounted) {
        final admin = ref.read(authControllerProvider);
        if (admin != null) {
          await logAdminAction('Оновлено дані та пароль клієнта "${_nameController.text.trim()}"', admin.id);
        }
        
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

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 22),
            SizedBox(width: 8),
            Text('Додати дитину', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Ім'я дитини",
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(LucideIcons.baby, color: Color(0xFF00E5FF), size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Вік дитини (років)',
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(LucideIcons.calendarDays, color: Color(0xFF00E5FF), size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('admin.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final age = int.tryParse(ageCtrl.text.trim());
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final childRef = FirebaseFirestore.instance.collection('children').doc();
                final childData = <String, dynamic>{
                  'id': childRef.id,
                  'parentId': widget.clientId,
                  'name': name,
                  'colorHex': '0xFF40C4FF',
                  'level': 1,
                  'xp': 0,
                  'maxXp': 100,
                  'notes': age != null ? 'Вік: $age' : '',
                };
                if (age != null) {
                  childData['age'] = age;
                }
                await childRef.set(childData);
                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Додано дитину "$name" для клієнта "${widget.initialName}"', admin.id);
                }
              } catch (e) {
                debugPrint('Error adding child: $e');
              }
            },
            child: const Text('Додати', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditChildDialog(String childId, String currentName, int? currentAge) {
    final nameCtrl = TextEditingController(text: currentName);
    final ageCtrl = TextEditingController(text: currentAge?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text('Редагувати дитину', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Ім'я дитини",
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(LucideIcons.baby, color: Color(0xFF38BDF8), size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Вік дитини (років)',
                labelStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(LucideIcons.calendarDays, color: Color(0xFF38BDF8), size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('admin.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final age = int.tryParse(ageCtrl.text.trim());
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('children').doc(childId).update({
                  'name': name,
                  'age': age,
                  'notes': age != null ? 'Вік: $age' : '',
                });
                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Оновлено дані дитини "$name" клієнта "${widget.initialName}"', admin.id);
                }
              } catch (e) {
                debugPrint('Error updating child: $e');
              }
            },
            child: const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteChild(String childId, String childName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Видалити дитину?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Ви дійсно бажаєте видалити дані дитини "$childName"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('admin.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('children').doc(childId).delete();
                try {
                  final classesSnap = await FirebaseFirestore.instance
                      .collection('classes')
                      .where('enrolledChildIds', arrayContains: childId)
                      .get();
                  for (var doc in classesSnap.docs) {
                    final enrolled = List<String>.from(doc.data()['enrolledChildIds'] ?? []);
                    enrolled.remove(childId);
                    await doc.reference.update({'enrolledChildIds': enrolled});
                  }
                } catch (err) {
                  debugPrint('Error cleaning up classes for child: $err');
                }

                final admin = ref.read(authControllerProvider);
                if (admin != null) {
                  await logAdminAction('Видалено дитину "$childName" клієнта "${widget.initialName}"', admin.id);
                }
              } catch (e) {
                debugPrint('Error deleting child: $e');
              }
            },
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  void _updateSubscriptionClasses(Subscription sub, int delta) async {
    final newClasses = sub.remainingClasses + delta;
    if (newClasses < 0) return;
    
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).update({
        'remainingClasses': newClasses,
        'isActive': newClasses > 0,
      });
      
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Змінено залишок занять для "${widget.initialName}" (стало $newClasses)', admin.id);
      }
    } catch (e) {
      debugPrint('Error updating subscription classes: $e');
    }
  }

  void _deleteSubscription(Subscription sub) async {
    try {
      await FirebaseFirestore.instance.collection('subscriptions').doc(sub.id).delete();
      
      final admin = ref.read(authControllerProvider);
      if (admin != null) {
        await logAdminAction('Видалено абонемент клієнта "${widget.initialName}"', admin.id);
      }
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
                  child: Text('admin.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
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
                      
                      final admin = ref.read(authControllerProvider);
                      if (admin != null) {
                        await logAdminAction('Призначено абонемент "${serviceDetails['name']}" для "$selectedOwner"', admin.id);
                      }
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
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.60),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed Header (outside scroll view, full drag & dismiss zone)
            _buildHeader(context),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: mediaQuery.viewInsets.bottom + 24,
                  left: 24,
                  right: 24,
                  top: 16,
                ),
                child: _isSuccess ? _buildSuccessState() : _buildFormState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator with generous touch footprint
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(LucideIcons.edit2, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'admin.edit_client_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              // Frosted glass close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    final userSubs = ref.watch(subscriptionControllerProvider).where((s) => s.userId == widget.clientId).toList();
    
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'admin.add_client_name_hint'.tr(),
          icon: LucideIcons.user,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _phoneController,
          label: 'admin.add_client_phone_hint'.tr(),
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _ageController,
          label: 'Вік клієнта (років)',
          icon: LucideIcons.calendar,
          keyboardType: TextInputType.number,
        ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _loginIdController,
          label: '${'admin.clients_login_label'.tr()} (Client1)',
          icon: LucideIcons.key,
        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
        const SizedBox(height: 16),

        // Password & Access Management Section
        _buildPasswordSection().animate().fadeIn(delay: 350.ms).slideX(begin: -0.1),
        const SizedBox(height: 32),

        // CHILDREN MANAGEMENT
        _buildChildrenSection().animate().fadeIn(delay: 380.ms),
        const SizedBox(height: 32),

        // SUBSCRIPTION MANAGEMENT
        Align(
          alignment: Alignment.centerLeft,
          child: Text('admin.sub_management'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    child: Center(
                      child: Text('admin.clients_no_subs'.tr(), style: const TextStyle(color: Colors.white54)),
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
                                  sub.serviceName ?? 'admin.cat_subscriptions'.tr(),
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
                                  isActive ? 'admin.clients_status_active'.tr() : 'admin.clients_status_unpaid'.tr(),
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
                              Text('${'parent.sub_left'.tr(args: ['${sub.remainingClasses}'])} (${sub.totalClasses})', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
                                    tooltip: 'admin.delete'.tr(),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text('admin.client_classes'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, childSnap) {
            List<String> allRelatedIds = [widget.clientId];
            Map<String, String> idToName = {widget.clientId: widget.initialName};
            if (childSnap.hasData) {
              for (var doc in childSnap.data!.docs) {
                allRelatedIds.add(doc.id);
                final cData = doc.data() as Map<String, dynamic>;
                idToName[doc.id] = (cData['name'] as String? ?? 'Дитина').trim();
              }
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
                
                classes.sort((a, b) => a.startTime.compareTo(b.startTime));

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
                                  '${DateFormat('dd.MM.yyyy').format(session.startTime)} о ${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
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
                                  Text(idToName[enrolledId] ?? 'Дитина', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  TextButton(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        final targetName = idToName[enrolledId] ?? widget.initialName;
                                        final success = await ref.read(scheduleControllerProvider.notifier).cancelClass(
                                          session.id, 
                                          enrolledId,
                                          targetUserId: widget.clientId,
                                          targetOwnerName: targetName,
                                        );
                                        if (success && mounted) {
                                          messenger.showSnackBar(
                                            const SnackBar(content: Text('Запис скасовано, заняття повернено на абонемент', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
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
                : Text('admin.add_client_save_btn'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessState() {
    final trText = 'admin.edit_client_success'.tr();
    final displayText = (trText == 'admin.edit_client_success' || trText.isEmpty)
        ? 'Дані клієнта оновлено!'
        : trText;
    return Column(
      children: [
        const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 64).animate().scale().fadeIn(),
        const SizedBox(height: 24),
        Text(
          displayText,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
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

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: 'admin.clients_password_label'.tr().replaceAll(':', '').trim().isEmpty
                  ? 'Пароль клієнта'
                  : 'admin.clients_password_label'.tr().replaceAll(':', '').trim(),
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              prefixIcon: const Icon(LucideIcons.keyRound, color: Color(0xFFF59E0B), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: Colors.white60,
                  size: 20,
                ),
                tooltip: _obscurePassword ? 'Показати пароль' : 'Приховати пароль',
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPasswordActionButton(
                      icon: LucideIcons.rotateCcw,
                      label: 'Скинути на "1"',
                      color: const Color(0xFFF59E0B),
                      onTap: _resetPasswordToDefault,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.sparkles,
                      label: 'Згенерувати PIN',
                      color: const Color(0xFF00E5FF),
                      onTap: _generateRandomPin,
                    ),
                    _buildPasswordActionButton(
                      icon: LucideIcons.copy,
                      label: 'Копіювати',
                      color: const Color(0xFF38BDF8),
                      onTap: _copyCredentials,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 12, color: Colors.white.withValues(alpha: 0.40)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Збережіть зміни, щоб оновити пароль у базі даних',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
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

  Widget _buildPasswordActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.baby, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Text(
                  'admin.add_client_children_title'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showAddChildDialog,
              icon: const Icon(LucideIcons.plus, color: Color(0xFF00E5FF), size: 16),
              label: const Text(
                'Додати',
                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: widget.clientId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Center(
                  child: Text(
                    'admin.clients_no_children'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              );
            }

            final children = snapshot.data!.docs;
            return Column(
              children: children.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cId = doc.id;
                final cName = data['name'] ?? 'Дитина';
                final cAge = data['age'] is int ? data['age'] as int : int.tryParse(data['age']?.toString() ?? '');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🏊', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cAge != null ? '$cAge ${'admin.years_short'.tr()}' : 'Вік не вказано',
                              style: TextStyle(
                                color: cAge != null ? const Color(0xFF00E5FF) : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.pencil, color: Color(0xFF38BDF8), size: 16),
                        tooltip: 'Редагувати',
                        onPressed: () => _showEditChildDialog(cId, cName, cAge),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                        tooltip: 'Видалити',
                        onPressed: () => _deleteChild(cId, cName),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
