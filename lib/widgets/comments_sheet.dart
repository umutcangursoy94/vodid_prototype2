import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/user_profile_screen.dart';

class CommentsSheet extends StatefulWidget {
  final String pollId;
  final ScrollController? scrollController;
  final String? highlightedCommentId; // EKLENDİ

  const CommentsSheet({
    super.key,
    required this.pollId,
    this.scrollController,
    this.highlightedCommentId, // EKLENDİ
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  bool _isPosting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isPosting) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız.')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      final pollRef = _db.collection('polls').doc(widget.pollId);
      final commentRef = pollRef.collection('comments').doc();
      final userRef = _db.collection('users').doc(user.uid);

      final writeBatch = _db.batch();
      writeBatch.set(commentRef, {
        'text': text,
        'authorId': user.uid,
        'authorUsername': userData?['username'] ?? 'anonymous',
        'authorPhotoUrl': userData?['photoURL'],
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });
      writeBatch.update(pollRef, {'commentsCount': FieldValue.increment(1)});
      writeBatch.update(userRef, {'commentsCount': FieldValue.increment(1)});

      await writeBatch.commit();
      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCommentsList()),
          if (_auth.currentUser != null) _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Henüz yorum yapılmamış.\nİlk yorumu sen yap!',
                textAlign: TextAlign.center),
          );
        }
        final comments = snapshot.data!.docs;
        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final data = comment.data() as Map<String, dynamic>;
            final isHighlighted = comment.id == widget.highlightedCommentId;

            return _CommentTile(data: data, isHighlighted: isHighlighted);
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  hintText: 'Yorumunu ekle...',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (_) => _postComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isPosting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.data, this.isHighlighted = false});

  final Map<String, dynamic> data;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: data['authorId']),
              ));
            },
            child: CircleAvatar(
              backgroundImage: data['authorPhotoUrl'] != null
                  ? NetworkImage(data['authorPhotoUrl'])
                  : null,
              child: data['authorPhotoUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['authorUsername'] ?? 'Kullanıcı',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(data['text'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}