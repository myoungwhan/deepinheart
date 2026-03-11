import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CouponUsage extends StatefulWidget {
  @override
  _CouponUsageState createState() => _CouponUsageState();
}

class _CouponUsageState extends State<CouponUsage> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: "How to use coupons".tr,
                        weight: FontWeightConstants.medium,
                        fontSize: FontConstants.font_16,
                      ),
                    ),
                    UIHelper.horizontalSpaceSm,
                    Icon(
                      isExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                  ],
                ),
                isExpanded
                    ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: "1. Before starting consultation service, go to My Page > Coupons.".tr,
                            fontSize: FontConstants.font_14,
                          ),
                          SizedBox(height: 8),
                          CustomText(
                            text: "2. Select the desired coupon from the available coupon list.".tr,
                            fontSize: FontConstants.font_14,
                          ),
                          SizedBox(height: 8),
                          CustomText(
                            text: "3. Discount is applied automatically during consultation or after consultation completion.".tr,
                            fontSize: FontConstants.font_14,
                          ),
                          SizedBox(height: 16),
                          CustomText(
                            text: "Notes:".tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.semiBold,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 4),
                          CustomText(
                            text: "Coupons cannot be used in combination.".tr,
                            fontSize: FontConstants.font_14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 4),
                          CustomText(
                            text: "Some coupons can only be used for specific consultation services.".tr,
                            fontSize: FontConstants.font_14,
                              color: Colors.grey[600],
                            ),
                          SizedBox(height: 4),
                          CustomText(
                            text: "Coupon discount rates are fixed and will not change.".tr,
                            fontSize: FontConstants.font_14,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    )
                    : Container(height: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
