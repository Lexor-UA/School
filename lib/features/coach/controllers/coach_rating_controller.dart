import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swimming_school_app/core/providers/shared_prefs_provider.dart';
import '../models/coach_rating.dart';

/// In-memory & local-persisted ratings map state:
/// Key: "${classId}_${clientId}" -> CoachRating
class CoachRatingState {
  final Map<String, CoachRating> ratings;
  final bool isLoading;

  const CoachRatingState({
    this.ratings = const {},
    this.isLoading = false,
  });

  CoachRatingState copyWith({
    Map<String, CoachRating>? ratings,
    bool? isLoading,
  }) {
    return CoachRatingState(
      ratings: ratings ?? this.ratings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CoachRatingNotifier extends Notifier<CoachRatingState> {
  static const String _prefKey = 'cached_coach_ratings_v1';

  @override
  CoachRatingState build() {
    final map = <String, CoachRating>{};
    try {
      final prefs = ref.watch(sharedPrefsProvider);
      final cachedJson = prefs.getString(_prefKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is Map<String, dynamic>) {
            map[k] = CoachRating.fromMap(v, k);
          }
        });
      }
    } catch (e) {
      debugPrint('[CoachRatingNotifier] build error: $e');
    }
    return CoachRatingState(ratings: map);
  }

  Future<void> _persistLocalCache() async {
    try {
      final prefs = ref.read(sharedPrefsProvider);
      final mapToSave = <String, dynamic>{};
      state.ratings.forEach((k, v) {
        mapToSave[k] = {
          'id': v.id,
          'classId': v.classId,
          'coachId': v.coachId,
          'coachName': v.coachName,
          'clientId': v.clientId,
          'clientName': v.clientName,
          'stars': v.stars,
          'comment': v.comment,
          'createdAt': v.createdAt.toIso8601String(),
          'updatedAt': v.updatedAt.toIso8601String(),
        };
      });
      await prefs.setString(_prefKey, jsonEncode(mapToSave));
    } catch (e) {
      debugPrint('[CoachRatingNotifier] _persistLocalCache error: $e');
    }
  }

  /// Rates a coach for a given class. Updates local state instantly and syncs to Firestore.
  Future<void> rateCoach({
    required String classId,
    required String coachId,
    required String coachName,
    required String clientId,
    required String clientName,
    required int stars,
    String? comment,
  }) async {
    final key = '${classId}_$clientId';
    final now = DateTime.now();

    final rating = CoachRating(
      id: key,
      classId: classId,
      coachId: coachId,
      coachName: coachName,
      clientId: clientId,
      clientName: clientName,
      stars: stars.clamp(1, 5),
      comment: comment,
      createdAt: state.ratings[key]?.createdAt ?? now,
      updatedAt: now,
    );

    // 1. Instant optimistic state update
    final updated = Map<String, CoachRating>.from(state.ratings);
    updated[key] = rating;
    state = state.copyWith(ratings: updated);

    // 2. Persist to local storage
    await _persistLocalCache();

    // 3. Sync to Firestore (resilient against offline / mock mode)
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('coach_ratings').doc(key).set(
            rating.toMap(),
            SetOptions(merge: true),
          );

      // Recalculate coach average rating in users collection if coachId is valid
      if (coachId.isNotEmpty && coachId != 'unassigned') {
        try {
          final querySnap = await firestore
              .collection('coach_ratings')
              .where('coachId', isEqualTo: coachId)
              .get();

          if (querySnap.docs.isNotEmpty) {
            double totalStars = 0;
            for (final d in querySnap.docs) {
              totalStars += ((d.data()['stars'] as num?)?.toInt() ?? 5);
            }
            final avgRating = totalStars / querySnap.docs.length;
            await firestore.collection('users').doc(coachId).set({
              'rating': double.parse(avgRating.toStringAsFixed(1)),
              'ratingCount': querySnap.docs.length,
            }, SetOptions(merge: true));
          }
        } catch (_) {
          // Non-critical background aggregation
        }
      }
    } catch (e) {
      debugPrint('[CoachRatingNotifier] Firestore sync ignored or offline: $e');
    }
  }

  /// Fetch rating from Firestore if not yet loaded
  Future<void> loadRatingForClass(String classId, String clientId) async {
    final key = '${classId}_$clientId';
    if (state.ratings.containsKey(key)) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('coach_ratings').doc(key).get();
      if (doc.exists && doc.data() != null) {
        final r = CoachRating.fromMap(doc.data()!, doc.id);
        final updated = Map<String, CoachRating>.from(state.ratings);
        updated[key] = r;
        state = state.copyWith(ratings: updated);
        await _persistLocalCache();
      }
    } catch (_) {}
  }
}

final coachRatingControllerProvider =
    NotifierProvider<CoachRatingNotifier, CoachRatingState>(() {
  return CoachRatingNotifier();
});

/// Returns the rating (1..5) for a specific class and client, or null if unrated.
final classRatingProvider = Provider.family<int?, ({String classId, String clientId})>((ref, arg) {
  final state = ref.watch(coachRatingControllerProvider);
  final key = '${arg.classId}_${arg.clientId}';
  return state.ratings[key]?.stars;
});

/// Returns a pair of (averageRating, count) for a coach by ID or Name.
final coachAverageRatingProvider = Provider.family<({double rating, int count}), String>((ref, coachIdentifier) {
  final state = ref.watch(coachRatingControllerProvider);
  final idLower = coachIdentifier.toLowerCase().trim();
  final coachRatings = state.ratings.values.where((r) {
    if (r.coachId.isNotEmpty && r.coachId.toLowerCase() == idLower) return true;
    if (r.coachName.isNotEmpty) {
      final nameLower = r.coachName.toLowerCase().trim();
      if (nameLower == idLower || idLower.contains(nameLower) || nameLower.contains(idLower)) {
        return true;
      }
    }
    return false;
  }).toList();

  if (coachRatings.isEmpty) {
    return (rating: 5.0, count: 0);
  }

  final total = coachRatings.fold<double>(0.0, (acc, r) => acc + r.stars);
  final avg = total / coachRatings.length;
  return (rating: double.parse(avg.toStringAsFixed(1)), count: coachRatings.length);
});
