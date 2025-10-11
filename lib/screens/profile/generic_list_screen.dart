import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/screens/profile/user_profile_screen.dart'; // Dosya yolu düzeltildi

class GenericListScreen extends StatelessWidget {
  final String title;
  final Future<List<DocumentSnapshot>> userListFuture;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.userListFuture,
  });

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı geri getirildi.
    return Scaffold(
      appBar: AppBar(
        // Orijinal AppBar stili
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Orijinal geri butonu ikonu
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // PERFORMANS: Verileri FutureBuilder ile verimli şekilde yüklüyoruz.
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: userListFuture,
        builder: (context, snapshot) {
          // 1. Veri bekleniyor durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          // 2. Hata durumu
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu.'));
          }

          // 3. Veri yok veya liste boş durumu
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Gösterilecek kimse bulunamadı.'));
          }

          final userDocs = snapshot.data!;

          // PERFORMANS: ListView.builder ile verimli liste gösterimi
          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userData = userDocs[index].data() as Map<String, dynamic>?;

              if (userData == null) {
                return const SizedBox.shrink(); // Hatalı veriye karşı koruma
              }
              
              final userId = userDocs[index].id;
              final userName = userData['displayName'] ?? 'İsimsiz Kullanıcı';
              final userPhotoUrl = userData['photoURL'];

              // Orijinal ListTile tasarımı
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(userId: userId),
                    ),
                  );
                },
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
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                // İleride buraya "Takip Et" butonu da eklenebilir.
              );
            },
          );
        },
      ),
    );
  }
}