import 'package:deepinheart/Controller/Model/coupon_banner_model.dart';
import 'package:deepinheart/Controller/Model/settings_model.dart';
import 'package:deepinheart/Controller/Viewmodel/payment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/mypage/coins/views/charging_benifits_guide.dart';
import 'package:deepinheart/screens/mypage/my_page_screen.dart';
import 'package:deepinheart/screens/mypage/views/price_with_currency.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CoinChargingScreen extends StatefulWidget {
  final CouponBanner? couponBanner;
  CoinChargingScreen({Key? key, this.couponBanner}) : super(key: key);

  @override
  _CoinChargingScreenState createState() => _CoinChargingScreenState();
}

class _CoinChargingScreenState extends State<CoinChargingScreen> {
  int _selectedCoins = 100; // Default selected coins
  double _totalAmount = 10000.0; // Default price for 100 coins

  // Payment method selection
  String _selectedPaymentMethod = 'stripe'; // 'paypal' or 'stripe'

  // Agreement checkboxes
  bool _agreeToAll = false;
  bool _termsOfService = false;
  bool _privacyPolicy = false;
  bool _marketingInfo = false;

  // Remove local API data variables - now using PaymentProvider

  // Helper function to get localized custom amount message
  String _getCustomAmountMessage(int amount) {
    // Use string interpolation with the base translatable message
    final baseMessage =
        "For amounts over %amount% coins, you can enter your desired amount."
            .tr;
    return baseMessage.replaceAll('%amount%', amount.toString());
  }

  @override
  void initState() {
    super.initState();
    // Refresh user data when screen opens to ensure latest coin balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();

      _loadCoinPackages();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshUserData() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.fetchUserData();
      print('User data refreshed in coin charging screen');
    } catch (e) {
      print('Error refreshing user data in coin charging screen: $e');
    }
  }

  Future<void> _loadCoinPackages() async {
    try {
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      await paymentProvider.fetchCoinPackages();

      // Set default values from basic package
      if (paymentProvider.basicPackage != null) {
        setState(() {
          _selectedCoins =
              paymentProvider.basicPackage!['b_number_of_coins'] ?? 5000;
          _totalAmount =
              (paymentProvider.basicPackage!['b_discounted_price'] ?? 50000.0)
                  .toDouble();
        });
      }
    } catch (e) {
      print('Error loading coin packages: $e');
    }
  }

  Future<void> _refreshCoinPackages() async {
    try {
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      await paymentProvider.fetchCoinPackages(forceRefresh: true);
      await context.read<SettingProvider>().fetchSettings(context);
    } catch (e) {
      print('Error refreshing coin packages: $e');
    }
  }

  // Function to calculate total amount based on selected coins using API data
  double _calculateTotalAmount(int coins) {
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    // Check basic package first
    if (paymentProvider.basicPackage != null &&
        paymentProvider.basicPackage!['b_number_of_coins'] == coins) {
      return (paymentProvider.basicPackage!['b_discounted_price'] ??
              paymentProvider.basicPackage!['b_coin_price'])
          .toDouble();
    }

    // Check if we have API data
    if (paymentProvider.coinPackages != null) {
      // Look for exact match in coin packages
      for (var package in paymentProvider.coinPackages!) {
        if (package['number_of_coins'] == coins) {
          return (package['discounted_price'] ?? package['coin_price'])
              .toDouble();
        }
      }
    }

    // Check if custom package applies
    if (paymentProvider.customPackage != null &&
        coins >= (paymentProvider.customPackage!['cus_amount_over'] ?? 0)) {
      // Use custom package pricing
      double customPricePerCoin =
          (paymentProvider.customPackage!['cus_discounted'] /
                  paymentProvider.customPackage!['cus_number_of_coins'])
              .toDouble();
      return coins * customPricePerCoin;
    }

    // If no exact match found, use basic package pricing
    if (paymentProvider.basicPackage != null) {
      double basicPricePerCoin =
          (paymentProvider.basicPackage!['b_discounted_price'] /
                  paymentProvider.basicPackage!['b_number_of_coins'])
              .toDouble();
      return coins * basicPricePerCoin;
    }

    // Fallback to default calculation (1 coin = ₩10)
    return coins * 10.0;
  }

  // Function to handle custom coin entry (admin minimum enforced; validation border on error)
  void _handleCustomAmount(value) {
    int enteredCoins = int.tryParse(value.toString().replaceAll(',', '')) ?? 0;
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    final int minAllowed =
        paymentProvider.customPackage != null
            ? (int.tryParse(
                  paymentProvider.customPackage!['cus_amount_over'].toString(),
                ) ??
                0)
            : 0;

    final bool hasMinimum =
        paymentProvider.customPackage != null && minAllowed > 0;
    final bool isBelowMin =
        hasMinimum && enteredCoins > 0 && enteredCoins < minAllowed;

    setState(() {
      if (isBelowMin) {
        _selectedCoins = 0;
        _totalAmount = 0.0;
        return;
      }
      _selectedCoins = enteredCoins;
      _totalAmount =
          enteredCoins > 0 ? _calculateTotalAmount(enteredCoins) : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        title: "Coin Charging".tr,
        isLogo: false,
        centerTitle: false,
        action: [
          IconButton(onPressed: () {}, icon: Icon(Icons.info_outline_rounded)),
        ],
      ),
      body: Container(
        width: Get.width,
        child: RefreshIndicator(
          onRefresh: _refreshCoinPackages,
          child: SingleChildScrollView(
            child: Consumer3<UserViewModel, PaymentProvider, SettingProvider>(
              builder: (context, pr, paymentProvider, settings, child) {
                return Column(
                  children: [
                    UIHelper.verticalSpaceSm,
                    coinBanner(
                      pr.userModel!.data.coins!.toDouble(),
                      txt: "Current Balance".tr,
                      isShowChargeButton: false,
                    ),
                    UIHelper.verticalSpaceMd,
                    CustomTitleWithButton(title: 'Select Amount'.tr),
                    UIHelper.verticalSpaceSm,
                    paymentProvider.isLoadingPackages
                        ? Center(child: CircularProgressIndicator())
                        : _buildCoinPackagesList(paymentProvider),
                    UIHelper.verticalSpaceL,
                    CustomText(
                      text:
                          paymentProvider.customPackage != null
                              ? _getCustomAmountMessage(
                                paymentProvider
                                    .customPackage!['cus_amount_over'],
                              )
                              : "For amounts over 30,000 coins, you can enter your desired amount."
                                  .tr,
                      fontSize: FontConstants.font_13,
                    ),
                    UIHelper.verticalSpaceMd,
                    customCoins(),
                    UIHelper.verticalSpaceMd,
                    Visibility(
                      visible: false,
                      child: CharginBenifitGuide(
                        heading: 'Charging Benefits Guide'.tr,
                        subtitle: '',
                        cardColor: Color(0xFFFEFBE7),
                        details: [
                          'Get Additional 10% Coins on Yourst Charge'.tr,
                          '5% discount when purchasing 10,000 coins or more'.tr,
                          '10% discount when purchasing 30,000 coins or more'
                              .tr,
                        ],
                      ),
                    ),
                    UIHelper.verticalSpaceMd,
                    CharginBenifitGuide(
                      cardColor: Color(0xFFBFDBFE),
                      heading: 'Charging and Discount Pack Usage Guide'.tr,
                      subtitle: '',
                      details: [
                        'Partialy used charging and discount packs are non-refundable.'
                            .tr,
                        'Unused Charging and Discount Packs Can be Fully Refunded Within 7 days of purchase.'
                            .tr,
                        'Unused Charging and Discount Packs After 7 Days of Purchase Can be Refunded with a 10% cancellation fee.'
                            .tr,
                      ],
                    ),
                    UIHelper.verticalSpaceL,
                    _buildPaymentMethodSection(),
                    UIHelper.verticalSpaceL,
                    _buildAgreementSection(),
                    UIHelper.verticalSpaceL,
                    _buildPaymentSummary(settings.settings!),
                    UIHelper.verticalSpaceL,
                    _buildPayNowButton(),
                    UIHelper.verticalSpaceL,
                  ],
                );
              },
            ),
          ),
        ),
      ).paddingAll(15.r),
    );
  }

  Widget customCoins() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        final minAmount =
            paymentProvider.customPackage != null
                ? (int.tryParse(
                      paymentProvider.customPackage!['cus_amount_over']
                          .toString(),
                    ) ??
                    0)
                : 0;
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Customtextfield(
                          required: false,
                          hint: "Enter Coins".tr,
                          keyboard: TextInputType.number,
                          egText: "",
                          onChanged: (value) {
                            _handleCustomAmount(value);
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                        
                            final entered = int.tryParse(
                                  value.toString().replaceAll(',', '')) ??
                              0;
                            if (minAmount > 0 && entered > 0 && entered < minAmount) {
                              return "Minimum amount is %amount% coins."
                                  .tr
                                  .replaceAll('%amount%', minAmount.toString());
                            }
                            return null;
                          },
                          prefix: SvgPicture.asset(
                            AppIcons.coinsvg,
                            colorFilter: ColorFilter.mode(
                              orangeColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          suffix: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: CustomText(
                              text: "Coins".tr,
                              color: primaryColor,
                              weight: FontWeightConstants.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  UIHelper.horizontalSpaceMd,
                  PriceWithCurrency(amount: _totalAmount.toStringAsFixed(2)),
                  UIHelper.horizontalSpaceSm,
                ],
              ),
              UIHelper.verticalSpaceSm,
              if (paymentProvider.customPackage != null &&
                  _selectedCoins >=
                      (paymentProvider.customPackage!['cus_amount_over'] ?? 0))
                CustomText(
                  text:
                      "${paymentProvider.customPackage!['cus_discount_rate']}% Discount Applied"
                          .tr,
                  color: primaryColor,
                ),
            ],
          ),
        );
      },
    );
  }

  // Build coin packages list from API data
  Widget _buildCoinPackagesList(PaymentProvider paymentProvider) {
    List<Widget> packageWidgets = [];

    // Add basic package at index 0
    if (paymentProvider.basicPackage != null) {
      int coins = paymentProvider.basicPackage!['b_number_of_coins'];
      double originalPrice =
          (paymentProvider.basicPackage!['b_coin_price'] ?? 0).toDouble();
      double discountedPrice =
          (paymentProvider.basicPackage!['b_discounted_price'] ?? originalPrice)
              .toDouble();
      double discountRate =
          (paymentProvider.basicPackage!['b_discount_rate'] ?? 0).toDouble();

      packageWidgets.add(
        Column(
          children: [
            _buildCoinTile(
              coins: coins,
              subtitle: 'Basic Package'.tr,
              originalPrice: originalPrice,
              discountedPrice: discountedPrice,
              discountRate: discountRate,
            ),
            UIHelper.verticalSpaceSm,
          ],
        ),
      );
    }

    // Add other coin packages
    if (paymentProvider.coinPackages != null &&
        paymentProvider.coinPackages!.isNotEmpty) {
      for (int i = 0; i < paymentProvider.coinPackages!.length; i++) {
        var package = paymentProvider.coinPackages![i];
        int coins = package['number_of_coins'];
        double originalPrice = (package['coin_price'] ?? 0).toDouble();
        double discountedPrice =
            (package['discounted_price'] ?? originalPrice).toDouble();
        double discountRate = (package['discount_rate'] ?? 0).toDouble();

        packageWidgets.add(
          Column(
            children: [
              _buildCoinTile(
                coins: coins,
                subtitle: '${"Package".tr} ${i + 1}',
                originalPrice: originalPrice,
                discountedPrice: discountedPrice,
                discountRate: discountRate,
              ),
              UIHelper.verticalSpaceSm,
            ],
          ),
        );
      }
    }

    if (packageWidgets.isEmpty) {
      return CustomText(text: 'No packages available'.tr);
    }

    return Column(children: packageWidgets);
  }

  Widget _buildCoinTile({
    required int coins,
    required String subtitle,
    required double originalPrice,
    required double discountedPrice,
    required double discountRate,
  }) {
    bool hasDiscount = discountRate > 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoins = coins;
          _totalAmount = discountedPrice;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _selectedCoins == coins
                  ? isMainDark
                      ? Color(0xff2C2C2E)
                      : Color(0xffEBF5FF)
                  : isMainDark
                  ? Color(0xff2C2C2E)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _selectedCoins == coins
                    ? primaryColor
                    : isMainDark
                    ? Color(0xff2C2C2E)
                    : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Coins label and subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: '${UIHelper.getCurrencyFormate(coins)} ${"Coins".tr}',
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                ),
                UIHelper.verticalSpaceSm5,
                CustomText(
                  text: subtitle,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Color(0xff4B5563),
                ),
                if (hasDiscount)
                  CustomText(
                    text:
                        '${discountRate.toStringAsFixed(0)}% ${"Discount".tr}',
                    fontSize: FontConstants.font_12,
                    color: primaryColor,
                  ),
              ],
            ),
            // Price with discount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  PriceWithCurrency(
                    amount: originalPrice.toStringAsFixed(2),
                    isLineThroug: true,
                    fSize: FontConstants.font_12,
                  ),
                UIHelper.verticalSpaceSm5,
                PriceWithCurrency(
                  amount: discountedPrice.toStringAsFixed(2),
                  fSize: FontConstants.font_14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Payment Method Section
  Widget _buildPaymentMethodSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Payment Method".tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.semiBold,
          ),
          UIHelper.verticalSpaceSm,

          // Stripe Payment Method
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'stripe';
              });
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _selectedPaymentMethod == 'stripe'
                        ? isMainDark
                            ? Color(0xff2C2C2E)
                            : Color(0xffEBF5FF)
                        : isMainDark
                        ? Color(0xff2C2C2E)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _selectedPaymentMethod == 'stripe'
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                  width: _selectedPaymentMethod == 'stripe' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color:
                        _selectedPaymentMethod == 'stripe'
                            ? primaryColor
                            : Colors.grey.shade600,
                    size: 28,
                  ),
                  UIHelper.horizontalSpaceSm,
                  Expanded(
                    child: CustomText(
                      text: "Credit/Debit Card (Stripe)".tr,
                      fontSize: FontConstants.font_15,
                      weight: FontWeightConstants.medium,
                    ),
                  ),
                  if (_selectedPaymentMethod == 'stripe')
                    Icon(Icons.check_circle, color: primaryColor, size: 24),
                ],
              ),
            ),
          ),
          UIHelper.verticalSpaceSm,

          // PayPal Payment Method
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'paypal';
              });
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _selectedPaymentMethod == 'paypal'
                        ? isMainDark
                            ? Color(0xff2C2C2E)
                            : Color(0xffEBF5FF)
                        : isMainDark
                        ? Color(0xff2C2C2E)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _selectedPaymentMethod == 'paypal'
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                  width: _selectedPaymentMethod == 'paypal' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'images/paypal_logo.png',
                    height: 28,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.account_balance_wallet,
                        color:
                            _selectedPaymentMethod == 'paypal'
                                ? primaryColor
                                : Colors.grey.shade600,
                        size: 28,
                      );
                    },
                  ),
                  UIHelper.horizontalSpaceSm,
                  Expanded(
                    child: CustomText(
                      text: "PayPal".tr,
                      fontSize: FontConstants.font_15,
                      weight: FontWeightConstants.medium,
                    ),
                  ),
                  if (_selectedPaymentMethod == 'paypal')
                    Icon(Icons.check_circle, color: primaryColor, size: 24),
                ],
              ),
            ),
          ),

          UIHelper.verticalSpaceSm,

          // Kakao Pay Payment Method
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'kakaopay';
              });
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _selectedPaymentMethod == 'kakaopay'
                        ? isMainDark
                            ? Color(0xff2C2C2E)
                            : Color(0xffEBF5FF)
                        : isMainDark
                        ? Color(0xff2C2C2E)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _selectedPaymentMethod == 'kakaopay'
                          ? primaryColor // Kakao yellow
                          : Colors.grey.shade300,
                  width: _selectedPaymentMethod == 'kakaopay' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Kakao Pay icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(0xffFEE500), // Kakao yellow
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'K',
                        fontSize: 18,
                        weight: FontWeight.bold,
                        color: Color(0xff3C1E1E),
                      ),
                    ),
                  ),
                  UIHelper.horizontalSpaceSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: "Kakao Pay (카카오페이)".tr,
                          fontSize: FontConstants.font_15,
                          weight: FontWeightConstants.medium,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedPaymentMethod == 'kakaopay')
                    Icon(Icons.check_circle, color: primaryColor, size: 24),
                ],
              ),
            ),
          ),

          UIHelper.verticalSpaceSm5,
        ],
      ),
    );
  }

  // Agreement Section
  Widget _buildAgreementSection() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agree to All
          _buildCheckboxTile(
            value: _agreeToAll,
            title: "Agree to All".tr,
            isMainCheckbox: true,
            onChanged: (value) {
              setState(() {
                _agreeToAll = value ?? false;
                _termsOfService = value ?? false;
                _privacyPolicy = value ?? false;
                _marketingInfo = value ?? false;
              });
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Colors.grey.shade300),
          ),
          // Terms of Service
          _buildCheckboxTile(
            value: _termsOfService,
            title: "Terms of Service Agreement".tr,
            subtitle: "(Required)".tr,
            hasViewButton: true,
            onChanged: (value) {
              setState(() {
                _termsOfService = value ?? false;
                _updateAgreeToAll();
              });
            },
            onViewPressed: () {
              _showTermsDialog(
                "Terms of Service".tr,
                "Terms of Service content here...".tr,
              );
            },
          ),
          SizedBox(height: 10),
          // Privacy Policy
          _buildCheckboxTile(
            value: _privacyPolicy,
            title: "Privacy Policy Agreement".tr,
            subtitle: "(Required)".tr,
            hasViewButton: true,
            onChanged: (value) {
              setState(() {
                _privacyPolicy = value ?? false;
                _updateAgreeToAll();
              });
            },
            onViewPressed: () {
              _showTermsDialog(
                "Privacy Policy".tr,
                "Privacy Policy content here...".tr,
              );
            },
          ),
          SizedBox(height: 10),
          // Marketing Information
          _buildCheckboxTile(
            value: _marketingInfo,
            title: "Marketing Information Agreement".tr,
            subtitle: "(Optional)".tr,
            hasViewButton: true,
            onChanged: (value) {
              setState(() {
                _marketingInfo = value ?? false;
                _updateAgreeToAll();
              });
            },
            onViewPressed: () {
              _showTermsDialog(
                "Marketing Information".tr,
                "Marketing Information content here...".tr,
              );
            },
          ),
        ],
      ),
    );
  }

  // Checkbox Tile Widget
  Widget _buildCheckboxTile({
    required bool value,
    required String title,
    String? subtitle,
    bool isMainCheckbox = false,
    bool hasViewButton = false,
    required Function(bool?) onChanged,
    VoidCallback? onViewPressed,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      fontSize: isMainCheckbox ? 15 : 14,
                      fontWeight:
                          isMainCheckbox ? FontWeight.w600 : FontWeight.w400,
                      color: isMainDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    TextSpan(
                      text: ' $subtitle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color:
                            subtitle.contains("Required")
                                ? Colors.red
                                : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (hasViewButton)
            InkWell(
              onTap: onViewPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "View".tr,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isMainDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: isMainDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update Agree to All checkbox
  void _updateAgreeToAll() {
    setState(() {
      _agreeToAll = _termsOfService && _privacyPolicy && _marketingInfo;
    });
  }

  // Show Terms Dialog
  void _showTermsDialog(String title, String content) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Close".tr)),
        ],
      ),
    );
  }

  // Payment Summary Section
  Widget _buildPaymentSummary(SettingsData settings) {
    double vat =
        _totalAmount * (settings.vat / 100); // Calculate VAT as percentage
    print('vat: $vat');

    // Calculate discount if couponBanner is not null
    double discountAmount = 0.0;
    if (widget.couponBanner != null) {
      try {
        discountAmount = double.parse(widget.couponBanner!.discountAmount);
      } catch (e) {
        discountAmount = 0.0;
      }
    }

    double totalPayment = _totalAmount + vat - discountAmount;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Coin Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: "Coin Amount".tr,
                fontSize: FontConstants.font_14,
                color: isMainDark ? Colors.white : Colors.grey.shade700,
              ),
              // CustomText(
              //   text: "₩${_totalAmount.toStringAsFixed(0)}",
              //   fontSize: FontConstants.font_14,
              //   weight: FontWeightConstants.medium,
              // ),
              PriceWithCurrency(amount: _totalAmount.toStringAsFixed(0)),
            ],
          ),
          UIHelper.verticalSpaceSm,
          // VAT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: "VAT (${settings.vat.toStringAsFixed(0)} %)".tr,
                fontSize: FontConstants.font_14,
                color: isMainDark ? Colors.white : Colors.grey.shade700,
              ),
              CustomText(
                text: "₩${vat.toStringAsFixed(0)}",
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
              ),
            ],
          ),
          // Discount row (only show if couponBanner is not null)
          if (widget.couponBanner != null && discountAmount > 0) ...[
            UIHelper.verticalSpaceSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: "Discount".tr,
                  fontSize: FontConstants.font_14,
                  color: Colors.green,
                ),
                CustomText(
                  text: "-₩${discountAmount.toStringAsFixed(0)}",
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: Colors.green,
                ),
              ],
            ),
          ],
          UIHelper.verticalSpaceSm,
          Divider(color: Colors.grey.shade400),
          UIHelper.verticalSpaceSm,
          // Total Payment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                text: "Total Payment".tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: isMainDark ? Colors.white : Colors.grey.shade700,
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      text: "Charging Coins".tr,
                      fontSize: FontConstants.font_12,
                      color: primaryColor,
                    ),
                    UIHelper.verticalSpaceSm5,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: "₩${UIHelper.getCurrencyFormate(totalPayment)}",
                          fontSize: FontConstants.font_18,
                          weight: FontWeightConstants.bold,
                        ),
                        UIHelper.horizontalSpaceSm5,
                        CustomText(
                          text:
                              "${UIHelper.getCurrencyFormate(_selectedCoins)} ${"Coins".tr}",
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.bold,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pay Now Button
  Widget _buildPayNowButton() {
    bool canPay = _termsOfService && _privacyPolicy && _selectedCoins > 0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: CustomText(
              text: "Cancel".tr,
              fontSize: FontConstants.font_15,
              weight: FontWeightConstants.medium,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        UIHelper.horizontalSpaceMd,
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canPay ? _handlePayment : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: primaryColor,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: CustomText(
              text: "Pay Now".tr,
              fontSize: FontConstants.font_15,
              weight: FontWeightConstants.semiBold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Handle payment button press
  void _handlePayment() {
    if (_selectedCoins <= 0) {
      Get.snackbar(
        'Invalid Amount'.tr,
        'Please select a coin package'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Check required agreements
    if (!_termsOfService || !_privacyPolicy) {
      Get.snackbar(
        'Agreement Required'.tr,
        'Please agree to the required terms and privacy policy.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Get settings for VAT calculation
    final settings =
        Provider.of<SettingProvider>(context, listen: false).settings;

    // Calculate total payment with VAT
    double vat =
        _totalAmount *
        ((settings?.vat ?? 0) / 100); // Calculate VAT as percentage

    // Calculate discount if couponBanner is not null
    double discountAmount = 0.0;
    if (widget.couponBanner != null) {
      try {
        discountAmount = double.parse(widget.couponBanner!.discountAmount);
      } catch (e) {
        discountAmount = 0.0;
      }
    }

    double totalPayment = (_totalAmount + vat) - discountAmount;

    // Get payment provider
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    // Initiate payment based on selected method
    if (_selectedPaymentMethod == 'stripe') {
      print('initiateStripePayment' + totalPayment.toString());
      paymentProvider.initiateStripePayment(
        context: context,
        amount: totalPayment, // Total payment including VAT
        coins: _selectedCoins,
        currency: 'KRW',
        coupon_banner_id:
            widget.couponBanner != null
                ? widget.couponBanner!.id.toString()
                : '',
      );
    } else if (_selectedPaymentMethod == 'paypal') {
      paymentProvider.initiatePayPalPayment(
        context: context,
        amount: totalPayment, // Total payment including VAT
        coins: _selectedCoins,
        currency: 'KRW',
        coupon_banner_id:
            widget.couponBanner != null
                ? widget.couponBanner!.id.toString()
                : '',
      );
    } else if (_selectedPaymentMethod == 'kakaopay') {
      print('initiateKakaoPayPayment' + totalPayment.toString());
      paymentProvider.initiateKakaoPayPayment(
        context: context,
        amount: totalPayment, // Total payment including VAT
        coins: _selectedCoins,
        currency: 'KRW',
        coupon_banner_id:
            widget.couponBanner != null
                ? widget.couponBanner!.id.toString()
                : '',
      );
    }
  }
}
