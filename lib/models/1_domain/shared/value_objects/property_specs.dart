// lib/models/1_domain/shared/value_objects/property_specs.dart

import 'package:equatable/equatable.dart';

/// PropertySpecs value object for physical property characteristics
///
/// Encapsulates measurable property attributes because Peru's real estate market
/// heavily relies on accurate specifications for pricing, filtering, and buyer decisions.
/// Immutable design prevents data corruption during property lifecycle.
///
/// V1 Scope: Basic property specs for search filtering and display
class PropertySpecs extends Equatable {
  /// Property area in square meters
  /// Critical for pricing calculations and legal documentation in Peru
  final double totalAreaInSquareMeters;

  /// Number of bedrooms (null for commercial properties/terrenos)
  /// Optional because commercial properties and land don't have bedrooms
  final int? bedroomCount;

  /// Number of bathrooms (null for terrenos)
  /// Optional because raw land doesn't have bathrooms
  final int? bathroomCount;

  /// Number of available parking spaces (0 if none)
  /// Important in Peru's urban areas where parking is scarce and valuable
  final int availableParkingSpaces;

  /// Property amenities and features list
  /// Stored as list because amenities vary widely and affect property value significantly
  final List<String> propertyAmenities;

  const PropertySpecs._({
    required this.totalAreaInSquareMeters,
    required this.availableParkingSpaces,
    required this.propertyAmenities,
    this.bedroomCount,
    this.bathroomCount,
  });

  /// Creates PropertySpecs with comprehensive validation
  /// Validation prevents invalid data that would break pricing and search functionality
  factory PropertySpecs.create({
    required double totalAreaInSquareMeters,
    int? bedroomCount,
    int? bathroomCount,
    int availableParkingSpaces = 0,
    List<String>? propertyAmenities,
  }) {
    final specs = PropertySpecs._(
      totalAreaInSquareMeters: totalAreaInSquareMeters,
      bedroomCount: bedroomCount,
      bathroomCount: bathroomCount,
      availableParkingSpaces: availableParkingSpaces,
      propertyAmenities:
          propertyAmenities?.map((amenity) => amenity.trim()).toList() ?? [],
    );

    final validationErrors = specs._validatePropertySpecifications();
    if (validationErrors.isNotEmpty) {
      throw PropertySpecsValidationException(
        'Invalid property specifications',
        validationErrors,
      );
    }

    return specs;
  }

  /// Creates PropertySpecs for residential properties (casa/departamento)
  /// Separate factory ensures residential properties always have room counts
  factory PropertySpecs.createForResidentialProperty({
    required double totalAreaInSquareMeters,
    required int bedroomCount,
    required int bathroomCount,
    int availableParkingSpaces = 0,
    List<String>? propertyAmenities,
  }) {
    return PropertySpecs.create(
      totalAreaInSquareMeters: totalAreaInSquareMeters,
      bedroomCount: bedroomCount,
      bathroomCount: bathroomCount,
      availableParkingSpaces: availableParkingSpaces,
      propertyAmenities: propertyAmenities,
    );
  }

  /// Creates PropertySpecs for terreno (land without structures)
  /// Separate factory prevents accidental room assignments to land
  factory PropertySpecs.createForLandProperty({
    required double totalAreaInSquareMeters,
    int availableParkingSpaces = 0,
    List<String>? propertyAmenities,
  }) {
    return PropertySpecs.create(
      totalAreaInSquareMeters: totalAreaInSquareMeters,
      bedroomCount: null,
      bathroomCount: null,
      availableParkingSpaces: availableParkingSpaces,
      propertyAmenities: propertyAmenities,
    );
  }

  // PROPERTY CALCULATIONS

  /// Calculates price per square meter for valuation analysis
  /// Critical metric for Peru real estate market pricing and comparison
  double calculatePricePerSquareMeter(double totalPropertyPrice) {
    if (totalAreaInSquareMeters <= 0) {
      throw ArgumentError(
        'Cannot calculate price per m² with zero or negative area',
      );
    }
    return totalPropertyPrice / totalAreaInSquareMeters;
  }

  /// Formats price per square meter for user interface display
  /// Format matches Peru market conventions for easy user comprehension
  String formatPricePerSquareMeterForDisplay(
    double totalPropertyPrice,
    String currencyCode,
  ) {
    final pricePerSquareMeter = calculatePricePerSquareMeter(
      totalPropertyPrice,
    );
    final currencySymbol = currencyCode == 'USD' ? 'US\$' : 'S/';

    if (pricePerSquareMeter >= 1000) {
      return '$currencySymbol ${(pricePerSquareMeter / 1000).toStringAsFixed(1)}K/m²';
    } else {
      return '$currencySymbol ${pricePerSquareMeter.toInt()}/m²';
    }
  }

  /// Determines if property has residential room structure
  /// Used to differentiate between residential and commercial/land properties
  bool hasResidentialRoomStructure() {
    return bedroomCount != null && bathroomCount != null;
  }

  /// Determines if property offers parking facilities
  /// Important for urban Peru where parking availability affects property value
  bool hasParkingFacilities() {
    return availableParkingSpaces > 0;
  }

  /// Checks if property includes specific amenity
  /// Case-insensitive search because user input varies in capitalization
  bool includesAmenity(String targetAmenity) {
    return propertyAmenities.any(
      (existingAmenity) =>
          existingAmenity.toLowerCase().contains(targetAmenity.toLowerCase()),
    );
  }

  // DISPLAY AND FORMATTING

  /// Generates concise property summary for listing cards
  /// Format optimized for Peru market expectations (Spanish abbreviations)
  String generateListingCardSummary() {
    final summaryParts = <String>[];

    if (bedroomCount != null) {
      summaryParts.add('$bedroomCount hab');
    }

    if (bathroomCount != null) {
      summaryParts.add('$bathroomCount baño${bathroomCount! > 1 ? 's' : ''}');
    }

    summaryParts.add('${totalAreaInSquareMeters.toInt()} m²');

    if (availableParkingSpaces > 0) {
      summaryParts.add(
        '$availableParkingSpaces cochera${availableParkingSpaces > 1 ? 's' : ''}',
      );
    }

    return summaryParts.join(', ');
  }

  /// Generates detailed specifications for property detail pages
  /// Multi-line format provides comprehensive property information
  String generateDetailedSpecificationsList() {
    final specificationBuffer = StringBuffer();

    specificationBuffer.writeln(
      'Área Total: ${totalAreaInSquareMeters.toInt()} m²',
    );

    if (bedroomCount != null) {
      specificationBuffer.writeln('Dormitorios: $bedroomCount');
    }

    if (bathroomCount != null) {
      specificationBuffer.writeln('Baños: $bathroomCount');
    }

    if (availableParkingSpaces > 0) {
      specificationBuffer.writeln('Estacionamientos: $availableParkingSpaces');
    }

    if (propertyAmenities.isNotEmpty) {
      specificationBuffer.writeln(
        'Características Adicionales: ${propertyAmenities.join(', ')}',
      );
    }

    return specificationBuffer.toString().trim();
  }

  /// Formats area for user-friendly display with appropriate units
  /// Uses thousands separator for large areas common in commercial properties
  String formatAreaForUserDisplay() {
    if (totalAreaInSquareMeters >= 1000) {
      return '${(totalAreaInSquareMeters / 1000).toStringAsFixed(1)} mil m²';
    } else {
      return '${totalAreaInSquareMeters.toInt()} m²';
    }
  }

  /// Generates compact room count summary for filter displays
  /// Returns null for non-residential properties to avoid confusion
  String? generateRoomCountSummary() {
    if (bedroomCount == null || bathroomCount == null) return null;
    return '$bedroomCount/$bathroomCount';
  }

  // SEARCH AND FILTERING

  /// Evaluates if property specifications match search criteria
  /// Comprehensive filtering enables precise property discovery
  bool matchesSearchFilters({
    int? minimumBedroomCount,
    int? maximumBedroomCount,
    int? minimumBathroomCount,
    int? maximumBathroomCount,
    double? minimumAreaInSquareMeters,
    double? maximumAreaInSquareMeters,
    int? minimumParkingSpaces,
    List<String>? requiredAmenities,
  }) {
    // Bedroom count filtering
    if (minimumBedroomCount != null) {
      if (bedroomCount == null || bedroomCount! < minimumBedroomCount) {
        return false;
      }
    }

    if (maximumBedroomCount != null) {
      if (bedroomCount == null || bedroomCount! > maximumBedroomCount) {
        return false;
      }
    }

    // Bathroom count filtering
    if (minimumBathroomCount != null) {
      if (bathroomCount == null || bathroomCount! < minimumBathroomCount) {
        return false;
      }
    }

    if (maximumBathroomCount != null) {
      if (bathroomCount == null || bathroomCount! > maximumBathroomCount) {
        return false;
      }
    }

    // Area filtering
    if (minimumAreaInSquareMeters != null &&
        totalAreaInSquareMeters < minimumAreaInSquareMeters) {
      return false;
    }
    if (maximumAreaInSquareMeters != null &&
        totalAreaInSquareMeters > maximumAreaInSquareMeters) {
      return false;
    }

    // Parking filtering
    if (minimumParkingSpaces != null &&
        availableParkingSpaces < minimumParkingSpaces) {
      return false;
    }

    // Amenities filtering - all required amenities must be present
    if (requiredAmenities != null) {
      for (final requiredAmenity in requiredAmenities) {
        if (!includesAmenity(requiredAmenity)) return false;
      }
    }

    return true;
  }

  /// Categorizes property size for filtering and comparison
  /// Categories align with Peru real estate market segments
  PropertySizeCategory determinePropertySizeCategory() {
    if (totalAreaInSquareMeters < 50) return PropertySizeCategory.compact;
    if (totalAreaInSquareMeters < 100) return PropertySizeCategory.standard;
    if (totalAreaInSquareMeters < 200) return PropertySizeCategory.spacious;
    return PropertySizeCategory.expansive;
  }

  // AMENITY MANAGEMENT

  /// Adds new amenity to property while preventing duplicates
  /// Returns new instance maintaining immutability
  PropertySpecs addPropertyAmenity(String newAmenity) {
    final sanitizedAmenity = newAmenity.trim();
    if (includesAmenity(sanitizedAmenity)) return this;

    return PropertySpecs._(
      totalAreaInSquareMeters: totalAreaInSquareMeters,
      bedroomCount: bedroomCount,
      bathroomCount: bathroomCount,
      availableParkingSpaces: availableParkingSpaces,
      propertyAmenities: [...propertyAmenities, sanitizedAmenity],
    );
  }

  /// Removes amenity from property if present
  /// Case-insensitive removal to handle user input variations
  PropertySpecs removePropertyAmenity(String amenityToRemove) {
    final updatedAmenities = propertyAmenities
        .where(
          (existingAmenity) => !existingAmenity.toLowerCase().contains(
            amenityToRemove.toLowerCase(),
          ),
        )
        .toList();

    return PropertySpecs._(
      totalAreaInSquareMeters: totalAreaInSquareMeters,
      bedroomCount: bedroomCount,
      bathroomCount: bathroomCount,
      availableParkingSpaces: availableParkingSpaces,
      propertyAmenities: updatedAmenities,
    );
  }

  // VALIDATION

  /// Validates all property specification fields comprehensively
  /// Prevents invalid data that would break property functionality and user experience
  List<String> _validatePropertySpecifications() {
    final validationErrors = <String>[];

    // Area validation - critical for all property calculations
    if (totalAreaInSquareMeters <= 0) {
      validationErrors.add('Total area must be greater than 0 square meters');
    }
    if (totalAreaInSquareMeters > 50000) {
      validationErrors.add(
        'Total area cannot exceed 50,000 square meters (unrealistic for individual properties)',
      );
    }

    // Bedroom validation - ensures reasonable residential property configuration
    if (bedroomCount != null) {
      if (bedroomCount! < 1) {
        validationErrors.add('Bedroom count must be at least 1 if specified');
      }
      if (bedroomCount! > 20) {
        validationErrors.add(
          'Bedroom count cannot exceed 20 (unrealistic for residential properties)',
        );
      }
    }

    // Bathroom validation - ensures practical property configuration
    if (bathroomCount != null) {
      if (bathroomCount! < 1) {
        validationErrors.add('Bathroom count must be at least 1 if specified');
      }
      if (bathroomCount! > 15) {
        validationErrors.add(
          'Bathroom count cannot exceed 15 (unrealistic for residential properties)',
        );
      }
    }

    // Room count relationship validation - maintains logical property structure
    if (bathroomCount != null && bedroomCount != null) {
      if (bathroomCount! > bedroomCount! + 2) {
        validationErrors.add(
          'Bathroom count cannot exceed bedroom count by more than 2 (unusual property configuration)',
        );
      }
    }

    // Parking validation - ensures realistic parking arrangements
    if (availableParkingSpaces < 0) {
      validationErrors.add('Available parking spaces cannot be negative');
    }
    if (availableParkingSpaces > 50) {
      validationErrors.add(
        'Available parking spaces cannot exceed 50 (unrealistic for individual properties)',
      );
    }

    // Amenities validation - prevents system abuse and maintains data quality
    if (propertyAmenities.length > 30) {
      validationErrors.add(
        'Cannot have more than 30 amenities (excessive for property listings)',
      );
    }

    for (final amenity in propertyAmenities) {
      if (amenity.trim().isEmpty) {
        validationErrors.add('Property amenities cannot be empty strings');
      }
      if (amenity.length > 50) {
        validationErrors.add(
          'Amenity descriptions cannot exceed 50 characters',
        );
      }
    }

    // Area-to-room density validation - ensures realistic living space
    if (hasResidentialRoomStructure()) {
      final areaPerBedroom = totalAreaInSquareMeters / bedroomCount!;
      if (areaPerBedroom < 8) {
        validationErrors.add(
          'Area per bedroom is unrealistically small (less than 8 m² per bedroom)',
        );
      }
      if (areaPerBedroom > 200) {
        validationErrors.add(
          'Area per bedroom is unrealistically large (more than 200 m² per bedroom)',
        );
      }
    }

    return validationErrors;
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object?> get props => [
    totalAreaInSquareMeters,
    bedroomCount,
    bathroomCount,
    availableParkingSpaces,
    propertyAmenities,
  ];

  @override
  String toString() {
    return 'PropertySpecs(${generateListingCardSummary()})';
  }
}

/// Property size categories for filtering and market segmentation
/// Categories reflect Peru real estate market standards and user search patterns
enum PropertySizeCategory {
  compact, // < 50 m²
  standard, // 50-100 m²
  spacious, // 100-200 m²
  expansive; // > 200 m²

  /// Provides localized category labels for user interface components
  String get categoryDisplayLabel {
    switch (this) {
      case PropertySizeCategory.compact:
        return 'Compacto (< 50 m²)';
      case PropertySizeCategory.standard:
        return 'Estándar (50-100 m²)';
      case PropertySizeCategory.spacious:
        return 'Espacioso (100-200 m²)';
      case PropertySizeCategory.expansive:
        return 'Amplio (> 200 m²)';
    }
  }
}

/// Exception for property specs validation errors
/// Specific exception type enables targeted error handling in application layers
class PropertySpecsValidationException implements Exception {
  final String message;
  final List<String> violations;

  const PropertySpecsValidationException(this.message, this.violations);

  @override
  String toString() =>
      'PropertySpecsValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// PropertySpecs domain service for common operations and business logic
/// Centralized service reduces code duplication and ensures consistent behavior
class PropertySpecsDomainService {
  /// Standard amenities commonly found in Peru properties
  /// Predefined list improves data consistency and provides autocomplete options
  static const List<String> standardPeruPropertyAmenities = [
    'Piscina',
    'Jardín',
    'Balcón',
    'Terraza',
    'Aire Acondicionado',
    'Calefacción',
    'Amoblado',
    'Semi Amoblado',
    'Cocina Equipada',
    'Lavandería',
    'Portón Eléctrico',
    'Seguridad 24h',
    'Gimnasio',
    'Ascensor',
    'Intercomunicador',
    'Vista al Mar',
    'Vista a la Ciudad',
    'Cerca al Centro',
    'Transporte Público',
  ];

  /// Validates property specs specifically for listing publication requirements
  /// Additional validation ensures listing quality and prevents problematic publications
  static List<String> validateSpecificationsForListingPublication(
    PropertySpecs specifications,
  ) {
    final listingValidationErrors = <String>[];

    // Area reasonableness checks for different property types
    if (specifications.hasResidentialRoomStructure()) {
      // Residential properties need minimum viable living space
      if (specifications.totalAreaInSquareMeters < 20) {
        listingValidationErrors.add(
          'Residential property area seems unrealistically small (< 20 m²)',
        );
      }

      // Bedroom density validation prevents misleading listings
      final areaPerBedroom =
          specifications.totalAreaInSquareMeters /
          (specifications.bedroomCount ?? 1);
      if (areaPerBedroom < 8) {
        listingValidationErrors.add(
          'Property appears too small for the specified number of bedrooms',
        );
      }
    } else {
      // Commercial/land properties have different minimum size expectations
      if (specifications.totalAreaInSquareMeters < 50) {
        listingValidationErrors.add(
          'Commercial property or land area seems unusually small',
        );
      }
    }

    // Parking validation for urban context
    if (specifications.availableParkingSpaces >
        specifications.totalAreaInSquareMeters / 20) {
      listingValidationErrors.add(
        'Parking space count seems excessive relative to property size',
      );
    }

    return listingValidationErrors;
  }

  /// Estimates property market value category based on specifications
  /// Scoring system helps users and algorithms categorize properties appropriately
  static PropertyMarketValueCategory estimateMarketValueCategory(
    PropertySpecs specifications,
  ) {
    var valueScore = 0;

    // Area contribution to value assessment
    if (specifications.totalAreaInSquareMeters > 200) {
      valueScore += 3;
    } else if (specifications.totalAreaInSquareMeters > 100) {
      valueScore += 2;
    } else if (specifications.totalAreaInSquareMeters > 50) {
      valueScore += 1;
    }

    // Room count contribution to value assessment
    if (specifications.bedroomCount != null &&
        specifications.bedroomCount! >= 4) {
      valueScore += 2;
    } else if (specifications.bedroomCount != null &&
        specifications.bedroomCount! >= 3) {
      valueScore += 1;
    }

    if (specifications.bathroomCount != null &&
        specifications.bathroomCount! >= 3) {
      valueScore += 2;
    } else if (specifications.bathroomCount != null &&
        specifications.bathroomCount! >= 2) {
      valueScore += 1;
    }

    // Parking contribution reflects Peru urban property value factors
    if (specifications.availableParkingSpaces >= 2) {
      valueScore += 2;
    } else if (specifications.availableParkingSpaces >= 1) {
      valueScore += 1;
    }

    // Amenities contribution to overall property appeal
    if (specifications.propertyAmenities.length >= 5) {
      valueScore += 2;
    } else if (specifications.propertyAmenities.length >= 3) {
      valueScore += 1;
    }

    if (valueScore >= 8) return PropertyMarketValueCategory.premium;
    if (valueScore >= 5) return PropertyMarketValueCategory.midRange;
    return PropertyMarketValueCategory.economic;
  }

  /// Calculates similarity score between two property specifications
  /// Similarity algorithm enables property recommendation and comparison features
  static double calculateSpecificationSimilarity(
    PropertySpecs firstProperty,
    PropertySpecs secondProperty,
  ) {
    var totalSimilarityScore = 0.0;

    // Area similarity weighted at 40% due to high importance in property comparison
    final areaPercentageDifference =
        (firstProperty.totalAreaInSquareMeters -
                secondProperty.totalAreaInSquareMeters)
            .abs() /
        ((firstProperty.totalAreaInSquareMeters +
                secondProperty.totalAreaInSquareMeters) /
            2);
    totalSimilarityScore += (1 - areaPercentageDifference.clamp(0, 1)) * 0.4;

    // Bedroom similarity weighted at 20% for residential property comparison
    if (firstProperty.bedroomCount != null &&
        secondProperty.bedroomCount != null) {
      final bedroomCountDifference =
          (firstProperty.bedroomCount! - secondProperty.bedroomCount!).abs();
      totalSimilarityScore +=
          (1 - (bedroomCountDifference / 5).clamp(0, 1)) * 0.2;
    }

    // Bathroom similarity weighted at 20% for practical living space comparison
    if (firstProperty.bathroomCount != null &&
        secondProperty.bathroomCount != null) {
      final bathroomCountDifference =
          (firstProperty.bathroomCount! - secondProperty.bathroomCount!).abs();
      totalSimilarityScore +=
          (1 - (bathroomCountDifference / 3).clamp(0, 1)) * 0.2;
    }

    // Parking similarity weighted at 10% for urban property value comparison
    final parkingDifference =
        (firstProperty.availableParkingSpaces -
                secondProperty.availableParkingSpaces)
            .abs();
    totalSimilarityScore += (1 - (parkingDifference / 3).clamp(0, 1)) * 0.1;

    // Amenity overlap similarity weighted at 10% for lifestyle compatibility
    final sharedAmenitiesCount = firstProperty.propertyAmenities
        .where(
          (firstPropertyAmenity) => secondProperty.propertyAmenities.any(
            (secondPropertyAmenity) =>
                firstPropertyAmenity.toLowerCase().contains(
                  secondPropertyAmenity.toLowerCase(),
                ) ||
                secondPropertyAmenity.toLowerCase().contains(
                  firstPropertyAmenity.toLowerCase(),
                ),
          ),
        )
        .length;

    final maximumAmenitiesCount = [
      firstProperty.propertyAmenities.length,
      secondProperty.propertyAmenities.length,
      1,
    ].reduce((a, b) => a > b ? a : b);
    totalSimilarityScore +=
        (sharedAmenitiesCount / maximumAmenitiesCount) * 0.1;

    return totalSimilarityScore.clamp(0, 1);
  }
}

/// Property market value categories for pricing and comparison analysis
/// Categories reflect Peru real estate market segments and consumer expectations
enum PropertyMarketValueCategory {
  economic,
  midRange,
  premium;

  /// Provides localized category labels for market positioning display
  String get marketSegmentLabel {
    switch (this) {
      case PropertyMarketValueCategory.economic:
        return 'Económico';
      case PropertyMarketValueCategory.midRange:
        return 'Rango Medio';
      case PropertyMarketValueCategory.premium:
        return 'Premium';
    }
  }
}
