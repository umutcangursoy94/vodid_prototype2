/// Firestore koleksiyon ve döküman yolları burada merkezi olarak tanımlanır.
/// Böylece kod içinde string sabitler yerine bu fonksiyonlar kullanılır.
class FirestorePaths {
  FirestorePaths._();

  // Ana koleksiyonlar
  static const String polls = 'polls';

  // Yorumlar
  static String pollComments(String pollId) => 'polls/$pollId/comments';

  // Yanıtlar
  static String pollCommentReplies(String pollId, String commentId) =>
      'polls/$pollId/comments/$commentId/replies';
}
