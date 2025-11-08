import 'package:cloud_firestore/cloud_firestore.dart';

class MatchFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String matchId;

  MatchFirestoreService(this.matchId);

  /// Create a new match document
  Future<void> createMatch(Map<String, dynamic> matchData) async {
    await _db.collection('matches').doc(matchId).set(matchData);
  }

  /// Update a field or nested map
  Future<void> updateMatch(Map<String, dynamic> data) async {
    await _db.collection('matches').doc(matchId).update(data);
  }

  /// Listen to match changes
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamMatch() {
    return _db.collection('matches').doc(matchId).snapshots();
  }
}
