import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/screens/profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Verimli arama fonksiyonunu koruyoruz
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      setState(() {
        _searchResults = snapshot.docs;
      });
    } catch (e) {
      // Hata yönetimi
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Ara',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Orijinal Arama Çubuğu Tasarımı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kullanıcıları ara...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none, // Kenarlık olmasın
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          // Sonuçları gösteren alan
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  // Arama sonuçlarını duruma göre gösteren yardımcı widget
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    if (!_hasSearched) {
      return const Center(child: Text('Kullanıcı adı ile arama yapın.', style: TextStyle(color: Colors.grey)));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey)));
    }
    
    // PERFORMANS: ListView.builder ve Orijinal ListTile Tasarımı
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index].data() as Map<String, dynamic>;
        final userId = _searchResults[index].id;
        final userPhotoUrl = userData['photoURL'];

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                ? NetworkImage(userPhotoUrl)
                : null,
            child: userPhotoUrl == null || userPhotoUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          title: Text(
            userData['displayName'] ?? 'İsimsiz',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(userId: userId),
              ),
            );
          },
        );
      },
    );
  }
}