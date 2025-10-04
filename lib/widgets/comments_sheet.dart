import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentsSheet extends StatefulWidget {
  final String pollId;
  final String? highlightedCommentId;

  const CommentsSheet({
    super.key,
    required this.pollId,
    this.highlightedCommentId,
  });

  static Future<void> show(BuildContext context,
      {required String pollId, String? highlightedCommentId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        pollId: pollId,
        highlightedCommentId: highlightedCommentId,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _initialScrollDone = false;

  CollectionReference<Map<String, dynamic>> get _commentsCol =>
      _db.collection('polls').doc(widget.pollId).collection('comments');

  DocumentReference<Map<String, dynamic>> get _pollDoc =>
      _db.collection('polls').doc(widget.pollId);

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) return;
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final user = _auth.currentUser!;
      final userDocRef = _db.collection('users').doc(user.uid);

      final pollSnap = await _pollDoc.get();
      final pollData = pollSnap.data();
      final pollQuestion = pollData?['question'] as String? ?? 'Anket Başlığı';
      final pollImageUrl = pollData?['imageUrl'] as String? ?? '';

      final data = <String, dynamic>{
        'text': raw,
        'uid': user.uid,
        'displayName': user.displayName ?? 'Misafir',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'pollId': widget.pollId,
        'pollQuestion': pollQuestion,
        'pollImageUrl': pollImageUrl,
      };

      await _db.runTransaction((tx) async {
        tx.set(_commentsCol.doc(), data);
        tx.update(_pollDoc, {'commentsCount': FieldValue.increment(1)});
        tx.update(userDocRef, {'commentsCount': FieldValue.increment(1)});
      });

      _textCtrl.clear();
      _focusNode.unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Yorum gönderilemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteOwnComment(
      DocumentSnapshot<Map<String, dynamic>> snap) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || snap.data()?['uid'] != uid) return;

    try {
      final userDocRef = _db.collection('users').doc(uid);

      await _db.runTransaction((tx) async {
        tx.delete(snap.reference);
        tx.update(_pollDoc, {'commentsCount': FieldValue.increment(-1)});
        tx.update(userDocRef, {'commentsCount': FieldValue.increment(-1)});
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Yorum silindi.'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Silinemedi: $e'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const _DragHandle(),
              const _Header(),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _commentsCol
                      .orderBy('createdAt', descending: true)
                      .limit(200)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const _EmptyState();
                    }

                    if (widget.highlightedCommentId != null &&
                        !_initialScrollDone) {
                      final index = docs.indexWhere(
                          (doc) => doc.id == widget.highlightedCommentId);
                      if (index != -1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final position = index * 80.0;
                          if (mounted) {
                            _scrollController.animateTo(
                              position,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                            _initialScrollDone = true;
                          }
                        });
                      }
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemBuilder: (_, i) => _CommentTile(
                        snap: docs[i],
                        onLongPressDelete: () => _deleteOwnComment(docs[i]),
                        isHighlighted:
                            docs[i].id == widget.highlightedCommentId,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: docs.length,
                    );
                  },
                ),
              ),
              _InputBar(
                controller: _textCtrl,
                focusNode: _focusNode,
                sending: _sending,
                onSend: _sendComment,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
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
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Text('Comments', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'İlk yorumu sen yap 🎉',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final VoidCallback? onLongPressDelete;
  final bool isHighlighted;

  const _CommentTile(
      {required this.snap, this.onLongPressDelete, this.isHighlighted = false});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final d = snap.data() ?? const {};
    final text = (d['text'] ?? '') as String;
    final displayName = (d['displayName'] ?? 'Anonymous') as String;
    final photoURL = d['photoURL'] as String?;
    final ts = d['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
        color: isHighlighted
            ? Theme.of(context).colorScheme.primary.withAlpha(26)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onLongPress: onLongPressDelete,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                  ? NetworkImage(photoURL)
                  : null,
              child: (photoURL == null || photoURL.isEmpty)
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(created),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Yorum ekle…',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
