import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vodid_prototype2/core/constants/firestore_paths.dart';
import 'package:vodid_prototype2/features/polls/models/poll.dart';

/// Firestore üzerinde anketlerle ilgili işlemleri yöneten repository.
class PollRepository {
  PollRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Aktif anketleri stream olarak getirir.
  Stream<List<Poll>> streamActivePolls() {
    return _db
        .collection(FirestorePaths.polls)
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Poll.fromDoc(doc)).toList());
  }

  /// Belirli bir anketi getir.
  Future<Poll?> getPollById(String pollId) async {
    final doc = await _db.collection(FirestorePaths.polls).doc(pollId).get();
    if (!doc.exists) return null;
    return Poll.fromDoc(doc);
  }

  /// Yeni anket ekle.
  Future<void> addPoll(Poll poll) async {
    await _db.collection(FirestorePaths.polls).add(poll.toMap());
  }

  /// Oy kullan.
  Future<void> vote({
    required String pollId,
    required String option,
  }) async {
    final ref = _db.collection(FirestorePaths.polls).doc(pollId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final counts = Map<String, dynamic>.from(data['counts'] ?? {});
      final current = (counts[option] ?? 0) as int;
      counts[option] = current + 1;
      tx.update(ref, {'counts': counts});
    });
  }

  /// Anketi pasif hale getir.
  Future<void> deactivatePoll(String pollId) async {
    await _db.collection(FirestorePaths.polls).doc(pollId).update({
      'isActive': false,
    });
  }
}
