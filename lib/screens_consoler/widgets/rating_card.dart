import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:get/get.dart';
import 'dashboard_card.dart';

class RatingCard extends StatelessWidget {
  final String rating;
  final String totalReviews;
  final VoidCallback? onTap;

  const RatingCard({
    Key? key,
    required this.rating,
    required this.totalReviews,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: "Average Rating".tr,
      value: rating,
      subtitle: "Average Rating".tr,
      iconBackgroundColor: Color(0xFFDBFBE7),
      icon: Icons.star,
      rating: double.tryParse(rating) ?? 0.0,
      onTap: onTap,
      customHeader: Container(
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
                color: Color(0xFFDBFBE7),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(Icons.star, size: 16.sp, color: Color(0xFF16A24A)),
            ),

            // Reviews count
            UIHelper.horizontalSpaceMd,
            CustomText(
              text: '$totalReviews ${"Reviews".tr}',
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.regular,
              color: Color(0xFF6A7280),
            ),
          ],
        ),
      ),
    );
  }
}
