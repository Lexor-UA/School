import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/core/router/app_router.dart';
import 'package:swimming_school_app/features/coach/presentation/coach_dashboard.dart';
import 'package:swimming_school_app/features/auth/controllers/auth_controller.dart';
import 'package:swimming_school_app/features/parent/models/child.dart';
import 'package:swimming_school_app/core/theme/app_theme_provider.dart';

/// Safe translation helper with clean Ukrainian fallback
String coachTr(String key, String fallback, {List<String>? args}) {
  final val = args != null ? key.tr(args: args) : key.tr();
  if (val == key || val.isEmpty) {
    if (args != null && args.isNotEmpty) {
      String res = fallback;
      for (int i = 0; i < args.length; i++) {
        res = res.replaceAll('{$i}', args[i]);
      }
      return res;
    }
    return fallback;
  }
  return val;
}

String _coachTr(String key, String fallback, {List<String>? args}) => coachTr(key, fallback, args: args);
void showCoachNoteDialog(BuildContext context, Child child) {
  final textController = TextEditingController();
  bool isSaving = false;
  final isAdult = child.parentId == 'adult_swimmer';

  // Asynchronously load note from users or children collection
  if (isAdult) {
    FirebaseFirestore.instance.collection('users').doc(child.id).get().then((userDoc) {
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!['notes'] != null) {
        textController.text = userDoc.data()!['notes'].toString();
      } else {
        FirebaseFirestore.instance.collection('children').doc(child.id).get().then((doc) {
          if (doc.exists && doc.data() != null && doc.data()!['notes'] != null) {
            textController.text = doc.data()!['notes'].toString();
          }
        }).catchError((_) {});
      }
    }).catchError((_) {});
  } else {
    FirebaseFirestore.instance.collection('children').doc(child.id).get().then((doc) {
      if (doc.exists && doc.data() != null && doc.data()!['notes'] != null) {
        textController.text = doc.data()!['notes'].toString();
      } else {
        FirebaseFirestore.instance.collection('users').doc(child.id).get().then((userDoc) {
          if (userDoc.exists && userDoc.data() != null && userDoc.data()!['notes'] != null) {
            textController.text = userDoc.data()!['notes'].toString();
          }
        }).catchError((_) {});
      }
    }).catchError((_) {});
  }

  showDialog(
    context: context,
    builder: (ctx) => Consumer(
      builder: (dialogCtx, ref, _) {
        final themeConfig = ref.watch(appThemeControllerProvider);
        final isDark = themeConfig.isDark;

        return StatefulBuilder(
          builder: (stateCtx, setDialogState) => AlertDialog(
            scrollable: true,
            backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                width: isDark ? 1.0 : 1.2,
              ),
            ),
            title: Text(
              _coachTr('coach.note_for', 'Нотатка про плавця {0}', args: [child.name]),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: textController,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _coachTr('coach.note_hint', 'Наприклад: Відпрацювати вдих під праву руку...'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: Text(
                  _coachTr('coach.btn_cancel', 'Скасувати'),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  elevation: isDark ? 0 : 2,
                  shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final note = textController.text.trim();
                        try {
                          if (isAdult) {
                            // 1. Save directly to users collection
                            await FirebaseFirestore.instance.collection('users').doc(child.id).set({
                              'notes': note,
                              'lastUpdated': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            // 2. Also mirror to children collection for backwards compatibility
                            try {
                              await FirebaseFirestore.instance.collection('children').doc(child.id).set({
                                'notes': note,
                                'name': child.name,
                                'lastUpdated': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                            } catch (e) {
                              debugPrint('Mirror adult note to children: $e');
                            }
                          } else {
                            // 1. Always save to children collection with merge (creates doc if it didn't exist)
                            await FirebaseFirestore.instance.collection('children').doc(child.id).set({
                              'notes': note,
                              'name': child.name,
                              'lastUpdated': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            // 2. Also save to users collection in case this swimmer is an adult client/user
                            try {
                              final userDoc = await FirebaseFirestore.instance.collection('users').doc(child.id).get();
                              if (userDoc.exists) {
                                await FirebaseFirestore.instance.collection('users').doc(child.id).set({
                                  'notes': note,
                                  'lastUpdated': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                              }
                            } catch (e) {
                              debugPrint('Could not update note in users collection: $e');
                            }
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_coachTr('coach.save_success', 'Нотатку збережено!')),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error saving coach note: $e');
                          if (ctx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Помилка збереження: $e'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(_coachTr('admin.save', 'Зберегти'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void showSwimmerDetailsSheet(BuildContext context, Child initialChild) {
  final isAdult = initialChild.parentId == 'adult_swimmer';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer(
        builder: (bottomSheetCtx, ref, _) {
          final themeConfig = ref.watch(appThemeControllerProvider);
          final isDark = themeConfig.isDark;

          return StreamBuilder<DocumentSnapshot>(
            stream: isAdult
                ? FirebaseFirestore.instance.collection('users').doc(initialChild.id).snapshots()
                : FirebaseFirestore.instance.collection('children').doc(initialChild.id).snapshots(),
            builder: (bottomSheetContext, snapshot) {
              final docData = (snapshot.hasData && snapshot.data != null && snapshot.data!.exists)
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;

              Child child;
              String? note;
              String? phone;

              if (isAdult) {
                int? adultAge;
                if (docData != null) {
                  note = docData['notes']?.toString();
                  phone = docData['phone']?.toString();
                  if (docData['birthDate'] != null) {
                    try {
                      DateTime birth;
                      if (docData['birthDate'] is Timestamp) {
                        birth = (docData['birthDate'] as Timestamp).toDate();
                      } else {
                        birth = DateTime.parse(docData['birthDate'].toString());
                      }
                      final now = DateTime.now();
                      int age = now.year - birth.year;
                      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
                        age--;
                      }
                      adultAge = age;
                    } catch (_) {}
                  } else if (docData['age'] != null) {
                    adultAge = int.tryParse(docData['age'].toString());
                  }
                  child = Child(
                    id: snapshot.data!.id,
                    name: docData['name']?.toString() ?? initialChild.name,
                    age: adultAge ?? initialChild.age,
                    level: 0,
                    parentId: 'adult_swimmer',
                    branchId: docData['branchId']?.toString() ?? initialChild.branchId,
                  );
                } else {
                  child = initialChild;
                }
              } else {
                child = (docData != null)
                    ? Child.fromJson({'id': snapshot.data!.id, ...docData})
                    : initialChild;
                if (docData != null && docData['notes'] != null) {
                  note = docData['notes'].toString();
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFF0F9FF)],
                        ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                    width: isDark ? 1.0 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : const Color(0xFF0284C7).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top drag bar & close button
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _coachTr('coach.swimmer_details_title', 'ПРОФІЛЬ ТА НОТАТКИ ПЛАВЦЯ'),
                              style: TextStyle(
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.transparent : Colors.white,
                                border: isDark ? null : Border.all(color: const Color(0xFFBAE6FD), width: 1.0),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  color: isDark ? Colors.white60 : const Color(0xFF0284C7),
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Swimmer Hero Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2638) : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                              width: isDark ? 1.0 : 1.1,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isAdult
                                        ? const [Color(0xFF38BDF8), Color(0xFF0284C7)]
                                        : const [Color(0xFF00E5FF), Color(0xFF0077B6)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isAdult ? const Color(0xFF0284C7) : const Color(0xFF00E5FF)).withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isAdult)
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                                                    : const Color(0xFF7DD3FC),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.user,
                                                  size: 11,
                                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'ДОРОСЛИЙ ПЛАВЕЦЬ${((child.currentAge ?? child.age ?? 0) > 0) ? ' • ${child.currentAge ?? child.age} р.' : ''}',
                                                  style: TextStyle(
                                                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark ? const Color(0xFF334155) : const Color(0xFF7DD3FC),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Text(
                                              '${_coachTr('coach.level_label', 'Рівень')} ${child.level}',
                                              style: TextStyle(
                                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0369A1),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if ((child.currentAge ?? child.age ?? 0) > 0) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '${child.currentAge ?? child.age} р.',
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    if (phone != null && phone.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.phone,
                                            size: 12,
                                            color: isDark ? Colors.white54 : const Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            phone,
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Quick Note Action Button
                        GestureDetector(
                          onTap: () => showCoachNoteDialog(context, child),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.fileText, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  note != null && note.trim().isNotEmpty
                                      ? _coachTr('coach.edit_note_btn', 'Редагувати нотатку')
                                      : _coachTr('coach.add_note_btn', 'Додати нотатку про плавця'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Note Section
                        if (note != null && note.trim().isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  LucideIcons.notepadText,
                                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _coachTr('coach.coach_note_label', 'Нотатка тренера:'),
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        note,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          fontSize: 13.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.pencil,
                                    color: isDark ? Colors.white60 : const Color(0xFF0284C7),
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => showCoachNoteDialog(context, child),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                                width: 1.1,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.clipboardEdit,
                                  color: isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF94A3B8),
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _coachTr('coach.no_notes_yet', 'Нотаток ще немає'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _coachTr('coach.no_notes_desc', 'Зафіксуйте прогрес або рекомендації для цього плавця'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

void _confirmCoachLogout(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      title: Text('coach.end_shift'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
        'coach.end_shift_confirm'.tr(),
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('coach.btn_cancel'.tr(), style: const TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref.read(authControllerProvider.notifier).logout();
            } catch (e) {
              debugPrint('Coach logout error: $e');
            }
            ref.read(coachTabProvider.notifier).setTab(0);
            ref.read(goRouterProvider).go('/?skipSplash=true');
          },
          child: Text('coach.btn_logout'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void confirmCoachLogout(BuildContext context, WidgetRef ref) => _confirmCoachLogout(context, ref);
