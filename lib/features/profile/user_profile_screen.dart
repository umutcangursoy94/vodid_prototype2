import 'package:flutter/material.dart';
import 'package:vodid_prototype2/core/constants/strings.dart';

/// Kullanıcı profil ekranı.
/// Şimdilik mock veriler ile çalışır, ileride FirebaseAuth bilgileri bağlanabilir.
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: FirebaseAuth bağlandığında kullanıcı bilgilerini buradan al
    final mockUser = {
      "displayName": "Deneme Kullanıcı",
      "email": "demo@example.com",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              mockUser["displayName"]!,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              mockUser["email"]!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: FirebaseAuth signOut eklenecek
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Çıkış yapıldı (mock)!")),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Çıkış Yap"),
            ),
          ],
        ),
      ),
    );
  }
}
