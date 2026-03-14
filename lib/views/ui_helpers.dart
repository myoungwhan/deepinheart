import 'package:deepinheart/views/font_constants.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:intl/intl.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';

import 'colors.dart';
import 'custom_button.dart';
import 'text_styles.dart';

/// Contains useful consts to reduce boilerplate and duplicate code
class UIHelper {
  // Vertical spacing constants. Adjust to your liking.
  // Vertical spacing constants using flutter_screenutil
  static Widget get verticalSpaceSm => SizedBox(height: 10.h);
  static Widget get verticalSpaceSm5 => SizedBox(height: 5.h);
  static Widget get verticalSpaceMd => SizedBox(height: 20.h);
  static Widget get verticalSpace30 => SizedBox(height: 30.h);
  static Widget get verticalSpaceL => SizedBox(height: 42.h);
  static Widget get verticalSpaceXL => SizedBox(height: 92.h);

  // Horizontal spacing constants using flutter_screenutil
  static Widget get horizontalSpaceSm => SizedBox(width: 10.w);
  static Widget get horizontalSpaceSm5 => SizedBox(width: 5.w);
  static Widget get horizontalSpaceMd => SizedBox(width: 20.w);
  static Widget get horizontalSpaceL => SizedBox(width: 60.w);
  static FlashController? ccontroller;

  static void showMySnak({var title, var message, bool? isError}) {
    if (isError!) {
      Get.snackbar(
        title,
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        title,
        message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  static String getCurrencyFormate(text) {
    try {
      // Handle both string and numeric inputs
      int value;
      if (text is String) {
        // Remove commas and spaces, but handle decimal point properly
        String cleaned = text.replaceAll(RegExp(r'[, ]'), '');
        if (cleaned.isEmpty) return '0';

        // If string contains decimal point, parse as double then convert to int
        if (cleaned.contains('.')) {
          value = double.parse(cleaned).toInt();
        } else {
          value = int.parse(cleaned);
        }
      } else if (text is int) {
        value = text;
      } else if (text is double) {
        value = text.toInt();
      } else {
        return '0';
      }

      // Use Korean locale for proper currency formatting
      final oCcy = NumberFormat("#,##0", "ko_KR");
      return oCcy.format(value);
    } catch (_) {
      // Return '0' if parsing fails (always integer format, no decimals)
      return '0';
    }
  }

  // Format Korean phone number for display
  static String formatKoreanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different Korean phone number formats
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 7) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else if (digitsOnly.length <= 11) {
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    } else {
      // Limit to 11 digits (Korean mobile numbers)
      digitsOnly = digitsOnly.substring(0, 11);
      return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    }
  }

  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Hide keyboard globally
  static void hideKeyboard(BuildContext? context) {
    if (context != null) {
      FocusScope.of(context).unfocus();
    } else {
      // Fallback: dismiss keyboard using system channels
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }

  static showDialogOk(
    context, {
    required title,
    required message,
    onOk,
    onConfirm,
    onOkAction,
    confirmText,
    cancelText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            //  width: Get.width * 0.3,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment(-0.71, 0.94),
                end: Alignment(0.8, -0.82),
                colors: [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.03, 1.0],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textStyleRobotoRegular(
                    fontSize: FontConstants.font_16,
                    color: Colors.black,
                    weight: FontWeightConstants.medium,
                  ),
                ),
                UIHelper.verticalSpaceSm,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textStyleRobotoRegular(
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                ),
                UIHelper.verticalSpaceMd,
                onOk != null
                    ? Container(
                      width: 150,
                      child: CustomButton(
                        onOkAction ??
                            () {
                              Get.back();
                            },
                        text: "Ok",
                      ),
                    )
                    : Container(),
                onConfirm != null
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          //  width: 80,
                          child: CustomButton(
                            () {
                              Get.back();
                            },
                            text: cancelText ?? "Cancel".tr,
                            textcolor: Colors.white,
                            buttonBorderColor: Colors.transparent,
                            fsize: FontConstants.font_12,
                            weight: FontWeightConstants.medium,

                            color: grey600,
                          ),
                        ),
                        UIHelper.horizontalSpaceSm,
                        Expanded(
                          child: Container(
                            //width: 120,
                            child: CustomButton(
                              onConfirm,
                              text: confirmText ?? "Confirm".tr,
                              fsize: FontConstants.font_12,
                              weight: FontWeightConstants.medium,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  static const mapKey = "AIzaSyDVX6dMqw5wbVC1t47hNg3xOEuseEwmA_c";

  //todo modify the theme
  /* static ThemeData darkTheme = ThemeData(
    primaryColor: Colors.black,
    backgroundColor: Colors.grey[700],
    brightness: Brightness.dark,
  );
  static ThemeData lightTheme = ThemeData(
    primaryColor: Colors.red,
    accentColor: Colors.red[400],
    backgroundColor: Colors.grey[200],
    brightness: Brightness.light,
  );*/
  static Widget WidgetCustomTextMed({required text, size, color}) {
    return Text(
      text,
      //maxLines: 2,
      style: textStyleLatoSemiBold(
        fontSize: size ?? 16.sp,
        color: color ?? Colors.black,
      ),
    );
  }

  static void showBottomFlash(
    context, {
    required title,
    required message,
    required isError,
    bool persistent = true,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    showFlash(
      context: context,
      persistent: persistent,
      duration: Duration(seconds: 4),
      builder: (_, controller) {
        ccontroller = controller;
        return Flash(
          controller: controller,

          // margin: EdgeInsets.all(15),
          // insetAnimationDuration: Duration(seconds: 3),

          // behavior: FlashBehavior.floating,
          position: FlashPosition.top,

          // borderRadius: BorderRadius.circular(8.0),
          // //  borderColor: Color(0xffD9FF9A),
          // backgroundColor: whiteColor,
          // boxShadows: kElevationToShadow[8],
          // backgroundGradient: RadialGradient(
          //   colors: [Color(0xffD9FF9A), Color(0xffD9FF9A), Color(0xffD9FF9A)],
          //   center: Alignment.center,
          //   tileMode: TileMode.decal,
          //   radius: 3,
          // ),
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.black),
            child: FlashBar(
              title: Text(
                message,
                style: textStyleLatoRegular(
                  color: blackbutton,
                  fontSize: 14.sp,
                ),
              ),
              content: Container(height: 0),

              indicatorColor: isError ? Colors.red : secondaryColor,
              //    icon: Icon(Icons.info_outline),
              primaryAction: TextButton(
                onPressed: () => controller.dismiss(),
                child: Icon(Icons.close, color: blackbutton),
              ),
              controller: controller,
            ),
          ),
        );
      },
    ).then((_) {});
  }

  static String getShortName({required string, required limitTo}) {
    var buffer = StringBuffer();
    var split = string.split(' ');
    print(split.length);
    for (var i = 0; i < (split.length); i++) {
      try {
        buffer.write(split[i][0].toString().toUpperCase());
      } on Exception catch (e) {
        // TODO
      }
    }

    return buffer.toString();
  }

  static Color getColor(color) {
    return Color(int.parse(color.replaceAll('#', '0xff')));
  }

  static Widget ricHText({text, text1, fsize, weight, color}) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: [
          WidgetSpan(
            child: CustomText(
              text: text,
              fontSize: fsize ?? 20.sp,
              isSemibold: true,
              color: color,
              weight: weight ?? fontWeightMedium,
            ),
          ),
          WidgetSpan(child: UIHelper.horizontalSpaceSm),
          WidgetSpan(
            child:
                text1 != null
                    ? CustomText(
                      text: text1,
                      fontSize: fsize ?? 20.sp,
                      color: color,
                      weight: weight ?? fontWeightRegular,
                    )
                    : Container(),
          ),
          // WidgetSpan(
          //   child: Image.asset(image,
          //       width: 22.0, height: 22, color: Colors.black54),
          // ),
        ],
      ),
    );
  }

  static launchInBrowser1(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  static bool isEmailValid(email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }
}
