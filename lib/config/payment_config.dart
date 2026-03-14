/// Global Payment Configuration for All Payment Methods
/// Switch between test and live environments easily
class GlobalPaymentConfig {
  // ============= GLOBAL PAYMENT ENVIRONMENT =============
  // Set this to false for testing, true for production
  static const bool IS_LIVE = false; // Toggle this for test/live mode

  // ============= KAKAO PAY CONFIGURATION (PortOne V2) =============
  // Kakao Pay uses PortOne V2 for integration in Korea
  // Get your credentials from: https://console.portone.io/
  // Documentation: https://pub.dev/packages/portone_flutter_v2

  // Test Mode Credentials (PortOne V2 Test)
  static const String KAKAO_TEST_STORE_ID =
      'store-15682506-b212-423f-8dee-d50165114bc7'; // Replace with your test store ID
  static const String KAKAO_TEST_CHANNEL_KEY =
      'channel-key-36f55334-21f6-4d5f-92c8-a0cbb2f9e8f2'; // Replace with your test channel key

  // Live Mode Credentials (Replace with your actual credentials from PortOne console)
  static const String KAKAO_LIVE_STORE_ID =
      'store-15682506-b212-423f-8dee-d50165114bc7'; // Your actual store ID
  static const String KAKAO_LIVE_CHANNEL_KEY =
      'channel-key-live-your-channel-key'; // Your actual channel key

  // Active Kakao Pay credentials based on environment
  static String get kakaoStoreId =>
      IS_LIVE ? KAKAO_LIVE_STORE_ID : KAKAO_TEST_STORE_ID;
  static String get kakaoChannelKey =>
      IS_LIVE ? KAKAO_LIVE_CHANNEL_KEY : KAKAO_TEST_CHANNEL_KEY;

  // App scheme for deep linking (must match AndroidManifest.xml and Info.plist)
  static const String APP_SCHEME = 'deepinheart';

  // ============= NAVER PAY CONFIGURATION =============
  // Naver Pay - Popular Korean payment method
  // Uses Inicis gateway for processing
  static const String NAVER_PG =
      'html5_inicis'; // Naver Pay through Inicis gateway
  static const String NAVER_PAY_METHOD = 'naverpay'; // Naver Pay payment method
  static const String NAVER_REDIRECT_URL =
      'https://sprawberry.ktechclans.com/payment/naver/callback';

  // ============= STRIPE CONFIGURATION =============
  static const String STRIPE_TEST_PUBLISHABLE_KEY =
      'pk_test_your_test_key_here';
  static const String STRIPE_LIVE_PUBLISHABLE_KEY =
      'pk_live_your_live_key_here';

  static String get stripePublishableKey =>
      IS_LIVE ? STRIPE_LIVE_PUBLISHABLE_KEY : STRIPE_TEST_PUBLISHABLE_KEY;

  // ============= PAYPAL CONFIGURATION =============
  // Already configured in paypal_config.dart but can be managed here too
  static bool get paypalSandboxMode => !IS_LIVE;

  // ============= GENERAL PAYMENT SETTINGS =============
  static const String DEFAULT_CURRENCY = 'KRW'; // Korean Won
  static const String APP_NAME = 'Deep In Heart';
  static const String COMPANY_NAME = 'Deep In Heart Inc.';

  // Payment timeout (in seconds)
  static const int PAYMENT_TIMEOUT = 300; // 5 minutes

  // Supported payment methods
  static const List<String> SUPPORTED_METHODS = [
    'stripe',
    'paypal',
    'kakaopay',
    'naverpay',
  ];

  // Payment method display names
  static const Map<String, String> PAYMENT_METHOD_NAMES = {
    'stripe': 'Credit/Debit Card (Stripe)',
    'paypal': 'PayPal',
    'kakaopay': 'Kakao Pay (카카오페이)',
    'naverpay': 'Naver Pay (네이버페이)',
  };

  // ============= HELPER METHODS =============

  /// Get environment status as string
  static String get environmentStatus => IS_LIVE ? 'LIVE' : 'TEST';

  /// Check if payment method is enabled
  static bool isMethodEnabled(String method) {
    return SUPPORTED_METHODS.contains(method.toLowerCase());
  }

  /// Get display name for payment method
  static String getMethodDisplayName(String method) {
    return PAYMENT_METHOD_NAMES[method.toLowerCase()] ?? method;
  }

  /// Validate payment amount (minimum 1000 KRW)
  static bool isValidAmount(double amount) {
    return amount >= 1000;
  }

  /// Format amount for display
  static String formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

// Alias for backward compatibility
typedef PaymentEnvConfig = GlobalPaymentConfig;
