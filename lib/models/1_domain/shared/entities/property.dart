// lib/models/1_domain/shared/entities/property.dart

import 'package:equatable/equatable.dart';

// Import value objects
import '../value_objects/location.dart';
import '../value_objects/property_specs.dart';
import '../value_objects/media.dart';

/// Strongly-typed identifier for Property entities
class PropertyId extends Equatable {
  final String value;

  const PropertyId._(this.value);

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

  bool get hasRooms {
    return this == PropertyType.casa || this == PropertyType.departamento;
  }

  bool get isResidential {
    return this == PropertyType.casa || this == PropertyType.departamento;
  }
}

/// Operation types for property transactions
enum OperationType {
  venta,
  alquiler;

  String get displayName {
    switch (this) {
      case OperationType.venta:
        return 'Venta';
      case OperationType.alquiler:
        return 'Alquiler';
    }
  }

  String get typicalCurrency {
    switch (this) {
      case OperationType.venta:
        return 'USD';
      case OperationType.alquiler:
        return 'PEN';
    }
  }
}

/// Property entity representing real estate being offered on the platform
class Property extends Equatable {
  final PropertyId id;
  final PropertyType propertyType;
  final OperationType operationType;
  final PropertySpecs specs;
  final Location location;
  final Media media;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;

  const Property._({
    required this.id,
    required this.propertyType,
    required this.operationType,
    required this.specs,
    required this.location,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    required this.isAvailable,
  });

  /// Factory: Create new property
  factory Property.create({
    required PropertyId id,
    required PropertyType propertyType,
    required OperationType operationType,
    required PropertySpecs specs,
    required Location location,
    Media? media,
  }) {
    final now = DateTime.now();
    return Property._(
      id: id,
      propertyType: propertyType,
      operationType: operationType,
      specs: specs,
      location: location,
      media: media ?? Media.empty(),
      createdAt: now,
      updatedAt: now,
      isAvailable: true,
    );
  }

  /// Creates copy with updated fields
  Property copyWith({
    PropertyType? propertyType,
    OperationType? operationType,
    PropertySpecs? specs,
    Location? location,
    Media? media,
    DateTime? updatedAt,
    bool? isAvailable,
  }) {
    return Property._(
      id: id,
      propertyType: propertyType ?? this.propertyType,
      operationType: operationType ?? this.operationType,
      specs: specs ?? this.specs,
      location: location ?? this.location,
      media: media ?? this.media,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // PROPERTY BUSINESS LOGIC

  /// Whether property has location coordinates for map display
  bool hasGpsCoordinates() {
    return location.latitude != 0.0 && location.longitude != 0.0;
  }

  /// Whether property has complete room information
  bool hasCompleteRoomInfo() {
    if (!propertyType.hasRooms) return true;
    return specs.bedrooms != null && specs.bathrooms != null;
  }

  /// Gets property summary for display
  String getPropertySummary() {
    return specs.getPropertySummary();
  }

  /// Gets formatted address for display
  String getFormattedAddress() {
    return location.getFormattedAddress();
  }

  /// Whether property has photos
  bool hasPhotos() {
    return media.hasPhotos();
  }

  /// Gets primary photo URL
  String? getPrimaryPhoto() {
    return media.getPrimaryPhoto();
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

    if (filterDistrict != null &&
        !location.district.toLowerCase().contains(
          filterDistrict.toLowerCase(),
        )) {
      return false;
    }

    return specs.matchesFilters(
      minBedrooms: minBedrooms,
      maxBedrooms: maxBedrooms,
      minArea: minArea,
      maxArea: maxArea,
      requiredAmenities: requiredAmenities,
    );
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'Property(id: ${id.value}, type: ${propertyType.name}, ${specs.getPropertySummary()})';
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
  /// Creates property with validation
  static Property createPropertyWithValidation({
    required PropertyId id,
    required PropertyType propertyType,
    required OperationType operationType,
    required PropertySpecs specs,
    required Location location,
    Media? media,
  }) {
    final property = Property.create(
      id: id,
      propertyType: propertyType,
      operationType: operationType,
      specs: specs,
      location: location,
      media: media,
    );

    return property;
  }

  /// Updates property content with validation
  static Property updatePropertyContent({
    required Property property,
    PropertySpecs? specs,
    Location? location,
    Media? media,
  }) {
    return property.copyWith(specs: specs, location: location, media: media);
  }
}
