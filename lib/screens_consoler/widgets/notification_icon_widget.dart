import 'package:deepinheart/Controller/Viewmodel/notification_provider.dart';
import 'package:deepinheart/screens_consoler/widgets/notification_dropdown.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        // Fetch notifications on first build
        if (notificationProvider.notifications.isEmpty &&
            !notificationProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notificationProvider.fetchNotifications(context);
          });
        }

        final unreadCount = notificationProvider.unreadCount;

        return GestureDetector(
          onTap: () => _showNotificationDropdown(context),
          child: Stack(
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(color: Colors.transparent),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 30.sp,
                  color: Color(0xFF4A5462),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Center(
                      child: CustomText(
                        text: unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: FontConstants.font_8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationDropdown(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0),
      builder: (context) => NotificationDropdown(),
    );
  }
}
