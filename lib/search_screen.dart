import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/today_polls_screen.dart';
import 'package:vodid_prototype2/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  List<DocumentSnapshot> _userResults = [];
  List<DocumentSnapshot> _pollResults = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final searchQuery = query.trim().toLowerCase();
    // Arama için minimum karakter sayısını 3'e çıkarıyoruz
    if (searchQuery.length < 3) {
      setState(() {
        _hasSearched = false;
        _userResults = [];
        _pollResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Kullanıcıları ara
    final userQuery = FirebaseFirestore.instance
        .collection('users')
        .where('displayName_lowercase', isGreaterThanOrEqualTo: searchQuery)
        .where('displayName_lowercase',
            isLessThanOrEqualTo: '$searchQuery\uf8ff')
        .limit(10)
        .get();

    // Anketleri ara (question_search_index alanında)
    final pollQuery = FirebaseFirestore.instance
        .collection('polls')
        .where('question_search_index',
            arrayContains: searchQuery) // DEĞİŞTİRİLDİ
        .orderBy('totalVotes', descending: true)
        .limit(10)
        .get();

    // İki aramayı aynı anda çalıştır
    final results = await Future.wait([userQuery, pollQuery]);

    if (mounted) {
      setState(() {
        _userResults = results[0].docs;
        _pollResults = results[1].docs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool noResults = _userResults.isEmpty && _pollResults.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ara', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Kullanıcı veya anket ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const _InfoState(
                        icon: Icons.search,
                        message: 'Aramak için en az 3 karakter girin.',
                      )
                    : noResults
                        ? const _InfoState(
                            icon: Icons.search_off_rounded,
                            message: 'Arama sonucu bulunamadı.',
                          )
                        : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    // Toplam eleman sayısı = kullanıcılar + anketler + (varsa) başlıklar
    int itemCount = _userResults.length + _pollResults.length;
    if (_userResults.isNotEmpty) itemCount++;
    if (_pollResults.isNotEmpty) itemCount++;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_userResults.isNotEmpty) {
          if (index == 0) {
            return const _Header(title: 'Kullanıcılar');
          }
          if (index <= _userResults.length) {
            final userDoc = _userResults[index - 1];
            return _UserResultTile(
                userId: userDoc.id,
                userData: userDoc.data() as Map<String, dynamic>);
          }
        }

        int pollStartIndex =
            _userResults.isNotEmpty ? _userResults.length + 1 : 0;

        if (_pollResults.isNotEmpty) {
          if (index == pollStartIndex) {
            return const _Header(title: 'Anketler');
          }
          if (index > pollStartIndex) {
            final pollDoc = _pollResults[index - pollStartIndex - 1];
            return _PollResultTile(
                pollData: pollDoc.data() as Map<String, dynamic>,
                pollId: pollDoc.id);
          }
        }

        return const SizedBox.shrink(); // Should not happen
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _UserResultTile({required this.userId, required this.userData});

  @override
  Widget build(BuildContext context) {
    final displayName = userData['displayName'] as String? ?? 'İsimsiz';
    final username = userData['username'] as String?;
    final photoURL = userData['photoURL'] as String?;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (photoURL != null) ? NetworkImage(photoURL) : null,
          child: (photoURL == null) ? const Icon(Icons.person) : null,
        ),
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

class _PollResultTile extends StatelessWidget {
  final String pollId;
  final Map<String, dynamic> pollData;

  const _PollResultTile({required this.pollId, required this.pollData});

  @override
  Widget build(BuildContext context) {
    final question = pollData['question'] as String? ?? 'Anket sorusu yok';
    final totalVotes = pollData['totalVotes'] ?? 0;

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.poll)),
        title: Text(question),
        subtitle: Text('$totalVotes oy'),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TodayPollsScreen(initialPollId: pollId),
          ));
        },
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
