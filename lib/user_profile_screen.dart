import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/generic_list_screen.dart';
import 'package:vodid_prototype2/my_votes_screen.dart';
import 'package:vodid_prototype2/sign_in_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isMyProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Profilim' : 'Profil'),
        // Başka birinin profilindeysek geri tuşu görünsün, kendi profilimizdeysek görünmesin.
        automaticallyImplyLeading: !isMyProfile,
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Çıkış Yap',
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                // Uygulamadan tamamen çıkış yapıp giriş ekranına yönlendiriyoruz.
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı bulunamadı.'));
          }
          final userData = snapshot.data!.data()!;
          return _ProfileBody(
            userData: userData,
            userId: widget.userId,
            isMyProfile: isMyProfile,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.userData,
    required this.userId,
    required this.isMyProfile,
    this.currentUserId,
  });

  final Map<String, dynamic> userData;
  final String userId;
  final bool isMyProfile;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHeader(
            userData: userData,
            userId: userId,
            isMyProfile: isMyProfile,
            currentUserId: currentUserId,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Yorumlar ve aktiviteler burada görünecek.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userData,
    required this.userId,
    required this.isMyProfile,
    this.currentUserId,
  });

  final Map<String, dynamic> userData;
  final String userId;
  final bool isMyProfile;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: userData['photoURL'] != null
                    ? NetworkImage(userData['photoURL'])
                    : null,
                child: userData['photoURL'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['username'] ?? 'İsimsiz',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (!isMyProfile && currentUserId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _FollowButton(
                          currentUserId: currentUserId!,
                          profileUserId: userId,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StatsRow(
            userData: userData,
            isMyProfile: isMyProfile,
            userId: userId,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.userData,
    required this.isMyProfile,
    required this.userId,
  });

  final Map<String, dynamic> userData;
  final bool isMyProfile;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: 'Oylar',
          value: (userData['votesCount'] ?? 0).toString(),
          onTap: isMyProfile
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyVotesScreen()),
                  )
              : null,
        ),
        _StatItem(
          label: 'Takipçi',
          value: (userData['followersCount'] ?? 0).toString(),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GenericListScreen(
              title: 'Takipçiler',
              // ===== HATA DÜZELTMESİ BAŞLANGIÇ =====
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('followers')
                  .snapshots(),
              itemBuilder: (context, doc) {
                return _UserTile(userId: doc.id);
              },
              // ===== HATA DÜZELTMESİ BİTİŞ =====
            ),
          )),
        ),
        _StatItem(
          label: 'Takip',
          value: (userData['followingCount'] ?? 0).toString(),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GenericListScreen(
              title: 'Takip Edilenler',
              // ===== HATA DÜZELTMESİ BAŞLANGIÇ =====
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('following')
                  .snapshots(),
              itemBuilder: (context, doc) {
                return _UserTile(userId: doc.id);
              },
              // ===== HATA DÜZELTMESİ BİTİŞ =====
            ),
          )),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String currentUserId;
  final String profileUserId;

  const _FollowButton({
    required this.currentUserId,
    required this.profileUserId,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('following')
        .doc(widget.profileUserId)
        .get();
    if (mounted) {
      setState(() {
        _isFollowing = doc.exists;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);
    final followingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('following')
        .doc(widget.profileUserId);
    final followerRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUserId)
        .collection('followers')
        .doc(widget.currentUserId);
    
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(widget.currentUserId);
    final profileUserRef = FirebaseFirestore.instance.collection('users').doc(widget.profileUserId);

    final batch = FirebaseFirestore.instance.batch();

    if (_isFollowing) {
      batch.delete(followingRef);
      batch.delete(followerRef);
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
      batch.update(profileUserRef, {'followersCount': FieldValue.increment(-1)});
    } else {
      batch.set(followingRef, {'timestamp': FieldValue.serverTimestamp()});
      batch.set(followerRef, {'timestamp': FieldValue.serverTimestamp()});
      batch.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
      batch.update(profileUserRef, {'followersCount': FieldValue.increment(1)});
    }
    
    await batch.commit();

    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }
    return ElevatedButton(
      onPressed: _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: Text(_isFollowing ? 'Takipten Çık' : 'Takip Et'),
    );
  }
}

// Bu yardımcı widget, GenericListScreen tarafından kullanılacak.
// Takipçi ve takip edilen listesindeki her bir kullanıcı satırını çizer.
class _UserTile extends StatelessWidget {
  final String userId;
  const _UserTile({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Kullanıcı bilgilerini almak için 'users' koleksiyonuna gidiyoruz.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Veri yüklenirken boş bir satır gösterilebilir.
          return const ListTile();
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        // userData boşsa veya null ise hiçbir şey gösterme
        if (userData == null) {
          return const SizedBox.shrink();
        }
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: userData['photoURL'] != null
                ? NetworkImage(userData['photoURL'])
                : null,
            child: userData['photoURL'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(userData['username'] ?? 'Kullanıcı'),
          onTap: () {
            // Bir kullanıcının üzerine tıklandığında onun profiline git
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: userId),
            ));
          },
        );
      },
    );
  }
}