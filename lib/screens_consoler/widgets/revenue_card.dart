import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dashboard_card.dart';
import 'time_period_selector.dart';
import '../models/dashboard_data.dart';

class RevenueCard extends StatelessWidget {
  final String revenue;
  final String changePercentage;
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;
  final VoidCallback? onTap;

  const RevenueCard({
    Key? key,
    required this.revenue,
    required this.changePercentage,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on whether changePercentage is negative
    final bool isNegative = changePercentage.trim().startsWith('-');

    return DashboardCard(
      title: "Today's Revenue".tr,
      value: revenue,
      subtitle: "Today's Revenue".tr,
      additionalInfo: changePercentage,
      iconBackgroundColor: Color(0xFFFEF9C2),
      icon: Icons.attach_money,
      additionalInfoColor: isNegative ? Colors.red : Color(0xFF16A24A),
      onTap: onTap,
      customHeader: Container(
        //width: 129.5.w,
        height: 32.h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            // Container(
            //   width: 32.w,
            //   height: 32.h,
            //   decoration: BoxDecoration(
            //     color: Color(0xFFFEF9C2),
            //     borderRadius: BorderRadius.circular(16.r),
            //   ),
            //   child: Icon(
            //     Icons.attach_money,
            //     size: 16.sp,
            //     color: Color(0xFFF59E0B),
            //   ),
            // ),

            // Time period selector
            TimePeriodSelector(
              selectedPeriod: selectedPeriod,
              onPeriodChanged: onPeriodChanged,
            ),
          ],
        ),
      ),
    );
  }
}
