import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase servislerini initialize eden sınıf.
/// İleride Authentication, Storage vb. eklenirse buraya dahil edilebilir.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // Firestore için default ayarlar
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  FirebaseFirestore get firestore => _firestore;
}
