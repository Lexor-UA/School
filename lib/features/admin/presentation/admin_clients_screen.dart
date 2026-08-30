import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:swimming_school_app/shared/widgets/animated_water_background.dart';
import 'package:swimming_school_app/shared/widgets/water_particles.dart';
import 'edit_client_sheet.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteClient(String clientId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Видалити клієнта?', style: TextStyle(color: Colors.white)),
        content: Text('Ви впевнені, що хочете видалити клієнта $name та всіх його дітей? Цю дію неможливо скасувати.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete user
        await FirebaseFirestore.instance.collection('users').doc(clientId).delete();
        
        // Delete children
        final childrenSnap = await FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: clientId).get();
        for (var doc in childrenSnap.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Клієнта успішно видалено', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Всі Клієнти', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AnimatedWaterBackground(),
          const Positioned.fill(child: WaterParticles()),
          SafeArea(
            child: Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Пошук клієнта...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'parent')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('Немає клієнтів', style: TextStyle(color: Colors.white54, fontSize: 16)));
                      }

                      var clients = snapshot.data!.docs;
                      if (_searchQuery.isNotEmpty) {
                        clients = clients.where((c) {
                          final name = (c.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
                          final loginId = (c.data() as Map<String, dynamic>)['loginId']?.toString().toLowerCase() ?? '';
                          final phone = (c.data() as Map<String, dynamic>)['phone']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery) || loginId.contains(_searchQuery) || phone.contains(_searchQuery);
                        }).toList();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final clientDoc = clients[index];
                          final data = clientDoc.data() as Map<String, dynamic>;
                          final clientId = clientDoc.id;
                          final name = data['name'] ?? 'Невідомо';
                          final phone = data['phone'] ?? 'Немає номеру';
                          final loginId = data['loginId'] ?? 'Не призначено';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            backgroundColor: Colors.cyanAccent,
                                            radius: 20,
                                            child: Icon(LucideIcons.user, color: Color(0xFF030D1B)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.edit2, color: Colors.blueAccent),
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (context) => EditClientSheet(
                                                clientId: clientId,
                                                initialName: name,
                                                initialPhone: phone,
                                                initialLoginId: loginId,
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                                          onPressed: () => _deleteClient(clientId, name),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 24),
                                
                                // Login Info
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.key, color: Colors.blueAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text('Логін: $loginId  |  Пароль: 1', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Children Info
                                const Text('Діти:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('children').where('parentId', isEqualTo: clientId).snapshots(),
                                  builder: (context, childSnap) {
                                    if (childSnap.connectionState == ConnectionState.waiting) return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                    if (!childSnap.hasData || childSnap.data!.docs.isEmpty) return const Text('Немає доданих дітей', style: TextStyle(color: Colors.white54));
                                    
                                    return Column(
                                      children: childSnap.data!.docs.map((doc) {
                                        final childData = doc.data() as Map<String, dynamic>;
                                        final childName = childData['name'] ?? 'Невідомо';
                                        final childLevel = childData['level'] ?? 1;
                                        final childAge = childData['age'];
                                        final ageText = childAge != null ? ', $childAge років' : '';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.baby, color: Colors.cyanAccent, size: 16),
                                              const SizedBox(width: 8),
                                              Text('$childName$ageText (Рівень $childLevel)', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
