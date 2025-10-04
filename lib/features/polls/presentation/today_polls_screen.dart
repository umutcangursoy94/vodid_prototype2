import 'package:flutter/material.dart';
import 'package:vodid_prototype2/features/polls/data/poll_repository.dart';
import 'package:vodid_prototype2/features/polls/models/poll.dart';
import 'package:vodid_prototype2/features/polls/presentation/widgets/poll_card.dart';
import 'package:vodid_prototype2/features/comments/presentation/comment_thread.dart';
import 'package:vodid_prototype2/core/widgets/loading.dart';
import 'package:vodid_prototype2/core/widgets/empty_state.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

class TodayPollsScreen extends StatefulWidget {
  const TodayPollsScreen({super.key});

  @override
  State<TodayPollsScreen> createState() => _TodayPollsScreenState();
}

class _TodayPollsScreenState extends State<TodayPollsScreen> {
  final PollRepository _repo = PollRepository();
  PollModel? _poll;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivePoll();
  }

  Future<void> _loadActivePoll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final poll = await _repo.getActivePoll();
      setState(() {
        _poll = poll;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _vote(String option) async {
    if (_poll == null) return;
    try {
      if (option.contains('Evet')) {
        await _repo.voteYes(_poll!.id);
      } else {
        await _repo.voteNo(_poll!.id);
      }
      // Yerel güncelleme
      setState(() {
        final updatedCounts = Map<String, int>.from(_poll!.counts);
        updatedCounts[option] = (updatedCounts[option] ?? 0) + 1;
        _poll = PollModel(
          id: _poll!.id,
          question: _poll!.question,
          options: _poll!.options,
          counts: updatedCounts,
          isActive: _poll!.isActive,
          createdAt: _poll!.createdAt,
          order: _poll!.order,
          newsSummary: _poll!.newsSummary,
          videoUrl: _poll!.videoUrl,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.error}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Loading(message: 'Anket yükleniyor...');
    }
    if (_error != null) {
      return EmptyState(
        message: '${AppStrings.couldNotLoad}: $_error',
        onRetry: _loadActivePoll,
        icon: Icons.error_outline,
      );
    }
    if (_poll == null) {
      return const EmptyState(message: AppStrings.noPollFound);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todaysPoll),
        actions: [
          IconButton(
            tooltip: AppStrings.comments,
            icon: const Icon(Icons.mode_comment_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CommentThreadPage(
                    pollId: _poll!.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivePoll,
        child: ListView(
          children: [
            PollCard(
              poll: _poll!,
              onVote: _vote,
            ),
          ],
        ),
      ),
    );
  }
}
