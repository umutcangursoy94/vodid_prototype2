import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/firestore_paths.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

/// Geliştirme ve test için admin seed ekranı.
/// Firestore'a sahte anketler, yorumlar eklemek için kullanılır.
class DevAdminSeedScreen extends StatefulWidget {
  const DevAdminSeedScreen({super.key});

  @override
  State<DevAdminSeedScreen> createState() => _DevAdminSeedScreenState();
}

class _DevAdminSeedScreenState extends State<DevAdminSeedScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = false;

  Future<void> _addSamplePoll() async {
    setState(() => _loading = true);
    try {
      await _db.collection(FirestorePaths.polls).add({
        'question': 'Sence yapay zekâ gelecekte işleri yok edecek mi?',
        'options': ['Evet', 'Hayır'],
        'counts': {'Evet': 0, 'Hayır': 0},
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'order': DateTime.now().millisecondsSinceEpoch,
        'commentsCount': 0,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Örnek anket eklendi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSampleComment(String pollId) async {
    setState(() => _loading = true);
    try {
      await _db.collection(FirestorePaths.pollComments(pollId)).add({
        'text': 'Bence bu çok önemli bir konu!',
        'userId': 'demoUser',
        'displayName': 'Deneme Kullanıcı',
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection(FirestorePaths.polls).doc(pollId).update({
        'commentsCount': FieldValue.increment(1),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Örnek yorum eklendi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSampleReply(String pollId, String commentId) async {
    setState(() => _loading = true);
    try {
      await _db
          .collection(FirestorePaths.pollCommentReplies(pollId, commentId))
          .add({
        'text': 'Katılıyorum 👍',
        'userId': 'demoUser2',
        'displayName': 'Başka Kullanıcı',
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Örnek yanıt eklendi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _addSamplePoll,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createPoll),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _loading ? null : () => _addSampleComment('testPollId'),
              icon: const Icon(Icons.comment),
              label: const Text(AppStrings.addSampleComment),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _addSampleReply('testPollId', 'testCommentId'),
              icon: const Icon(Icons.reply),
              label: const Text(AppStrings.addSampleReply),
            ),
          ],
        ),
      ),
    );
  }
}
