import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String? additionalInfo;
  final Color iconBackgroundColor;
  final IconData icon;
  final Color? additionalInfoColor;
  final Widget? customHeader;
  final VoidCallback? onTap;
  final double? rating;

  DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.additionalInfo,
    required this.iconBackgroundColor,
    required this.icon,
    this.additionalInfoColor,
    this.customHeader,
    this.rating,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        //   width: 163.5.w,
        height: 150.h,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(width: 1, color: Color(0xFFE4E7EB)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status/custom widget
            Container(
              padding: EdgeInsets.only(bottom: 8.h),
              child: customHeader ?? _buildDefaultHeader(),
            ),

            // Content
            Container(
              // width: 129.5.w,
              height: 80.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main value
                  Row(
                    children: [
                      Container(
                        // width: 129.5.w,
                        height: 32.h,
                        child: CustomText(
                          text: value,
                          fontSize: FontConstants.font_22,
                          weight: FontWeightConstants.bold,
                          color: Color(0xFF111726),
                        ),
                      ),
                      UIHelper.horizontalSpaceSm5,
                      rating != null
                          ? Expanded(
                            child: MyRatingView(
                              initialRating: rating,
                              isAllowRating: false,
                              itemSize: 15.w,
                              onRatingUpdate: (dta) {},
                            ),
                          )
                          : Container(),
                    ],
                  ),

                  // Subtitle
                  Container(
                    // color: Colors.red,
                    padding: EdgeInsets.only(top: 4.h),
                    child: CustomText(
                      text: subtitle,
                      maxlines: 2,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.regular,
                      color: Color(0xFF4A5462),
                    ),
                  ),

                  // Additional info (if provided)
                  if (additionalInfo != null)
                    Container(
                      padding: EdgeInsets.only(top: 5.h),
                      child: CustomText(
                        text: additionalInfo!,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                        color: additionalInfoColor ?? Color(0xFF6A7280),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      // width: 129.5.w,
      height: 32.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, size: 16.sp, color: Colors.white),
          ),

          // Title
          Expanded(
            child: CustomText(
              text: title,
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.regular,
              color: Color(0xFF6A7280),
              align: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
