// lib/models/1_domain/shared/value_objects/contact_info.dart

import 'package:equatable/equatable.dart';

/// Contact hours preferences for property inquiries
enum ContactHours {
  morning, // 8AM - 12PM
  afternoon, // 12PM - 6PM
  evening, // 6PM - 10PM
  anytime; // Any reasonable hour

  /// User-friendly labels for UI
  String get displayName {
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

  /// Time range description for WhatsApp messages
  String get timeRange {
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
/// This immutable value object handles all contact information needed
/// for Ubiqa's WhatsApp-first communication model. It validates Peru
/// phone numbers and manages contact preferences.
///
/// V1 Scope: WhatsApp contact with basic preferences
class ContactInfo extends Equatable {
  /// WhatsApp phone number in Peru format
  final String whatsappNumber;

  /// Preferred contact hours
  final ContactHours preferredHours;

  /// Optional additional contact instructions
  final String? instructions;

  const ContactInfo._({
    required this.whatsappNumber,
    required this.preferredHours,
    this.instructions,
  });

  /// Creates ContactInfo with validation
  factory ContactInfo.create({
    required String whatsappNumber,
    required ContactHours preferredHours,
    String? instructions,
  }) {
    final contactInfo = ContactInfo._(
      whatsappNumber: whatsappNumber.trim(),
      preferredHours: preferredHours,
      instructions: instructions?.trim(),
    );

    final violations = contactInfo._validate();
    if (violations.isNotEmpty) {
      throw ContactInfoException('Invalid contact information', violations);
    }

    return contactInfo;
  }

  /// Creates ContactInfo with default anytime preference
  factory ContactInfo.createSimple({
    required String whatsappNumber,
    String? instructions,
  }) {
    return ContactInfo.create(
      whatsappNumber: whatsappNumber,
      preferredHours: ContactHours.anytime,
      instructions: instructions,
    );
  }

  // WHATSAPP INTEGRATION

  /// Gets WhatsApp contact URL for direct messaging
  String getWhatsAppUrl([String? customMessage]) {
    final cleanPhone = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');
    final internationalFormat = cleanPhone.startsWith('51')
        ? cleanPhone
        : '51$cleanPhone';

    final baseUrl = 'https://wa.me/$internationalFormat';

    if (customMessage?.isNotEmpty == true) {
      final encoded = Uri.encodeComponent(customMessage!);
      return '$baseUrl?text=$encoded';
    }

    return baseUrl;
  }

  /// Gets WhatsApp URL with property inquiry message
  String getPropertyInquiryUrl({
    required String propertyTitle,
    String? propertyAddress,
  }) {
    final title = propertyTitle.length > 50
        ? '${propertyTitle.substring(0, 50)}...'
        : propertyTitle;

    var message = 'Hola! Me interesa tu propiedad: $title';

    if (propertyAddress != null) {
      message += ' en $propertyAddress';
    }

    // Add contact hours preference
    if (preferredHours != ContactHours.anytime) {
      message += '. Prefiero contacto ${preferredHours.timeRange}.';
    }

    // Add custom instructions if any
    if (instructions?.isNotEmpty == true) {
      message += ' $instructions';
    }

    return getWhatsAppUrl(message);
  }

  // DISPLAY AND FORMATTING

  /// Gets formatted phone number for display
  String getFormattedNumber() {
    final cleaned = whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle 9-digit format (999 999 999)
    if (cleaned.length == 9 && cleaned.startsWith('9')) {
      return '+51 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }

    // Handle 11-digit format with country code (51999999999)
    if (cleaned.length == 11 && cleaned.startsWith('519')) {
      final mobile = cleaned.substring(2);
      return '+51 ${mobile.substring(0, 3)} ${mobile.substring(3, 6)} ${mobile.substring(6)}';
    }

    return whatsappNumber; // Fallback to original
  }

  /// Gets contact summary for property listings
  String getContactSummary() {
    var summary = 'WhatsApp: ${getFormattedNumber()}';

    if (preferredHours != ContactHours.anytime) {
      summary += ' • ${preferredHours.displayName}';
    }

    return summary;
  }

  /// Gets contact instructions for display
  String? getInstructions() {
    return instructions?.isNotEmpty == true ? instructions : null;
  }

  // VALIDATION

  /// Validates contact information
  List<String> _validate() {
    final errors = <String>[];

    // WhatsApp number validation
    if (!_isValidPeruvianMobile(whatsappNumber)) {
      errors.add('WhatsApp number must be a valid Peruvian mobile number');
    }

    // Instructions validation (if provided)
    if (instructions != null) {
      if (instructions!.length > 200) {
        errors.add('Contact instructions cannot exceed 200 characters');
      }
      if (instructions!.trim().isEmpty) {
        errors.add('Contact instructions cannot be empty if provided');
      }
    }

    return errors;
  }

  /// Validates Peruvian mobile phone format for WhatsApp
  bool _isValidPeruvianMobile(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // 9 digits starting with 9 (999999999)
    if (cleaned.length == 9 && cleaned.startsWith('9')) {
      return true;
    }

    // 11 digits: 51 + 9 digits starting with 9 (51999999999)
    if (cleaned.length == 11 && cleaned.startsWith('519')) {
      return true;
    }

    return false;
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object?> get props => [whatsappNumber, preferredHours, instructions];

  @override
  String toString() {
    return 'ContactInfo(${getFormattedNumber()}, ${preferredHours.name})';
  }
}

/// Exception for contact info validation errors
class ContactInfoException implements Exception {
  final String message;
  final List<String> violations;

  const ContactInfoException(this.message, this.violations);

  @override
  String toString() =>
      'ContactInfoException: $message\nViolations: ${violations.join(', ')}';
}

/// ContactInfo domain service for common operations
class ContactInfoDomainService {
  /// Standard contact instructions templates for users
  static const List<String> commonInstructions = [
    'Llamar antes de enviar WhatsApp',
    'Preferible por las mañanas',
    'Solo mensajes de WhatsApp',
    'Respondo después del trabajo',
    'Disponible fines de semana',
  ];

  /// Creates contact info from user's verified phone
  static ContactInfo createFromUserPhone({
    required String phoneNumber,
    ContactHours preferredHours = ContactHours.anytime,
    String? instructions,
  }) {
    return ContactInfo.create(
      whatsappNumber: phoneNumber,
      preferredHours: preferredHours,
      instructions: instructions,
    );
  }

  /// Updates contact preferences while keeping same phone
  static ContactInfo updatePreferences({
    required ContactInfo contactInfo,
    ContactHours? newPreferredHours,
    String? newInstructions,
  }) {
    return ContactInfo.create(
      whatsappNumber: contactInfo.whatsappNumber,
      preferredHours: newPreferredHours ?? contactInfo.preferredHours,
      instructions: newInstructions ?? contactInfo.instructions,
    );
  }

  /// Validates contact info for property listing
  static List<String> validateForListing(ContactInfo contactInfo) {
    final errors = <String>[];

    // Must have valid WhatsApp number
    if (!contactInfo._isValidPeruvianMobile(contactInfo.whatsappNumber)) {
      errors.add('Valid WhatsApp number required for property listings');
    }

    // Instructions should be professional for listings
    if (contactInfo.instructions != null) {
      final instructions = contactInfo.instructions!.toLowerCase();

      // Basic professionalism check
      if (instructions.contains('no llamar') ||
          instructions.contains('no molestar') ||
          instructions.contains('urgente')) {
        errors.add('Contact instructions should be professional and welcoming');
      }
    }

    return errors;
  }

  /// Gets estimated response time based on contact hours
  static String getEstimatedResponseTime(ContactInfo contactInfo) {
    switch (contactInfo.preferredHours) {
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

  /// Checks if current time aligns with contact preferences
  static bool isGoodTimeToContact(ContactInfo contactInfo) {
    final now = DateTime.now();
    final hour = now.hour;

    switch (contactInfo.preferredHours) {
      case ContactHours.morning:
        return hour >= 8 && hour < 12;
      case ContactHours.afternoon:
        return hour >= 12 && hour < 18;
      case ContactHours.evening:
        return hour >= 18 && hour < 22;
      case ContactHours.anytime:
        return hour >= 7 && hour < 23; // Reasonable hours
    }
  }
}
