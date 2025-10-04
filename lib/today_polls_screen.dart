import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:vodid_prototype2/summary_screen.dart';
import 'package:vodid_prototype2/widgets/comments_sheet.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TodayPollsScreen extends StatefulWidget {
  final String? initialPollId;
  final String? showCommentsForPollId;
  final String? highlightedCommentId;

  const TodayPollsScreen({
    super.key,
    this.initialPollId,
    this.showCommentsForPollId,
    this.highlightedCommentId,
  });

  @override
  State<TodayPollsScreen> createState() => _TodayPollsScreenState();
}

class _TodayPollsScreenState extends State<TodayPollsScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  late final PageController _pageCtrl;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _polls;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPollsAndSetup();
  }

  Future<void> _fetchPollsAndSetup() async {
    try {
      final snap = await _db
          .collection('polls')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      final docs = snap.docs;
      int initialIndex = 0;
      if (widget.initialPollId != null) {
        final index = docs.indexWhere((doc) => doc.id == widget.initialPollId);
        if (index != -1) {
          initialIndex = index;
        }
      }
      _pageCtrl = PageController(initialPage: initialIndex);
      if (mounted) {
        setState(() {
          _polls = docs;
          _isLoading = false;
        });
      }
      if (widget.showCommentsForPollId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CommentsSheet.show(
              context,
              pollId: widget.showCommentsForPollId!,
              highlightedCommentId: widget.highlightedCommentId,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _vote({
    required String pollId,
    required String question,
    required String choice,
  }) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oy vermek için giriş yapmalısınız.')),
      );
      return;
    }
    final uid = _auth.currentUser!.uid;
    final pollRef = _db.collection('polls').doc(pollId);
    final voteRef = pollRef.collection('votes').doc(uid);
    final userVoteRef =
        _db.collection('users').doc(uid).collection('votes').doc(pollId);
    final userDocRef = _db.collection('users').doc(uid);
    try {
      await _db.runTransaction((tx) async {
        final voteSnap = await tx.get(voteRef);
        if (voteSnap.exists) {
          return;
        }
        final voteData = {
          'choice': choice,
          'votedAt': FieldValue.serverTimestamp(),
        };
        tx.set(voteRef, voteData);
        tx.set(userVoteRef, {
          ...voteData,
          'pollId': pollId,
          'question': question,
        });
        tx.update(userDocRef, {'votesCount': FieldValue.increment(1)});
        tx.update(pollRef, {'counts.$choice': FieldValue.increment(1)});
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oy verilirken bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPushedAsPage = widget.initialPollId != null;
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_polls == null || _polls!.isEmpty)
            const Center(child: Text('Bugün için aktif anket bulunamadı.'))
          else
            PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: _polls!.length + 1,
              itemBuilder: (_, i) {
                if (i == _polls!.length) {
                  return _SummaryEndCard(polls: _polls!);
                }
                final pollDoc = _polls![i];
                return _PollFullPage(
                  key: ValueKey(pollDoc.id),
                  pollDoc: pollDoc,
                  onVote: (choice) => _vote(
                    pollId: pollDoc.id,
                    question: pollDoc.data()['question'],
                    choice: choice,
                  ),
                );
              },
            ),
          if (isPushedAsPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black.withAlpha(102),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 20, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Geri',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryEndCard extends StatelessWidget {
  const _SummaryEndCard({required this.polls});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> polls;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text('Günün Özeti',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 22)),
            ),
            Expanded(child: SummaryScreen(showAppBar: false, polls: polls)),
          ],
        ),
      ),
    );
  }
}

class _PollFullPage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> pollDoc;
  final void Function(String choice) onVote;

  const _PollFullPage({super.key, required this.pollDoc, required this.onVote});

  @override
  State<_PollFullPage> createState() => _PollFullPageState();
}

class _PollFullPageState extends State<_PollFullPage> {
  VideoPlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    if (info.visibleFraction > 0.8) {
      _initializeAndPlayVideo();
    } else if (info.visibleFraction < 0.2 && _controller != null) {
      _disposeVideo();
    }
  }

  void _initializeAndPlayVideo() {
    if (_controller != null) {
      _controller!.play();
      return;
    }

    final data = widget.pollDoc.data();
    final videoUrl = data?['videoUrl'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      httpHeaders: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      },
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (!mounted || _controller == null) return;
        _controller!.setLooping(true);
        _controller!.setVolume(0);
        _controller!.play();
        setState(() {});
      });

    setState(() {});
  }

  Future<void> _disposeVideo() async {
    final oldController = _controller;
    if (mounted) {
      setState(() {
        _controller = null;
      });
    }
    await oldController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final pollId = widget.pollDoc.id;

    return VisibilityDetector(
      key: ValueKey(pollId),
      onVisibilityChanged: _onVisibilityChanged,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: widget.pollDoc.reference.snapshots(),
          builder: (context, pollSnapshot) {
            if (!pollSnapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            final realTimeData = pollSnapshot.data!.data()!;
            final options = List<String>.from(realTimeData['options'] ?? []);
            final commentsCount = (realTimeData['commentsCount'] ?? 0) as int;
            final newsSummary = (realTimeData['news_summary'] ??
                'Bu konu hakkında bir özet bulunamadı.') as String;
            final pollQuestion =
                (realTimeData['question'] ?? 'Anket Sorusu') as String;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                else
                  const Center(
                      child: CircularProgressIndicator(color: Colors.white24)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(153),
                        Colors.transparent,
                        Colors.black.withAlpha(153),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      _PollQuestion(pollData: realTimeData),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: _RightActionBar(
                            commentsCount: commentsCount,
                            pollId: pollId,
                            pollQuestion: pollQuestion,
                            newsSummary: newsSummary,
                          ),
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: uid == null
                            ? const Stream.empty()
                            : widget.pollDoc.reference
                                .collection('votes')
                                .doc(uid)
                                .snapshots(),
                        builder: (context, voteSnapshot) {
                          if (voteSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _BottomLeftControls.waiting(
                                options: options);
                          }

                          final hasVoted =
                              voteSnapshot.hasData && voteSnapshot.data!.exists;
                          final counts = Map<String, dynamic>.from(
                              realTimeData['counts'] ?? {});
                          final totalVotes = counts.values
                              .fold<int>(0, (p, e) => p + (e as int));

                          return _BottomLeftControls(
                            options: options,
                            hasVoted: hasVoted,
                            userChoice:
                                (voteSnapshot.data?.data() as Map?)?['choice'],
                            counts: counts,
                            totalVotes: totalVotes,
                            onVote: widget.onVote,
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BottomLeftControls extends StatelessWidget {
  final List<String> options;
  final bool hasVoted;
  final String? userChoice;
  final Map<String, dynamic> counts;
  final int totalVotes;
  final void Function(String choice) onVote;

  const _BottomLeftControls({
    required this.options,
    required this.hasVoted,
    this.userChoice,
    required this.counts,
    required this.totalVotes,
    required this.onVote,
  });

  const _BottomLeftControls.waiting({
    required this.options,
  })  : hasVoted = false,
        userChoice = null,
        counts = const {},
        totalVotes = 0,
        onVote = _doNothing;

  static void _doNothing(String choice) {}

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasVoted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: options.map((option) {
                  final voteCount = counts[option] ?? 0;
                  final percent =
                      totalVotes == 0 ? 0.0 : voteCount / totalVotes;
                  return _VoteResultBar(
                    label: option,
                    percent: percent,
                    isUsersChoice: userChoice == option,
                  );
                }).toList(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VoteButton(
                    label: options[0],
                    onPressed: () => onVote(options[0]),
                  ),
                  const SizedBox(height: 12),
                  if (options.length > 1)
                    _VoteButton(
                      label: options[1],
                      onPressed: () => onVote(options[1]),
                    ),
                ],
              ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: Colors.white.withAlpha(230),
        foregroundColor: Colors.black,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }
}

class _VoteResultBar extends StatelessWidget {
  const _VoteResultBar({
    required this.label,
    required this.percent,
    required this.isUsersChoice,
  });
  final String label;
  final double percent;
  final bool isUsersChoice;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isUsersChoice ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: isUsersChoice ? 10 : 8,
                    backgroundColor: Colors.white.withAlpha(77),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUsersChoice
                          ? Colors.white
                          : Colors.white.withAlpha(179),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollQuestion extends StatelessWidget {
  const _PollQuestion({required this.pollData});
  final Map<String, dynamic> pollData;
  @override
  Widget build(BuildContext context) {
    final question = (pollData['question'] ?? '') as String;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 60.0, 24.0),
        child: Text(
          question,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            height: 1.3,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _RightActionBar extends StatefulWidget {
  final int commentsCount;
  final String pollId;
  final String pollQuestion;
  final String newsSummary;

  const _RightActionBar({
    required this.commentsCount,
    required this.pollId,
    required this.pollQuestion,
    required this.newsSummary,
  });

  @override
  State<_RightActionBar> createState() => _RightActionBarState();
}

class _RightActionBarState extends State<_RightActionBar> {
  bool _isSaving = false;
  late final Stream<DocumentSnapshot> _savedStatusStream;
  late final FirebaseFunctions _functions;

  @override
  void initState() {
    super.initState();
    _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _savedStatusStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedPolls')
          .doc(widget.pollId)
          .snapshots();
    } else {
      _savedStatusStream = const Stream.empty();
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu işlem için giriş yapmalısınız.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final callable = _functions.httpsCallable('toggleSavePoll');
      await callable.call({'pollId': widget.pollId});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız oldu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// KESİN OLARAK DÜZELTİLMİŞ PAYLAŞIM FONKSİYONU
  Future<void> _sharePoll() async {
    // HATA DÜZELTİLDİ: Artık 'Share.share' metodu kullanılıyor.
    final result = await Share.share(
      'Vodid anketini gördün mü? "${widget.pollQuestion}" #vodid',
      subject: 'Vodid Anketi',
    );

    if (result.status == ShareResultStatus.success) {
      try {
        final callable = _functions.httpsCallable('incrementShareCount');
        await callable.call({
          'pollId': widget.pollId,
          // result.raw içinde hangi uygulamayla paylaşıldığı bilgisi olabilir.
          'platform': result.raw.isNotEmpty ? result.raw : 'shared',
        });
      } catch (e) {
        // Arka plan işlemi, kullanıcıya hata göstermeye gerek yok.
      }
    }
  }

  void _showNewsSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (_, controller) {
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: controller,
                    children: [
                      Center(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ne Olmuştu?',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.newsSummary,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: widget.commentsCount.toString(),
          onTap: () => CommentsSheet.show(context, pollId: widget.pollId),
        ),
        const SizedBox(height: 24),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Paylaş',
          onTap: _sharePoll,
        ),
        const SizedBox(height: 24),
        StreamBuilder<DocumentSnapshot>(
          stream: _savedStatusStream,
          builder: (context, snapshot) {
            final isSaved = snapshot.hasData && snapshot.data!.exists;
            return _ActionButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border_outlined,
              label: 'Kaydet',
              onTap: _toggleSave,
              isLoading: _isSaving,
            );
          },
        ),
        const SizedBox(height: 24),
        _ActionButton(
          icon: Icons.help_outline,
          label: 'Ne Olmuştu',
          onTap: () => _showNewsSummarySheet(context),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const shadow = Shadow(color: Colors.black87, blurRadius: 6);
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          else
            Icon(icon, color: Colors.white, size: 28, shadows: const [shadow]),
          const SizedBox(height: 4),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [shadow],
              ),
            )
        ],
      ),
    );
  }
}
