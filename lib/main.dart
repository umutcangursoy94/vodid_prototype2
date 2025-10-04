import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vodid_prototype2/dev_admin_seed_screen.dart';
import 'package:vodid_prototype2/home_screen.dart';
import 'package:vodid_prototype2/sign_in_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VodidApp());
}

class VodidApp extends StatelessWidget {
  const VodidApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    const primaryColor = Color(0xFF1A1A1A);
    const backgroundColor = Color(0xFFF1EDE7);
    const cardBackgroundColor = Color(0xFFFDFBF8);
    const textColor = Color(0xFF1A1A1A);

    return MaterialApp(
      title: 'Social Poll',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: primaryColor,
          surface: cardBackgroundColor,
          onSurface: textColor,
        ),
        textTheme: GoogleFonts.sourceSans3TextTheme(textTheme).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            textStyle: textTheme.headlineLarge,
            fontWeight: FontWeight.w500,
            color: textColor,
            fontSize: 34,
          ),
          titleLarge: GoogleFonts.playfairDisplay(
            textStyle: textTheme.titleLarge,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          bodyMedium: GoogleFonts.sourceSans3(
            textStyle: textTheme.bodyMedium,
            fontSize: 17,
            color: textColor.withAlpha(220),
            height: 1.5,
          ),
          labelLarge: GoogleFonts.sourceSans3(
            textStyle: textTheme.labelLarge,
            fontWeight: FontWeight.w400,
            fontSize: 20,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryColor),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/seed': (_) => const DevAdminSeedScreen(),
        '/signin': (_) => const SignInScreen(),
        '/home': (_) => const HomeScreen(),
      },
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
            body: Center(child: CircularProgressIndicator()),
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
