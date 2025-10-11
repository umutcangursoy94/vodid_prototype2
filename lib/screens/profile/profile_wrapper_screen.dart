import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/screens/profile/user_profile_screen.dart';

class ProfileWrapperScreen extends StatelessWidget {
  const ProfileWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mevcut kullanıcıyı al
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Her ihtimale karşı bir kontrol eklemek en iyi pratiktir.
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Giriş yapmış bir kullanıcı bulunamadı.'),
        ),
      );
    }

    // Mevcut kullanıcının ID'sini UserProfileScreen'e geçirerek onu döndür.
    // Bu sayede UserProfileScreen, kimin profilini göstereceğini bilir.
    return UserProfileScreen(userId: currentUser.uid);
  }
}