// lib/services/5_injection/dependency_container.dart

import 'package:get_it/get_it.dart';
import 'package:ubiqa/services/5_injection/features/auth/auth_dependencies.dart';
import 'package:ubiqa/services/5_injection/features/listings/listing_dependencies.dart';

// Import infrastructure services
import '../4_infrastructure/firebase/firebase_auth_service.dart';
import '../4_infrastructure/firebase/firestore_service.dart';

/// Centralized dependency injection container for Ubiqa
///
/// Manages service registration in two phases:
/// - Horizontal: Shared infrastructure services
/// - Vertical: Feature-specific services (auth, listings, payments)
class UbiqaDependencyContainer {
  static final GetIt _container = GetIt.instance;

  /// Initialize horizontal foundation services
  /// Called once during app startup
  static Future<void> initializeHorizontalFoundation() async {
    await _registerInfrastructureServices();
    print('✅ Horizontal Foundation Dependencies Initialized');
  }

  /// Register all vertical feature dependencies
  /// Called after horizontal foundation is complete
  static Future<void> initializeVerticalFeatures() async {
    // Feature registration will be added during vertical development
    // Each feature calls its own registration function here

    // Example (to be implemented):
    await AuthDependencies.register(_container);
    await ListingDependencies.register(_container);
    // await PaymentsDependencies.register(_container);

    print('✅ Vertical Feature Dependencies Initialized');
  }

  /// Get service instance
  static T get<T extends Object>() => _container<T>();

  /// Check if service is registered
  static bool isRegistered<T extends Object>() => _container.isRegistered<T>();

  /// Reset container (testing only)
  static Future<void> reset() async {
    await _container.reset();
  }

  // PRIVATE: Register shared infrastructure services
  static Future<void> _registerInfrastructureServices() async {
    // Register Firebase services as singletons
    _container.registerSingleton<FirebaseAuthService>(FirebaseAuthService());

    _container.registerSingleton<FirestoreService>(FirestoreService());

    print('📱 Infrastructure services registered');
  }
}
