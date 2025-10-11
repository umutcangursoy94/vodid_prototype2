import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/today_polls_screen.dart';

class SummaryScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>>? polls;
  final bool showAppBar;

  const SummaryScreen({
    super.key,
    this.polls,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Anket Özetleri'),
            )
          : null,
      body: polls != null
          ? _buildList(polls!)
          : FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('polls')
                  .where('isActive', isEqualTo: true)
                  .orderBy('order')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aktif anket bulunamadı.'));
                }
                final pollDocs = snapshot.data!.docs;
                return _buildList(pollDocs);
              },
            ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot<Map<String, dynamic>>> pollDocs) {
    return ListView.builder(
      itemCount: pollDocs.length,
      itemBuilder: (context, index) {
        final poll = pollDocs[index];
        final data = poll.data();
        final options = List<String>.from(data['options'] ?? []);
        final counts = Map<String, int>.from(data['counts'] ?? {});
        final totalVotes = counts.values.fold<int>(0, (prev, e) => prev + e);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TodayPollsScreen(initialPollId: poll.id),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['question'] ?? 'Soru',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...options.map((option) {
                    final voteCount = counts[option] ?? 0;
                    final percent = totalVotes == 0 ? 0.0 : voteCount / totalVotes;
                    return _SummaryResultBar(
                      label: option,
                      percent: percent,
                      voteCount: voteCount,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryResultBar extends StatelessWidget {
  const _SummaryResultBar({
    required this.label,
    required this.percent,
    required this.voteCount,
  });

  final String label;
  final double percent;
  final int voteCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% ($voteCount Oy)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}