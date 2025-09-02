// services/0_config/shared/culqi_config.dart

/// Culqi payment configuration for Ubiqa production
class CulqiConfig {
  /// Culqi public key for frontend token creation
  static const String publicKey = 'pk_test_YOUR_PUBLIC_KEY_HERE';

  /// Culqi secret key for backend operations (keep secure)
  static const String secretKey = 'sk_test_YOUR_SECRET_KEY_HERE';

  /// Culqi API base URL
  static const String baseUrl = 'https://api.culqi.com/v2';

  /// Webhook URL for payment notifications
  static const String webhookUrl = 'https://your-app.com/api/webhooks/culqi';

  /// Payment methods available through Culqi
  static const List<String> supportedMethods = ['card', 'yape', 'plin'];

  /// Currency code for Peru (soles)
  static const String currency = 'PEN';

  /// Minimum payment amount in cents (Culqi uses cents)
  static const int minAmountCents = 300; // 3.00 soles

  /// Maximum payment amount in cents
  static const int maxAmountCents = 10000000; // 100,000.00 soles

  /// Convert soles to cents for Culqi API
  static int solesToCents(double soles) {
    return (soles * 100).round();
  }

  /// Convert cents from Culqi API to soles
  static double centsToSoles(int cents) {
    return cents / 100.0;
  }

  /// Get headers for Culqi API requests
  static Map<String, String> getHeaders() {
    return {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/json',
    };
  }

  /// Validate payment amount is within limits
  static bool isValidAmount(double soles) {
    final cents = solesToCents(soles);
    return cents >= minAmountCents && cents <= maxAmountCents;
  }
}

/// Culqi API endpoints
class CulqiEndpoints {
  static const String charges = '${CulqiConfig.baseUrl}/charges';
  static const String tokens = '${CulqiConfig.baseUrl}/tokens';
  static const String customers = '${CulqiConfig.baseUrl}/customers';
}
