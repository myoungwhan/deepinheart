import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubCategoryChip extends StatelessWidget {
  String text;
  Color color;
  bool isHaveCircle;
  var img;
  double? fontSize;
  double? iconSize;
  double? height;
  SubCategoryChip({
    Key? key,
    required this.text,
    required this.color,
    this.img,
    this.isHaveCircle = false,
    this.fontSize,
    this.iconSize,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: isMainDark ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar/Icon
              if (img != null && img != "" && img != "null")
                Container(
                  margin: EdgeInsets.only(right: 6.w),
                  child: CachedNetworkImage(
                    imageUrl: img,
                    width: iconSize ?? 15.w,
                    height: iconSize ?? 15.w,
                    fit: BoxFit.cover,
                  ),
                )
              else if (isHaveCircle)
                Container(
                  margin: EdgeInsets.only(right: 6.w),
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMainDark ? Colors.white : color,
                  ),
                ),

              // Text
              CustomText(
                text: text,
                color: isMainDark ? Colors.white : color,
                fontSize: fontSize ?? FontConstants.font_13,
                weight: FontWeightConstants.regular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubCategoryChipCategory extends StatelessWidget {
  final String text;
  final Color color;

  final String? img;
  final bool isHaveCircle;
  double? fontSize;
  double? iconSize;
  double? height;
  bool? isBackgroundDark;
  Color? borderColor;
  Color? textColor;

  SubCategoryChipCategory({
    Key? key,
    required this.text,
    required this.color,
    this.img,
    this.isHaveCircle = false,
    this.fontSize,
    this.iconSize,
    this.height,
    this.isBackgroundDark,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pastel background (faded color)
    final bg =
        isBackgroundDark != null
            ? color
            : isMainDark
            ? Color(0xff2C2C2E)
            : color.withOpacity(0.12);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 5.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Icon / avatar
            if (img != null && img!.isNotEmpty && img != 'null')
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: img!,
                  width: iconSize ?? 22.w,
                  height: iconSize ?? 22.w,
                  fit: BoxFit.cover,
                ),
              )
            else if (isHaveCircle)
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),

            if ((img != null && img!.isNotEmpty && img != 'null') ||
                isHaveCircle)
              SizedBox(width: 2.w),
            // Text area — allow wrapping up to 2 lines and shrink when necessary
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use a simple Text with maxLines=2 and overflow ellipsis
                  // For consistent look we use your CustomText if preferred.
                  return CustomText(
                    text: text,
                    fontSize: fontSize ?? 10.5.sp,
                    maxlines: 2,
                    color:
                        isBackgroundDark != null
                            ? Colors.white
                            : textColor ?? color,
                    weight: FontWeightConstants.medium,
                    align: TextAlign.center,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class toxinCategoryChip extends StatelessWidget {
  final String text;
  final Color color;

  final String? img;
  final bool isHaveCircle;
  double? fontSize;
  double? iconSize;
  double? height;
  bool? isBackgroundDark;
  Color? borderColor;
  Color? textColor;

  toxinCategoryChip({
    Key? key,
    required this.text,
    required this.color,
    this.img,
    this.isHaveCircle = false,
    this.fontSize,
    this.iconSize,
    this.height,
    this.isBackgroundDark,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pastel background (faded color)
    final bg =
        isBackgroundDark != null
            ? color
            : isMainDark
            ? Color(0xff2C2C2E)
            : color.withOpacity(0.12);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 5.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28.r),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icon / avatar
            if (img != null && img!.isNotEmpty && img != 'null')
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: img!,
                  width: iconSize ?? 25.w,
                  height: iconSize ?? 25.w,
                  fit: BoxFit.cover,
                ),
              ),
            // Text area — allow wrapping up to 2 lines and shrink when necessary
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use a simple Text with maxLines=2 and overflow ellipsis
                  // For consistent look we use your CustomText if preferred.
                  return CustomText(
                    text: text,
                    fontSize: fontSize ?? 10.5.sp,
                    maxlines: 2,
                    color:
                        isBackgroundDark != null
                            ? Colors.white
                            : textColor ?? color,
                    weight: FontWeightConstants.medium,
                    align: TextAlign.center,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
