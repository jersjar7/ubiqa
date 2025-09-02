// lib/models/1_domain/shared/value_objects/price.dart

import 'package:equatable/equatable.dart';

/// Currency types used in Peru real estate market
/// Limited to PEN/USD because these dominate Piura property transactions
enum Currency {
  pen, // Peruvian Soles
  usd; // US Dollars

  /// Currency symbol for user interface display
  String get currencySymbol {
    switch (this) {
      case Currency.pen:
        return 'S/';
      case Currency.usd:
        return 'US\$';
    }
  }

  /// ISO currency code for API and database storage
  String get isoCurrencyCode {
    switch (this) {
      case Currency.pen:
        return 'PEN';
      case Currency.usd:
        return 'USD';
    }
  }

  /// Localized currency name for user-friendly display
  String get localizedCurrencyName {
    switch (this) {
      case Currency.pen:
        return 'Soles';
      case Currency.usd:
        return 'Dólares';
    }
  }

  /// Creates Currency from ISO code string
  /// Enables flexible currency parsing from external data sources
  static Currency fromIsoCode(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'PEN':
        return Currency.pen;
      case 'USD':
        return Currency.usd;
      default:
        throw ArgumentError('Unsupported currency code: $currencyCode');
    }
  }
}

/// Price value object for property pricing in Piura real estate market
///
/// Encapsulates monetary value because accurate pricing is critical for
/// property discovery, comparison, and transaction completion. Immutable design
/// prevents price corruption during property lifecycle and ensures consistent
/// financial calculations across the platform.
///
/// V1 Scope: PEN/USD support with Piura market validation
class Price extends Equatable {
  /// Monetary amount in the specified currency
  /// Stored as double to handle precise pricing including cents/centimos
  final double monetaryAmountValue;

  /// Currency denomination for the monetary amount
  /// Essential for multi-currency support in Peru real estate transactions
  final Currency transactionCurrency;

  const Price._({
    required this.monetaryAmountValue,
    required this.transactionCurrency,
  });

  /// Creates Price with comprehensive validation
  /// Validation prevents invalid amounts that would break financial calculations
  factory Price.create({
    required double monetaryAmountValue,
    required Currency transactionCurrency,
  }) {
    final price = Price._(
      monetaryAmountValue: monetaryAmountValue,
      transactionCurrency: transactionCurrency,
    );

    final validationErrors = price._validatePriceData();
    if (validationErrors.isNotEmpty) {
      throw PriceValidationException('Invalid price data', validationErrors);
    }

    return price;
  }

  /// Creates Price from amount and ISO currency code
  /// Enables price creation from API responses and external data sources
  factory Price.createFromCurrencyCode({
    required double monetaryAmountValue,
    required String isoCurrencyCode,
  }) {
    return Price.create(
      monetaryAmountValue: monetaryAmountValue,
      transactionCurrency: Currency.fromIsoCode(isoCurrencyCode),
    );
  }

  /// Creates Price in Peruvian Soles
  /// Convenience factory for PEN transactions common in Piura rentals
  factory Price.createInSoles(double solesAmount) {
    return Price.create(
      monetaryAmountValue: solesAmount,
      transactionCurrency: Currency.pen,
    );
  }

  /// Creates Price in US Dollars
  /// Convenience factory for USD transactions common in Piura sales
  factory Price.createInDollars(double dollarsAmount) {
    return Price.create(
      monetaryAmountValue: dollarsAmount,
      transactionCurrency: Currency.usd,
    );
  }

  // PRICE DISPLAY AND FORMATTING

  /// Generates formatted price for property listing display
  /// Format follows Peru market conventions for user recognition
  String generateFormattedPriceForDisplay() {
    return '${transactionCurrency.currencySymbol} ${_formatAmountWithThousandsSeparators(monetaryAmountValue)}';
  }

  /// Generates compact price format for property cards and mobile display
  /// Abbreviated format saves space while maintaining readability
  String generateCompactPriceFormat() {
    if (monetaryAmountValue >= 1000000) {
      final millionsAmount = monetaryAmountValue / 1000000;
      return '${transactionCurrency.currencySymbol} ${millionsAmount.toStringAsFixed(1)}M';
    } else if (monetaryAmountValue >= 1000) {
      final thousandsAmount = monetaryAmountValue / 1000;
      return '${transactionCurrency.currencySymbol} ${thousandsAmount.toStringAsFixed(0)}K';
    } else {
      return '${transactionCurrency.currencySymbol} ${monetaryAmountValue.toStringAsFixed(0)}';
    }
  }

  /// Generates price range display for search filters
  /// Static method handles mixed currency scenarios appropriately
  static String generatePriceRangeDisplay(
    Price minimumPrice,
    Price maximumPrice,
  ) {
    if (minimumPrice.transactionCurrency != maximumPrice.transactionCurrency) {
      return '${minimumPrice.generateCompactPriceFormat()} - ${maximumPrice.generateFormattedPriceForDisplay()}';
    }

    return '${minimumPrice.transactionCurrency.currencySymbol} ${_formatAmountWithThousandsSeparators(minimumPrice.monetaryAmountValue)} - ${_formatAmountWithThousandsSeparators(maximumPrice.monetaryAmountValue)}';
  }

  /// Generates price with full currency name for formal display
  /// Used in contracts and formal property documentation
  String generatePriceWithCurrencyName() {
    return '${_formatAmountWithThousandsSeparators(monetaryAmountValue)} ${transactionCurrency.localizedCurrencyName}';
  }

  // PRICE CALCULATIONS

  /// Calculates price per square meter for property valuation
  /// Critical metric for Peru real estate comparison and market analysis
  Price calculatePricePerSquareMeter(double totalAreaInSquareMeters) {
    if (totalAreaInSquareMeters <= 0) {
      throw ArgumentError(
        'Total area must be greater than 0 to calculate price per square meter',
      );
    }

    return Price.create(
      monetaryAmountValue: monetaryAmountValue / totalAreaInSquareMeters,
      transactionCurrency: transactionCurrency,
    );
  }

  /// Formats price per square meter for property comparison display
  /// Enables easy valuation comparison between similar properties
  String formatPricePerSquareMeterForDisplay(double totalAreaInSquareMeters) {
    final pricePerSquareMeter = calculatePricePerSquareMeter(
      totalAreaInSquareMeters,
    );
    return '${pricePerSquareMeter.generateFormattedPriceForDisplay()}/m²';
  }

  /// Determines if price falls within specified range boundaries
  /// Enables property filtering by price range in search functionality
  bool isWithinPriceRange(
    Price minimumPriceThreshold,
    Price maximumPriceThreshold,
  ) {
    // Same currency comparison only to avoid exchange rate complications in V1
    if (transactionCurrency != minimumPriceThreshold.transactionCurrency ||
        transactionCurrency != maximumPriceThreshold.transactionCurrency) {
      return false;
    }

    return monetaryAmountValue >= minimumPriceThreshold.monetaryAmountValue &&
        monetaryAmountValue <= maximumPriceThreshold.monetaryAmountValue;
  }

  /// Calculates percentage difference from another price for market analysis
  /// Used for price trend analysis and property value assessment
  double calculatePercentageDifferenceFrom(Price comparisonPrice) {
    if (transactionCurrency != comparisonPrice.transactionCurrency) {
      throw ArgumentError(
        'Cannot compare prices in different currencies without exchange rate',
      );
    }

    if (comparisonPrice.monetaryAmountValue == 0) {
      throw ArgumentError(
        'Cannot calculate percentage difference from zero-value price',
      );
    }

    return ((monetaryAmountValue - comparisonPrice.monetaryAmountValue) /
            comparisonPrice.monetaryAmountValue) *
        100;
  }

  // PRICE COMPARISON

  /// Compares price magnitude with another price (same currency only)
  /// Enables price sorting and ranking functionality
  int compareToPrice(Price otherPrice) {
    if (transactionCurrency != otherPrice.transactionCurrency) {
      throw ArgumentError(
        'Cannot compare prices in different currencies without exchange rate',
      );
    }

    return monetaryAmountValue.compareTo(otherPrice.monetaryAmountValue);
  }

  /// Determines if this price exceeds another price value
  /// Useful for price threshold validation and comparison
  bool isHigherThanPrice(Price comparisonPrice) {
    return compareToPrice(comparisonPrice) > 0;
  }

  /// Determines if this price is below another price value
  /// Useful for budget filtering and affordability checks
  bool isLowerThanPrice(Price comparisonPrice) {
    return compareToPrice(comparisonPrice) < 0;
  }

  // PRICE CATEGORIES FOR FILTERING

  /// Determines price category for market segmentation and filtering
  /// Categories based on Piura real estate market ranges
  PriceMarketCategory determinePriceMarketCategory() {
    final solesEquivalentAmount = transactionCurrency == Currency.usd
        ? monetaryAmountValue *
              3.8 // Approximate USD to PEN conversion for categorization
        : monetaryAmountValue;

    if (solesEquivalentAmount < 150000)
      return PriceMarketCategory.economicSegment;
    if (solesEquivalentAmount < 300000)
      return PriceMarketCategory.midMarketSegment;
    if (solesEquivalentAmount < 600000)
      return PriceMarketCategory.upscaleSegment;
    return PriceMarketCategory.luxurySegment;
  }

  // VALIDATION

  /// Validates price data comprehensively for Piura market context
  /// Prevents invalid amounts that would break financial functionality
  List<String> _validatePriceData() {
    final validationErrors = <String>[];

    // Amount validation - must be positive for valid transactions
    if (monetaryAmountValue <= 0) {
      validationErrors.add(
        'Price amount must be greater than 0 for valid property transactions',
      );
    }

    // Precision validation - excessive decimal places indicate data corruption
    final decimalPlaces = monetaryAmountValue.toString().split('.').length > 1
        ? monetaryAmountValue.toString().split('.')[1].length
        : 0;
    if (decimalPlaces > 2) {
      validationErrors.add(
        'Price precision cannot exceed 2 decimal places (currency subdivision limit)',
      );
    }

    // Piura market reasonable limits based on local property values
    if (transactionCurrency == Currency.pen) {
      if (monetaryAmountValue > 2000000) {
        // 2 million soles - beyond typical Piura property range
        validationErrors.add(
          'PEN price cannot exceed S/ 2,000,000 (exceeds typical Piura market range)',
        );
      }
      if (monetaryAmountValue < 500) {
        // 500 soles - below realistic minimum
        validationErrors.add(
          'PEN price cannot be less than S/ 500 (below realistic property minimum)',
        );
      }
    } else if (transactionCurrency == Currency.usd) {
      if (monetaryAmountValue > 600000) {
        // 600k USD - beyond typical Piura luxury range
        validationErrors.add(
          'USD price cannot exceed US\$ 600,000 (exceeds typical Piura market range)',
        );
      }
      if (monetaryAmountValue < 200) {
        // 200 USD - below realistic minimum
        validationErrors.add(
          'USD price cannot be less than US\$ 200 (below realistic property minimum)',
        );
      }
    }

    return validationErrors;
  }

  /// Formats monetary amount with thousands separators for readability
  /// Follows Peru number formatting conventions
  static String _formatAmountWithThousandsSeparators(double amount) {
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

    // Add decimal part if significant (greater than 1 centimo/cent)
    if (decimalPart > 0.009) {
      buffer.write(
        '.${(decimalPart * 100).round().toString().padLeft(2, '0')}',
      );
    }

    return buffer.toString();
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [monetaryAmountValue, transactionCurrency];

  @override
  String toString() {
    return 'Price(${generateFormattedPriceForDisplay()})';
  }
}

/// Price market categories for filtering and market analysis
/// Categories reflect Piura real estate market segments and buyer demographics
enum PriceMarketCategory {
  economicSegment, // < S/ 150K (or equivalent)
  midMarketSegment, // S/ 150K - 300K
  upscaleSegment, // S/ 300K - 600K
  luxurySegment; // > S/ 600K

  /// Localized category labels for user interface display
  String get categoryDisplayLabel {
    switch (this) {
      case PriceMarketCategory.economicSegment:
        return 'Económico';
      case PriceMarketCategory.midMarketSegment:
        return 'Rango Medio';
      case PriceMarketCategory.upscaleSegment:
        return 'Alto Valor';
      case PriceMarketCategory.luxurySegment:
        return 'Lujo';
    }
  }

  /// Price range descriptions for search filter display
  String generateRangeDescription() {
    switch (this) {
      case PriceMarketCategory.economicSegment:
        return 'Hasta S/ 150,000';
      case PriceMarketCategory.midMarketSegment:
        return 'S/ 150,000 - 300,000';
      case PriceMarketCategory.upscaleSegment:
        return 'S/ 300,000 - 600,000';
      case PriceMarketCategory.luxurySegment:
        return 'Más de S/ 600,000';
    }
  }
}

/// Exception for price validation errors
/// Specific exception type enables targeted financial error handling
class PriceValidationException implements Exception {
  final String message;
  final List<String> violations;

  const PriceValidationException(this.message, this.violations);

  @override
  String toString() =>
      'PriceValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// Price domain service for common pricing operations and business logic
/// Centralized service ensures consistent pricing behavior across the platform
class PriceDomainService {
  /// Validates price specifically for property listing publication
  /// Additional validation ensures listing prices meet market expectations
  static List<String> validatePriceForPropertyListing(Price propertyPrice) {
    final listingValidationErrors = <String>[];

    // Minimum viable property prices for Piura market
    if (propertyPrice.transactionCurrency == Currency.pen &&
        propertyPrice.monetaryAmountValue < 30000) {
      listingValidationErrors.add(
        'PEN property price seems unusually low for Piura market (below S/ 30,000)',
      );
    }

    if (propertyPrice.transactionCurrency == Currency.usd &&
        propertyPrice.monetaryAmountValue < 8000) {
      listingValidationErrors.add(
        'USD property price seems unusually low for Piura market (below US\$ 8,000)',
      );
    }

    // Price precision validation for user interface clarity
    if (propertyPrice.monetaryAmountValue % 100 != 0 &&
        propertyPrice.monetaryAmountValue > 10000) {
      listingValidationErrors.add(
        'Large property prices should be rounded to hundreds for better presentation',
      );
    }

    return listingValidationErrors;
  }

  /// Determines typical currency for operation type in Piura market
  /// Based on local market practices and transaction preferences
  static Currency getTypicalCurrencyForOperationType(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'venta':
        return Currency.usd; // Sales commonly priced in USD in Piura
      case 'alquiler':
        return Currency.pen; // Rentals typically priced in PEN in Piura
      default:
        return Currency.pen; // Default to local currency
    }
  }

  /// Creates predefined price ranges for search filters
  /// Ranges optimized for Piura property market distribution
  static List<Price> createSearchFilterPriceRanges(Currency currency) {
    if (currency == Currency.pen) {
      return [
        Price.createInSoles(0),
        Price.createInSoles(50000),
        Price.createInSoles(100000),
        Price.createInSoles(200000),
        Price.createInSoles(300000),
        Price.createInSoles(500000),
        Price.createInSoles(750000),
        Price.createInSoles(1000000),
      ];
    } else {
      return [
        Price.createInDollars(0),
        Price.createInDollars(15000),
        Price.createInDollars(30000),
        Price.createInDollars(60000),
        Price.createInDollars(100000),
        Price.createInDollars(150000),
        Price.createInDollars(250000),
        Price.createInDollars(400000),
      ];
    }
  }

  /// Formats price for URL parameters in search and routing
  /// Enables price-based deep linking and shareable property searches
  static String formatPriceForUrlParameter(Price price) {
    return '${price.monetaryAmountValue.toInt()}_${price.transactionCurrency.isoCurrencyCode}';
  }

  /// Parses price from URL parameter string
  /// Enables price reconstruction from deep links and shared searches
  static Price? parsePriceFromUrlParameter(String urlParameter) {
    try {
      final parts = urlParameter.split('_');
      if (parts.length != 2) return null;

      final amount = double.parse(parts[0]);
      final currency = Currency.fromIsoCode(parts[1]);

      return Price.create(
        monetaryAmountValue: amount,
        transactionCurrency: currency,
      );
    } catch (e) {
      return null;
    }
  }
}
