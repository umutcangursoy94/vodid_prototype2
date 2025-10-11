import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vodid_prototype2/sign_in_screen.dart';
import 'package:vodid_prototype2/user_profile_screen.dart';

class ProfileWrapperScreen extends StatelessWidget {
  const ProfileWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Veri beklenirken boş bir ekran göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Eğer kullanıcı giriş yapmışsa, onun profilini göster
        if (snapshot.hasData && snapshot.data != null) {
          return UserProfileScreen(userId: snapshot.data!.uid);
        } 
        
        // Kullanıcı giriş yapmamışsa, giriş ekranını göster
        else {
          return const SignInScreen();
        }
      },
    );
  }
}