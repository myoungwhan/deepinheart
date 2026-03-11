import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/services/call_state_manager.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Dialog to rejoin an interrupted call
class RejoinCallDialog extends StatelessWidget {
  final Map<String, dynamic> callState;

  const RejoinCallDialog({Key? key, required this.callState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String callType = callState['callType'] ?? 'video';
    final String counselorName = callState['counselorName'] ?? 'Counselor';
    final int durationSeconds = callState['callDurationSeconds'] ?? 0;
    final Duration callDuration = Duration(seconds: durationSeconds);

    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String hours = twoDigits(duration.inHours);
      String minutes = twoDigits(duration.inMinutes.remainder(60));
      String seconds = twoDigits(duration.inSeconds.remainder(60));

      if (duration.inHours > 0) {
        return "$hours:$minutes:$seconds";
      }
      return "$minutes:$seconds";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                callType == 'video' ? Icons.videocam : Icons.call,
                color: primaryColor,
                size: 30.w,
              ),
            ),
            UIHelper.verticalSpaceMd,

            // Title
            CustomText(
              text: "Rejoin Call?".tr,
              fontSize: FontConstants.font_20,
              weight: FontWeightConstants.bold,
              color: Colors.black87,
            ),
            UIHelper.verticalSpaceSm,

            // Description
            CustomText(
              text: "${'You have an active call with'.tr} $counselorName.",
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Colors.black54,
              align: TextAlign.center,
            ),
            UIHelper.verticalSpaceSm5,

            // Call duration info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, size: 18.w, color: primaryColor),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: "${'Duration:'.tr} ${formatDuration(callDuration)}",
                    fontSize: FontConstants.font_13,
                    weight: FontWeightConstants.medium,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            UIHelper.verticalSpaceL,

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Clear call state and close dialog
                      CallStateManager.clearCallState();
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: CustomText(
                      text: "End Call".tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: Colors.black54,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Rejoin button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _rejoinCall(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: CustomText(
                      text: "Rejoin".tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _rejoinCall(BuildContext context) {
    // Clear the dialog
    Get.back();

    // Extract call parameters
    final String callType = callState['callType'] ?? 'video';
    final String channelName = callState['channelName'] ?? '';
    final String counselorName = callState['counselorName'] ?? '';
    final int userId = callState['userId'] ?? 0;
    final double counselorRate = (callState['counselorRate'] ?? 0.0).toDouble();
    final int? appointmentId = callState['appointmentId'] as int?;
    final int? counselorId = callState['counselorId'] as int?;
    final String? counselorImage = callState['counselorImage'] as String?;
    final bool isCounselor = callState['isCounselor'] ?? false;
    final bool isTroat = callState['isTroat'] ?? false;

    // Navigate to appropriate call screen
    if (callType == 'video') {
      Get.to(
        () => VideoCallScreen(
          counslername: counselorName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointmentId,
          counselorId: counselorId,
          counselorImage: counselorImage,
          isCounsler: isCounselor,
          isTroat: isTroat,
        ),
      );
    } else {
      Get.to(
        () => VoiceCallScreen(
          counslername: counselorName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointmentId,
          counselorId: counselorId,
          counselorImage: counselorImage,
          isCounselor: isCounselor,
          isTroat: isTroat,
        ),
      );
    }

    // Clear the saved call state after rejoining
    CallStateManager.clearCallState();
  }
}
