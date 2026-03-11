import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class MessageAlertDialog extends StatelessWidget {
  String title;
  String message;
  MessageAlertDialog({Key? key, required this.title, required this.message})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(15),
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Center(child: SvgPicture.asset(AppIcons.alertsvg)),

      content: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: title,
              fontSize: FontConstants.font_17,
              weight: FontWeightConstants.bold,
            ),
            UIHelper.verticalSpaceSm,
            CustomText(
              text: message,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              align: TextAlign.start,
            ),
            UIHelper.verticalSpaceSm,
          ],
        ),
      ),
      actions: [
        CustomButton(() {
          Get.back();
        }, text: "Confirm".tr),
      ],
    );
  }
}
