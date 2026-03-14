import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

/// Reusable widget to display coin balance and estimated time remaining
/// Used in both VideoCallScreen and VoiceCallScreen
/// Hidden for counselors as they don't need to see coin balance
class CoinBalanceWidget extends StatelessWidget {
  final double coinsLeft;
  final int estimatedMinutesLeft;
  final int lowCoinsThreshold;
  final bool isCounselor; // Hide widget for counselors

  const CoinBalanceWidget({
    Key? key,
    required this.coinsLeft,
    required this.estimatedMinutesLeft,
    this.lowCoinsThreshold = 100,
    this.isCounselor = false, // Default to false (show for regular users)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hide widget completely for counselors
    if (isCounselor) {
      return SizedBox.shrink();
    }

    // Determine color based on coin level
    Color coinColor = Colors.amber;
    if (coinsLeft <= lowCoinsThreshold) {
      coinColor = Colors.orange;
    }
    if (coinsLeft <= 50) {
      coinColor = Colors.red;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              coinsLeft <= lowCoinsThreshold
                  ? Colors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
          width: coinsLeft <= lowCoinsThreshold ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppIcons.coinsvg,
                color: coinColor,
                width: 25.w,
                height: 25.w,
              ),
              SizedBox(width: 6.w),
              CustomText(
                text: coinsLeft.toInt().toString(),
                fontSize: FontConstants.font_16,
                weight: FontWeightConstants.bold,
                color: Colors.white,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          CustomText(
            text: "coins left".tr,
            fontSize: FontConstants.font_11,
            weight: FontWeightConstants.regular,
            color: Colors.white70,
          ),
          SizedBox(height: 4.h),
          CustomText(
            text: "~$estimatedMinutesLeft ${"min".tr}",
            fontSize: FontConstants.font_12,
            weight: FontWeightConstants.medium,
            color:
                coinsLeft <= lowCoinsThreshold
                    ? Colors.red.shade200
                    : Colors.white60,
          ),
        ],
      ),
    );
  }
}
