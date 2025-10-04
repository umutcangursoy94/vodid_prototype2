import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'daki anket belgelerini temsil eden model.
class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> counts;
  final bool isActive;
  final DateTime? createdAt;
  final int commentsCount;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.counts,
    required this.isActive,
    required this.createdAt,
    required this.commentsCount,
  });

  factory Poll.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Poll(
      id: doc.id,
      question: (data['question'] ?? '').toString(),
      options:
          (data['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      counts: (data['counts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value ?? 0) as int),
          ) ??
          {},
      isActive: (data['isActive'] ?? false) as bool,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      commentsCount: (data['commentsCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'counts': counts,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'order': DateTime.now().millisecondsSinceEpoch,
      'commentsCount': commentsCount,
    };
  }
}
