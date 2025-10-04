import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'daki yorum belgelerini temsil eden model.
/// Hem üst seviye yorumlar hem de yanıtlar için kullanılır.
class CommentModel {
  final String id;
  final String text;
  final String userId;
  final String displayName;
  final int likeCount;
  final DateTime? createdAt;

  CommentModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.displayName,
    required this.likeCount,
    required this.createdAt,
  });

  /// Firestore dokümanından model oluşturur.
  factory CommentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      displayName: (data['displayName'] ?? '').toString(),
      likeCount: (data['likeCount'] ?? 0) is int ? data['likeCount'] as int : 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Modele göre Firestore’a kaydedilecek map
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'displayName': displayName,
      'likeCount': likeCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
