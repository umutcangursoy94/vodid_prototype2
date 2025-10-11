import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSigningIn = false;

  // Güvenli ve modern giriş fonksiyonunu koruyoruz.
  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningIn = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSigningIn = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          await userDocRef.set({
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'following': [],
            'followers': [],
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yaparken bir hata oluştu. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TASARIM SIFIRLAMA: Orijinal arayüz widget ağacı birebir geri getirildi.
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a), // Orijinal siyah arka plan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            // Orijinal "vodid" metin logosu
            const Text(
              'vodid',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            // Orijinal slogan metni
            const Text(
              'Gündemi oylarınla şekillendir.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.0,
              ),
            ),
            const Spacer(),
            // Giriş butonu ve yükleme durumu
            _isSigningIn
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : GestureDetector(
                    onTap: _signInWithGoogle,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google logosu yerine orijinaldeki gibi genel bir ikon
                          Icon(Icons.login, color: Colors.white),
                          SizedBox(width: 12.0),
                          Text(
                            'Google ile Devam Et',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 80.0), // Orijinal alttaki boşluk
          ],
        ),
      ),
    );
  }
}