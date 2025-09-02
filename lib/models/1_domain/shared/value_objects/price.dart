// lib/models/1_domain/shared/value_objects/price.dart

import 'package:equatable/equatable.dart';

/// Currency types used in Peru real estate market
enum Currency {
  pen, // Peruvian Soles
  usd; // US Dollars

  /// Currency symbol for display
  String get symbol {
    switch (this) {
      case Currency.pen:
        return 'S/';
      case Currency.usd:
        return 'US\$';
    }
  }

  /// Currency code for API/storage
  String get code {
    switch (this) {
      case Currency.pen:
        return 'PEN';
      case Currency.usd:
        return 'USD';
    }
  }

  /// User-friendly currency name
  String get displayName {
    switch (this) {
      case Currency.pen:
        return 'Soles';
      case Currency.usd:
        return 'Dólares';
    }
  }

  /// Creates Currency from string code
  static Currency fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PEN':
        return Currency.pen;
      case 'USD':
        return Currency.usd;
      default:
        throw ArgumentError('Unsupported currency: $code');
    }
  }
}

/// Price value object for property pricing in Peru market
///
/// This immutable value object handles property prices with proper
/// currency support, formatting, and validation for the Peru real estate market.
///
/// V1 Scope: Basic price representation with PEN/USD support
class Price extends Equatable {
  /// Price amount
  final double amount;

  /// Price currency
  final Currency currency;

  const Price._({required this.amount, required this.currency});

  /// Creates Price with validation
  factory Price.create({required double amount, required Currency currency}) {
    final price = Price._(amount: amount, currency: currency);

    final violations = price._validate();
    if (violations.isNotEmpty) {
      throw PriceException('Invalid price data', violations);
    }

    return price;
  }

  /// Creates Price from amount and currency code
  factory Price.fromCode({
    required double amount,
    required String currencyCode,
  }) {
    return Price.create(
      amount: amount,
      currency: Currency.fromCode(currencyCode),
    );
  }

  /// Creates Price in Peruvian Soles
  factory Price.inSoles(double amount) {
    return Price.create(amount: amount, currency: Currency.pen);
  }

  /// Creates Price in US Dollars
  factory Price.inDollars(double amount) {
    return Price.create(amount: amount, currency: Currency.usd);
  }

  // PRICE DISPLAY AND FORMATTING

  /// Gets formatted price for display (e.g., "S/ 350,000" or "US$ 95,000")
  String getFormattedPrice() {
    return '${currency.symbol} ${_formatAmount(amount)}';
  }

  /// Gets compact price format for cards (e.g., "S/ 350K" or "US$ 95K")
  String getCompactPrice() {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${currency.symbol} ${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${currency.symbol} ${thousands.toStringAsFixed(0)}K';
    } else {
      return '${currency.symbol} ${amount.toStringAsFixed(0)}';
    }
  }

  /// Gets price range display (e.g., "S/ 300K - 400K")
  static String getPriceRangeDisplay(Price minPrice, Price maxPrice) {
    if (minPrice.currency != maxPrice.currency) {
      return '${minPrice.getCompactPrice()} - ${maxPrice.getFormattedPrice()}';
    }

    return '${minPrice.currency.symbol} ${_formatAmount(minPrice.amount)} - ${_formatAmount(maxPrice.amount)}';
  }

  /// Gets price with currency name (e.g., "350,000 Soles")
  String getPriceWithCurrencyName() {
    return '${_formatAmount(amount)} ${currency.displayName}';
  }

  // PRICE CALCULATIONS

  /// Calculates price per square meter
  Price calculatePricePerM2(double areaM2) {
    if (areaM2 <= 0) {
      throw ArgumentError(
        'Area must be greater than 0 to calculate price per m²',
      );
    }

    return Price.create(amount: amount / areaM2, currency: currency);
  }

  /// Gets formatted price per m² for display
  String getFormattedPricePerM2(double areaM2) {
    final pricePerM2 = calculatePricePerM2(areaM2);
    return '${pricePerM2.getFormattedPrice()}/m²';
  }

  /// Checks if price is within specified range
  bool isWithinRange(Price minPrice, Price maxPrice) {
    // For simplicity in V1, only compare prices in same currency
    if (currency != minPrice.currency || currency != maxPrice.currency) {
      return false;
    }

    return amount >= minPrice.amount && amount <= maxPrice.amount;
  }

  /// Calculates percentage difference from another price
  double percentageDifferenceFrom(Price otherPrice) {
    if (currency != otherPrice.currency) {
      throw ArgumentError('Cannot compare prices in different currencies');
    }

    if (otherPrice.amount == 0) {
      throw ArgumentError('Cannot calculate percentage from zero price');
    }

    return ((amount - otherPrice.amount) / otherPrice.amount) * 100;
  }

  // PRICE COMPARISON

  /// Compares with another price (same currency only)
  int compareTo(Price other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot compare prices in different currencies');
    }

    return amount.compareTo(other.amount);
  }

  /// Checks if price is higher than another
  bool isHigherThan(Price other) {
    return compareTo(other) > 0;
  }

  /// Checks if price is lower than another
  bool isLowerThan(Price other) {
    return compareTo(other) < 0;
  }

  // PRICE CATEGORIES FOR FILTERING

  /// Gets price category for filtering
  PriceCategory getPriceCategory() {
    final baseAmount = currency == Currency.usd
        ? amount *
              3.8 // Rough USD to PEN conversion for categorization
        : amount;

    if (baseAmount < 150000) return PriceCategory.budget;
    if (baseAmount < 300000) return PriceCategory.mid;
    if (baseAmount < 600000) return PriceCategory.high;
    return PriceCategory.luxury;
  }

  // VALIDATION

  /// Validates price data
  List<String> _validate() {
    final errors = <String>[];

    // Amount validation
    if (amount <= 0) {
      errors.add('Price amount must be greater than 0');
    }

    // Reasonable price limits for Peru real estate
    if (currency == Currency.pen) {
      if (amount > 10000000) {
        // 10 million soles
        errors.add('Price cannot exceed S/ 10,000,000');
      }
      if (amount < 1000) {
        // 1,000 soles
        errors.add('Price cannot be less than S/ 1,000');
      }
    } else if (currency == Currency.usd) {
      if (amount > 3000000) {
        // 3 million dollars
        errors.add('Price cannot exceed US\$ 3,000,000');
      }
      if (amount < 500) {
        // 500 dollars
        errors.add('Price cannot be less than US\$ 500');
      }
    }

    return errors;
  }

  /// Formats amount with thousands separators
  static String _formatAmount(double amount) {
    final integerPart = amount.floor();
    final decimalPart = amount - integerPart;

    // Add thousands separators to integer part
    final integerString = integerPart.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < integerString.length; i++) {
      if (i > 0 && (integerString.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerString[i]);
    }

    // Add decimal part if significant
    if (decimalPart > 0.009) {
      // Only show decimals if > 0.01
      buffer.write(
        '.${(decimalPart * 100).round().toString().padLeft(2, '0')}',
      );
    }

    return buffer.toString();
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [amount, currency];

  @override
  String toString() {
    return 'Price(${getFormattedPrice()})';
  }
}

/// Price categories for filtering and display
enum PriceCategory {
  budget, // < S/ 150K (or equivalent)
  mid, // S/ 150K - 300K
  high, // S/ 300K - 600K
  luxury; // > S/ 600K

  String get displayName {
    switch (this) {
      case PriceCategory.budget:
        return 'Económico';
      case PriceCategory.mid:
        return 'Intermedio';
      case PriceCategory.high:
        return 'Alto';
      case PriceCategory.luxury:
        return 'Lujo';
    }
  }

  /// Gets price range description for category
  String getRangeDescription() {
    switch (this) {
      case PriceCategory.budget:
        return 'Hasta S/ 150,000';
      case PriceCategory.mid:
        return 'S/ 150,000 - 300,000';
      case PriceCategory.high:
        return 'S/ 300,000 - 600,000';
      case PriceCategory.luxury:
        return 'Más de S/ 600,000';
    }
  }
}

/// Exception for price validation errors
class PriceException implements Exception {
  final String message;
  final List<String> violations;

  const PriceException(this.message, this.violations);

  @override
  String toString() =>
      'PriceException: $message\nViolations: ${violations.join(', ')}';
}

/// Price domain service for common operations
class PriceDomainService {
  /// Validates price for property listing
  static List<String> validateForListing(Price price) {
    final errors = <String>[];

    // Check if price is reasonable for property type
    if (price.currency == Currency.pen && price.amount < 50000) {
      errors.add('Property price seems unusually low for Peru market');
    }

    if (price.currency == Currency.usd && price.amount < 15000) {
      errors.add('Property price seems unusually low for Peru market');
    }

    return errors;
  }

  /// Gets typical currency for operation type
  static Currency getTypicalCurrencyFor(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'venta':
        return Currency.usd; // Sales often in dollars
      case 'alquiler':
        return Currency.pen; // Rentals often in soles
      default:
        return Currency.pen; // Default to soles
    }
  }

  /// Creates price range for search filters
  static List<Price> createPriceRanges(Currency currency) {
    if (currency == Currency.pen) {
      return [
        Price.inSoles(0),
        Price.inSoles(100000),
        Price.inSoles(200000),
        Price.inSoles(350000),
        Price.inSoles(500000),
        Price.inSoles(750000),
        Price.inSoles(1000000),
        Price.inSoles(2000000),
      ];
    } else {
      return [
        Price.inDollars(0),
        Price.inDollars(25000),
        Price.inDollars(50000),
        Price.inDollars(100000),
        Price.inDollars(150000),
        Price.inDollars(250000),
        Price.inDollars(400000),
        Price.inDollars(600000),
      ];
    }
  }

  /// Formats price for search URL parameters
  static String formatForUrl(Price price) {
    return '${price.amount.toInt()}_${price.currency.code}';
  }

  /// Parses price from URL parameter
  static Price? parseFromUrl(String urlParam) {
    try {
      final parts = urlParam.split('_');
      if (parts.length != 2) return null;

      final amount = double.parse(parts[0]);
      final currency = Currency.fromCode(parts[1]);

      return Price.create(amount: amount, currency: currency);
    } catch (e) {
      return null;
    }
  }
}
