/// Payment Configuration (PayPal & Stripe)
///
/// IMPORTANT: Replace these values with your actual credentials
///
/// PayPal: https://developer.paypal.com/
/// Stripe: https://dashboard.stripe.com/

class PaymentConfig {
  // ==================== PayPal Configuration ====================
  static const String paypalClientId =
      "AW1TdvpSGbIM5iP4HJNI5TyTmwpY9Gv9dYw8_8yW5lYIbCqf326vrkrp0ce9TAqjEGMHiV3OqJM_aRT0";

  static const String paypalSecretKey =
      "EHHtTDjnmTZATYBPiGzZC_AZUfMpMAzj2VZUeqlFUrRJA_C0pQNCxDccB5qoRQSEdcOnnKQhycuOWdP9";

  static const String paypalReturnURL =
      'https://sprawberry.ktechclans.com/return';
  static const String paypalCancelURL =
      'https://sprawberry.ktechclans.com/cancel';

  // Set to true for testing, false for production
  static const bool paypalSandboxMode = true;

  // ==================== Stripe Configuration ====================
  static const String stripePublishableKey =
      "pk_test_51Rqgc3QGTy9gtb153mEJL92Vkz6N1GmozRwrEkOagS2hNAMY1RJ1GODitqKX3EvaTANo4p12CBl5BMBCE4S41aJd00ZHaD4hvR";

  static const String stripeSecretKey =
      "sk_test_51Rqgc3QGTy9gtb15BsZFshL0hv8D4sDnaNlUrC4zJM9mKp7bu51MKi1fK06co78XEasnoR7IfiUiuQrm4cTxwpas00JOoDqpGT";

  // ==================== Currency Configuration ====================
  // Currency for PayPal transactions (PayPal typically uses USD)
  static const String paypalCurrency = "USD";

  // Currency for Stripe transactions (lowercase for Stripe API)
  // KRW is a zero-decimal currency (no cents/decimals, uses whole numbers)
  static const String stripeCurrency = "krw"; // Korean Won

  // Your local currency for display
  static const String localCurrency = "KRW";
}

// Backward compatibility alias
class PayPalConfig {
  static const String clientId = PaymentConfig.paypalClientId;
  static const String secretKey = PaymentConfig.paypalSecretKey;
  static const String PayPalReturnURL = PaymentConfig.paypalReturnURL;
  static const String PayPalCancelURL = PaymentConfig.paypalCancelURL;
  static const bool sandboxMode = PaymentConfig.paypalSandboxMode;
  static const String paypalCurrency = PaymentConfig.paypalCurrency;
  static const String localCurrency = PaymentConfig.localCurrency;
}
