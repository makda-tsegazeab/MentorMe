import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorRecommendation {
  final String tutorId;
  final String name;
  final String? city;
  final List<String> subjects;
  final List<String> gradeLevels;
  final String? sex;
  final double? minPricePerHour;
  final int? hoursPerDay;
  final int? daysPerWeek;
  final double score; // cosine score from backend
  final List<String> reasons; // explanation strings

  TutorRecommendation({
    required this.tutorId,
    required this.name,
    required this.city,
    required this.subjects,
    required this.gradeLevels,
    required this.sex,
    required this.minPricePerHour,
    required this.hoursPerDay,
    required this.daysPerWeek,
    required this.score,
    required this.reasons,
  });

  /// Match percentage (0–100) from cosine score
  int get matchPercent {
    final clamped = score.clamp(0.0, 1.0);
    return (clamped * 100).round();
  }

  factory TutorRecommendation.fromMap(Map<String, dynamic> data) {
    return TutorRecommendation(
      tutorId: data['tutorId'] as String,
      name: (data['name'] ?? 'Tutor') as String,
      city: data['city'] as String?,
      subjects: (data['subjects'] as List<dynamic>? ?? []).cast<String>(),
      gradeLevels: (data['gradeLevels'] as List<dynamic>? ?? []).cast<String>(),
      sex: data['sex'] as String?,
      minPricePerHour: data['minPricePerHour'] == null
          ? null
          : (data['minPricePerHour'] as num).toDouble(),
      hoursPerDay: data['hoursPerDay'] as int?,
      daysPerWeek: data['daysPerWeek'] as int?,
      score: (data['score'] as num).toDouble(),
      reasons: (data['reasons'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class RecommendationsService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  RecommendationsService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<List<TutorRecommendation>> fetchRecommendations(
      {int limit = 20}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final callable = _functions.httpsCallable('cosineRecommend');
    final result = await callable.call({
      'uid': user.uid,
      'limit': limit,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final items = List<Map<String, dynamic>>.from(data['items'] as List);

    return items.map((m) => TutorRecommendation.fromMap(m)).toList();
  }
}
