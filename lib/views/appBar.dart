import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/text_styles.dart';

AppBar appBarrWitoutAction(
    {actionWidget,
    title,
    actionIcon,
    context,
    backgroundColor,
    centerTitle,
    leadinIconColor,
    titleColor,
    isBlockBack}) {
  return AppBar(
    titleSpacing: 0.0,
    backgroundColor: backgroundColor ?? Colors.transparent,
    leading: InkWell(
        onTap: () {
          print(Navigator.of(context).canPop());
          Get.back();
        },
        child: Icon(
          // vmm.isEnglish ?
          Icons.arrow_back,
          //: Icons.arrow_back,
          color: leadinIconColor ?? blackbutton,
          size: 25,
        )),
    elevation: 0,
    centerTitle: centerTitle ?? true,
    title: Text(
      title ?? "title",
      // style: textStylePopinsBold(color: blackbutton),
    ),
  );
}

AppBar appBarrWitAction(
    {title,
    context,
    actionwidget,
    backgroundColor,
    elevation,
    leadinIconColor,
    centerTitle,
    titleColor}) {
  return AppBar(
    backgroundColor: backgroundColor ?? Colors.transparent,
    leading: InkWell(
        onTap: () {
          Get.back();
        },
        child: Icon(
          //  vm.isEnglish ?
          Icons.arrow_back,
          //  : Icons.arrow_back,
          color: leadinIconColor ?? blackbutton,
          size: 25,
        )),
    elevation: elevation ?? 0,
    centerTitle: centerTitle ?? true,
    title: Text(
      title ?? "title",
      // style: textStylePopinsBold(color: blackbutton),
    ),
    actions: [
      Padding(
        padding: EdgeInsets.only(right: 12),
        child: actionwidget,
      )
    ],
  );
}

Widget verticaldivider({verticalPadding, horizontalPadding}) {
  return Padding(
    padding: EdgeInsets.symmetric(
        vertical: verticalPadding ?? 12, horizontal: horizontalPadding ?? 0),
    child: Container(
      height: Get.height,
      width: 1,
      color: Colors.grey,
    ),
  );
}

Widget horizontaldivider({verticalPadding, horizontalPadding}) {
  return Padding(
    padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 0, vertical: verticalPadding ?? 5),
    child: Container(
      height: 1,
      width: Get.width,
      color: Colors.grey,
    ),
  );
}
