import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';
import 'package:vodid_prototype2/core/widgets/loading.dart';
import 'package:vodid_prototype2/features/polls/data/poll_repository.dart';
import 'package:vodid_prototype2/features/polls/models/poll.dart';
import 'package:vodid_prototype2/features/polls/presentation/widgets/poll_card.dart';

/// Bugünün aktif anketlerini gösteren ekran.
class TodayPollsScreen extends StatelessWidget {
  const TodayPollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PollRepository();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.todaysPoll)),
      body: StreamBuilder<List<Poll>>(
        stream: repo.streamActivePolls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          if (snapshot.hasError) {
            return const EmptyState(message: AppStrings.couldNotLoad);
          }
          final polls = snapshot.data ?? [];
          if (polls.isEmpty) {
            return const EmptyState(message: AppStrings.noPollFound);
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: polls.length,
            itemBuilder: (context, i) => PollCard(poll: polls[i]),
          );
        },
      ),
    );
  }
}
