import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Herhangi bir kullanıcının profilini göstermek için kullanılan genel sayfa.
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;
  bool _isProcessingFollow = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  /// Mevcut kullanıcının bu profili takip edip etmediğini kontrol eder.
  Future<void> _checkIfFollowing() async {
    if (_auth.currentUser == null) {
      setState(() => _isLoadingFollowStatus = false);
      return;
    }
    final currentUserUid = _auth.currentUser!.uid;
    final followingDoc = await _db
        .collection('users')
        .doc(currentUserUid)
        .collection('following')
        .doc(widget.userId)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = followingDoc.exists;
        _isLoadingFollowStatus = false;
      });
    }
  }

  /// Takip etme ve takipten çıkarma işlemlerini yönetir.
  Future<void> _toggleFollow() async {
    if (_auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu işlem için giriş yapmalısınız.')),
        );
      }
      return;
    }

    setState(() => _isProcessingFollow = true);

    final currentUserUid = _auth.currentUser!.uid;
    final currentUserRef = _db.collection('users').doc(currentUserUid);
    final profileUserRef = _db.collection('users').doc(widget.userId);

    final followingRef =
        currentUserRef.collection('following').doc(widget.userId);
    final followersRef =
        profileUserRef.collection('followers').doc(currentUserUid);

    try {
      final WriteBatch batch = _db.batch();
      final currentUserData = await currentUserRef.get();
      final currentUserDisplayName =
          currentUserData.data()?['displayName'] ?? 'Bir Kullanıcı';

      if (_isFollowing) {
        // --- Takipten Çıkar ---
        batch.delete(followingRef);
        batch.delete(followersRef);
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(-1)});
        batch.update(
            profileUserRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        // --- Takip Et ---
        batch.set(followingRef, {
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.set(followersRef, {
          'displayName': currentUserDisplayName,
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.update(
            currentUserRef, {'followingCount': FieldValue.increment(1)});
        batch.update(
            profileUserRef, {'followersCount': FieldValue.increment(1)});
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız oldu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingFollow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isViewingOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }

          final userData = snapshot.data!.data()!;
          final theme = Theme.of(context);
          final displayName = userData['displayName'] as String? ?? 'Kullanıcı';
          final username = userData['username'] as String?;
          final photoURL = userData['photoURL'] as String?;

          final voteCount = userData['votesCount'] as int? ?? 0;
          final commentCount = userData['commentsCount'] as int? ?? 0;
          final followersCount = userData['followersCount'] as int? ?? 0;
          final followingCount = userData['followingCount'] as int? ?? 0;

          return Padding(
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
                          _buildStatColumn('Oylar', voteCount),
                          _buildStatColumn('Yorumlar', commentCount),
                          _buildStatColumn('Takipçi', followersCount),
                          _buildStatColumn('Takip', followingCount),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // --- GÜNCELLENDİ: Kullanıcı adı eklendi ---
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
                // --- GÜNCELLEME SONU ---
                const SizedBox(height: 16),
                if (!isViewingOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    child: _isLoadingFollowStatus
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ))
                        : _isFollowing
                            ? OutlinedButton(
                                onPressed:
                                    _isProcessingFollow ? null : _toggleFollow,
                                child: const Text('Takipten Çıkar'),
                              )
                            : ElevatedButton(
                                onPressed:
                                    _isProcessingFollow ? null : _toggleFollow,
                                child: const Text('Takip Et'),
                              ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Kendi profilini düzenleme sayfasına yönlendirme eklenebilir
                      },
                      child: const Text('Profili Düzenle'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, int number) {
    return Column(
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
    );
  }
}
