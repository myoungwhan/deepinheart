import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:get/get.dart';

class LogoView extends StatelessWidget {
  double? width;
  double? height;
  BoxFit? fit;
  var imagePath;

  LogoView({Key? key, this.width, this.fit, this.height, this.imagePath})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Hero(
      tag: "mylogo",
      child: Image.asset(
        imagePath ??
            (themeController.isDarkMode.value
                ? AppIcons.simplelogo
                : AppIcons.simplelogo),
        width: width ?? 300,
        height: height ?? 300,
        fit: fit ?? BoxFit.fitWidth,
      ),
    );
  }
}
