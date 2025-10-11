import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsSheet extends StatefulWidget {
  final String pollId;

  const CommentsSheet({
    super.key,
    required this.pollId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Güvenli ve anlık yorum gönderme fonksiyonu
  Future<void> _postComment() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    FocusScope.of(context).unfocus(); // Klavyeyi kapat

    try {
      await _firestore
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments')
          .add({
        'text': commentText,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonim',
        'authorPhotoUrl': user.photoURL,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      // Hata yönetimi
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi
    // Klavye açıldığında taşmayı önleyen ve sheet'i yukarı iten yapı
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // Ekranın %75'ini kapla
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Column(
          children: [
            // Orijinal "tutmaç" (handle) tasarımı
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            // Başlık ve kapatma butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yorumlar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // PERFORMANS: Yorum listesi Expanded ile sarmalanarak taşması engellendi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('polls')
                    .doc(widget.pollId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.black));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('İlk yorumu sen yap!',
                            style: TextStyle(color: Colors.grey)));
                  }
                  final comments = snapshot.data!.docs;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index].data() as Map<String, dynamic>;
                      final authorPhotoUrl = comment['authorPhotoUrl'];
                      // Orijinal ListTile tasarımı
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: authorPhotoUrl != null
                              ? NetworkImage(authorPhotoUrl)
                              : null,
                          child: authorPhotoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(comment['authorName'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(comment['text'], style: const TextStyle(fontSize: 14)),
                      );
                    },
                  );
                },
              ),
            ),
            // Orijinal yorum yazma alanı tasarımı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Yorum ekle...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: _postComment,
                    child: const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}