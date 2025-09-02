// lib/models/1_domain/shared/entities/payment.dart

import 'package:equatable/equatable.dart';

/// Strongly-typed identifier for Payment entities
class PaymentId extends Equatable {
  final String value;

  const PaymentId._(this.value);

  /// Creates PaymentId from string with validation
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
  /// Payment created but not yet processed
  pending,

  /// Payment is being processed by payment provider
  processing,

  /// Payment completed successfully
  completed,

  /// Payment failed due to insufficient funds, declined card, etc.
  failed,

  /// Payment was cancelled by user before completion
  cancelled,

  /// Payment was refunded after completion
  refunded,

  /// Payment expired without completion
  expired;

  /// User-friendly status labels for UI
  String get displayName {
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

  /// Whether this status represents a successful payment
  bool get isSuccess => this == PaymentStatus.completed;

  /// Whether this status represents a final state (no further changes expected)
  bool get isFinal => [
    PaymentStatus.completed,
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.refunded,
    PaymentStatus.expired,
  ].contains(this);

  /// Whether this status allows for retry attempts
  bool get canRetry => [
    PaymentStatus.failed,
    PaymentStatus.cancelled,
    PaymentStatus.expired,
  ].contains(this);
}

/// Payment providers supported in V1
enum PaymentProvider {
  culqi;

  /// User-friendly provider names for UI
  String get displayName {
    switch (this) {
      case PaymentProvider.culqi:
        return 'Culqi';
    }
  }

  /// Payment methods supported by this provider
  List<PaymentMethod> get supportedMethods {
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

  /// User-friendly method names for UI
  String get displayName {
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

  /// Whether this method requires immediate processing
  bool get isInstant {
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
///
/// Business Concept: A Payment represents a financial transaction where
/// users pay for listing subscriptions. Each payment tracks the complete
/// transaction lifecycle from initiation to completion or failure.
///
/// Core Responsibilities:
/// - Transaction lifecycle management
/// - Payment provider integration
/// - Amount and currency handling
/// - Receipt and reference tracking
/// - Payment validation and security
class Payment extends Equatable {
  /// Unique identifier for this payment
  final PaymentId id;

  /// Amount being paid in the specified currency
  final double amount;

  /// Currency for the payment (PEN for V1)
  final String currency;

  /// Current status of the payment
  final PaymentStatus status;

  /// Payment provider used for processing
  final PaymentProvider provider;

  /// Payment method chosen by user
  final PaymentMethod method;

  /// External transaction ID from payment provider
  final String? providerTransactionId;

  /// Reference code for customer service and tracking
  final String referenceCode;

  /// Description of what the payment is for
  final String description;

  /// When payment was created
  final DateTime createdAt;

  /// When payment was last updated
  final DateTime updatedAt;

  /// When payment was completed (if successful)
  final DateTime? completedAt;

  /// When payment expires if not completed
  final DateTime? expiresAt;

  /// Payment provider response data (JSON string)
  final String? providerResponse;

  /// Error message if payment failed
  final String? errorMessage;

  /// Receipt URL or data for successful payments
  final String? receiptData;

  const Payment._({
    required this.id,
    required this.amount,
    required this.currency,
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
    required double amount,
    required String currency,
    required PaymentProvider provider,
    required PaymentMethod method,
    required String description,
    String? referenceCode,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return Payment._(
      id: id,
      amount: amount,
      currency: currency.toUpperCase(),
      status: PaymentStatus.pending,
      provider: provider,
      method: method,
      referenceCode: referenceCode ?? _generateReferenceCode(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
      expiresAt:
          expiresAt ??
          now.add(const Duration(hours: 2)), // Default 2-hour expiry
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
      amount: amount,
      currency: currency,
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

  /// Marks payment as processing with provider transaction ID
  Payment markAsProcessing(String providerTransactionId) {
    return copyWith(
      status: PaymentStatus.processing,
      providerTransactionId: providerTransactionId,
    );
  }

  /// Completes payment successfully
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

  /// Marks payment as failed with error details
  Payment fail({required String errorMessage, String? providerResponse}) {
    return copyWith(
      status: PaymentStatus.failed,
      errorMessage: errorMessage,
      providerResponse: providerResponse,
    );
  }

  /// Cancels payment (user-initiated)
  Payment cancel() {
    return copyWith(status: PaymentStatus.cancelled);
  }

  /// Expires payment due to timeout
  Payment expire() {
    return copyWith(status: PaymentStatus.expired);
  }

  /// Processes refund for completed payment
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

  /// Whether payment is completed successfully
  bool isCompleted() {
    return status == PaymentStatus.completed;
  }

  /// Whether payment has failed
  bool isFailed() {
    return status == PaymentStatus.failed;
  }

  /// Whether payment is still pending or processing
  bool isPending() {
    return status == PaymentStatus.pending ||
        status == PaymentStatus.processing;
  }

  /// Whether payment is in a final state
  bool isFinal() {
    return status.isFinal;
  }

  /// Whether payment can be retried
  bool canRetry() {
    return status.canRetry;
  }

  /// Whether payment has expired
  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!) && !isFinal();
  }

  // PAYMENT CALCULATIONS

  /// Gets formatted amount for display
  String getFormattedAmount() {
    if (currency == 'USD') {
      return 'US\$ ${amount.toStringAsFixed(2)}';
    } else if (currency == 'PEN') {
      return 'S/ ${amount.toStringAsFixed(2)}';
    } else {
      return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  /// Gets payment processing time if completed
  Duration? getProcessingTime() {
    if (completedAt == null) return null;
    return completedAt!.difference(createdAt);
  }

  /// Gets time remaining until expiration
  Duration? getTimeUntilExpiry() {
    if (expiresAt == null || isFinal()) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Checks if payment is expiring soon (within 30 minutes)
  bool isExpiringSoon() {
    final timeLeft = getTimeUntilExpiry();
    return timeLeft != null && timeLeft.inMinutes <= 30;
  }

  // VALIDATION

  /// Validates payment data against business rules
  List<String> validateBusinessRules() {
    final errors = <String>[];

    // Amount validation
    if (amount <= 0) {
      errors.add('Payment amount must be greater than 0');
    }
    if (amount > 100000) {
      errors.add('Payment amount cannot exceed 100,000');
    }

    // Currency validation
    if (!['PEN', 'USD'].contains(currency)) {
      errors.add('Currency must be PEN or USD');
    }

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
    if (!provider.supportedMethods.contains(method)) {
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

  /// Generates unique reference code for payment tracking
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
  /// V1 listing fee amount
  static const double listingFeeAmount = 19.0;

  /// V1 default currency
  static const String defaultCurrency = 'PEN';

  /// Default payment expiry time
  static const Duration defaultExpiryTime = Duration(hours: 2);

  /// Creates payment with validation
  static Payment createPaymentWithValidation({
    required PaymentId id,
    required double amount,
    required String currency,
    required PaymentProvider provider,
    required PaymentMethod method,
    required String description,
    String? referenceCode,
    DateTime? expiresAt,
  }) {
    final payment = Payment.create(
      id: id,
      amount: amount,
      currency: currency,
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

  /// Creates listing payment with standard V1 pricing
  static Payment createListingPayment({
    required PaymentId id,
    required PaymentProvider provider,
    required PaymentMethod method,
    String? referenceCode,
  }) {
    return createPaymentWithValidation(
      id: id,
      amount: listingFeeAmount,
      currency: defaultCurrency,
      provider: provider,
      method: method,
      description: 'Publicación de propiedad (30 días)',
      referenceCode: referenceCode,
    );
  }

  /// Processes payment completion with validation
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

  /// Processes payment failure with validation
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

  /// Processes payment expiry (called by background job)
  static Payment? processExpiry(Payment payment) {
    if (payment.isFinal()) return null;
    if (!payment.isExpired()) return null;

    return payment.expire();
  }

  /// Validates payment provider configuration
  static bool isProviderConfigured(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.culqi:
        // In real implementation, check if Culqi keys are configured
        return true; // Simplified for V1
    }
  }

  /// Gets processing time estimate for payment method
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
