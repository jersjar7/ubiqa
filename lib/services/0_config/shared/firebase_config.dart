// services/0_config/shared/firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../firebase_options.dart';

/// Firebase configuration and service access for Ubiqa production
class FirebaseConfig {
  static bool _initialized = false;

  /// Initialize Firebase with generated configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firestore settings for production
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    _initialized = true;
  }

  /// Firebase Auth instance for user authentication
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Firestore instance for data storage
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Firebase Storage instance for file uploads
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Storage reference for property photos
  static Reference get propertyPhotosRef =>
      storage.ref().child('property-photos');

  /// Storage reference for user profile photos
  static Reference get userPhotosRef => storage.ref().child('user-photos');

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}

/// Firebase collection references for type safety
class FirebaseCollections {
  /// Users collection reference
  static CollectionReference get users =>
      FirebaseConfig.firestore.collection('users');

  /// Properties collection reference
  static CollectionReference get properties =>
      FirebaseConfig.firestore.collection('properties');

  /// Listings collection reference
  static CollectionReference get listings =>
      FirebaseConfig.firestore.collection('listings');

  /// Payments collection reference
  static CollectionReference get payments =>
      FirebaseConfig.firestore.collection('payments');
}
