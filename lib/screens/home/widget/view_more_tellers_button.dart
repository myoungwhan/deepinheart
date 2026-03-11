import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ViewMoreTellersButton extends StatelessWidget {
  String text;
  Function onTap;
  ViewMoreTellersButton({Key? key, required this.text, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      child: CustomButton(
        onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: text,
              weight: FontWeightConstants.medium,
              color: whiteColor,
            ),
            UIHelper.horizontalSpaceSm5,
            SvgPicture.asset(AppIcons.arrowdownsvg),
          ],
        ),
      ),
    );
  }
}
