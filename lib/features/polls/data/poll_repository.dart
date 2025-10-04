import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/poll.dart';

/// Firestore üzerinde anketlerle (polls) ilgili işlemleri yapan repository.
class PollRepository {
  PollRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Aktif anketi getirir (isActive == true). Eğer yoksa en güncelini döner.
  Future<PollModel?> getActivePoll() async {
    try {
      final activeSnap = await _db
          .collection(FirestorePaths.polls)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (activeSnap.docs.isNotEmpty) {
        return PollModel.fromDoc(activeSnap.docs.first);
      }

      final latestSnap = await _db
          .collection(FirestorePaths.polls)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (latestSnap.docs.isNotEmpty) {
        return PollModel.fromDoc(latestSnap.docs.first);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Belirli bir anketi stream olarak dinler.
  Stream<PollModel?> streamPoll(String pollId) {
    return _db
        .collection(FirestorePaths.polls)
        .doc(pollId)
        .snapshots()
        .map((doc) => doc.exists ? PollModel.fromDoc(doc) : null);
  }

  /// Evet oyu verir.
  Future<void> voteYes(String pollId) async {
    final ref = _db.collection(FirestorePaths.polls).doc(pollId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final counts = Map<String, dynamic>.from(data['counts'] ?? {});
      if (counts.isNotEmpty) {
        final curr = (counts['Evet, doğruydu'] ?? 0) as int;
        counts['Evet, doğruydu'] = curr + 1;
        tx.update(ref, {'counts': counts});
      } else {
        final curr = (data['yesCount'] ?? 0) as int;
        tx.update(ref, {'yesCount': curr + 1});
      }
    });
  }

  /// Hayır oyu verir.
  Future<void> voteNo(String pollId) async {
    final ref = _db.collection(FirestorePaths.polls).doc(pollId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final counts = Map<String, dynamic>.from(data['counts'] ?? {});
      if (counts.isNotEmpty) {
        final curr = (counts['Hayır, yanlıştı'] ?? 0) as int;
        counts['Hayır, yanlıştı'] = curr + 1;
        tx.update(ref, {'counts': counts});
      } else {
        final curr = (data['noCount'] ?? 0) as int;
        tx.update(ref, {'noCount': curr + 1});
      }
    });
  }
}
