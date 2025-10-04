import 'package:flutter/material.dart';
import 'package:vodid_prototype2/features/polls/models/poll.dart';
import 'package:vodid_prototype2/features/comments/presentation/comment_thread.dart';

/// Tek bir anketi (poll) kart görünümünde gösteren widget.
/// Kullanıcı oy verebilir ve yorumlara gidebilir.
class PollCard extends StatefulWidget {
  final Poll poll;

  const PollCard({super.key, required this.poll});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String? _selectedOption;
  bool _voted = false;

  void _vote(String option) {
    if (_voted) return; // Tekrar oy verilmesini engelle
    setState(() {
      _selectedOption = option;
      _voted = true;
    });

    // TODO: PollRepository.vote() ile Firestore’a kaydet
  }

  void _openComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommentThreadPage(pollId: widget.poll.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final totalVotes =
        poll.counts.values.fold<int>(0, (sum, count) => sum + count);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final option in poll.options)
              _OptionTile(
                option: option,
                selected: _selectedOption == option,
                onTap: () => _vote(option),
                votes: poll.counts[option] ?? 0,
                totalVotes: totalVotes,
                voted: _voted,
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${poll.commentsCount} yorum",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: _openComments,
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text("Yorumlar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final bool selected;
  final bool voted;
  final int votes;
  final int totalVotes;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.voted,
    required this.votes,
    required this.totalVotes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalVotes > 0 ? (votes / totalVotes * 100).toStringAsFixed(1) : '0';

    return InkWell(
      onTap: voted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.withOpacity(0.15)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.blue.shade700 : null,
                ),
              ),
            ),
            if (voted) ...[
              Text(
                "$percentage%",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Text(
                "$votes oy",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
