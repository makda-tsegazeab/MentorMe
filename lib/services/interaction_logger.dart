import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight helper to log learner/tutor interactions.
class InteractionLogger {
  /// Records an interaction in `learner_tutor_interaction`.
  static Future<void> log({
    required String event,
    String? tutorId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('learner_tutor_interaction').add({
        'event': event,
        'userId': user.uid,
        'tutorId': tutorId,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Swallow logging errors; should never block UX.
    }
  }
}
