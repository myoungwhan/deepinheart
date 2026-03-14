import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:get/get.dart';
import 'dashboard_card.dart';

class ScheduledSessionsCard extends StatelessWidget {
  final String currentSessions;
  final String totalSessions;
  final String nextSessionTime;
  final VoidCallback? onTap;

  const ScheduledSessionsCard({
    Key? key,
    required this.currentSessions,
    required this.totalSessions,
    required this.nextSessionTime,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: "Scheduled Sessions".tr,
      value: '$currentSessions/$totalSessions',
      subtitle: "Scheduled Sessions".tr,
      additionalInfo: '${"Next".tr}: $nextSessionTime',
      iconBackgroundColor: Color(0xFFF2E7FF),
      icon: Icons.schedule,
      onTap: onTap,
      customHeader: Container(
        //  width: 129.5.w,
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
                color: Color(0xFFF2E7FF),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.calendar_month,
                size: 16.sp,
                color: Color(0xFF8B5CF6),
              ),
            ),
            UIHelper.horizontalSpaceMd,

            // Today/Weekly indicator
            CustomText(
              text: 'Today/Weekly'.tr,
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.regular,
              color: primaryColorConsulor,
            ),
          ],
        ),
      ),
    );
  }
}
