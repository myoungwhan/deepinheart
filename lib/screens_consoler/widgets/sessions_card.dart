import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dashboard_card.dart';

class SessionsCard extends StatelessWidget {
  final String sessionCount;
  final String totalTime;
  final bool isOnline;
  final VoidCallback? onTap;

  const SessionsCard({
    Key? key,
    required this.sessionCount,
    required this.totalTime,
    this.isOnline = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: "Today's Sessions".tr,
      value: sessionCount,
      subtitle: "Today's Sessions".tr,
      additionalInfo: totalTime,
      iconBackgroundColor: Color(0xFFDAE9FE),
      icon: Icons.people_outline,
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
              height: 32.w,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFDAE9FE),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: SvgPicture.asset(
                AppIcons.chatsvg,
                width: 16.0,
                height: 16.0,
              ),
            ),

            // Online status badge
            Spacer(),
            SubCategoryChip(text: 'Online'.tr, color: Color(0xFF16A34A)),

            // Container(
            //   padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            //   decoration: BoxDecoration(
            //     color: Color(0xFFF0FDF4),
            //     borderRadius: BorderRadius.circular(9999.r),
            //   ),
            //   child: CustomText(
            //     text: 'Online',
            //     fontSize: FontConstants.font_12,
            //     weight: FontWeightConstants.regular,
            //     color: Color(0xFF16A24A),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
