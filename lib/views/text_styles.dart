import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'package:get/get.dart';

const fontWeightExtraLight = FontWeight.w200;
const fontWeightLight = FontWeight.w300;
const fontWeightRegular = FontWeight.w400;
const fontWeightMedium = FontWeight.w500;
const fontWeightW600 = FontWeight.w600;
const fontWeightSemiBold = FontWeight.w700;
const fontWeightBold = FontWeight.w700;
const fontWeightExtraBold = FontWeight.w800;
const double fontMedium1 = 12.0;
TextStyle textStyleRobotoExtraLight({Color? color, double? fontSize}) =>
    TextStyle(
      color: color ?? Colors.black,
      fontSize: fontSize ?? fontMedium1,
      fontWeight: fontWeightExtraLight,
      letterSpacing: 0.8,
    );

TextStyle textStyleRobotoLight({Color? color, double? fontSize}) => TextStyle(
  color: color ?? Colors.black,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightLight,
  letterSpacing: 0.8,
);

TextStyle textStyleRobotoRegular({
  Color? color,
  double? fontSize,
  weight,
  height,
  decoration,
}) => GoogleFonts.roboto(
  color: color ?? Colors.black,
  fontSize: fontSize ?? FontConstants.font_14,
  fontWeight: weight ?? fontWeightRegular,
  height: height,
  decoration: decoration,
  //letterSpacing: 0.8,
);

TextStyle textStyleRobotoMedium({Color? color, double? fontSize}) => TextStyle(
  color: color ?? Colors.black,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightMedium,
  letterSpacing: 0.8,
);

TextStyle textStyleRobotoW600({Color? color, double? fontSize}) => TextStyle(
  color: color ?? Colors.black,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightW600,
  letterSpacing: 0.8,
);

TextStyle textStyleRobotoSemiBold({Color? color, double? fontSize}) =>
    TextStyle(
      color: color ?? Colors.black,
      fontSize: fontSize ?? fontMedium1,
      fontWeight: fontWeightSemiBold,
      letterSpacing: 0.8,
    );

TextStyle textStyleRobotoBold({Color? color, double? fontSize}) => TextStyle(
  color: color ?? Colors.black,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightBold,
  letterSpacing: 0.8,
);

TextStyle textStyleRobotoSlabRegular({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
}) => GoogleFonts.robotoSlab(
  color: color ?? Colors.black,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeight ?? fontWeightRegular,
  letterSpacing: 0.8,
);

TextStyle textStyleRobotoSlabLight({Color? color, double? fontSize}) =>
    GoogleFonts.robotoSlab(
      color: color ?? backGroundColor,
      fontSize: fontSize ?? fontMedium1,
      fontWeight: fontWeightLight,
      letterSpacing: 0.8,
    );

// Lato

TextStyle textStyleLatoExtraBold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.lato(
  color: color ?? backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightExtraBold,
  letterSpacing: letterSpacing ?? 0,
);

TextStyle textStyleLatoSemiBold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.lato(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? grey600
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightSemiBold,
  letterSpacing: letterSpacing ?? 0,
);

TextStyle textStyleLatoW600({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.lato(
  color: color ?? backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightW600,
  letterSpacing: letterSpacing ?? 0,
);

TextStyle textStyleLatoRegular({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.lato(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightRegular,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStylemontserratRegular({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  double? height,
  var textDecoration,
  FontWeight? weight,
}) => GoogleFonts.montserrat(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: weight ?? fontWeightRegular,
  letterSpacing: letterSpacing ?? 0,
  decoration: textDecoration,
  height: height,
);
TextStyle textStylePopinsMiddle({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.montserrat(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightMedium,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStylePopinsBold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  FontWeight? weight,
}) => GoogleFonts.montserrat(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: weight ?? fontWeightBold,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStylePopinExtrasBold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.montserrat(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightExtraBold,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStyleDinRegular({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  FontWeight? weight,
}) =>
    Get.locale!.countryCode == 'SA'
        ? GoogleFonts.tajawal(
          color:
              color != null
                  ? color
                  : Get.isDarkMode
                  ? whiteColor
                  : backGroundColor,
          fontSize: fontSize ?? fontMedium1,
          fontWeight: weight ?? FontWeight.bold,
          letterSpacing: letterSpacing ?? 0,
        )
        : GoogleFonts.poppins(
          color:
              color != null
                  ? color
                  : Get.isDarkMode
                  ? whiteColor
                  : backGroundColor,
          fontSize: fontSize ?? fontMedium1,
          fontWeight: weight ?? FontWeight.bold,
          letterSpacing: letterSpacing ?? 0,
        );
TextStyle textStyleDinBold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
}) => GoogleFonts.tajawal(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: fontWeightExtraBold,
  letterSpacing: letterSpacing ?? 0,
);

TextStyle textStylesamiboldMontserrat({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  double? height,
  FontWeight? weight,
}) => GoogleFonts.montserrat(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontWeight: weight ?? fontWeightSemiBold,
  letterSpacing: letterSpacing ?? 0,
  height: height,
);

TextStyle textStyleLMS({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  FontWeight? weight,
}) => TextStyle(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontFamily: "LMS",
  fontWeight: weight ?? FontWeight.normal,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStyleLIDO({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  FontWeight? weight,
}) => TextStyle(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : backGroundColor,
  fontSize: fontSize ?? fontMedium1,
  fontFamily: "Lido",
  fontWeight: weight ?? FontWeight.normal,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStyleSegeoui({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  TextDecoration? textDecoration,
  double? height,
  FontWeight? weight,
}) => TextStyle(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : blackbutton,
  fontSize: fontSize ?? fontMedium1,
  fontFamily: "segeoui",
  decoration: textDecoration ?? TextDecoration.none,
  fontWeight: weight ?? FontWeight.normal,
  height: height,
  letterSpacing: letterSpacing ?? 0,
);
TextStyle textStyleSegeouibold({
  Color? color,
  double? fontSize,
  double? letterSpacing,
  TextDecoration? textDecoration,
  FontWeight? weight,
}) => TextStyle(
  color:
      color != null
          ? color
          : Get.isDarkMode
          ? whiteColor
          : blackbutton,
  fontSize: fontSize ?? 14.0,
  fontFamily: "segeouibold",
  decoration: textDecoration ?? TextDecoration.none,
  fontWeight: weight ?? FontWeight.normal,
  letterSpacing: letterSpacing ?? 0,
);
