import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MaintenanceDialog extends StatelessWidget {
  final bool isServiceShutdown;
  final String message;
  final String? startTime;
  final String? endTime;

  const MaintenanceDialog({
    Key? key,
    required this.isServiceShutdown,
    required this.message,
    this.startTime,
    this.endTime,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required bool isServiceShutdown,
    required String message,
    String? startTime,
    String? endTime,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => MaintenanceDialog(
            isServiceShutdown: isServiceShutdown,
            message: message,
            startTime: startTime,
            endTime: endTime,
          ),
    );
  }

  static void checkAndShow(BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );

    // Check service shutdown first (higher priority)
    if (settingProvider.isServiceShutdown) {
      final shutdownMessage = settingProvider.serviceShutdownMessage;
      if (shutdownMessage.isNotEmpty) {
        show(context, isServiceShutdown: true, message: shutdownMessage);
        return;
      }
    }

    // Check maintenance mode
    if (settingProvider.isInMaintenanceMode) {
      final maintenanceMessage = settingProvider.maintenanceMessage;
      final startTime = settingProvider.maintenanceStartTime;
      final endTime = settingProvider.maintenanceEndTime;

      if (maintenanceMessage.isNotEmpty) {
        show(
          context,
          isServiceShutdown: false,
          message: maintenanceMessage,
          startTime: startTime.isNotEmpty ? startTime : null,
          endTime: endTime.isNotEmpty ? endTime : null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 400.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Content
            _buildContent(context),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isServiceShutdown
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isServiceShutdown
                  ? Icons.block_rounded
                  : Icons.build_circle_rounded,
              color: Colors.white,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      isServiceShutdown
                          ? "Service Unavailable".tr
                          : "Maintenance Mode".tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: Colors.white,
                ),
                if (!isServiceShutdown &&
                    startTime != null &&
                    endTime != null) ...[
                  SizedBox(height: 4.h),
                  CustomText(
                    text: "${"Scheduled Time".tr}: $startTime - $endTime",
                    fontSize: FontConstants.font_12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color:
                      (isServiceShutdown ? Colors.red : Colors.orange).shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  isServiceShutdown
                      ? Icons.error_outline_rounded
                      : Icons.info_outline_rounded,
                  color:
                      isServiceShutdown
                          ? Colors.red.shade600
                          : Colors.orange.shade600,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text:
                          isServiceShutdown
                              ? "Service Temporarily Unavailable".tr
                              : "Scheduled Maintenance".tr,
                      fontSize: FontConstants.font_16,
                      weight: FontWeightConstants.semiBold,
                      color: const Color(0xFF111726),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: borderColor),
                      ),
                      child: CustomText(
                        text: message,
                        fontSize: FontConstants.font_14,
                        color: const Color(0xFF374151),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Additional info for maintenance mode
          if (!isServiceShutdown && startTime != null && endTime != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.blue.shade700,
                    size: 20.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomText(
                      text: "${"Maintenance Period".tr}: $startTime - $endTime",
                      fontSize: FontConstants.font_13,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],

          // Contact information
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: primaryColor,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final settingProvider = Provider.of<SettingProvider>(
                        context,
                        listen: false,
                      );
                      final phone = settingProvider.customerServicePhone;
                      final email = settingProvider.customerServiceEmail;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: "Need Help?".tr,
                            fontSize: FontConstants.font_13,
                            weight: FontWeightConstants.semiBold,
                            color: primaryColor,
                          ),
                          if (phone.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            CustomText(
                              text: "${"Phone".tr}: $phone",
                              fontSize: FontConstants.font_12,
                              color: const Color(0xFF374151),
                            ),
                          ],
                          if (email.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            CustomText(
                              text: "${"Email".tr}: $email",
                              fontSize: FontConstants.font_12,
                              color: const Color(0xFF374151),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Close button
          isServiceShutdown
              ? SizedBox()
              : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isServiceShutdown
                            ? Colors.red.shade600
                            : Colors.orange.shade600,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: CustomText(
                    text: "Understood".tr,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.semiBold,
                    color: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
