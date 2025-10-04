import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase ile ilgili tüm başlangıç ayarlarını ve ortak erişim noktalarını içerir.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Firebase initialize edildi mi kontrolü
  bool _initialized = false;

  /// Firebase initialize
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization error: $e');
      }
      rethrow;
    }
  }

  /// Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// FirebaseAuth instance
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Test için Firestore bağlantısı kontrolü
  Future<void> testConnection() async {
    try {
      final doc = await firestore.collection('test').doc('connection').get();
      if (kDebugMode) {
        print('Firestore connection OK. Doc exists: ${doc.exists}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firestore connection failed: $e');
      }
    }
  }
}
