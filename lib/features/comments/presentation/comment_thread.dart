import 'package:flutter/material.dart';
import 'package:vodid_prototype2/features/comments/data/comment_service.dart';
import 'package:vodid_prototype2/features/comments/models/comment.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';
import 'package:vodid_prototype2/core/widgets/loading.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

class CommentThreadPage extends StatelessWidget {
  const CommentThreadPage({
    super.key,
    required this.pollId,
    this.parentComment,
  });

  final String pollId;
  final CommentModel? parentComment;

  @override
  Widget build(BuildContext context) {
    final isReplyPage = parentComment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReplyPage ? AppStrings.replies : AppStrings.comments),
      ),
      body: Column(
        children: [
          if (isReplyPage) _ParentCommentCard(comment: parentComment!),
          Expanded(
            child: _CommentList(
              pollId: pollId,
              parentComment: parentComment,
            ),
          ),
          _CommentInput(
            pollId: pollId,
            parentComment: parentComment,
          ),
        ],
      ),
    );
  }
}

class _CommentList extends StatelessWidget {
  const _CommentList({required this.pollId, required this.parentComment});

  final String pollId;
  final CommentModel? parentComment;

  @override
  Widget build(BuildContext context) {
    final service = CommentService();
    final stream = parentComment == null
        ? service.streamComments(pollId)
        : service.streamReplies(pollId, parentComment!.id);

    return StreamBuilder<List<CommentModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loading(fullscreen: false);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(message: AppStrings.noCommentsYet);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
          itemBuilder: (context, i) => _CommentTile(
            pollId: pollId,
            comment: items[i],
            parentComment: parentComment,
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.pollId,
    required this.comment,
    required this.parentComment,
  });

  final String pollId;
  final CommentModel comment;
  final CommentModel? parentComment;

  @override
  Widget build(BuildContext context) {
    final isReply = parentComment != null;
    final timeStr = comment.createdAt != null
        ? TimeOfDay.fromDateTime(comment.createdAt!).format(context)
        : 'şimdi';

    return ListTile(
      leading: const Icon(Icons.person),
      title: Text(
        comment.displayName.isEmpty ? 'Anonim' : comment.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(comment.text),
      ),
      trailing: Text(
        timeStr,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        if (!isReply) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentThreadPage(
                pollId: pollId,
                parentComment: comment,
              ),
            ),
          );
        }
      },
    );
  }
}

class _CommentInput extends StatefulWidget {
  const _CommentInput({required this.pollId, required this.parentComment});

  final String pollId;
  final CommentModel? parentComment;

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _controller = TextEditingController();
  bool _sending = false;

  String get _userId =>
      'demoUserId'; // TODO: FirebaseAuth entegrasyonu eklenecek
  String get _displayName => 'Kullanıcı';

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await CommentService().addComment(
        pollId: widget.pollId,
        text: text,
        userId: _userId,
        displayName: _displayName,
        parentCommentId: widget.parentComment?.id,
      );
      _controller.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.sendFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReply = widget.parentComment != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      isReply ? AppStrings.writeReply : AppStrings.writeComment,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentCommentCard extends StatelessWidget {
  const _ParentCommentCard({required this.comment});
  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final timeStr = comment.createdAt != null
        ? TimeOfDay.fromDateTime(comment.createdAt!).format(context)
        : 'şimdi';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.forum),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.displayName.isEmpty
                        ? 'Anonim'
                        : comment.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(comment.text),
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall,
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
