import 'package:deepinheart/Controller/Model/notification_model.dart';
import 'package:deepinheart/Controller/Viewmodel/notification_provider.dart';
import 'package:deepinheart/screens_consoler/widgets/all_notifications_screen.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class NotificationDropdown extends StatelessWidget {
  const NotificationDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;
        final unreadCount = notificationProvider.unreadCount;

        return Dialog(
          backgroundColor: Colors.transparent,
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.only(
            top: 60.h,
            right: 16.w,
            left: Get.width - 320.w,
          ),
          child: Container(
            width: 300.w,
            constraints: BoxConstraints(maxHeight: Get.height * 0.7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text:
                              unreadCount > 0
                                  ? '${"You have".tr} $unreadCount ${unreadCount > 1 ? "new notifications".tr : "new notification".tr}'
                                  : 'No new notifications'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.semiBold,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close,
                          size: 20.w,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Notifications List
                Flexible(
                  child:
                      notificationProvider.isLoading
                          ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            ),
                          )
                          : notifications.isEmpty
                          ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 48.w,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 16.h),
                                  CustomText(
                                    text: 'No notifications'.tr,
                                    fontSize: FontConstants.font_14,
                                    weight: FontWeightConstants.medium,
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemCount:
                                notifications.length > 5
                                    ? 5
                                    : notifications.length,
                            separatorBuilder:
                                (context, index) =>
                                    Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              return _buildNotificationItem(
                                context,
                                notification,
                              );
                            },
                          ),
                ),

                // Footer - See all notifications
                if (notifications.length > 5)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.to(() => AllNotificationsScreen());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            text: 'See all notifications'.tr,
                            fontSize: FontConstants.font_13,
                            weight: FontWeightConstants.medium,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12.w,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem notification,
  ) {
    final notificationData = notification.notificationData;
    final isRead = notification.isRead;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          final provider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await provider.markAsRead(context, notification.id);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: isRead ? Colors.white : primaryColorConsulor.withAlpha(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: notificationData.notificationIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notificationData.notificationIcon,
                size: 20.w,
                color: notificationData.notificationIconColor,
              ),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text:
                        notificationData.displayMessage.length > 60
                            ? '${notificationData.displayMessage.substring(0, 60)}...'
                            : notificationData.displayMessage,
                    fontSize: FontConstants.font_13,
                    weight:
                        isRead
                            ? FontWeightConstants.regular
                            : FontWeightConstants.semiBold,
                    color: Colors.black87,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: notification.formattedDate,
                    fontSize: FontConstants.font_11,
                    weight: FontWeightConstants.regular,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
