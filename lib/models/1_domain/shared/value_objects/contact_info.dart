// lib/models/1_domain/shared/value_objects/contact_info.dart

import 'package:equatable/equatable.dart';
import 'international_phone_number.dart';

/// Contact hours preferences for property inquiries
/// These slots align with Peru's business culture and WhatsApp usage patterns
enum ContactHours {
  morning, // 8AM - 12PM
  afternoon, // 12PM - 6PM
  evening, // 6PM - 10PM
  anytime; // Any reasonable hour

  /// Provides localized labels for UI components to match user expectations
  String get userInterfaceLabel {
    switch (this) {
      case ContactHours.morning:
        return 'Mañana (8AM - 12PM)';
      case ContactHours.afternoon:
        return 'Tarde (12PM - 6PM)';
      case ContactHours.evening:
        return 'Noche (6PM - 10PM)';
      case ContactHours.anytime:
        return 'Cualquier hora';
    }
  }

  /// Generates contextual phrases for WhatsApp messages to set clear expectations
  String get contextualTimePhrase {
    switch (this) {
      case ContactHours.morning:
        return 'en la mañana';
      case ContactHours.afternoon:
        return 'en la tarde';
      case ContactHours.evening:
        return 'en la noche';
      case ContactHours.anytime:
        return 'a cualquier hora';
    }
  }
}

/// ContactInfo value object for WhatsApp-based communication
///
/// Encapsulates contact data because WhatsApp is the dominant communication
/// channel in Peru's real estate market, requiring phone validation and
/// preference management for successful property transactions.
///
/// Updated: Now supports international phone numbers (Peru + US) with future extensibility
class ContactInfo extends Equatable {
  /// WhatsApp phone number with international validation
  /// Uses InternationalPhoneNumber for comprehensive validation and formatting
  final InternationalPhoneNumber whatsappPhoneNumber;

  /// Preferred contact hours
  /// Reduces friction by managing buyer-seller communication timing expectations
  final ContactHours preferredContactTimeSlot;

  /// Optional additional contact instructions
  /// Allows users to set boundaries and preferences for more effective communication
  final String? additionalContactNotes;

  const ContactInfo._({
    required this.whatsappPhoneNumber,
    required this.preferredContactTimeSlot,
    this.additionalContactNotes,
  });

  /// Creates ContactInfo with validation
  /// Validation is critical because invalid phone numbers break WhatsApp integration
  factory ContactInfo.create({
    required String whatsappPhoneNumber,
    required ContactHours preferredContactTimeSlot,
    String? additionalContactNotes,
  }) {
    // Create and validate international phone number first
    final internationalPhone = InternationalPhoneNumber.create(
      phoneNumber: whatsappPhoneNumber.trim(),
    );

    final contactInfo = ContactInfo._(
      whatsappPhoneNumber: internationalPhone,
      preferredContactTimeSlot: preferredContactTimeSlot,
      additionalContactNotes: additionalContactNotes?.trim(),
    );

    // Validate additional contact info fields
    final violations = contactInfo._validateAdditionalContactFields();
    if (violations.isNotEmpty) {
      throw ContactInfoValidationException(
        'Invalid contact information',
        violations,
      );
    }

    return contactInfo;
  }

  /// Creates ContactInfo with default anytime preference
  /// Simplifies creation when users don't specify time preferences
  factory ContactInfo.createWithDefaultTimeSlot({
    required String whatsappPhoneNumber,
    String? additionalContactNotes,
  }) {
    return ContactInfo.create(
      whatsappPhoneNumber: whatsappPhoneNumber,
      preferredContactTimeSlot: ContactHours.anytime,
      additionalContactNotes: additionalContactNotes,
    );
  }

  // WHATSAPP INTEGRATION

  /// Generates WhatsApp contact URL for direct messaging
  /// Returns wa.me URL because it works universally across all devices and WhatsApp installations
  String generateWhatsAppContactUrl([String? prefilledMessage]) {
    // Get E.164 format and remove + prefix for WhatsApp URL
    final e164Number = whatsappPhoneNumber.getE164Format();
    final cleanedNumber = e164Number.substring(1); // Remove + prefix

    final baseUrl = 'https://wa.me/$cleanedNumber';

    if (prefilledMessage?.isNotEmpty == true) {
      final encodedMessage = Uri.encodeComponent(prefilledMessage!);
      return '$baseUrl?text=$encodedMessage';
    }

    return baseUrl;
  }

  /// Generates WhatsApp URL with property-specific inquiry message
  /// Pre-fills message to reduce friction and improve response rates
  String generatePropertyInquiryWhatsAppUrl({
    required String propertyTitle,
    String? propertyAddress,
  }) {
    final truncatedTitle = propertyTitle.length > 50
        ? '${propertyTitle.substring(0, 50)}...'
        : propertyTitle;

    var inquiryMessage = 'Hola! Me interesa tu propiedad: $truncatedTitle';

    if (propertyAddress != null) {
      inquiryMessage += ' en $propertyAddress';
    }

    // Include contact preferences to set expectations upfront
    if (preferredContactTimeSlot != ContactHours.anytime) {
      inquiryMessage +=
          '. Prefiero contacto ${preferredContactTimeSlot.contextualTimePhrase}.';
    }

    // Add custom instructions to provide context for better communication
    if (additionalContactNotes?.isNotEmpty == true) {
      inquiryMessage += ' $additionalContactNotes';
    }

    return generateWhatsAppContactUrl(inquiryMessage);
  }

  // DISPLAY AND FORMATTING

  /// Formats phone number for consistent UI display across all components
  /// Uses international formatting from InternationalPhoneNumber for country-specific display
  String getFormattedPhoneNumberForDisplay() {
    return whatsappPhoneNumber.getFormattedPhoneNumberForDisplay();
  }

  /// Generates contact summary for property listings display
  /// Combines essential contact info to help users make informed contact decisions
  String generateContactSummaryForListing() {
    var contactSummary = 'WhatsApp: ${getFormattedPhoneNumberForDisplay()}';

    if (preferredContactTimeSlot != ContactHours.anytime) {
      contactSummary += ' • ${preferredContactTimeSlot.userInterfaceLabel}';
    }

    return contactSummary;
  }

  /// Returns additional contact notes if present
  /// Separates null checking logic to avoid UI component complexity
  String? getAdditionalContactNotes() {
    return additionalContactNotes?.isNotEmpty == true
        ? additionalContactNotes
        : null;
  }

  /// Gets the detected country code for business logic
  /// Enables country-specific features and validation
  SupportedCountryCode getDetectedCountryCode() {
    return whatsappPhoneNumber.detectedCountryCode;
  }

  /// Gets the raw phone number with country code
  /// For storage and API integrations that need the full international format
  String getInternationalPhoneNumber() {
    return whatsappPhoneNumber.phoneNumberWithCountryCode;
  }

  // VALIDATION

  /// Validates additional contact information fields
  /// Phone validation is now handled by InternationalPhoneNumber creation
  List<String> _validateAdditionalContactFields() {
    final validationErrors = <String>[];

    // Additional notes validation prevents abuse and maintains professionalism
    if (additionalContactNotes != null) {
      if (additionalContactNotes!.length > 200) {
        validationErrors.add(
          'Contact instructions cannot exceed 200 characters',
        );
      }
      if (additionalContactNotes!.trim().isEmpty) {
        validationErrors.add(
          'Contact instructions cannot be empty if provided',
        );
      }
    }

    return validationErrors;
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object?> get props => [
    whatsappPhoneNumber,
    preferredContactTimeSlot,
    additionalContactNotes,
  ];

  @override
  String toString() {
    return 'ContactInfo(${getFormattedPhoneNumberForDisplay()}, ${preferredContactTimeSlot.name})';
  }
}

/// Exception for contact info validation errors
/// Specific exception type enables better error handling in upper layers
class ContactInfoValidationException implements Exception {
  final String message;
  final List<String> violations;

  const ContactInfoValidationException(this.message, this.violations);

  @override
  String toString() =>
      'ContactInfoValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// ContactInfo domain service for common operations
/// Centralized business logic reduces duplication across the application
class ContactInfoDomainService {
  /// Standard contact instruction templates for user guidance
  /// Pre-defined options reduce user friction and improve communication quality
  static const List<String> standardContactInstructionTemplates = [
    'Llamar antes de enviar WhatsApp',
    'Preferible por las mañanas',
    'Solo mensajes de WhatsApp',
    'Respondo después del trabajo',
    'Disponible fines de semana',
  ];

  /// Creates contact info from user's verified phone number
  /// Leverages existing verification to ensure consistent contact data
  static ContactInfo createFromVerifiedUserPhone({
    required String phoneNumber,
    ContactHours preferredContactTimeSlot = ContactHours.anytime,
    String? additionalContactNotes,
  }) {
    return ContactInfo.create(
      whatsappPhoneNumber: phoneNumber,
      preferredContactTimeSlot: preferredContactTimeSlot,
      additionalContactNotes: additionalContactNotes,
    );
  }

  /// Updates contact preferences while preserving verified phone number
  /// Prevents accidental phone number changes that would break verification
  static ContactInfo updateContactPreferences({
    required ContactInfo existingContactInfo,
    ContactHours? newPreferredContactTimeSlot,
    String? newAdditionalContactNotes,
  }) {
    return ContactInfo.create(
      whatsappPhoneNumber: existingContactInfo.getInternationalPhoneNumber(),
      preferredContactTimeSlot:
          newPreferredContactTimeSlot ??
          existingContactInfo.preferredContactTimeSlot,
      additionalContactNotes:
          newAdditionalContactNotes ??
          existingContactInfo.additionalContactNotes,
    );
  }

  /// Validates contact info specifically for property listing requirements
  /// Stricter validation for listings maintains platform quality and trust
  static List<String> validateContactInfoForPropertyListing(
    ContactInfo contactInfo,
  ) {
    final listingValidationErrors = <String>[];

    // Phone validation is automatically handled by InternationalPhoneNumber
    // Additional WhatsApp-specific validation for listings
    final countryCode = contactInfo.getDetectedCountryCode();

    // Country-specific validation rules
    switch (countryCode) {
      case SupportedCountryCode.peru:
        // Peru-specific business rules can go here
        break;
      case SupportedCountryCode.unitedStates:
        // US-specific business rules can go here
        break;
    }

    // Instructions must maintain professional tone for marketplace trust
    if (contactInfo.additionalContactNotes != null) {
      final lowerCaseInstructions = contactInfo.additionalContactNotes!
          .toLowerCase();

      // Basic professionalism check prevents negative user experience
      if (lowerCaseInstructions.contains('no llamar') ||
          lowerCaseInstructions.contains('no molestar') ||
          lowerCaseInstructions.contains('urgente')) {
        listingValidationErrors.add(
          'Contact instructions should be professional and welcoming',
        );
      }
    }

    return listingValidationErrors;
  }

  /// Provides estimated response time based on contact time preferences
  /// Helps manage buyer expectations and improves satisfaction
  static String generateEstimatedResponseTimeMessage(ContactInfo contactInfo) {
    switch (contactInfo.preferredContactTimeSlot) {
      case ContactHours.morning:
        return 'Responde generalmente en la mañana';
      case ContactHours.afternoon:
        return 'Responde generalmente en la tarde';
      case ContactHours.evening:
        return 'Responde generalmente en la noche';
      case ContactHours.anytime:
        return 'Responde durante el día';
    }
  }

  /// Determines if current time aligns with user's preferred contact hours
  /// Enables smart UI features like "good time to contact" indicators
  static bool isCurrentTimeWithinPreferredContactWindow(
    ContactInfo contactInfo,
  ) {
    final currentHour = DateTime.now().hour;

    switch (contactInfo.preferredContactTimeSlot) {
      case ContactHours.morning:
        return currentHour >= 8 && currentHour < 12;
      case ContactHours.afternoon:
        return currentHour >= 12 && currentHour < 18;
      case ContactHours.evening:
        return currentHour >= 18 && currentHour < 22;
      case ContactHours.anytime:
        return currentHour >= 7 && currentHour < 23; // Reasonable hours only
    }
  }

  /// Gets country-specific formatting example for help text
  /// Helps users understand expected phone number format
  static String getPhoneFormatExampleForCountry(SupportedCountryCode country) {
    return InternationalPhoneNumberDomainService.getFormatExampleForCountry(
      country,
    );
  }

  /// Validates phone number format without creating ContactInfo object
  /// Useful for real-time validation in UI forms
  static bool isValidPhoneNumberFormat(String phoneNumber) {
    return InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
      phoneNumber,
    );
  }
}
