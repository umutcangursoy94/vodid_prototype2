import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/today_polls_screen.dart';

class SummaryScreen extends StatelessWidget {
  final bool showAppBar;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> polls;

  const SummaryScreen({
    super.key,
    this.showAppBar = true,
    required this.polls,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text('Poll Summaries',
                  style: Theme.of(context).textTheme.titleLarge),
            )
          : null,
      body: polls.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz anket sonucu yok',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: polls.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _RichSummaryCard(pollSnap: polls[index]);
              },
            ),
    );
  }
}

/// YENİ TASARIM: Zenginleştirilmiş, arka planı görselli özet kartı
class _RichSummaryCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> pollSnap;

  const _RichSummaryCard({required this.pollSnap});

  @override
  Widget build(BuildContext context) {
    final pollData = pollSnap.data() ?? {};
    final pollQuestion = pollData['question'] as String? ?? 'Anket';
    final pollImageUrl = pollData['imageUrl'] as String? ?? '';
    final hasImage = pollImageUrl.isNotEmpty;

    final counts = Map<String, dynamic>.from(pollData['counts'] ?? {});
    final options = (pollData['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (options.isEmpty && counts.isNotEmpty) {
      options.addAll(counts.keys);
      options.sort();
    }
    final totalVotes = counts.values.fold<int>(0, (p, e) => p + (e as int));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TodayPollsScreen(initialPollId: pollSnap.id),
        ));
      },
      borderRadius: BorderRadius.circular(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          height: 250, // Kartlar için sabit bir yükseklik
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(pollImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                      Colors.black.withAlpha(153),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pollQuestion,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasImage
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalVotes Toplam Oy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                    color: hasImage
                        ? Colors.white.withAlpha(204)
                        : Colors.grey[600],
                  ),
                ),
                const Spacer(), // Sonuçları en alta iter
                if (totalVotes > 0)
                  Column(
                    children: [
                      for (final opt in options)
                        _SummaryResultBar(
                          label: opt,
                          value: counts[opt] ?? 0,
                          total: totalVotes,
                          hasImage: hasImage,
                        ),
                    ],
                  )
                else if (hasImage)
                  const Text(
                    'Henüz oy kullanılmamış',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  )
                else
                  const Text(
                    'Henüz oy kullanılmamış',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// YENİ: Zenginleştirilmiş özet kartı için sonuç barı
class _SummaryResultBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final bool hasImage;

  const _SummaryResultBar({
    required this.label,
    required this.value,
    required this.total,
    required this.hasImage,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;
    final pctText = (percent * 100).toStringAsFixed(0);
    final textColor =
        hasImage ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: TextStyle(color: textColor, fontSize: 15))),
              Text('$pctText%',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
              backgroundColor:
                  hasImage ? Colors.white.withAlpha(51) : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                hasImage ? Colors.white.withAlpha(179) : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
