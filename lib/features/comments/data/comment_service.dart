import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/comment.dart';

/// Firestore üzerinde yorumlar ve yanıtlarla ilgili işlemleri yapan servis.
class CommentService {
  CommentService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Belirli bir anketin yorumlarını stream olarak getirir.
  Stream<List<CommentModel>> streamComments(String pollId) {
    return _db
        .collection(FirestorePaths.pollComments(pollId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromDoc(doc)).toList());
  }

  /// Belirli bir yoruma ait yanıtları stream olarak getirir.
  Stream<List<CommentModel>> streamReplies(String pollId, String commentId) {
    return _db
        .collection(FirestorePaths.pollCommentReplies(pollId, commentId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromDoc(doc)).toList());
  }

  /// Yeni yorum veya yanıt ekler.
  Future<void> addComment({
    required String pollId,
    required String text,
    required String userId,
    required String displayName,
    String? parentCommentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final data = {
      'text': trimmed,
      'userId': userId,
      'displayName': displayName,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (parentCommentId == null) {
      // Üst seviye yorum
      await _db.collection(FirestorePaths.pollComments(pollId)).add(data);

      // İstersen commentsCount alanını artır
      await _db.collection(FirestorePaths.polls).doc(pollId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } else {
      // Yanıt
      await _db
          .collection(
              FirestorePaths.pollCommentReplies(pollId, parentCommentId))
          .add(data);
    }
  }

  /// Like sayısını artırır veya azaltır.
  Future<void> incrementLike({
    required String pollId,
    required String commentId,
    String? parentCommentId,
    int delta = 1,
  }) async {
    final ref = parentCommentId == null
        ? _db.collection(FirestorePaths.pollComments(pollId)).doc(commentId)
        : _db
            .collection(
                FirestorePaths.pollCommentReplies(pollId, parentCommentId))
            .doc(commentId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['likeCount'] ?? 0) as int;
      tx.update(ref, {'likeCount': current + delta});
    });
  }
}
