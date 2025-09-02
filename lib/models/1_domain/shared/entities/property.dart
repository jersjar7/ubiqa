// lib/models/1_domain/shared/entities/property.dart

import 'package:equatable/equatable.dart';

/// Strongly-typed identifier for Property entities
class PropertyId extends Equatable {
  final String value;

  const PropertyId._(this.value);

  /// Creates PropertyId from string with validation
  factory PropertyId.fromString(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('PropertyId cannot be empty');
    }
    return PropertyId._(id.trim());
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

/// Property types common in Peru real estate market
enum PropertyType {
  casa,
  departamento,
  terreno,
  oficina,
  local;

  /// User-friendly labels for UI
  String get displayName {
    switch (this) {
      case PropertyType.casa:
        return 'Casa';
      case PropertyType.departamento:
        return 'Departamento';
      case PropertyType.terreno:
        return 'Terreno';
      case PropertyType.oficina:
        return 'Oficina';
      case PropertyType.local:
        return 'Local Comercial';
    }
  }

  /// Whether this property type typically has rooms
  bool get hasRooms {
    return this == PropertyType.casa || this == PropertyType.departamento;
  }

  /// Whether this property type is residential
  bool get isResidential {
    return this == PropertyType.casa || this == PropertyType.departamento;
  }
}

/// Operation types for property transactions
enum OperationType {
  venta,
  alquiler;

  /// User-friendly labels for UI
  String get displayName {
    switch (this) {
      case OperationType.venta:
        return 'Venta';
      case OperationType.alquiler:
        return 'Alquiler';
    }
  }

  /// Currency typically used for this operation in Peru
  String get typicalCurrency {
    switch (this) {
      case OperationType.venta:
        return 'USD'; // Sales often in dollars
      case OperationType.alquiler:
        return 'PEN'; // Rentals often in soles
    }
  }
}

/// Property entity representing real estate being offered on the platform
///
/// Business Concept: A Property is the physical real estate that can be
/// listed multiple times by different users over time. The same apartment
/// might have multiple listings across different periods.
///
/// Core Responsibilities:
/// - Physical characteristics (bedrooms, area, amenities)
/// - Location information
/// - Property type and operation classification
/// - Basic validation for property data quality
class Property extends Equatable {
  /// Unique identifier for this property
  final PropertyId id;

  /// Type of property (casa, departamento, etc.)
  final PropertyType propertyType;

  /// Type of operation (venta, alquiler)
  final OperationType operationType;

  /// Property area in square meters
  final double areaM2;

  /// Number of bedrooms (null for terrenos/oficinas)
  final int? bedrooms;

  /// Number of bathrooms (null for terrenos)
  final int? bathrooms;

  /// Number of parking spots (0 if none)
  final int parkingSpots;

  /// Property address or reference location
  final String address;

  /// Piura district where property is located
  final String district;

  /// GPS coordinates for map display
  final double? latitude;
  final double? longitude;

  /// Property amenities and features
  final List<String> amenities;

  /// When property was added to platform
  final DateTime createdAt;

  /// Last time property info was updated
  final DateTime updatedAt;

  /// Whether property is available for new listings
  final bool isAvailable;

  const Property._({
    required this.id,
    required this.propertyType,
    required this.operationType,
    required this.areaM2,
    required this.address,
    required this.district,
    required this.parkingSpots,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
    required this.isAvailable,
    this.bedrooms,
    this.bathrooms,
    this.latitude,
    this.longitude,
  });

  /// Factory: Create new property
  factory Property.create({
    required PropertyId id,
    required PropertyType propertyType,
    required OperationType operationType,
    required double areaM2,
    required String address,
    required String district,
    int? bedrooms,
    int? bathrooms,
    int parkingSpots = 0,
    double? latitude,
    double? longitude,
    List<String>? amenities,
  }) {
    final now = DateTime.now();
    return Property._(
      id: id,
      propertyType: propertyType,
      operationType: operationType,
      areaM2: areaM2,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      address: address.trim(),
      district: district.trim(),
      latitude: latitude,
      longitude: longitude,
      amenities: amenities ?? [],
      createdAt: now,
      updatedAt: now,
      isAvailable: true,
    );
  }

  /// Creates copy with updated fields
  Property copyWith({
    PropertyType? propertyType,
    OperationType? operationType,
    double? areaM2,
    int? bedrooms,
    int? bathrooms,
    int? parkingSpots,
    String? address,
    String? district,
    double? latitude,
    double? longitude,
    List<String>? amenities,
    DateTime? updatedAt,
    bool? isAvailable,
  }) {
    return Property._(
      id: id,
      propertyType: propertyType ?? this.propertyType,
      operationType: operationType ?? this.operationType,
      areaM2: areaM2 ?? this.areaM2,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      parkingSpots: parkingSpots ?? this.parkingSpots,
      address: address ?? this.address,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // PROPERTY BUSINESS LOGIC

  /// Whether property has location coordinates for map display
  bool hasGpsCoordinates() {
    return latitude != null && longitude != null;
  }

  /// Whether property has complete room information
  bool hasCompleteRoomInfo() {
    if (!propertyType.hasRooms) return true; // Terrenos don't need room info
    return bedrooms != null && bathrooms != null;
  }

  /// Gets property size category for filtering
  PropertySizeCategory getSizeCategory() {
    if (areaM2 < 50) return PropertySizeCategory.small;
    if (areaM2 < 100) return PropertySizeCategory.medium;
    if (areaM2 < 200) return PropertySizeCategory.large;
    return PropertySizeCategory.extraLarge;
  }

  /// Gets property description summary for display
  String getPropertySummary() {
    final buffer = StringBuffer();

    if (bedrooms != null && bathrooms != null) {
      buffer.write('$bedrooms hab, $bathrooms baños, ');
    }

    buffer.write('${areaM2.toInt()} m²');

    if (parkingSpots > 0) {
      buffer.write(', $parkingSpots cochera${parkingSpots > 1 ? 's' : ''}');
    }

    return buffer.toString();
  }

  /// Gets formatted address for display
  String getFormattedAddress() {
    return '$address, $district';
  }

  /// Calculates approximate price per m² for comparison
  double? calculatePricePerM2(double totalPrice) {
    if (areaM2 <= 0) return null;
    return totalPrice / areaM2;
  }

  /// Validates property data against business rules
  List<String> validateBusinessRules() {
    final errors = <String>[];

    // Area validation
    if (areaM2 <= 0) {
      errors.add('Area must be greater than 0 square meters');
    }
    if (areaM2 > 10000) {
      errors.add('Area cannot exceed 10,000 square meters');
    }

    // Room validation for residential properties
    if (propertyType.hasRooms) {
      if (bedrooms == null || bedrooms! < 1) {
        errors.add('${propertyType.displayName} must have at least 1 bedroom');
      }
      if (bathrooms == null || bathrooms! < 1) {
        errors.add('${propertyType.displayName} must have at least 1 bathroom');
      }

      if (bedrooms != null && bedrooms! > 20) {
        errors.add('Bedrooms cannot exceed 20');
      }
      if (bathrooms != null && bathrooms! > 10) {
        errors.add('Bathrooms cannot exceed 10');
      }
    }

    // Parking validation
    if (parkingSpots < 0 || parkingSpots > 50) {
      errors.add('Parking spots must be between 0 and 50');
    }

    // Address validation
    if (address.trim().length < 10) {
      errors.add('Address must be at least 10 characters');
    }
    if (district.trim().isEmpty) {
      errors.add('District is required');
    }

    // GPS coordinates validation
    if (latitude != null) {
      if (latitude! < -90 || latitude! > 90) {
        errors.add('Invalid latitude value');
      }
    }
    if (longitude != null) {
      if (longitude! < -180 || longitude! > 180) {
        errors.add('Invalid longitude value');
      }
    }

    // Amenities validation
    if (amenities.length > 50) {
      errors.add('Cannot have more than 50 amenities');
    }

    return errors;
  }

  /// Checks if property matches search filters
  bool matchesFilters({
    PropertyType? filterPropertyType,
    OperationType? filterOperationType,
    int? minBedrooms,
    int? maxBedrooms,
    double? minArea,
    double? maxArea,
    String? filterDistrict,
    List<String>? requiredAmenities,
  }) {
    if (filterPropertyType != null && propertyType != filterPropertyType) {
      return false;
    }

    if (filterOperationType != null && operationType != filterOperationType) {
      return false;
    }

    if (minBedrooms != null && (bedrooms == null || bedrooms! < minBedrooms)) {
      return false;
    }

    if (maxBedrooms != null && (bedrooms == null || bedrooms! > maxBedrooms)) {
      return false;
    }

    if (minArea != null && areaM2 < minArea) {
      return false;
    }

    if (maxArea != null && areaM2 > maxArea) {
      return false;
    }

    if (filterDistrict != null &&
        !district.toLowerCase().contains(filterDistrict.toLowerCase())) {
      return false;
    }

    if (requiredAmenities != null) {
      for (final requiredAmenity in requiredAmenities) {
        if (!amenities.any(
          (a) => a.toLowerCase().contains(requiredAmenity.toLowerCase()),
        )) {
          return false;
        }
      }
    }

    return true;
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'Property(id: ${id.value}, type: ${propertyType.name}, ${getPropertySummary()})';
  }
}

/// Property size categories for filtering and display
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

/// Domain exception for property business rule violations
class PropertyDomainException implements Exception {
  final String message;
  final List<String> violations;

  const PropertyDomainException(this.message, this.violations);

  @override
  String toString() =>
      'PropertyDomainException: $message\nViolations: ${violations.join(', ')}';
}

/// Property domain service for validation and creation
class PropertyDomainService {
  /// Standard amenities common in Piura properties
  static const List<String> standardAmenities = [
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
  ];

  /// Common Piura districts for validation
  static const List<String> piuraDistricts = [
    'Piura',
    'Castilla',
    'Catacaos',
    'Cura Mori',
    'El Tallán',
    'La Arena',
    'La Unión',
    'Las Lomas',
    'Tambo Grande',
  ];

  /// Creates property with validation
  static Property createPropertyWithValidation({
    required PropertyId id,
    required PropertyType propertyType,
    required OperationType operationType,
    required double areaM2,
    required String address,
    required String district,
    int? bedrooms,
    int? bathrooms,
    int parkingSpots = 0,
    double? latitude,
    double? longitude,
    List<String>? amenities,
  }) {
    final property = Property.create(
      id: id,
      propertyType: propertyType,
      operationType: operationType,
      areaM2: areaM2,
      address: address,
      district: district,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      parkingSpots: parkingSpots,
      latitude: latitude,
      longitude: longitude,
      amenities: amenities,
    );

    final violations = property.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw PropertyDomainException('Invalid property data', violations);
    }

    return property;
  }

  /// Validates district is supported in Piura
  static bool isValidPiuraDistrict(String district) {
    return piuraDistricts.any((d) => d.toLowerCase() == district.toLowerCase());
  }

  /// Estimates property value category based on characteristics
  static PropertyValueCategory estimateValueCategory(Property property) {
    var score = 0;

    // Area contribution
    if (property.areaM2 > 200)
      score += 3;
    else if (property.areaM2 > 100)
      score += 2;
    else if (property.areaM2 > 50)
      score += 1;

    // Rooms contribution
    if (property.bedrooms != null && property.bedrooms! >= 4)
      score += 2;
    else if (property.bedrooms != null && property.bedrooms! >= 3)
      score += 1;

    if (property.bathrooms != null && property.bathrooms! >= 3)
      score += 2;
    else if (property.bathrooms != null && property.bathrooms! >= 2)
      score += 1;

    // Parking contribution
    if (property.parkingSpots >= 2)
      score += 2;
    else if (property.parkingSpots >= 1)
      score += 1;

    // Amenities contribution
    if (property.amenities.length >= 5)
      score += 2;
    else if (property.amenities.length >= 3)
      score += 1;

    if (score >= 8) return PropertyValueCategory.premium;
    if (score >= 5) return PropertyValueCategory.mid;
    return PropertyValueCategory.basic;
  }
}

/// Property value categories for pricing guidance
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
