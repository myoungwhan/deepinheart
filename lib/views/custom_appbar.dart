import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/screens/search/search_screen.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/logo_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

AppBar customAppBar({
  leading,
  title,
  elevation,
  color,
  centerTitle,
  ctx,
  action,
  bool isLogo = true,
}) {
  return AppBar(
    leading:
        leading ??
        (isLogo
            ? Padding(
              padding: EdgeInsets.all(10),
              child: LogoView(imagePath: AppIcons.simplelogo),
            )
            : null),
    //: 40,
    // leading: Padding(
    //   padding: const EdgeInsets.only(left: 15),
    //   child: InkWell(
    //       onTap: () {
    //         Navigator.of(ctx).pop();
    //       },
    //       child: Icon(Icons.arrow_back)),
    // ),
    actions:
        action ??
        [
          GestureDetector(
            onTap: () {
              Get.to(() => const SearchScreen());
            },
            child: SvgPicture.asset(
              AppIcons.searchsvg,
              color: Get.isDarkMode ? Colors.white : Colors.grey,
            ),
          ),

          UIHelper.horizontalSpaceMd,
          GestureDetector(
            onTap: () {
              Get.to(() => CoinChargingScreen());
            },
            child: SvgPicture.asset(
              AppIcons.coinsvg,
              color: secondaryButtonColor,
            ),
          ),
          UIHelper.horizontalSpaceSm,
        ],

    // backgroundColor: color ?? Colors.white,
    elevation: elevation ?? 1,
    centerTitle: centerTitle ?? true,
    surfaceTintColor: color ?? Colors.white,
    title: CustomText(
      text: title ?? "",
      fontSize: FontConstants.font_18,
      weight: FontWeightConstants.bold,
    ),
    // title: Text(
    //   AppName,
    //   style: textStylePopinsMiddle(color: Colors.red, fontSize: 18.0),
    // ),
    // actions: [],
  );
}
