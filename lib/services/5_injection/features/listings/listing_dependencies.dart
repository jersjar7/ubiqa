// lib/services/5_injection/features/listings/listing_dependencies.dart

import 'package:get_it/get_it.dart';

// Import infrastructure services
import '../../../4_infrastructure/firebase/firestore_service.dart';

// Import data sources
import '../../../3_datasources/features/listings/listings_firestore_datasource.dart';

// Import contracts
import '../../../1_contracts/features/listings/listings_repository.dart';

// Import coordinators
import '../../../2_coordinators/features/listings/listings_repository_impl.dart';

// Import use cases
import '../../../../models/2_usecases/features/listings/get_active_listings_usecase.dart';
import '../../../../models/2_usecases/features/listings/get_listing_details_usecase.dart';
import '../../../../models/2_usecases/features/listings/create_listings_usecase.dart';

// Import BLoC
import '../../../../ui/1_state/features/listings/listings_bloc.dart';

/// Listings Feature Dependency Registration
class ListingDependencies {
  static Future<void> register(GetIt container) async {
    // Data Source
    container.registerLazySingleton<ListingsFirestoreDataSource>(
      () => ListingsFirestoreDataSource(container<FirestoreService>()),
    );

    // Coordinator (Repository Implementation)
    container.registerLazySingleton<IListingsRepository>(
      () => ListingsRepositoryImpl(container<ListingsFirestoreDataSource>()),
    );

    // Use Cases
    container.registerLazySingleton<GetActiveListingsUseCase>(
      () => GetActiveListingsUseCase(container<IListingsRepository>()),
    );

    container.registerLazySingleton<GetListingDetailsUseCase>(
      () => GetListingDetailsUseCase(container<IListingsRepository>()),
    );

    // ✅ NEW: Register CreateListingUseCase
    container.registerLazySingleton<CreateListingUseCase>(
      () => CreateListingUseCase(container<IListingsRepository>()),
    );

    // BLoC (Factory - new instance each time)
    container.registerFactory<ListingsBloc>(
      () => ListingsBloc(
        getActiveListingsUseCase: container<GetActiveListingsUseCase>(),
        getListingDetailsUseCase: container<GetListingDetailsUseCase>(),
        createListingUseCase: container<CreateListingUseCase>(),
      ),
    );

    print('📋 Listings dependencies registered');
  }
}