// lib/models/1_domain/shared/value_objects/property_specs.dart

import 'package:equatable/equatable.dart';

/// PropertySpecs value object for physical property characteristics
///
/// This immutable value object encapsulates all the measurable and
/// countable characteristics of a property. It handles validation,
/// formatting, and basic calculations for property specifications.
///
/// V1 Scope: Basic property specs for search filtering and display
class PropertySpecs extends Equatable {
  /// Property area in square meters
  final double areaM2;

  /// Number of bedrooms (null for commercial properties/terrenos)
  final int? bedrooms;

  /// Number of bathrooms (null for terrenos)
  final int? bathrooms;

  /// Number of parking spots (0 if none)
  final int parkingSpots;

  /// Property amenities and features
  final List<String> amenities;

  const PropertySpecs._({
    required this.areaM2,
    required this.parkingSpots,
    required this.amenities,
    this.bedrooms,
    this.bathrooms,
  });

  /// Creates PropertySpecs with validation
  factory PropertySpecs.create({
    required double areaM2,
    int? bedrooms,
    int? bathrooms,
    int parkingSpots = 0,
    List<String>? amenities,
  }) {
    final specs = PropertySpecs._(
      areaM2: areaM2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      amenities: amenities?.map((a) => a.trim()).toList() ?? [],
    );

    final violations = specs._validate();
    if (violations.isNotEmpty) {
      throw PropertySpecsException(
        'Invalid property specifications',
        violations,
      );
    }

    return specs;
  }

  /// Creates PropertySpecs for residential property (casa/departamento)
  factory PropertySpecs.createResidential({
    required double areaM2,
    required int bedrooms,
    required int bathrooms,
    int parkingSpots = 0,
    List<String>? amenities,
  }) {
    return PropertySpecs.create(
      areaM2: areaM2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      amenities: amenities,
    );
  }

  /// Creates PropertySpecs for terreno (no rooms)
  factory PropertySpecs.createTerreno({
    required double areaM2,
    int parkingSpots = 0,
    List<String>? amenities,
  }) {
    return PropertySpecs.create(
      areaM2: areaM2,
      bedrooms: null,
      bathrooms: null,
      parkingSpots: parkingSpots,
      amenities: amenities,
    );
  }

  // PROPERTY CALCULATIONS

  /// Calculates price per square meter
  double calculatePricePerM2(double totalPrice) {
    if (areaM2 <= 0) {
      throw ArgumentError(
        'Cannot calculate price per m² with zero or negative area',
      );
    }
    return totalPrice / areaM2;
  }

  /// Gets formatted price per m² for display
  String formatPricePerM2(double totalPrice, String currency) {
    final pricePerM2 = calculatePricePerM2(totalPrice);
    final symbol = currency == 'USD' ? 'US\$' : 'S/';

    if (pricePerM2 >= 1000) {
      return '$symbol ${(pricePerM2 / 1000).toStringAsFixed(1)}K/m²';
    } else {
      return '$symbol ${pricePerM2.toInt()}/m²';
    }
  }

  /// Checks if property has rooms (residential)
  bool hasRooms() {
    return bedrooms != null && bathrooms != null;
  }

  /// Checks if property has parking
  bool hasParking() {
    return parkingSpots > 0;
  }

  /// Checks if property has specific amenity
  bool hasAmenity(String amenity) {
    return amenities.any(
      (a) => a.toLowerCase().contains(amenity.toLowerCase()),
    );
  }

  // DISPLAY AND FORMATTING

  /// Gets property summary for listings (e.g., "3 hab, 2 baños, 120 m²")
  String getPropertySummary() {
    final parts = <String>[];

    if (bedrooms != null) {
      parts.add('$bedrooms hab');
    }

    if (bathrooms != null) {
      parts.add('$bathrooms baño${bathrooms! > 1 ? 's' : ''}');
    }

    parts.add('${areaM2.toInt()} m²');

    if (parkingSpots > 0) {
      parts.add('$parkingSpots cochera${parkingSpots > 1 ? 's' : ''}');
    }

    return parts.join(', ');
  }

  /// Gets detailed specifications for property page
  String getDetailedSpecs() {
    final buffer = StringBuffer();

    buffer.writeln('Área: ${areaM2.toInt()} m²');

    if (bedrooms != null) {
      buffer.writeln('Dormitorios: $bedrooms');
    }

    if (bathrooms != null) {
      buffer.writeln('Baños: $bathrooms');
    }

    if (parkingSpots > 0) {
      buffer.writeln('Estacionamientos: $parkingSpots');
    }

    if (amenities.isNotEmpty) {
      buffer.writeln('Características: ${amenities.join(', ')}');
    }

    return buffer.toString().trim();
  }

  /// Gets area display with proper formatting
  String getAreaDisplay() {
    if (areaM2 >= 1000) {
      return '${(areaM2 / 1000).toStringAsFixed(1)} mil m²';
    } else {
      return '${areaM2.toInt()} m²';
    }
  }

  /// Gets room summary (e.g., "3/2" for 3 bed, 2 bath)
  String? getRoomSummary() {
    if (bedrooms == null || bathrooms == null) return null;
    return '$bedrooms/$bathrooms';
  }

  // SEARCH AND FILTERING

  /// Checks if specs match search filters
  bool matchesFilters({
    int? minBedrooms,
    int? maxBedrooms,
    int? minBathrooms,
    int? maxBathrooms,
    double? minArea,
    double? maxArea,
    int? minParkingSpots,
    List<String>? requiredAmenities,
  }) {
    // Bedroom filtering
    if (minBedrooms != null) {
      if (bedrooms == null || bedrooms! < minBedrooms) return false;
    }

    if (maxBedrooms != null) {
      if (bedrooms == null || bedrooms! > maxBedrooms) return false;
    }

    // Bathroom filtering
    if (minBathrooms != null) {
      if (bathrooms == null || bathrooms! < minBathrooms) return false;
    }

    if (maxBathrooms != null) {
      if (bathrooms == null || bathrooms! > maxBathrooms) return false;
    }

    // Area filtering
    if (minArea != null && areaM2 < minArea) return false;
    if (maxArea != null && areaM2 > maxArea) return false;

    // Parking filtering
    if (minParkingSpots != null && parkingSpots < minParkingSpots) return false;

    // Amenities filtering
    if (requiredAmenities != null) {
      for (final requiredAmenity in requiredAmenities) {
        if (!hasAmenity(requiredAmenity)) return false;
      }
    }

    return true;
  }

  /// Gets size category for filtering
  PropertySizeCategory getSizeCategory() {
    if (areaM2 < 50) return PropertySizeCategory.small;
    if (areaM2 < 100) return PropertySizeCategory.medium;
    if (areaM2 < 200) return PropertySizeCategory.large;
    return PropertySizeCategory.extraLarge;
  }

  // AMENITY MANAGEMENT

  /// Adds amenity if not already present
  PropertySpecs addAmenity(String amenity) {
    final trimmedAmenity = amenity.trim();
    if (hasAmenity(trimmedAmenity)) return this;

    return PropertySpecs._(
      areaM2: areaM2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      amenities: [...amenities, trimmedAmenity],
    );
  }

  /// Removes amenity if present
  PropertySpecs removeAmenity(String amenity) {
    final filteredAmenities = amenities
        .where((a) => !a.toLowerCase().contains(amenity.toLowerCase()))
        .toList();

    return PropertySpecs._(
      areaM2: areaM2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      amenities: filteredAmenities,
    );
  }

  // VALIDATION

  /// Validates property specifications
  List<String> _validate() {
    final errors = <String>[];

    // Area validation
    if (areaM2 <= 0) {
      errors.add('Area must be greater than 0 square meters');
    }
    if (areaM2 > 50000) {
      errors.add('Area cannot exceed 50,000 square meters');
    }

    // Bedroom validation
    if (bedrooms != null) {
      if (bedrooms! < 1) {
        errors.add('Bedrooms must be at least 1 if specified');
      }
      if (bedrooms! > 20) {
        errors.add('Bedrooms cannot exceed 20');
      }
    }

    // Bathroom validation
    if (bathrooms != null) {
      if (bathrooms! < 1) {
        errors.add('Bathrooms must be at least 1 if specified');
      }
      if (bathrooms! > 15) {
        errors.add('Bathrooms cannot exceed 15');
      }
    }

    // Logical validation
    if (bathrooms != null && bedrooms != null) {
      if (bathrooms! > bedrooms! + 2) {
        errors.add('Bathrooms cannot exceed bedrooms by more than 2');
      }
    }

    // Parking validation
    if (parkingSpots < 0) {
      errors.add('Parking spots cannot be negative');
    }
    if (parkingSpots > 50) {
      errors.add('Parking spots cannot exceed 50');
    }

    // Amenities validation
    if (amenities.length > 30) {
      errors.add('Cannot have more than 30 amenities');
    }

    for (final amenity in amenities) {
      if (amenity.trim().isEmpty) {
        errors.add('Amenities cannot be empty');
      }
      if (amenity.length > 50) {
        errors.add('Amenity names cannot exceed 50 characters');
      }
    }

    return errors;
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object?> get props => [
    areaM2,
    bedrooms,
    bathrooms,
    parkingSpots,
    amenities,
  ];

  @override
  String toString() {
    return 'PropertySpecs(${getPropertySummary()})';
  }
}

/// Property size categories for filtering
enum PropertySizeCategory {
  small, // < 50 m²
  medium, // 50-100 m²
  large, // 100-200 m²
  extraLarge; // > 200 m²

  String get displayName {
    switch (this) {
      case PropertySizeCategory.small:
        return 'Pequeño (< 50 m²)';
      case PropertySizeCategory.medium:
        return 'Mediano (50-100 m²)';
      case PropertySizeCategory.large:
        return 'Grande (100-200 m²)';
      case PropertySizeCategory.extraLarge:
        return 'Extra Grande (> 200 m²)';
    }
  }
}

/// Exception for property specs validation errors
class PropertySpecsException implements Exception {
  final String message;
  final List<String> violations;

  const PropertySpecsException(this.message, this.violations);

  @override
  String toString() =>
      'PropertySpecsException: $message\nViolations: ${violations.join(', ')}';
}

/// PropertySpecs domain service for common operations
class PropertySpecsDomainService {
  /// Common amenities in Peru properties (for reference/suggestions)
  static const List<String> commonAmenities = [
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

  /// Validates property specs for listing creation
  static List<String> validateForListing(PropertySpecs specs) {
    final errors = <String>[];

    // Area should be reasonable for the property type
    if (specs.hasRooms()) {
      // Residential properties
      if (specs.areaM2 < 20) {
        errors.add('Residential property area seems too small (< 20 m²)');
      }

      // Bedroom density check
      final areaPerBedroom = specs.areaM2 / (specs.bedrooms ?? 1);
      if (areaPerBedroom < 8) {
        errors.add('Property seems too small for the number of bedrooms');
      }
    } else {
      // Commercial/terreno properties
      if (specs.areaM2 < 50) {
        errors.add('Commercial property or terreno area seems small');
      }
    }

    return errors;
  }

  /// Estimates property value category based on specs
  static PropertyValueCategory estimateValueCategory(PropertySpecs specs) {
    var score = 0;

    // Area contribution
    if (specs.areaM2 > 200) {
      score += 3;
    } else if (specs.areaM2 > 100) {
      score += 2;
    } else if (specs.areaM2 > 50) {
      score += 1;
    }

    // Rooms contribution
    if (specs.bedrooms != null && specs.bedrooms! >= 4) {
      score += 2;
    } else if (specs.bedrooms != null && specs.bedrooms! >= 3) {
      score += 1;
    }

    if (specs.bathrooms != null && specs.bathrooms! >= 3) {
      score += 2;
    } else if (specs.bathrooms != null && specs.bathrooms! >= 2) {
      score += 1;
    }

    // Parking contribution
    if (specs.parkingSpots >= 2) {
      score += 2;
    } else if (specs.parkingSpots >= 1) {
      score += 1;
    }

    // Amenities contribution
    if (specs.amenities.length >= 5) {
      score += 2;
    } else if (specs.amenities.length >= 3) {
      score += 1;
    }

    if (score >= 8) return PropertyValueCategory.premium;
    if (score >= 5) return PropertyValueCategory.mid;
    return PropertyValueCategory.basic;
  }

  /// Compares two property specs for similarity
  static double calculateSimilarity(
    PropertySpecs specs1,
    PropertySpecs specs2,
  ) {
    var similarity = 0.0;

    // Area similarity (40% weight)
    final areaDifference =
        (specs1.areaM2 - specs2.areaM2).abs() /
        ((specs1.areaM2 + specs2.areaM2) / 2);
    similarity += (1 - areaDifference.clamp(0, 1)) * 0.4;

    // Bedroom similarity (20% weight)
    if (specs1.bedrooms != null && specs2.bedrooms != null) {
      final bedroomDiff = (specs1.bedrooms! - specs2.bedrooms!).abs();
      similarity += (1 - (bedroomDiff / 5).clamp(0, 1)) * 0.2;
    }

    // Bathroom similarity (20% weight)
    if (specs1.bathrooms != null && specs2.bathrooms != null) {
      final bathroomDiff = (specs1.bathrooms! - specs2.bathrooms!).abs();
      similarity += (1 - (bathroomDiff / 3).clamp(0, 1)) * 0.2;
    }

    // Parking similarity (10% weight)
    final parkingDiff = (specs1.parkingSpots - specs2.parkingSpots).abs();
    similarity += (1 - (parkingDiff / 3).clamp(0, 1)) * 0.1;

    // Amenity similarity (10% weight)
    final commonAmenitiesCount = specs1.amenities
        .where(
          (a1) => specs2.amenities.any(
            (a2) =>
                a1.toLowerCase().contains(a2.toLowerCase()) ||
                a2.toLowerCase().contains(a1.toLowerCase()),
          ),
        )
        .length;

    final maxAmenities = [
      specs1.amenities.length,
      specs2.amenities.length,
      1,
    ].reduce((a, b) => a > b ? a : b);
    similarity += (commonAmenitiesCount / maxAmenities) * 0.1;

    return similarity.clamp(0, 1);
  }
}

/// Property value categories for comparison
enum PropertyValueCategory {
  basic,
  mid,
  premium;

  String get displayName {
    switch (this) {
      case PropertyValueCategory.basic:
        return 'Básico';
      case PropertyValueCategory.mid:
        return 'Intermedio';
      case PropertyValueCategory.premium:
        return 'Premium';
    }
  }
}
