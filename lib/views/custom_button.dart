import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:deepinheart/views/text_styles.dart';

import 'colors.dart';
import 'ui_helpers.dart';

class CustomButton extends StatelessWidget {
  double? width;
  var color;
  var child;
  var text;
  var textcolor;
  var weight;
  var fsize;
  var onTap;
  var buttonBorderColor;
  var icon;
  var circleRadius;
  bool? isDisable;
  bool isCancelButton;
  CustomButton(
    this.onTap, {
    this.child,
    this.color,
    this.fsize,
    this.text,
    this.textcolor,
    this.buttonBorderColor,
    this.weight,
    this.isDisable,
    this.icon,
    this.circleRadius,
    this.width,
    this.isCancelButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onTap,
      elevation: 1.0,
      disabledColor: inactiveColor,
      padding: EdgeInsets.symmetric(horizontal: 00.w),
      height: 45.h,
      // highlightColor:
      //     color != null ? color.withOpacity(0.2) : orangeColor.withOpacity(0.2),
      hoverColor: primaryColor,
      focusColor: Colors.lightGreen,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          color:
              buttonBorderColor ??
              (isCancelButton ? primaryColor : Colors.transparent),
        ),
        borderRadius: BorderRadius.circular(circleRadius ?? 10),
      ),
      minWidth: width != null ? width : MediaQuery.of(context).size.width,
      //= height: 45,
      color: color ?? (isCancelButton ? Colors.white : primaryColor),
      child:
          child ??
          (text == "loading"
              ? CircularProgressIndicator(
                color: (isCancelButton ? primaryColor : whiteColor),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: textStyleRobotoRegular(
                        weight: FontWeightConstants.medium,
                        color:
                            textcolor ??
                            ((isCancelButton ? primaryColor : backGroundColor)),
                        fontSize: fsize ?? FontConstants.font_16,
                      ),
                    ),
                  ),
                  icon != null
                      ? Padding(
                        padding: EdgeInsets.only(left: 5),
                        child: Icon(Icons.arrow_forward_ios, color: textcolor),
                      )
                      : Container(),
                ],
              )),
    );
  }
}
