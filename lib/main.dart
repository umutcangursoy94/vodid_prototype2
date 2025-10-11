import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Bu satırı ekle
import 'package:vodid_prototype2/firebase_options.dart';
import 'package:vodid_prototype2/screens/home_screen.dart';
import 'package:vodid_prototype2/screens/auth/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ÇÖKME HATASINI GİDEREN KOD:
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vodid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Lora',
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        primaryColor: const Color(0xFF1a1a1a),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const SignInScreen();
      },
    );
  }
}