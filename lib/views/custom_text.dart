import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomText extends StatefulWidget {
  var text;
  var color;
  var fontSize;
  var weight;
  var height;
  var maxlines;
  var align;
  var style;
  var isSemibold;
  var decoration;
  CustomText({
    this.color,
    this.fontSize,
    this.style,
    this.height,
    this.text,
    this.weight,
    this.align,
    this.isSemibold,
    this.maxlines,
    this.decoration,
  });

  @override
  State<CustomText> createState() => _CustomTextState();
}

class _CustomTextState extends State<CustomText> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return Text(
          widget.text,
          maxLines: widget.maxlines,
          textAlign: widget.align,
          style:
              widget.style ??
              textStyleRobotoRegular(
                color:
                    widget.color ??
                    (themeController.isDarkMode.value
                        ? Colors.white
                        : Colors.black),
                fontSize:
                    widget.fontSize != null
                        ? double.tryParse(widget.fontSize.toString())
                        : FontConstants.font_14,

                weight:
                    widget.weight != null
                        ? widget.weight
                        : FontWeightConstants.regular,
                height: widget.height ?? 0.0,
                decoration: widget.decoration,
              ),
        );
      },
    );
  }
}
