import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/mypage/my_page_screen.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class CouponCard extends StatelessWidget {
  final String typeLabel; // e.g. "Coin discount" or "Event coupon"
  final String title; // e.g. "50 Coin Discount"
  final String subtitle; // e.g. "Can be used for all service payments"
  final String expirationText; // e.g. "Up to 2025.07.06"
  final String icon; // e.g. Icon or Image
  final bool isExpired;
  Color color;
  final VoidCallback? onUse; // callback for “Use” button

  CouponCard({
    Key? key,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.expirationText,
    required this.icon,
    this.isExpired = false,
    required this.color,
    this.onUse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // card background / disabled color
    final bgColor = isExpired ? Colors.grey.shade200 : Colors.white;
    final textColor = isExpired ? Colors.grey : Colors.black87;
    final borderColor = isExpired ? Colors.grey.shade300 : Colors.blue.shade700;
    color = isExpired ? Colors.grey : color;
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.symmetric(vertical: 0, horizontal: 0),

          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: type label & icon
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SubCategoryChip(text: typeLabel, color: color),
                          UIHelper.verticalSpaceMd,
                          CustomText(
                            text: title,
                            fontSize: FontConstants.font_20,
                            weight: FontWeightConstants.bold,
                            color: color,
                          ),
                          UIHelper.verticalSpaceSm,

                          CustomText(
                            text: subtitle,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.regular,
                          ),
                        ],
                      ),
                    ),
                    UIHelper.horizontalSpaceSm,
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withAlpha(40),
                      ),
                      padding: EdgeInsets.all(12),
                      child: SvgPicture.asset(icon, color: color),
                    ),
                  ],
                ),
                UIHelper.verticalSpaceMd,

                DottedLine(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.center,
                  lineLength: double.infinity,
                  lineThickness: 1.0,
                  dashLength: 4.0,
                ),
                UIHelper.verticalSpaceMd,

                // Expiry & button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'expiration period'.tr,
                          fontSize: FontConstants.font_12,
                        ),
                        SizedBox(height: 5),
                        CustomText(
                          text: expirationText,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          color: textColor,
                        ),
                      ],
                    ),

                    // “Use” button disabled when expired
                    MaterialButton(
                      onPressed: isExpired ? null : onUse,
                      color: color,
                      child: CustomText(
                        text: isExpired ? 'Expired'.tr : 'Use'.tr,
                        color: whiteColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // EXPIRED stamp
        if (isExpired)
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: -0.5, // tilt the stamp
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: CustomText(
                    text: 'EXPIRED'.tr,
                    fontSize: 20,
                    weight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
