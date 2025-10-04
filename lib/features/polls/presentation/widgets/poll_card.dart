import 'package:flutter/material.dart';
import 'package:vodid_prototype2/features/polls/models/poll.dart';

/// Bir anketi (PollModel) kart şeklinde gösteren widget.
/// Soru, seçenekler ve oy sayıları dahil edilir.
class PollCard extends StatelessWidget {
  final PollModel poll;
  final void Function(String option)? onVote;

  const PollCard({
    super.key,
    required this.poll,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              poll.question,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (poll.newsSummary != null && poll.newsSummary!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                poll.newsSummary!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.justify,
              ),
            ],
            const SizedBox(height: 16),
            Column(
              children: poll.options.map((opt) {
                final count = poll.counts[opt] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: onVote != null ? () => onVote!(opt) : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('$opt ($count)'),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
