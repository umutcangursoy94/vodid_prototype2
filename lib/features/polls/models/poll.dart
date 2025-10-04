import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'daki anket belgelerini temsil eden model.
class PollModel {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> counts;
  final bool isActive;
  final DateTime? createdAt;
  final int order;
  final String? newsSummary;
  final String? videoUrl;

  PollModel({
    required this.id,
    required this.question,
    required this.options,
    required this.counts,
    required this.isActive,
    required this.createdAt,
    required this.order,
    this.newsSummary,
    this.videoUrl,
  });

  factory PollModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PollModel(
      id: doc.id,
      question: (data['question'] ?? '').toString(),
      options: List<String>.from(data['options'] ?? []),
      counts: Map<String, int>.from(
          (data['counts'] ?? {}).map((k, v) => MapEntry(k, v as int))),
      isActive: (data['isActive'] ?? false) as bool,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      order: (data['order'] ?? 0) as int,
      newsSummary: data['news_summary']?.toString(),
      videoUrl: data['videoUrl']?.toString(),
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
      'order': order,
      if (newsSummary != null) 'news_summary': newsSummary,
      if (videoUrl != null) 'videoUrl': videoUrl,
    };
  }
}
