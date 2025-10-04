import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vodid_prototype2/core/utils/slugify.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

/// Firestore'a hızlı şekilde anket ve örnek veri eklemek için admin ekranı.
/// Geliştirme/test amaçlıdır, production'da kaldırılabilir.
class DevAdminSeedScreen extends StatefulWidget {
  const DevAdminSeedScreen({super.key});

  @override
  State<DevAdminSeedScreen> createState() => _DevAdminSeedScreenState();
}

class _DevAdminSeedScreenState extends State<DevAdminSeedScreen> {
  final _formKey = GlobalKey<FormState>();

  final _questionCtrl = TextEditingController(
    text: 'Sence Fatih Altaylı\'nın tutukluluk kararı doğru muydu?',
  );
  final _summaryCtrl = TextEditingController(
    text:
        '“Kalemlerin sustuğu bir gece... Tanınmış gazeteci hakkında verilen tutuklama kararı, ifade özgürlüğü tartışmalarını yeniden alevlendirdi.”',
  );
  final _videoUrlCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController(
    text: 'Evet, doğruydu\nHayır, yanlıştı',
  );
  final _orderCtrl = TextEditingController(text: '1');

  bool _isActive = true;
  String? _selectedPollId;

  CollectionReference<Map<String, dynamic>> get _polls =>
      FirebaseFirestore.instance.collection('polls');

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    final q = _questionCtrl.text.trim();
    final summary = _summaryCtrl.text.trim();
    final videoUrl = _videoUrlCtrl.text.trim();
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 1;

    final rawOptions = _optionsCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rawOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az iki seçenek girin.')),
      );
      return;
    }

    final counts = {for (final opt in rawOptions) opt: 0};

    final docId = Slugify.generate(q);
    final data = {
      'question': q,
      'question_lowercase': q.toLowerCase(),
      'options': rawOptions,
      'counts': counts,
      'commentsCount': 0,
      'isActive': _isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'order': order,
      if (summary.isNotEmpty) 'news_summary': summary,
      if (videoUrl.isNotEmpty) 'videoUrl': videoUrl,
    };

    try {
      await _polls.doc(docId).set(data);
      setState(() => _selectedPollId = docId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Anket oluşturuldu: $docId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  Future<void> _toggleActive(String pollId, bool active) async {
    try {
      await _polls.doc(pollId).update({'isActive': active});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('isActive = $active olarak güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  Future<void> _addSampleComment(String pollId) async {
    try {
      final commentRef = await _polls.doc(pollId).collection('comments').add({
        'text': 'İlk yorum (örnek)',
        'userId': 'demoUserId',
        'displayName': 'Umut',
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _polls.doc(pollId).update({
        'commentsCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Yorum eklendi: ${commentRef.id}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  Future<void> _addSampleReply(String pollId) async {
    try {
      final commentsSnap = await _polls
          .doc(pollId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (commentsSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce bir yorum ekleyin.')),
        );
        return;
      }

      final lastComment = commentsSnap.docs.first;

      final replyRef = await _polls
          .doc(pollId)
          .collection('comments')
          .doc(lastComment.id)
          .collection('replies')
          .add({
        'text': 'Bu da o yoruma yanıt (örnek)',
        'userId': 'demoUserId2',
        'displayName': 'Ziyaretçi',
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Yanıt eklendi: ${replyRef.id}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.adminTitle)),
      body: Row(
        children: [
          // Sol taraf: mevcut anketler listesi
          SizedBox(
            width: 350,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _polls.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Henüz anket yok.'));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final isActive = (data['isActive'] ?? false) as bool;
                    return ListTile(
                      title: Text(
                        data['question'] ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('id: ${d.id}'),
                      trailing: Switch(
                        value: isActive,
                        onChanged: (v) => _toggleActive(d.id, v),
                      ),
                      selected: _selectedPollId == d.id,
                      onTap: () => setState(() => _selectedPollId = d.id),
                    );
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),

          // Sağ taraf: anket oluşturma + aksiyonlar
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _questionCtrl,
                      decoration: const InputDecoration(labelText: 'Soru'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Soru girin' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _optionsCtrl,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          labelText: 'Seçenekler (her satıra bir)'),
                      validator: (v) {
                        final lines = (v ?? '')
                            .split('\n')
                            .where((e) => e.trim().isNotEmpty)
                            .toList();
                        return lines.length < 2
                            ? 'En az iki seçenek girilmeli'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _summaryCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Haber özeti'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _videoUrlCtrl,
                      decoration: const InputDecoration(labelText: 'Video URL'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orderCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Order (öncelik)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Aktif mi?'),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _createPoll,
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.createPoll),
                    ),
                    const Divider(height: 32),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectedPollId == null
                              ? null
                              : () => _addSampleComment(_selectedPollId!),
                          icon: const Icon(Icons.chat),
                          label: const Text(AppStrings.addSampleComment),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectedPollId == null
                              ? null
                              : () => _addSampleReply(_selectedPollId!),
                          icon: const Icon(Icons.reply),
                          label: const Text(AppStrings.addSampleReply),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
