import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:get/get.dart';

enum ConsultationTab { reservation, completed, schedule }

class ConsultationTabBar extends StatelessWidget {
  final ConsultationTab selectedTab;
  final Function(ConsultationTab) onTabChanged;

  const ConsultationTabBar({
    Key? key,
    required this.selectedTab,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          _buildTab(ConsultationTab.reservation, 'Reservation'.tr),
          _buildTab(ConsultationTab.completed, 'Completed'.tr),
          _buildTab(ConsultationTab.schedule, 'Schedule'.tr),
        ],
      ),
    );
  }

  Widget _buildTab(ConsultationTab tab, String label) {
    final isSelected = selectedTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(tab),
        child: Container(
          height: 35.h,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected ? primaryColorConsulor : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CustomText(
                text: label,
                align: TextAlign.center,
                maxlines: 1,
                fontSize:
                    Get.locale!.languageCode == 'ko'
                        ? FontConstants.font_13
                        : FontConstants.font_12,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
