// lib/models/1_domain/shared/value_objects/international_phone_number.dart

import 'package:equatable/equatable.dart';

/// Supported country codes for international phone number validation
/// Enum approach enables type-safe country handling and easy expansion
enum SupportedCountryCode {
  peru, // +51
  unitedStates; // +1

  /// Returns the international dialing code for the country
  String get dialingCode {
    switch (this) {
      case SupportedCountryCode.peru:
        return '+51';
      case SupportedCountryCode.unitedStates:
        return '+1';
    }
  }

  /// Returns user-friendly country name for UI display
  String get countryDisplayName {
    switch (this) {
      case SupportedCountryCode.peru:
        return 'Perú';
      case SupportedCountryCode.unitedStates:
        return 'Estados Unidos';
    }
  }

  /// Returns expected digit count after country code
  int get expectedDigitCount {
    switch (this) {
      case SupportedCountryCode.peru:
        return 9; // Mobile numbers in Peru are 9 digits
      case SupportedCountryCode.unitedStates:
        return 10; // US numbers are 10 digits (area code + number)
    }
  }
}

/// InternationalPhoneNumber value object for multi-country phone validation
///
/// WHY this separate value object exists:
/// 1. SCALABILITY: Ubiqa will expand beyond Peru to other Latin American markets.
///    Centralizing international phone logic here prevents code duplication across
///    authentication, contact info, and future features.
///
/// 2. BUSINESS COMPLIANCE: Different countries have strict phone number formats
///    for SMS verification services. Invalid formats cause verification failures
///    and poor user experience. This ensures compliance before API calls.
///
/// 3. DEVELOPER EXPERIENCE: As Ubiqa grows internationally, developers need
///    a single source of truth for phone validation. Adding new countries
///    requires only updating this file, not searching across the codebase.
///
/// 4. AUTHENTICATION INFRASTRUCTURE: Firebase Auth and SMS providers require
///    properly formatted international numbers. This value object ensures
///    consistent formatting before reaching external services.
///
/// 5. FUTURE FEATURES: Will enable country-specific SMS routing, carrier
///    validation, formatting preferences, and localized error messages.
///
/// V1 Scope: US and Peru support for developer (US-based) and target market
class InternationalPhoneNumber extends Equatable {
  /// Complete phone number with country code (e.g., "+51987654321")
  /// Stored in E.164 format for international SMS service compatibility
  final String phoneNumberWithCountryCode;

  /// Detected country based on phone number format
  /// Enables country-specific business logic and user experience
  final SupportedCountryCode detectedCountryCode;

  const InternationalPhoneNumber._({
    required this.phoneNumberWithCountryCode,
    required this.detectedCountryCode,
  });

  /// Creates InternationalPhoneNumber with comprehensive validation
  /// Validation prevents SMS verification failures and improves user experience
  factory InternationalPhoneNumber.create({required String phoneNumber}) {
    final validationErrors = _validateInternationalPhoneNumber(phoneNumber);

    if (validationErrors.isNotEmpty) {
      throw InternationalPhoneNumberValidationException(
        'Invalid international phone number format',
        validationErrors,
      );
    }

    final cleanedPhoneNumber = phoneNumber.trim();
    final detectedCountry = _detectCountryCode(cleanedPhoneNumber);

    return InternationalPhoneNumber._(
      phoneNumberWithCountryCode: cleanedPhoneNumber,
      detectedCountryCode: detectedCountry,
    );
  }

  // PHONE NUMBER OPERATIONS

  /// Returns phone number without country code for local display
  /// Useful for UI components showing familiar local format to users
  String getLocalPhoneNumber() {
    return phoneNumberWithCountryCode.replaceFirst(
      detectedCountryCode.dialingCode,
      '',
    );
  }

  /// Returns formatted phone number for user display
  /// Applies country-specific formatting conventions for better readability
  String getFormattedPhoneNumberForDisplay() {
    final localNumber = getLocalPhoneNumber();

    switch (detectedCountryCode) {
      case SupportedCountryCode.peru:
        // Peru format: +51 987 654 321
        if (localNumber.length == 9) {
          return '${detectedCountryCode.dialingCode} ${localNumber.substring(0, 3)} ${localNumber.substring(3, 6)} ${localNumber.substring(6)}';
        }
        break;
      case SupportedCountryCode.unitedStates:
        // US format: +1 (555) 123-4567
        if (localNumber.length == 10) {
          return '${detectedCountryCode.dialingCode} (${localNumber.substring(0, 3)}) ${localNumber.substring(3, 6)}-${localNumber.substring(6)}';
        }
        break;
    }

    // Fallback to original format if formatting fails
    return phoneNumberWithCountryCode;
  }

  /// Returns E.164 format for SMS services
  /// International SMS providers require this specific format
  String getE164Format() {
    return phoneNumberWithCountryCode; // Already in E.164 format
  }

  // VALIDATION LOGIC

  /// Validates international phone number format for supported countries
  /// Comprehensive validation prevents SMS verification failures
  static List<String> _validateInternationalPhoneNumber(String phoneNumber) {
    final validationErrors = <String>[];
    final cleanedPhoneNumber = phoneNumber.trim();

    // Check basic presence and format
    if (cleanedPhoneNumber.isEmpty) {
      validationErrors.add('Phone number cannot be empty');
      return validationErrors;
    }

    if (!cleanedPhoneNumber.startsWith('+')) {
      validationErrors.add(
        'Phone number must include country code starting with +',
      );
      return validationErrors;
    }

    // Validate against supported country formats
    if (!_isValidForAnySupportedCountry(cleanedPhoneNumber)) {
      validationErrors.add(
        'Phone number format not supported. Must be US (+1) or Peru (+51) format',
      );
    }

    return validationErrors;
  }

  /// Checks if phone number matches any supported country format
  /// Used for initial validation before country-specific processing
  static bool _isValidForAnySupportedCountry(String phoneNumber) {
    return _isValidUsPhoneNumber(phoneNumber) ||
        _isValidPeruPhoneNumber(phoneNumber);
  }

  /// Validates US phone number format (+1 followed by 10 digits)
  /// US numbers have consistent 10-digit format after country code
  static bool _isValidUsPhoneNumber(String phoneNumber) {
    final usPhoneRegex = RegExp(r'^\+1[0-9]{10}$');
    return usPhoneRegex.hasMatch(phoneNumber);
  }

  /// Validates Peru phone number format (+51 followed by 9 digits)
  /// Peru mobile numbers are 9 digits starting with 9
  static bool _isValidPeruPhoneNumber(String phoneNumber) {
    final peruPhoneRegex = RegExp(r'^\+51[0-9]{9}$');
    return peruPhoneRegex.hasMatch(phoneNumber);
  }

  /// Detects country code from validated phone number
  /// Assumes phone number has already passed validation
  static SupportedCountryCode _detectCountryCode(String phoneNumber) {
    if (phoneNumber.startsWith('+1')) {
      return SupportedCountryCode.unitedStates;
    } else if (phoneNumber.startsWith('+51')) {
      return SupportedCountryCode.peru;
    }

    // This should never happen after validation, but provides safety
    throw InternationalPhoneNumberValidationException(
      'Unable to detect country code',
      ['Phone number does not match supported country formats'],
    );
  }

  // VALUE OBJECT EQUALITY - Based on phone number
  @override
  List<Object> get props => [phoneNumberWithCountryCode];

  @override
  String toString() {
    return 'InternationalPhoneNumber(${getFormattedPhoneNumberForDisplay()}, ${detectedCountryCode.countryDisplayName})';
  }
}

/// Exception for international phone number validation errors
/// Specific exception type enables targeted error handling across application layers
class InternationalPhoneNumberValidationException implements Exception {
  final String message;
  final List<String> violations;

  const InternationalPhoneNumberValidationException(
    this.message,
    this.violations,
  );

  @override
  String toString() =>
      'InternationalPhoneNumberValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// InternationalPhoneNumber domain service for common operations
/// Centralized service ensures consistent phone number handling across features
class InternationalPhoneNumberDomainService {
  /// Supported countries list for UI dropdowns and user guidance
  /// Ordered by priority: target market (Peru) first, then developer location (US)
  static const List<SupportedCountryCode> supportedCountriesInPriorityOrder = [
    SupportedCountryCode.peru,
    SupportedCountryCode.unitedStates,
  ];

  /// Creates phone number from user input with error handling
  /// Provides safe wrapper for UI components to handle validation gracefully
  static InternationalPhoneNumber? createSafelyFromUserInput(
    String phoneNumber,
  ) {
    try {
      return InternationalPhoneNumber.create(phoneNumber: phoneNumber);
    } on InternationalPhoneNumberValidationException {
      return null; // UI can handle null to show validation errors
    }
  }

  /// Validates phone number without creating object
  /// Useful for real-time input validation in forms
  static bool isValidInternationalPhoneNumber(String phoneNumber) {
    return InternationalPhoneNumber._validateInternationalPhoneNumber(
      phoneNumber,
    ).isEmpty;
  }

  /// Gets expected format example for country
  /// Helps users understand correct input format
  static String getFormatExampleForCountry(SupportedCountryCode country) {
    switch (country) {
      case SupportedCountryCode.peru:
        return '+51987654321';
      case SupportedCountryCode.unitedStates:
        return '+15551234567';
    }
  }

  /// Formats partial phone number input for better UX
  /// Applies formatting as user types to guide correct input
  static String formatPhoneNumberAsUserTypes(
    String partialInput,
    SupportedCountryCode? expectedCountry,
  ) {
    // Remove non-digit characters except +
    final cleanedInput = partialInput.replaceAll(RegExp(r'[^\d+]'), '');

    // Basic formatting logic - can be enhanced for each country
    if (expectedCountry == SupportedCountryCode.unitedStates &&
        cleanedInput.startsWith('+1')) {
      final digits = cleanedInput.substring(2);
      if (digits.length <= 3) {
        return '+1 ($digits';
      } else if (digits.length <= 6) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3)}';
      } else if (digits.length <= 10) {
        return '+1 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
      }
    }

    return cleanedInput; // Return cleaned input if no specific formatting applied
  }
}
