import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Etiketlenmiş metni oluşturan yardımcı fonksiyon
Widget buildCommentText(String text, BuildContext context) {
  final List<TextSpan> textSpans = [];
  final RegExp mentionRegex = RegExp(r"(@\w+)");

  text.splitMapJoin(
    mentionRegex,
    onMatch: (Match match) {
      final mention = match.group(0)!;
      textSpans.add(
        TextSpan(
          text: mention,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Gelecekte etiketlenen kullanıcının profiline gitme eklenebilir.
            },
        ),
      );
      return '';
    },
    onNonMatch: (String nonMatch) {
      textSpans.add(TextSpan(text: nonMatch));
      return '';
    },
  );

  return RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context)
          .style
          .copyWith(fontSize: 15, height: 1.3),
      children: textSpans,
    ),
  );
}

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
  final _auth = FirebaseAuth.instance;
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _initialScrollDone = false;

  CollectionReference<Map<String, dynamic>> get _commentsCol =>
      FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments');

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
      final callable = FirebaseFunctions.instance.httpsCallable('addComment');
      await callable.call({
        'pollId': widget.pollId,
        'text': raw,
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

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
                        key: ValueKey(docs[i].id),
                        pollId: widget.pollId,
                        snap: docs[i],
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
          Text('Yorumlar', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(
            tooltip: 'Kapat',
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

class _CommentTile extends StatefulWidget {
  final String pollId;
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final bool isHighlighted;

  const _CommentTile(
      {super.key,
      required this.pollId,
      required this.snap,
      this.isHighlighted = false});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplyInput = false;
  bool _showReplies = false;
  final _replyCtrl = TextEditingController();
  bool _isSendingReply = false;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  Future<void> _likeComment() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('likeComment');
      await callable.call({
        'pollId': widget.pollId,
        'commentId': widget.snap.id,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beğenme işlemi başarısız: $e')),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addReply');
      await callable.call({
        'pollId': widget.pollId,
        'commentId': widget.snap.id,
        'text': text,
      });
      _replyCtrl.clear();
      setState(() => _showReplyInput = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yanıt gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
      }
    }
  }

  void _handleReplyTap() {
    final commentData = widget.snap.data();
    if (commentData == null) return;

    final username = commentData['username'] as String?;

    setState(() {
      _showReplyInput = !_showReplyInput; // Her dokunuşta aç/kapa
      if (_showReplyInput && username != null && username.isNotEmpty) {
        _replyCtrl.text = '@$username ';
        _replyCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _replyCtrl.text.length),
        );
      } else {
        _replyCtrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.snap.data() ?? const {};
    final text = (d['text'] ?? '') as String;
    final displayName = (d['displayName'] ?? 'Anonymous') as String;
    final photoURL = d['photoURL'] as String?;
    final likeCount = (d['likeCount'] ?? 0) as int;
    final replyCount = (d['replyCount'] ?? 0) as int;
    final likes = (d['likes'] as Map<String, dynamic>?) ?? {};
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && likes[currentUser.uid] == true;
    final ts = d['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? Theme.of(context).colorScheme.primary.withAlpha(26)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    buildCommentText(text, context),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: _handleReplyTap,
                          child: const Text(
                            'Yanıtla',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _likeComment,
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              if (likeCount > 0)
                                Text(
                                  likeCount.toString(),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showReplyInput)
            Padding(
              padding: const EdgeInsets.only(left: 52.0, top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      autofocus: true,
                      decoration:
                          const InputDecoration(hintText: 'Yanıt yaz...'),
                    ),
                  ),
                  IconButton(
                    icon: _isSendingReply
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _isSendingReply ? null : _sendReply,
                  )
                ],
              ),
            ),
          if (replyCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 52.0, top: 8.0),
              child: InkWell(
                onTap: () => setState(() => _showReplies = !_showReplies),
                child: Text(
                  _showReplies
                      ? 'Yanıtları gizle'
                      : '$replyCount yanıtı göster',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_showReplies)
            Padding(
              padding: const EdgeInsets.only(left: 32.0, top: 8.0),
              child: _RepliesList(
                  pollId: widget.pollId, commentId: widget.snap.id),
            ),
        ],
      ),
    );
  }
}

class _RepliesList extends StatelessWidget {
  final String pollId;
  final String commentId;

  const _RepliesList({required this.pollId, required this.commentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final replies = snapshot.data!.docs;
        return Column(
          children: replies
              .map((doc) => _ReplyTile(
                  snap: doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList(),
        );
      },
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  const _ReplyTile({required this.snap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final data = snap.data() ?? {};
    final text = data['text'] as String? ?? '';
    final displayName = data['displayName'] as String? ?? 'Anonim';
    final photoURL = data['photoURL'] as String?;
    final ts = data['createdAt'];
    DateTime? createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                ? NetworkImage(photoURL)
                : null,
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A')
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                buildCommentText(text, context),
              ],
            ),
          ),
        ],
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
