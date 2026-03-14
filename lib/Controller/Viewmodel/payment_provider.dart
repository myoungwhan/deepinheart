import 'dart:convert';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/locale_controller.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/config/paypal_config.dart' as paypal_cfg;
import 'package:deepinheart/config/payment_config.dart' as payment_env;
import 'package:deepinheart/screens/counselor/views/dialogs/message_alert_dialog.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isProcessing = false;
  String? _lastTransactionId;

  // Coin packages data
  List<dynamic>? _coinPackages;
  Map<String, dynamic>? _basicPackage;
  Map<String, dynamic>? _customPackage;
  bool _isLoadingPackages = false;
  bool _packagesLoaded = false;

  bool get isProcessing => _isProcessing;
  String? get lastTransactionId => _lastTransactionId;

  // Coin packages getters
  List<dynamic>? get coinPackages => _coinPackages;
  Map<String, dynamic>? get basicPackage => _basicPackage;
  Map<String, dynamic>? get customPackage => _customPackage;
  bool get isLoadingPackages => _isLoadingPackages;
  bool get packagesLoaded => _packagesLoaded;

  /// Initialize PayPal payment
  void initiatePayPalPayment({
    required BuildContext context,
    required double amount,
    required int coins,
    required String currency,
    required String coupon_banner_id,
  }) {
    // Convert amount to USD for PayPal (or keep it in KRW based on your requirements)
    // For now, assuming the amount is in KRW and we need to show it
    final String paypalAmount = amount.toStringAsFixed(2);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (BuildContext context) => PaypalCheckoutView(
              sandboxMode: paypal_cfg.PayPalConfig.sandboxMode,
              clientId: paypal_cfg.PayPalConfig.clientId,
              secretKey: paypal_cfg.PayPalConfig.secretKey,
              transactions: [
                {
                  "amount": {
                    "total": paypalAmount,
                    "currency": paypal_cfg.PayPalConfig.paypalCurrency,
                    "details": {
                      "subtotal": paypalAmount,
                      "shipping": '0',
                      "shipping_discount": 0,
                    },
                  },
                  "description": "Coin Recharge - $coins coins",
                  "item_list": {
                    "items": [
                      {
                        "name": "Coins",
                        "quantity": coins,
                        "price": (amount / coins).toStringAsFixed(2),
                        "currency": paypal_cfg.PayPalConfig.paypalCurrency,
                      },
                    ],
                  },
                },
              ],
              note: "Contact us for any questions on your order.",
              onSuccess: (Map params) async {
                debugPrint("PayPal Payment Success: $params");
                await _handlePaymentSuccess(
                  context: context,
                  paymentMethod: 'paypal',
                  transactionId:
                      params['paymentId'] ??
                      params['payerID'] ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: amount,
                  coins: coins,
                  currency: currency,
                  paymentParams: params,
                  coupon_banner_id: coupon_banner_id,
                );
              },
              onError: (error) {
                debugPrint("PayPal Payment Error: $error");
                _handlePaymentError(context, error.toString());
              },
              onCancel: () {
                debugPrint("PayPal Payment Cancelled");
                _handlePaymentCancelled(context);
              },
            ),
      ),
    );
  }

  /// Handle successful payment
  Future<void> _handlePaymentSuccess({
    required BuildContext context,
    required String transactionId,
    required double amount,
    required int coins,
    required String currency,
    required Map paymentParams,
    required String paymentMethod,
    required String? coupon_banner_id,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      // Call the coin recharge API
      final response = await _rechargeCoins(
        transactionId: transactionId,
        amount: amount.toString(),
        currency: currency,
        paymentMethod: paymentMethod,
        status: 'success',
        meta: paymentParams,
        coins: coins.toString(),
        coupon_banner_id: coupon_banner_id ?? '',
      );

      _isProcessing = false;
      _lastTransactionId = transactionId;
      notifyListeners();

      if (response['success'] == true) {
        // Immediately update coins in UI for instant feedback
        _updateCoinsImmediately(context, coins);

        // Automatically refresh user data to update coins
        await _refreshUserData(context);

        // Show success dialog
        // Get.back(); // Close PayPal screen
        _showSuccessDialog(context, coins, amount);
      } else {
        // Show error dialog
        Get.back();
        _showErrorDialog(
          context,
          response['message'] ?? 'Payment verification failed',
        );
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      Get.back();
      _showErrorDialog(context, 'Failed to process payment: $e');
    }
  }

  /// Handle payment error
  void _handlePaymentError(BuildContext context, String error) {
    _isProcessing = false;
    notifyListeners();

    // Get.back(); // Close PayPal screen
    print(error);
    //show a error dialog like

    Get.dialog(
      MessageAlertDialog(title: 'Payment Failed', message: error),
      barrierDismissible: false,
    );
  }

  /// Handle payment cancellation
  void _handlePaymentCancelled(BuildContext context) {
    _isProcessing = false;
    notifyListeners();

    // dialog
    Get.dialog(
      MessageAlertDialog(
        title: 'Payment Cancelled',
        message: 'You have cancelled the payment.',
      ),
      barrierDismissible: false,
    );
  }

  /// Refresh user data to update coins after successful payment
  Future<void> _refreshUserData(BuildContext context) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.fetchUserData();
      print('User data refreshed successfully after payment');
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  /// Update coins immediately in UI (optimistic update)
  void _updateCoinsImmediately(BuildContext context, int coinsToAdd) {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      userViewModel.addCoins(coinsToAdd);
      print('Coins updated immediately in UI: +$coinsToAdd');
    } catch (e) {
      print('Error updating coins immediately: $e');
    }
  }

  /// Call API to recharge coins after successful payment
  Future<Map<String, dynamic>> _rechargeCoins({
    required String transactionId,
    required String amount,
    required String currency,
    required String paymentMethod,
    required String status,
    required Map meta,
    required String coins,
    required String coupon_banner_id,
  }) async {
    try {
      final url = '${ApiEndPoints.BASE_URL}coin-recharge';
      final token = await _apiClient.getToken();

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['transaction_id'] = transactionId;
      request.fields['amount'] = amount;
      request.fields['currency'] = currency;
      request.fields['payment_method'] = paymentMethod;
      request.fields['status'] = status;
      request.fields['meta'] = jsonEncode(meta);
      request.fields['coin'] = coins;
      request.fields['coupon_banner_id'] = coupon_banner_id;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      debugPrint('Coin Recharge API Response: $responseData');

      return responseData;
    } catch (e) {
      debugPrint('Error in coin recharge API: $e');
      return {'success': false, 'message': 'Failed to connect to server: $e'};
    }
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, int coins, double totalAmount) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFFE6F7E6), // Light green background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Color(0xFF4CAF50), // Green checkmark
                  size: 30,
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                'Payment completed'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                'Coin charging has been completed.'.tr,
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // Transaction Details Container
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Recharge coin row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'recharge coin'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '${coins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${"coins".tr}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Payment amount row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'payment amount'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${"won".tr}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Check Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'check'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Payment Failed'.tr),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
            },
            child: Text('OK'.tr),
          ),
        ],
      ),
    );
  }

  /// Clear transaction data
  void clearTransaction() {
    _lastTransactionId = null;
    notifyListeners();
  }

  /// Initialize Stripe payment
  Future<void> initiateStripePayment({
    required BuildContext context,
    required double amount,
    required int coins,
    required String currency,
    required String coupon_banner_id,
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      // Convert amount to smallest currency unit for Stripe
      // KRW is a zero-decimal currency (no cents), so we use the amount as-is
      // USD/EUR: multiply by 100 (e.g., $55.00 = 5500 cents)
      // KRW/JPY: use as-is (e.g., ₩55,000 = 55000)
      int amountInSmallestUnit;
      if (paypal_cfg.PaymentConfig.stripeCurrency.toLowerCase() == 'krw' ||
          paypal_cfg.PaymentConfig.stripeCurrency.toLowerCase() == 'jpy') {
        amountInSmallestUnit = amount.toInt(); // Zero-decimal currencies
      } else {
        amountInSmallestUnit = (amount * 100).toInt(); // Decimal currencies
      }

      // Create payment intent
      final paymentIntentData = await _createStripePaymentIntent(
        amount: amountInSmallestUnit,
        currency: paypal_cfg.PaymentConfig.stripeCurrency,
      );

      if (paymentIntentData == null ||
          paymentIntentData['client_secret'] == null) {
        throw Exception('Failed to create payment intent');
      }

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: AppName,
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: Color(0xFF0066CC)),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      _isProcessing = false;
      notifyListeners();

      await _handlePaymentSuccess(
        context: context,
        paymentMethod: 'stripe',
        transactionId:
            paymentIntentData['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        coins: coins,
        currency: currency,
        paymentParams: paymentIntentData,
        coupon_banner_id: coupon_banner_id,
      );
    } on StripeException catch (e) {
      _isProcessing = false;
      notifyListeners();

      if (e.error.code == FailureCode.Canceled) {
        _handlePaymentCancelled(context);
      } else {
        _handlePaymentError(context, e.error.message ?? 'Payment failed');
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      _handlePaymentError(context, 'Payment failed: $e');
    }
  }

  /// Create Stripe Payment Intent
  Future<Map<String, dynamic>?> _createStripePaymentIntent({
    required int amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${paypal_cfg.PaymentConfig.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  /// Fetch coin history
  Future<Map<String, dynamic>> fetchCoinHistory() async {
    try {
      final url =
          '${ApiEndPoints.BASE_URL}coin-history?lang=${LocalizationService.getApiLanguageCode()}';
      final token = await _apiClient.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Coin History API Response: $responseData');
        return responseData;
      } else {
        debugPrint('Failed to fetch coin history: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to fetch coin history',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error fetching coin history: $e');
      return {
        'success': false,
        'message': 'Failed to connect to server: $e',
        'data': null,
      };
    }
  }

  /// Fetch coin packages and store in provider
  Future<Map<String, dynamic>> fetchCoinPackages({
    bool forceRefresh = false,
  }) async {
    // Return cached data if already loaded and not forcing refresh
    if (_packagesLoaded && !forceRefresh) {
      return {
        'success': true,
        'message': 'Packages loaded from cache',
        'data': {
          'coin_packages': _coinPackages,
          'basic_package': _basicPackage,
          'custom_package': _customPackage,
        },
      };
    }

    try {
      _isLoadingPackages = true;
      notifyListeners();

      final url = '${ApiEndPoints.BASE_URL}coin-packages';
      final token = await _apiClient.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Coin Packages API Response: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          _coinPackages = responseData['data']['coin_packages'];
          _basicPackage = responseData['data']['basic_package'];
          _customPackage = responseData['data']['custom_package'];
          _packagesLoaded = true;
        }

        _isLoadingPackages = false;
        notifyListeners();
        return responseData;
      } else {
        debugPrint('Failed to fetch coin packages: ${response.body}');
        _isLoadingPackages = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Failed to fetch coin packages',
          'data': null,
        };
      }
    } catch (e) {
      debugPrint('Error fetching coin packages: $e');
      _isLoadingPackages = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Failed to connect to server: $e',
        'data': null,
      };
    }
  }

  /// Clear coin packages cache
  void clearCoinPackagesCache() {
    _coinPackages = null;
    _basicPackage = null;
    _customPackage = null;
    _packagesLoaded = false;
    notifyListeners();
  }

  /// Initialize Kakao Pay payment
  /// Note: Requires iamport_flutter package to be properly installed
  /// Initialize Kakao Pay payment using PortOne V2 API
  void initiateKakaoPayPayment({
    required BuildContext context,
    required double amount,
    required int coins,
    required String currency,
    required String coupon_banner_id,
  }) {
    final String paymentId = 'payment-${DateTime.now().millisecondsSinceEpoch}';

    // Create payment request using PortOne V2 API
    final paymentRequest = PaymentRequest(
      storeId: payment_env.GlobalPaymentConfig.kakaoStoreId,
      paymentId: paymentId,
      orderName: '$coins Coins - ${payment_env.GlobalPaymentConfig.APP_NAME}',
      totalAmount: amount.toInt(),
      currency: PaymentCurrency.KRW,
      channelKey: payment_env.GlobalPaymentConfig.kakaoChannelKey,
      payMethod: PaymentPayMethod.easyPay, // For Kakao Pay
      appScheme: payment_env.GlobalPaymentConfig.APP_SCHEME,
      // Optional: Specify Kakao Pay specifically
      // pg: PGCompany.kakaoPay, // This will be handled by channelKey
      // Customer information (optional in V2)
      // customerId: userViewModel.userModel?.data.id.toString() ?? 'guest',
      // customerName: userViewModel.userModel?.data.name ?? 'User',
      // customerPhoneNumber: userViewModel.userModel?.data.phone ?? '010-0000-0000',
      // customerEmail: userViewModel.userModel?.data.email ?? 'user@example.com',
    );

    debugPrint("=" * 50);
    debugPrint("Initiating Kakao Pay Payment (V2)");
    debugPrint("Payment ID: $paymentId");
    debugPrint("Amount: ${amount.toInt()} KRW");
    debugPrint("Coins: $coins");
    debugPrint("Store ID: ${payment_env.GlobalPaymentConfig.kakaoStoreId}");
    debugPrint(
      "Channel Key: ${payment_env.GlobalPaymentConfig.kakaoChannelKey}",
    );
    debugPrint("=" * 50);

    // Navigate to Kakao Pay payment screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (BuildContext context) => Scaffold(
              appBar: AppBar(
                title: Text('Kakao Pay'.tr),
                backgroundColor: primaryColor,
                elevation: 0,
              ),
              body: PortonePayment(
                data: paymentRequest,
                initialChild: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
                callback: (PaymentResponse response) async {
                  debugPrint("=" * 50);
                  debugPrint("Kakao Pay Payment Success (V2)!");
                  debugPrint("Payment ID: ${response.paymentId}");
                  debugPrint("Full Response: ${response.toJson()}");
                  debugPrint("=" * 50);

                  try {
                    // Close payment screen
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    // Handle successful payment
                    // In V2, paymentId is the transaction identifier
                    await _handlePaymentSuccess(
                      context: context,
                      paymentMethod: 'kakaopay',
                      transactionId: response.paymentId,
                      amount: amount,
                      coins: coins,
                      currency: currency,
                      paymentParams: response.toJson(),
                      coupon_banner_id: coupon_banner_id,
                    );
                  } catch (e, stackTrace) {
                    debugPrint("Error processing Kakao Pay success: $e");
                    debugPrint("Stack trace: $stackTrace");
                    _handlePaymentError(
                      context,
                      'Payment processing error: $e',
                    );
                  }
                },
                onError: (Object? error) {
                  debugPrint("=" * 50);
                  debugPrint("Kakao Pay Payment Error (V2)");
                  debugPrint("Error: $error");
                  debugPrint("=" * 50);

                  // Close payment screen
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }

                  // Handle payment error
                  final errorMsg =
                      error?.toString() ?? 'Payment failed or was cancelled'.tr;
                  _handlePaymentError(context, errorMsg);
                },
              ),
            ),
      ),
    );
  }
}
