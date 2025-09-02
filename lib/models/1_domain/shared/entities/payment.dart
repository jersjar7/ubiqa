// lib/models/1_domain/shared/entities/payment.dart

import 'package:equatable/equatable.dart';

// Import value objects
import '../value_objects/price.dart';

// Import pricing configuration
import '../configurations/pricing_configuration.dart';

/// Strongly-typed identifier for Payment entities
class PaymentId extends Equatable {
  final String value;

  const PaymentId._(this.value);

  factory PaymentId.fromString(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('PaymentId cannot be empty');
    }
    return PaymentId._(id.trim());
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

/// Payment status for transaction lifecycle tracking
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  expired;

  String get getSpanishStatusLabel {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.processing:
        return 'Procesando';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.cancelled:
        return 'Cancelado';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.expired:
        return 'Expirado';
    }
  }

  bool get isSuccessfulStatus => this == PaymentStatus.completed;
  bool get isFinalStatus => [
    PaymentStatus.completed,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.refunded,
    PaymentStatus.expired,
  ].contains(this);
  bool get canRetryPayment => [
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
  ].contains(this);
}

/// Payment providers supported in V1
enum PaymentProvider {
  culqi;

  String get getProviderDisplayName {
    switch (this) {
      case PaymentProvider.culqi:
        return 'Culqi';
    }
  }

  List<PaymentMethod> get getSupportedPaymentMethods {
    switch (this) {
      case PaymentProvider.culqi:
        return [PaymentMethod.card, PaymentMethod.yape, PaymentMethod.plin];
    }
  }
}

/// Payment methods available to users
enum PaymentMethod {
  card,
  yape,
  plin,
  bankTransfer;

  String get getSpanishMethodLabel {
    switch (this) {
      case PaymentMethod.card:
        return 'Tarjeta de Crédito/Débito';
      case PaymentMethod.yape:
        return 'Yape';
      case PaymentMethod.plin:
        return 'Plin';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
    }
  }

  bool get isInstantPayment {
    switch (this) {
      case PaymentMethod.card:
      case PaymentMethod.yape:
      case PaymentMethod.plin:
        return true;
      case PaymentMethod.bankTransfer:
        return false;
    }
  }
}

/// Payment entity representing a financial transaction in the platform
class Payment extends Equatable {
  final PaymentId id;
  final Price price;
  final PaymentStatus status;
  final PaymentProvider provider;
  final PaymentMethod method;
  final String? providerTransactionId;
  final String referenceCode;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? providerResponse;
  final String? errorMessage;
  final String? receiptData;

  const Payment._({
    required this.id,
    required this.price,
    required this.status,
    required this.provider,
    required this.method,
    required this.referenceCode,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.providerTransactionId,
    this.completedAt,
    this.expiresAt,
    this.providerResponse,
    this.errorMessage,
    this.receiptData,
  });

  /// Factory: Create new payment
  factory Payment.create({
    required PaymentId id,
    required Price price,
    required PaymentProvider provider,
    required PaymentMethod method,
    required String description,
    String? referenceCode,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return Payment._(
      id: id,
      price: price,
      status: PaymentStatus.pending,
      provider: provider,
      method: method,
      referenceCode: referenceCode ?? _generateReferenceCode(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
      expiresAt: expiresAt ?? now.add(const Duration(hours: 2)),
    );
  }

  /// Creates copy with updated fields
  Payment copyWith({
    PaymentStatus? status,
    String? providerTransactionId,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? providerResponse,
    String? errorMessage,
    String? receiptData,
  }) {
    return Payment._(
      id: id,
      price: price,
      status: status ?? this.status,
      provider: provider,
      method: method,
      providerTransactionId:
          providerTransactionId ?? this.providerTransactionId,
      referenceCode: referenceCode,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      providerResponse: providerResponse ?? this.providerResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      receiptData: receiptData ?? this.receiptData,
    );
  }

  // PAYMENT LIFECYCLE METHODS

  Payment markAsProcessing(String providerTransactionId) {
    return copyWith(
      status: PaymentStatus.processing,
      providerTransactionId: providerTransactionId,
    );
  }

  Payment complete({String? receiptData, String? providerResponse}) {
    final now = DateTime.now();
    return copyWith(
      status: PaymentStatus.completed,
      completedAt: now,
      receiptData: receiptData,
      providerResponse: providerResponse,
      updatedAt: now,
    );
  }

  Payment fail({required String errorMessage, String? providerResponse}) {
    return copyWith(
      status: PaymentStatus.failed,
      errorMessage: errorMessage,
      providerResponse: providerResponse,
    );
  }

  Payment cancel() {
    return copyWith(status: PaymentStatus.cancelled);
  }

  Payment expire() {
    return copyWith(status: PaymentStatus.expired);
  }

  Payment refund({
    required String providerTransactionId,
    String? providerResponse,
  }) {
    if (status != PaymentStatus.completed) {
      throw PaymentDomainException('Cannot refund payment', [
        'Payment must be completed to process refund',
      ]);
    }

    return copyWith(
      status: PaymentStatus.refunded,
      providerTransactionId: providerTransactionId,
      providerResponse: providerResponse,
    );
  }

  // PAYMENT STATUS QUERIES

  bool isCompleted() => status == PaymentStatus.completed;
  bool isFailed() => status == PaymentStatus.failed;
  bool isPending() =>
      status == PaymentStatus.pending || status == PaymentStatus.processing;
  bool isFinal() => status.isFinalStatus;
  bool canRetry() => status.canRetryPayment;

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!) && !isFinal();
  }

  // DELEGATION TO VALUE OBJECTS

  /// Gets formatted amount for display
  String getFormattedAmount() {
    return price.generateFormattedPriceForDisplay();
  }

  /// Gets compact amount format
  String getCompactAmount() {
    return price.generateCompactPriceFormat();
  }

  // PAYMENT CALCULATIONS

  Duration? getProcessingTime() {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  Duration? getTimeUntilExpiry() {
    if (expiresAt == null || isFinal()) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiringSoon() {
    final timeLeft = getTimeUntilExpiry();
    return timeLeft != null && timeLeft.inMinutes <= 30;
  }

  // VALIDATION

  List<String> validateBusinessRules() {
    final errors = <String>[];

    // Reference code validation
    if (referenceCode.length < 6 || referenceCode.length > 20) {
      errors.add('Reference code must be between 6 and 20 characters');
    }

    // Description validation
    if (description.trim().length < 5) {
      errors.add('Description must be at least 5 characters');
    }
    if (description.length > 200) {
      errors.add('Description cannot exceed 200 characters');
    }

    // Provider-method compatibility
    if (!provider.getSupportedPaymentMethods.contains(method)) {
      errors.add('Payment method not supported by provider');
    }

    // Status consistency validation
    if (status == PaymentStatus.completed && completedAt == null) {
      errors.add('Completed payments must have completion timestamp');
    }

    if (status == PaymentStatus.failed && errorMessage == null) {
      errors.add('Failed payments must have error message');
    }

    // Expiration validation
    if (expiresAt != null && expiresAt!.isBefore(createdAt)) {
      errors.add('Expiration date cannot be before creation date');
    }

    return errors;
  }

  static String _generateReferenceCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).toString().padLeft(4, '0');
    return 'UBQ$random${timestamp.substring(timestamp.length - 4)}';
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'Payment(id: ${id.value}, amount: ${getFormattedAmount()}, status: ${status.name})';
  }
}

/// Domain exception for payment business rule violations
class PaymentDomainException implements Exception {
  final String message;
  final List<String> violations;

  const PaymentDomainException(this.message, this.violations);

  @override
  String toString() =>
      'PaymentDomainException: $message\nViolations: ${violations.join(', ')}';
}

/// Payment domain service for validation and operations
class PaymentDomainService {
  static const String defaultCurrency = 'PEN';
  static const Duration defaultExpiryTime = Duration(hours: 2);

  static Payment createPaymentWithValidation({
    required PaymentId id,
    required Price price,
    required PaymentProvider provider,
    required PaymentMethod method,
    required String description,
    String? referenceCode,
    DateTime? expiresAt,
  }) {
    final payment = Payment.create(
      id: id,
      price: price,
      provider: provider,
      method: method,
      description: description,
      referenceCode: referenceCode,
      expiresAt: expiresAt,
    );

    final violations = payment.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw PaymentDomainException('Invalid payment data', violations);
    }

    return payment;
  }

  /// Creates listing payment with current pricing configuration
  static Future<Payment> createListingPayment({
    required PaymentId id,
    required PaymentProvider provider,
    required PaymentMethod method,
    String? referenceCode,
    String? promotionalCode,
  }) async {
    // Get current pricing (with potential promotional pricing)
    final listingPricing = await PricingConfiguration.getCurrentListingPricing(
      promotionalCode: promotionalCode,
    );

    return createPaymentWithValidation(
      id: id,
      price: Price.createInSoles(listingPricing.feeAmount),
      provider: provider,
      method: method,
      description: listingPricing.generatePricingDescription(),
      referenceCode: referenceCode,
    );
  }

  /// Creates listing payment with standard pricing (synchronous version)
  static Payment createStandardListingPayment({
    required PaymentId id,
    required PaymentProvider provider,
    required PaymentMethod method,
    String? referenceCode,
  }) {
    return createPaymentWithValidation(
      id: id,
      price: Price.createInSoles(PricingConfiguration.baseListingFeeInSoles),
      provider: provider,
      method: method,
      description:
          'Publicación de propiedad (${PricingConfiguration.standardListingDurationDays} días)',
      referenceCode: referenceCode,
    );
  }

  static Payment processCompletion({
    required Payment payment,
    String? receiptData,
    String? providerResponse,
  }) {
    if (payment.status != PaymentStatus.processing) {
      throw PaymentDomainException('Cannot complete payment', [
        'Payment must be in processing status',
      ]);
    }

    if (payment.isExpired()) {
      throw PaymentDomainException('Cannot complete expired payment', [
        'Payment has expired and cannot be completed',
      ]);
    }

    return payment.complete(
      receiptData: receiptData,
      providerResponse: providerResponse,
    );
  }

  static Payment processFailure({
    required Payment payment,
    required String errorMessage,
    String? providerResponse,
  }) {
    if (payment.isFinal()) {
      throw PaymentDomainException('Cannot fail completed payment', [
        'Payment is already in final status',
      ]);
    }

    return payment.fail(
      errorMessage: errorMessage,
      providerResponse: providerResponse,
    );
  }

  static Duration getEstimatedProcessingTime(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return const Duration(seconds: 30);
      case PaymentMethod.yape:
      case PaymentMethod.plin:
        return const Duration(minutes: 2);
      case PaymentMethod.bankTransfer:
        return const Duration(hours: 24);
    }
  }
}
