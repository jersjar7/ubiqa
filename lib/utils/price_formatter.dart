// lib/utils/price_formatter.dart

import '../models/1_domain/shared/value_objects/price.dart';

/// Price formatting utilities for map bubbles and UI display
class PriceFormatter {
  /// Formats price for map bubble display
  /// Uses K for thousands, M for millions
  /// Examples: $1.2M, S/645K, $89K
  static String formatForMapBubble(Price price) {
    final amount = price.monetaryAmountValue;
    final symbol = price.transactionCurrency.currencySymbol;

    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '$symbol${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '$symbol${thousands.toStringAsFixed(0)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  /// Formats full price for detail views
  /// Examples: $180,000, S/2,500
  static String formatFullPrice(Price price) {
    final amount = price.monetaryAmountValue;
    final symbol = price.transactionCurrency.currencySymbol;
    final formattedAmount = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$symbol$formattedAmount';
  }
}
