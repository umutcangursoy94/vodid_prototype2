import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vodid_prototype2/generic_list_screen.dart';
import 'package:vodid_prototype2/today_polls_screen.dart';
import 'package:vodid_prototype2/user_profile_screen.dart';

// Kendi profilimiz için ana sayfa widget'ı
class MyVotesScreen extends StatelessWidget {
  const MyVotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
            child: Text(
              'Son Aktiviteler',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 20),
            ),
          ),
          // YENİ: Aktivite akışını, mevcut kullanıcı ID'si ile burada çağırıyoruz
          Expanded(
            child: uid == null
                ? const Center(child: Text("Giriş yapmalısınız."))
                : ActivityFeedWidget(
                    userId: uid,
                    isOwnProfile:
                        true, // Kendi profilimiz olduğunu belirtiyoruz
                  ),
          ),
        ],
      ),
    );
  }
}

// YENİ: Diğer profil sayfasında da kullanmak üzere ayrılmış aktivite akışı widget'ı
class ActivityFeedWidget extends StatelessWidget {
  final String userId;
  final bool isOwnProfile;

  const ActivityFeedWidget({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                isOwnProfile
                    ? 'Henüz bir aktiviten bulunmuyor.'
                    : 'Kullanıcının henüz bir aktivitesi yok.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _ActivityCard(
              snap: docs[index],
              isOwnProfile: isOwnProfile, // Bilgiyi aktivite kartına iletiyoruz
            );
          },
        );
      },
    );
  }
}

// Aktivite kartı son hali
class _ActivityCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final bool isOwnProfile; // Profilin kime ait olduğu bilgisi

  const _ActivityCard({required this.snap, required this.isOwnProfile});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM yyyy, HH:mm', 'tr_TR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final data = snap.data() ?? {};
    final type = data['type'] as String?;
    final pollId = data['pollId'] as String?;
    final commentId = data['commentId'] as String?;
    final pollQuestion = data['pollQuestion'] as String? ?? 'bir anket';
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp?.toDate();

    final voteVerb = isOwnProfile ? 'verdin' : 'verdi';
    final commentVerb = isOwnProfile ? 'yaptın' : 'yaptı';
    final replyVerb = isOwnProfile ? 'verdin' : 'verdi';
    final likeVerb = isOwnProfile ? 'beğendin' : 'beğendi';

    Widget titleWidget;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'vote':
        icon = Icons.poll_outlined;
        titleWidget = Text(
          '"$pollQuestion" anketine oy $voteVerb.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        );
        subtitle = 'Seçim: ${data['choice']}';
        break;
      case 'comment':
        icon = Icons.chat_bubble_outline_rounded;
        titleWidget = Text(
          '"$pollQuestion" anketine yorum $commentVerb.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        );
        subtitle = data['text'] as String? ?? '';
        break;
      case 'reply':
        icon = Icons.reply_outlined;
        titleWidget = RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
            children: [
              TextSpan(text: 'Bir yoruma yanıt $replyVerb. '),
              TextSpan(
                // DÜZELTME: Tırnak işaretleri kaldırıldı
                text: '($pollQuestion anketine)',
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.normal),
              ),
            ],
          ),
        );
        subtitle = data['text'] as String? ?? '';
        break;
      case 'like':
        icon = Icons.favorite;
        titleWidget = RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
            children: [
              TextSpan(text: 'Bir yorumu $likeVerb. '),
              TextSpan(
                // DÜZELTME: Tırnak işaretleri kaldırıldı
                text: '($pollQuestion anketine)',
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.normal),
              ),
            ],
          ),
        );
        subtitle = data['text'] as String? ?? '';
        break;
      default:
        icon = Icons.history;
        titleWidget = const Text('Bilinmeyen bir aktivite.');
        subtitle = '';
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: titleWidget,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (date != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTime(date),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
        onTap: () {
          if (pollId == null) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TodayPollsScreen(
              initialPollId: pollId,
              showCommentsForPollId: (type != 'vote') ? pollId : null,
              highlightedCommentId: commentId,
            ),
          ));
        },
        isThreeLine: true,
      ),
    );
  }
}

// BU KISIMLAR DEĞİŞMEDİ, AYNI KALIYOR
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
                          _buildStatColumn('Oylar', voteCount, () {}),
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

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('"$text"'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            '${_formatTime(created)} tarihinde yorum yapıldı',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
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
      ),
    );
  }
}
