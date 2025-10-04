/// Firestore koleksiyon ve doküman yolları için sabitler.
/// Tüm servisler ve widget'lar bu sınıf üzerinden referans almalı.
class FirestorePaths {
  // Ana koleksiyon
  static const String polls = 'polls';

  // Alt koleksiyonlar
  static String poll(String pollId) => '$polls/$pollId';
  static String pollComments(String pollId) => '$polls/$pollId/comments';
  static String pollComment(String pollId, String commentId) =>
      '$polls/$pollId/comments/$commentId';
  static String pollCommentReplies(String pollId, String commentId) =>
      '$polls/$pollId/comments/$commentId/replies';
  static String pollCommentReply(
          String pollId, String commentId, String replyId) =>
      '$polls/$pollId/comments/$commentId/replies/$replyId';

  // Opsiyonel: votes koleksiyonu (eğer kullanıyorsan)
  static String pollVotes(String pollId) => '$polls/$pollId/votes';
  static String pollVote(String pollId, String voteId) =>
      '$polls/$pollId/votes/$voteId';
}
