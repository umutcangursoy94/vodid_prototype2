import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/screens/profile/generic_list_screen.dart';
import 'package:vodid_prototype2/screens/profile/my_votes_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

// Sekmeli yapı için TickerProviderStateMixin ekliyoruz
class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 sekmemiz var
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Güvenli Takip Et/Bırak fonksiyonu
  Future<void> _toggleFollow() async {
    // ... (Bu fonksiyon daha öncekiyle aynı, güvenli ve performanslı)
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == widget.userId) return;

    final currentUserRef = _firestore.collection('users').doc(currentUser.uid);
    final targetUserRef = _firestore.collection('users').doc(widget.userId);

    await _firestore.runTransaction((transaction) async {
      final targetUserDoc = await transaction.get(targetUserRef);
      if (!targetUserDoc.exists) return;

      final List<dynamic> followers = (targetUserDoc.data() as Map<String, dynamic>)['followers'] ?? [];
      final bool isFollowing = followers.contains(currentUser.uid);

      if (isFollowing) {
        transaction.update(targetUserRef, {'followers': FieldValue.arrayRemove([currentUser.uid])});
        transaction.update(currentUserRef, {'following': FieldValue.arrayRemove([widget.userId])});
      } else {
        transaction.update(targetUserRef, {'followers': FieldValue.arrayUnion([currentUser.uid])});
        transaction.update(currentUserRef, {'following': FieldValue.arrayUnion([widget.userId])});
      }
    });
  }

  // Listeleri getiren performanslı fonksiyonlar
  Future<List<DocumentSnapshot>> _getFollowers(List<dynamic> followerIds) async {
    if (followerIds.isEmpty) return [];
    final userDocs = await _firestore.collection('users').where(FieldPath.documentId, whereIn: followerIds).get();
    return userDocs.docs;
  }

  Future<List<DocumentSnapshot>> _getFollowing(List<dynamic> followingIds) async {
    if (followingIds.isEmpty) return [];
    final userDocs = await _firestore.collection('users').where(FieldPath.documentId, whereIn: followingIds).get();
    return userDocs.docs;
  }

  @override
  Widget build(BuildContext context) {
    // REAL-TIME: Profil verilerini anlık dinliyoruz
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
        }
        if (!snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bulunamadı.')));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isMyProfile = _auth.currentUser?.uid == widget.userId;

        // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            title: Text(
              userData['displayName'] ?? 'Profil',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: isMyProfile
                ? [IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () {})]
                : null,
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(context, userData, isMyProfile),
                )
              ];
            },
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.check_box_outlined)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Sekme: Gelecekte kullanıcının anketleri/gönderileri
                      const Center(child: Text('Anketler (Yakında)')),
                      // 2. Sekme: Verdiği Oylar (MyVotesScreen'i burada kullanabiliriz)
                      const Center(child: Text('Verilen Oylar (Yakında)')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Orijinal Profil Üst Kısım Tasarımı
  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> userData, bool isMyProfile) {
    final List<dynamic> followersList = userData['followers'] ?? [];
    final List<dynamic> followingList = userData['following'] ?? [];
    final photoURL = userData['photoURL'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: photoURL != null && photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                child: photoURL == null || photoURL.isEmpty ? const Icon(Icons.person, size: 40) : null,
              ),
              _buildStatColumn('Anket', 0),
              _buildStatColumn('Takipçi', followersList.length, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GenericListScreen(title: 'Takipçiler', userListFuture: _getFollowers(followersList))));
              }),
              _buildStatColumn('Takip', followingList.length, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GenericListScreen(title: 'Takip Edilenler', userListFuture: _getFollowing(followingList))));
              }),
            ],
          ),
          const SizedBox(height: 12),
          Text(userData['displayName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          isMyProfile ? _buildEditProfileButton() : _buildFollowButton(followersList.contains(_auth.currentUser!.uid)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  // Orijinal "Profili Düzenle" Buton Tasarımı
  Widget _buildEditProfileButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // Orijinal "Takip Et / Takibi Bırak" Buton Tasarımı
  Widget _buildFollowButton(bool isFollowing) {
    return GestureDetector(
      onTap: _toggleFollow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: isFollowing ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Center(
          child: Text(
            isFollowing ? 'Takibi Bırak' : 'Takip Et',
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}