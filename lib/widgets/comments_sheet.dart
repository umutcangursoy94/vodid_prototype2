import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vodid_prototype2/user_profile_screen.dart';

class CommentsSheet extends StatefulWidget {
  final String pollId;
  final ScrollController? scrollController;
  final String? highlightedCommentId;

  const CommentsSheet({
    super.key,
    required this.pollId,
    this.scrollController,
    this.highlightedCommentId,
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
        'likesCount': 0, // Beğeni sayacı eklendi
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

            return _CommentTile(
              pollId: widget.pollId,
              commentId: comment.id,
              data: data,
              isHighlighted: isHighlighted,
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
    return Material(
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
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

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.pollId,
    required this.commentId,
    required this.data,
    this.isHighlighted = false,
  });

  final String pollId;
  final String commentId;
  final Map<String, dynamic> data;
  final bool isHighlighted;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  
  bool _isLiked = false;
  late int _likesCount;
  bool _isProcessingLike = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.data['likesCount'] ?? 0;
    _checkIfLiked();
  }

  void _checkIfLiked() {
    final user = _auth.currentUser;
    if (user == null) return;

    _db
        .collection('polls')
        .doc(widget.pollId)
        .collection('comments')
        .doc(widget.commentId)
        .collection('likes')
        .doc(user.uid)
        .get()
        .then((doc) {
      if (mounted && doc.exists) {
        setState(() => _isLiked = true);
      }
    });
  }

  Future<void> _toggleLike() async {
    if (_isProcessingLike) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beğenmek için giriş yapmalısınız.')),
      );
      return;
    }
    
    setState(() => _isProcessingLike = true);

    // ---- Optimistic UI Başlangıcı ----
    final previousLikedState = _isLiked;
    final previousLikesCount = _likesCount;
    
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesCount++ : _likesCount--;
    });
    // ---- Optimistic UI Bitişi ----

    try {
      HapticFeedback.lightImpact();
      final commentRef = _db
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments')
          .doc(widget.commentId);
      final likeRef = commentRef.collection('likes').doc(user.uid);

      if (_isLiked) { // Beğenme işlemi
        await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
        await commentRef.update({'likesCount': FieldValue.increment(1)});
      } else { // Beğeniyi geri alma işlemi
        await likeRef.delete();
        await commentRef.update({'likesCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      // Hata olursa, arayüzü eski haline döndür
      setState(() {
        _isLiked = previousLikedState;
        _likesCount = previousLikesCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız oldu.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isHighlighted
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
                builder: (_) => UserProfileScreen(userId: widget.data['authorId']),
              ));
            },
            child: CircleAvatar(
              backgroundImage: widget.data['authorPhotoUrl'] != null
                  ? NetworkImage(widget.data['authorPhotoUrl'])
                  : null,
              child: widget.data['authorPhotoUrl'] == null
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
                  widget.data['authorUsername'] ?? 'Kullanıcı',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.data['text'] ?? ''),
              ],
            ),
          ),
          // --- BEĞENME BUTONU VE SAYACI ---
          Column(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
              Text(
                _likesCount.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}