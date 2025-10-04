import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vodid_prototype2/features/home/generic_list_screen.dart';
import 'package:vodid_prototype2/features/polls/presentation/today_polls_screen.dart';
import 'package:vodid_prototype2/features/profile/user_profile_screen.dart';

class MyVotesScreen extends StatelessWidget {
  const MyVotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Text(
              'Son Oylar',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ProfileHeaderState()
                  ._myVotesStream(FirebaseAuth.instance.currentUser?.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Henüz hiç oy kullanmadın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _RichVoteCard(snap: docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  Future<void> _signOut(BuildContext context) async {
    final wantsToSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İPTAL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ÇIKIŞ YAP'),
            ),
          ],
        );
      },
    );

    if (wantsToSignOut == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void _navigateToDetails(
      BuildContext context,
      String title,
      Stream<QuerySnapshot> stream,
      Widget Function(BuildContext, DocumentSnapshot) itemBuilder,
      String emptyMessage) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GenericListScreen(
        title: title,
        stream: stream,
        itemBuilder: itemBuilder,
        emptyMessage: emptyMessage,
      ),
    ));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _myVotesStream(String? uid) {
    if (uid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('votes')
        .orderBy('votedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _commentsStream(String uid) {
    return FirebaseFirestore.instance
        .collectionGroup('comments')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _followersStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _followingStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: const Center(child: Text('Lütfen giriş yapın.')),
        ),
      );
    }
    final uid = user.uid;
    final String displayName = user.isAnonymous == true
        ? 'Guest User'
        : user.displayName ?? 'Anonymous';
    final String? photoURL = user.photoURL;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SafeArea(bottom: false, child: SizedBox(height: 250));
        }

        final userData = snapshot.data?.data() ?? {};
        final voteCount = userData['votesCount'] as int? ?? 0;
        final commentCount = userData['commentsCount'] as int? ?? 0;
        final followersCount = userData['followersCount'] as int? ?? 0;
        final followingCount = userData['followingCount'] as int? ?? 0;
        final username = userData['username'] as String?;

        return SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage:
                          photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null
                          ? Icon(Icons.person_outline,
                              size: 40, color: Colors.grey.shade400)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Oylar', voteCount, () {
                            // Detay sayfası artık yeni tasarımı kullanacak.
                          }),
                          _buildStatColumn('Yorumlar', commentCount, () {
                            _navigateToDetails(
                              context,
                              'Yorumlarım',
                              _commentsStream(uid),
                              (ctx, doc) => _CommentListItem(snap: doc),
                              'Henüz hiç yorum yapmadınız.',
                            );
                          }),
                          _buildStatColumn('Takipçi', followersCount, () {
                            _navigateToDetails(
                                context,
                                'Takipçiler',
                                _followersStream(uid),
                                (ctx, doc) => _UserListItem(
                                    userId: doc.id,
                                    userData:
                                        doc.data() as Map<String, dynamic>),
                                'Henüz hiç takipçiniz yok.');
                          }),
                          _buildStatColumn('Takip', followingCount, () {
                            _navigateToDetails(
                                context,
                                'Takip Edilenler',
                                _followingStream(uid),
                                (ctx, doc) => _UserListItem(
                                    userId: doc.id,
                                    userData:
                                        doc.data() as Map<String, dynamic>),
                                'Henüz kimseyi takip etmiyorsunuz.');
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (username != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '@$username',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/seed');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Tooltip(
                          message: 'Geliştirici Panelini Aç',
                          child: Icon(
                            Icons.construction_rounded,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Profili Düzenle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary.withAlpha(200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Çıkış Yap',
                      style: IconButton.styleFrom(
                        foregroundColor:
                            theme.colorScheme.primary.withAlpha(200),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, int number, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _RichVoteCard extends StatefulWidget {
  final DocumentSnapshot snap;

  const _RichVoteCard({required this.snap});

  @override
  State<_RichVoteCard> createState() => _RichVoteCardState();
}

class _RichVoteCardState extends State<_RichVoteCard> {
  DocumentSnapshot<Map<String, dynamic>>? _pollSnap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPollData();
  }

  Future<void> _fetchPollData() async {
    final data = widget.snap.data() as Map<String, dynamic>? ?? {};
    final pollId = data['pollId'] as String?;
    if (pollId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final pollDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .get();
      if (mounted) {
        setState(() {
          _pollSnap = pollDoc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM y, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final voteData = widget.snap.data() as Map<String, dynamic>? ?? {};
    final userChoice = voteData['choice'] as String? ?? 'Oy bulunamadı.';
    final pollId = voteData['pollId'] as String?;
    final ts = voteData['votedAt'];
    DateTime? votedAt;
    if (ts is Timestamp) votedAt = ts.toDate();

    final pollData = _pollSnap?.data();
    final pollQuestion = pollData?['question'] as String? ?? 'Anket';
    final pollImageUrl = pollData?['imageUrl'] as String? ?? '';
    final hasImage = pollImageUrl.isNotEmpty;

    final counts = Map<String, dynamic>.from(pollData?['counts'] ?? {});
    final options = (pollData?['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (options.isEmpty && counts.isNotEmpty) {
      options.addAll(counts.keys);
      options.sort();
    }
    final totalVotes =
        counts.values.fold<int>(0, (prev, item) => prev + (item as int));

    return InkWell(
      onTap: () {
        if (pollId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu oyun anketi bulunamadı.')),
          );
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TodayPollsScreen(initialPollId: pollId),
        ));
      },
      borderRadius: BorderRadius.circular(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
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
                  'Oy verilen anket:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                    color: hasImage
                        ? Colors.white.withAlpha(204)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
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
                Divider(
                    height: 24,
                    color: hasImage ? Colors.white54 : Colors.grey[300]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                    color: hasImage
                        ? Colors.white.withAlpha(38)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: hasImage
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(180),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Seçimin: $userChoice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasImage
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  ))
                else if (totalVotes > 0)
                  Column(
                    children: [
                      for (final opt in options)
                        _VoteResultBar(
                          label: opt,
                          value: counts[opt] ?? 0,
                          total: totalVotes,
                          isUsersChoice: opt == userChoice,
                          hasImage: hasImage,
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatTime(votedAt),
                    style: TextStyle(
                      // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                      color:
                          hasImage ? Colors.white.withAlpha(204) : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteResultBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final bool isUsersChoice;
  final bool hasImage;

  const _VoteResultBar({
    required this.label,
    required this.value,
    required this.total,
    required this.isUsersChoice,
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
                      style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: isUsersChoice
                              ? FontWeight.bold
                              : FontWeight.normal))),
              Text('$pctText%',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight:
                          isUsersChoice ? FontWeight.bold : FontWeight.normal)),
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
                isUsersChoice
                    ? (hasImage
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary)
                    : (hasImage
                        // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                        ? Colors.white.withAlpha(128)
                        : Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _UserListItem({required this.userId, required this.userData});

  @override
  Widget build(BuildContext context) {
    final displayName = userData['displayName'] as String? ?? 'İsimsiz';
    final username = userData['username'] as String?;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: username != null ? Text('@$username') : null,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: userId),
          ));
        },
      ),
    );
  }
}

class _CommentListItem extends StatelessWidget {
  final DocumentSnapshot snap;

  const _CommentListItem({required this.snap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM y, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final text = data['text'] as String? ?? 'Yorum metni alınamadı.';
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    final pollId = data['pollId'] as String?;
    final pollQuestion = data['pollQuestion'] as String? ?? 'Anket';
    final pollImageUrl = data['pollImageUrl'] as String? ?? '';
    final hasImage = pollImageUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        if (pollId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu yorumun anketi bulunamadı.')),
          );
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TodayPollsScreen(
            initialPollId: pollId,
            showCommentsForPollId: pollId,
            highlightedCommentId: snap.id,
          ),
        ));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(pollImageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                      Colors.black.withAlpha(128),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                  hasImage ? Colors.black.withAlpha(51) : Colors.transparent,
                  hasImage ? Colors.black.withAlpha(179) : Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.8],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yorum yapılan anket:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                      color: hasImage
                          ? Colors.white.withAlpha(204)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pollQuestion,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasImage
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Divider(
                      height: 24,
                      color: hasImage ? Colors.white38 : Colors.grey[300]),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.4,
                      color: hasImage
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatTime(created),
                      style: TextStyle(
                        // --- DÜZELTME: Deprecated 'withOpacity' kaldırıldı. ---
                        color: hasImage
                            ? Colors.white.withAlpha(179)
                            : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
