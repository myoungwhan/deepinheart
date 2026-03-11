import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // for .tr() translation

class CustomTitleWithButton extends StatelessWidget {
  final String title; // Title text
  final VoidCallback? onButtonPressed; // Action for View All button

  const CustomTitleWithButton({
    Key? key,
    required this.title,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CustomText(
          text: title, // For localization
          height: 1.5,
          weight:
              FontWeightConstants
                  .medium, // Or FontWeightConstants.medium if you have it defined
          fontSize:
              FontConstants
                  .font_16, // Or use 18.sp if you are using ScreenUtil for scaling
        ),
        const Spacer(),
        onButtonPressed == null
            ? Container()
            : TextButton.icon(
              onPressed: onButtonPressed,
              iconAlignment: IconAlignment.end,
              label: CustomText(
                text: "View All".tr, // For localization
                fontSize: FontConstants.font_12,
                weight: FontWeightConstants.regular,
                color: isMainDark ? Colors.white70 : const Color(0xff6B7280),
              ),
              icon: Icon(
                Icons.arrow_forward_ios,
                color: isMainDark ? Colors.white70 : Color(0xff6B7280),
                size: FontConstants.font_15,
              ),
            ),
      ],
    );
  }
}
