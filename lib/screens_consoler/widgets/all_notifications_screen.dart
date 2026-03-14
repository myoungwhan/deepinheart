import 'package:deepinheart/Controller/Model/notification_model.dart';
import 'package:deepinheart/Controller/Viewmodel/notification_provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AllNotificationsScreen extends StatefulWidget {
  const AllNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AllNotificationsScreen> createState() =>
      _AllNotificationsScreenState();
}

class _AllNotificationsScreenState extends State<AllNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: CustomText(
          text: 'Notifications'.tr,
          fontSize: FontConstants.font_18,
          weight: FontWeightConstants.bold,
          color: Colors.black87,
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              if (unreadCount > 0) {
                return IconButton(
                  icon: Icon(Icons.done_all, color: Colors.black87),
                  tooltip: 'Mark all as read'.tr,
                  onPressed: () async {
                    await notificationProvider.markAllAsRead(context);
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final notifications = notificationProvider.notifications;

          if (notificationProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (notificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: notificationProvider.error!,
                    fontSize: FontConstants.font_14,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      notificationProvider.fetchNotifications(context);
                    },
                    child: CustomText(text: 'Retry'.tr),
                  ),
                ],
              ),
            );
          }

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64.w,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'No notifications'.tr,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await notificationProvider.refreshNotifications(context);
            },
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
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
        color: isRead ? Colors.white : Colors.blue[50],
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
                    text: notificationData.displayMessage.length > 100
                        ? '${notificationData.displayMessage.substring(0, 100)}...'
                        : notificationData.displayMessage,
                    fontSize: FontConstants.font_13,
                    weight: isRead
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

