import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:get/get.dart';
import '../models/dashboard_data.dart';

class TimePeriodSelector extends StatelessWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;

  const TimePeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPeriodButton(TimePeriod.day, 'Day'.tr),
        //  SizedBox(width: 2.w),
        _buildPeriodButton(TimePeriod.week, 'Week'.tr),
        //SizedBox(width: 2.w),
        _buildPeriodButton(TimePeriod.month, 'Month'.tr),
      ],
    );
  }

  Widget _buildPeriodButton(TimePeriod period, String label) {
    final isSelected = selectedPeriod == period;

    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3B81F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(9999.r),
        ),
        child: CustomText(
          text: label,
          fontSize: FontConstants.font_12,
          weight: FontWeightConstants.regular,
          color: isSelected ? Colors.white : Color(0xFF6A7280),
          align: TextAlign.center,
        ),
      ),
    );
  }
}
