// lib/models/1_domain/shared/configurations/pricing_configuration.dart

import 'package:equatable/equatable.dart';

/// Centralized pricing configuration for the Ubiqa platform
/// Handles base pricing, promotional pricing, and future dynamic pricing needs
class PricingConfiguration {
  // BASE PRICING CONSTANTS

  /// Standard listing fee in Peruvian Soles for 30-day property publication
  static const double baseListingFeeInSoles = 19.0;

  /// Standard listing duration in days
  static const int standardListingDurationDays = 30;

  /// Default currency for listing fees
  static const String defaultListingFeeCurrency = 'PEN';

  // PROMOTIONAL PRICING SUPPORT

  /// Gets current listing fee with promotional pricing support
  /// In V1, returns base price. Future: integrate with promotional system
  static Future<ListingPricing> getCurrentListingPricing({
    String? promotionalCode,
    String? userId,
  }) async {
    // V1: Return standard pricing
    // Future: Check promotional campaigns, user eligibility, A/B tests

    return const ListingPricing(
      feeAmount: baseListingFeeInSoles,
      currency: defaultListingFeeCurrency,
      durationDays: standardListingDurationDays,
      isPromotional: false,
    );
  }

  /// Validates promotional code (placeholder for future implementation)
  static Future<PromotionalPricingResult> validatePromotionalCode(
    String promotionalCode,
  ) async {
    // Future: Integrate with promotional system
    return PromotionalPricingResult.invalid(
      'Promotional codes not yet supported',
    );
  }

  // PRICING CALCULATION HELPERS

  /// Calculates total cost for multiple listings
  static double calculateMultipleListingsCost(
    int listingCount,
    double unitPrice,
  ) {
    if (listingCount <= 0) return 0.0;

    // Future: Volume discounts
    return listingCount * unitPrice;
  }

  /// Gets price breakdown for display purposes
  static ListingPriceBreakdown getListingPriceBreakdown(double basePrice) {
    // V1: Simple breakdown. Future: taxes, fees, discounts
    return ListingPriceBreakdown(
      basePrice: basePrice,
      taxes: 0.0,
      platformFee: 0.0,
      discount: 0.0,
      totalPrice: basePrice,
    );
  }
}

/// Listing pricing information with promotional context
class ListingPricing extends Equatable {
  final double feeAmount;
  final String currency;
  final int durationDays;
  final bool isPromotional;
  final String? promotionalDescription;
  final DateTime? promotionalExpiresAt;

  const ListingPricing({
    required this.feeAmount,
    required this.currency,
    required this.durationDays,
    required this.isPromotional,
    this.promotionalDescription,
    this.promotionalExpiresAt,
  });

  /// Creates standard (non-promotional) pricing
  factory ListingPricing.standard() {
    return const ListingPricing(
      feeAmount: PricingConfiguration.baseListingFeeInSoles,
      currency: PricingConfiguration.defaultListingFeeCurrency,
      durationDays: PricingConfiguration.standardListingDurationDays,
      isPromotional: false,
    );
  }

  /// Creates promotional pricing
  factory ListingPricing.promotional({
    required double discountedFeeAmount,
    required String promotionalDescription,
    DateTime? expiresAt,
  }) {
    return ListingPricing(
      feeAmount: discountedFeeAmount,
      currency: PricingConfiguration.defaultListingFeeCurrency,
      durationDays: PricingConfiguration.standardListingDurationDays,
      isPromotional: true,
      promotionalDescription: promotionalDescription,
      promotionalExpiresAt: expiresAt,
    );
  }

  /// Calculates savings compared to standard pricing
  double calculateSavings() {
    if (!isPromotional) return 0.0;
    return PricingConfiguration.baseListingFeeInSoles - feeAmount;
  }

  /// Generates user-friendly pricing description
  String generatePricingDescription() {
    if (!isPromotional) {
      return 'S/ ${feeAmount.toStringAsFixed(0)} por $durationDays días';
    }

    final savings = calculateSavings();
    return 'S/ ${feeAmount.toStringAsFixed(0)} por $durationDays días (Ahorro: S/ ${savings.toStringAsFixed(0)})';
  }

  @override
  List<Object?> get props => [
    feeAmount,
    currency,
    durationDays,
    isPromotional,
    promotionalDescription,
    promotionalExpiresAt,
  ];
}

/// Result of promotional code validation
class PromotionalPricingResult extends Equatable {
  final bool isValid;
  final String? errorMessage;
  final ListingPricing? discountedPricing;

  const PromotionalPricingResult._({
    required this.isValid,
    this.errorMessage,
    this.discountedPricing,
  });

  factory PromotionalPricingResult.valid(ListingPricing discountedPricing) {
    return PromotionalPricingResult._(
      isValid: true,
      discountedPricing: discountedPricing,
    );
  }

  factory PromotionalPricingResult.invalid(String errorMessage) {
    return PromotionalPricingResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isValid, errorMessage, discountedPricing];
}

/// Price breakdown for transparency
class ListingPriceBreakdown extends Equatable {
  final double basePrice;
  final double taxes;
  final double platformFee;
  final double discount;
  final double totalPrice;

  const ListingPriceBreakdown({
    required this.basePrice,
    required this.taxes,
    required this.platformFee,
    required this.discount,
    required this.totalPrice,
  });

  /// Formats breakdown for display
  List<String> getFormattedBreakdown() {
    final breakdown = <String>[];

    breakdown.add('Publicación: S/ ${basePrice.toStringAsFixed(0)}');

    if (taxes > 0) {
      breakdown.add('Impuestos: S/ ${taxes.toStringAsFixed(2)}');
    }

    if (platformFee > 0) {
      breakdown.add(
        'Tarifa de plataforma: S/ ${platformFee.toStringAsFixed(2)}',
      );
    }

    if (discount > 0) {
      breakdown.add('Descuento: -S/ ${discount.toStringAsFixed(2)}');
    }

    breakdown.add('Total: S/ ${totalPrice.toStringAsFixed(0)}');

    return breakdown;
  }

  @override
  List<Object> get props => [
    basePrice,
    taxes,
    platformFee,
    discount,
    totalPrice,
  ];
}

/// Pricing domain service for pricing-related business logic
class PricingDomainService {
  /// Validates if a fee amount is acceptable for listings
  static bool isValidListingFeeAmount(double feeAmount) {
    return feeAmount >= 1.0 && feeAmount <= 200.0;
  }

  /// Gets minimum acceptable listing fee
  static double getMinimumListingFee() {
    return 1.0; // Minimum for promotional campaigns
  }

  /// Gets maximum acceptable listing fee
  static double getMaximumListingFee() {
    return 200.0; // Reasonable upper limit
  }

  /// Calculates if current pricing is competitive (placeholder)
  static bool isPricingCompetitive(double proposedFee) {
    // Future: Compare with market competitors
    return proposedFee <= PricingConfiguration.baseListingFeeInSoles * 1.2;
  }
}
