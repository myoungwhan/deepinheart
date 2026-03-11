import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/screens/mypage/coupons/coupon_card.dart';
import 'package:deepinheart/screens/mypage/coupons/coupon_usage.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CouponsList extends StatefulWidget {
  final bool isExpired;
  CouponsList({Key? key, required this.isExpired}) : super(key: key);

  @override
  State<CouponsList> createState() => _CouponsListState();
}

class _CouponsListState extends State<CouponsList> {
  @override
  void initState() {
    super.initState();
    // Fetch registered coupons when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = context.read<UserViewModel>();
      userViewModel.fetchRegisteredCoupons();
    });
  }

  // Helper method to get color based on coupon scope
  Color getColorForCouponScope(String couponScope) {
    switch (couponScope) {
      case 'coin_discount':
        return primaryColor;
      default:
        return Color(0xffA855F7);
    }
  }

  // Helper method to get type label based on coupon scope
  String getTypeLabelForCouponScope(String couponScope) {
    switch (couponScope) {
      case 'coin_discount':
        return 'Coin discount'.tr;
      default:
        return 'Coupon'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(15),
      child: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          // Get registered coupons based on expired status
          final coupons =
              widget.isExpired
                  ? userViewModel.usedAndExpiredCoupons
                  : userViewModel.registeredCoupons;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Display coupon cards from API
                if (coupons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      widget.isExpired
                          ? 'No expired coupons'.tr
                          : 'No available coupons'.tr,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                else
                  ...coupons.map((registeredCoupon) {
                    final coupon = registeredCoupon.couponBanner;
                    final isExpiredOrUsed =
                        registeredCoupon.isExpired || registeredCoupon.used;
                    return Column(
                      children: [
                        CouponCard(
                          typeLabel: getTypeLabelForCouponScope(
                            coupon.couponScope,
                          ),
                          title: coupon.couponName,
                          subtitle: coupon.description,
                          expirationText:
                              registeredCoupon.formattedExpirationDate,
                          color: getColorForCouponScope(coupon.couponScope),
                          icon: AppIcons.coinhistorySvg,
                          isExpired: isExpiredOrUsed,
                          onUse: () {
                            // your use logic
                            print('Using coupon: ${coupon.couponCode}');
                            Get.to(
                              () => CoinChargingScreen(couponBanner: coupon),
                            );
                          },
                        ),
                        UIHelper.verticalSpaceSm,
                      ],
                    );
                  }).toList(),
                UIHelper.verticalSpaceL,
                CouponUsage(),
                UIHelper.verticalSpaceMd,
              ],
            ),
          );
        },
      ),
    );
  }
}
