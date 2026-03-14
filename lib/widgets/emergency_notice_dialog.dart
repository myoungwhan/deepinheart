import 'package:deepinheart/Controller/Model/emergency_announcement_model.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyNoticeDialog extends StatelessWidget {
  final EmergencyAnnouncement announcement;

  const EmergencyNoticeDialog({Key? key, required this.announcement})
    : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required EmergencyAnnouncement announcement,
  }) async {
    // Check if user has dismissed this announcement
    final prefs = await SharedPreferences.getInstance();
    final dismissedKey = 'emergency_notice_dismissed_${announcement.id}';
    final isDismissed = prefs.getBool(dismissedKey) ?? false;

    if (isDismissed) {
      return; // Don't show if user dismissed it
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyNoticeDialog(announcement: announcement),
    );
  }

  /// Check and show emergency announcements based on priority
  /// [priorityFilter] can be null (show all), or specific priority level
  static Future<void> checkAndShow(
    BuildContext context,
    List<EmergencyAnnouncement> announcements, {
    PriorityLevel? priorityFilter,
  }) async {
    if (announcements.isEmpty) return;

    // Filter active announcements based on date range
    final now = DateTime.now();
    var activeAnnouncements =
        announcements.where((announcement) {
          try {
            final start = DateTime.parse(announcement.startDate);
            final end = DateTime.parse(announcement.endDate);
            final isInDateRange =
                now.isAfter(start.subtract(Duration(seconds: 1))) &&
                now.isBefore(end.add(Duration(days: 1)));
            final isActive =
                announcement.isActive &&
                announcement.status.toLowerCase() == 'active';

            // Filter by priority if specified
            if (priorityFilter != null) {
              return isInDateRange &&
                  isActive &&
                  announcement.priorityLevel == priorityFilter;
            }

            return isInDateRange && isActive;
          } catch (e) {
            return false;
          }
        }).toList();

    if (activeAnnouncements.isEmpty) return;

    // Sort by priority: high > medium > low
    activeAnnouncements.sort((a, b) {
      final priorityOrder = {
        PriorityLevel.high: 0,
        PriorityLevel.medium: 1,
        PriorityLevel.low: 2,
      };
      return priorityOrder[a.priorityLevel]!.compareTo(
        priorityOrder[b.priorityLevel]!,
      );
    });

    // Show the highest priority announcement
    final announcementToShow = activeAnnouncements.first;
    await show(context, announcement: announcementToShow);
  }

  /// Show high priority announcements (immediately on app launch)
  static Future<void> checkAndShowHighPriority(
    BuildContext context,
    List<EmergencyAnnouncement> announcements,
  ) async {
    await checkAndShow(
      context,
      announcements,
      priorityFilter: PriorityLevel.high,
    );
  }

  /// Show medium priority announcements (after login)
  static Future<void> checkAndShowMediumPriority(
    BuildContext context,
    List<EmergencyAnnouncement> announcements,
  ) async {
    await checkAndShow(
      context,
      announcements,
      priorityFilter: PriorityLevel.medium,
    );
  }

  /// Show low priority announcements (as local push notification)
  static Future<void> checkAndShowLowPriority(
    BuildContext context,
    List<EmergencyAnnouncement> announcements,
  ) async {
    print('🔔 checkAndShowLowPriority called');
    print('   - Total announcements: ${announcements.length}');

    if (announcements.isEmpty) {
      print('   - No announcements, returning');
      return;
    }

    // Filter active low priority announcements based on date range
    final now = DateTime.now();
    print('   - Current date: $now');

    final activeAnnouncements =
        announcements.where((announcement) {
          try {
            final start = DateTime.parse(announcement.startDate);
            final end = DateTime.parse(announcement.endDate);
            final isInRange =
                now.isAfter(start.subtract(Duration(seconds: 1))) &&
                now.isBefore(end.add(Duration(days: 1)));
            final isActive =
                announcement.isActive &&
                announcement.status.toLowerCase() == 'active';
            final isLowPriority =
                announcement.priorityLevel == PriorityLevel.low;

            print('   - Announcement ${announcement.id}:');
            print('     - Priority: ${announcement.priority}');
            print('     - Is Low: $isLowPriority');
            print('     - Is Active: $isActive');
            print('     - Status: ${announcement.status}');
            print('     - Start: $start, End: $end');
            print('     - In Range: $isInRange');

            return isInRange && isActive && isLowPriority;
          } catch (e) {
            print('   - Error parsing dates: $e');
            return false;
          }
        }).toList();

    print(
      '   - Active low priority announcements: ${activeAnnouncements.length}',
    );

    if (activeAnnouncements.isEmpty) {
      print('   - No active low priority announcements, returning');
      return;
    }

    // For low priority, show as local push notification
    final announcementToShow = activeAnnouncements.first;

    // Check if user has dismissed this announcement
    final prefs = await SharedPreferences.getInstance();
    final dismissedKey = 'emergency_notice_dismissed_${announcementToShow.id}';
    final isDismissed = prefs.getBool(dismissedKey) ?? false;

    if (isDismissed) {
      return; // Don't show if user dismissed it
    }

    // Check if notification was already shown today
    final lastShownKey = 'emergency_notice_last_shown_${announcementToShow.id}';
    final lastShownDate = prefs.getString(lastShownKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    print('   - Last shown date: $lastShownDate');
    print('   - Today: $today');

    if (lastShownDate == today) {
      print('   - Already shown today, skipping');
      return; // Already shown today, don't show again
    }

    print('   - Not shown today, proceeding to show notification');

    // Show as local push notification
    try {
      print('🔔 Showing emergency notice notification');
      print('   - ID: ${announcementToShow.id}');
      print('   - Title: ${announcementToShow.title}');
      print('   - Content length: ${announcementToShow.content.length}');

      await showEmergencyNoticeNotification(
        announcementId: announcementToShow.id,
        title: announcementToShow.title,
        content: announcementToShow.content,
      );

      print('✅ Emergency notice notification shown successfully');

      // Save that notification was shown today
      await prefs.setString(lastShownKey, today);
    } catch (e) {
      print('❌ Error showing emergency notice notification: $e');
      print('   Stack trace: ${StackTrace.current}');
      // Fallback to snackbar if notification fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: announcementToShow.title,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: Colors.white,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text:
                      announcementToShow.content.length > 100
                          ? '${announcementToShow.content.substring(0, 100)}...'
                          : announcementToShow.content,
                  fontSize: FontConstants.font_12,
                  color: Colors.white,
                  maxlines: 2,
                ),
              ],
            ),
            backgroundColor: const Color(0xFF246596),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: "View".tr,
              textColor: Colors.white,
              onPressed: () {
                // Show full dialog when user taps "View"
                show(context, announcement: announcementToShow);
              },
            ),
          ),
        );
      }
    }
  }

  static Future<void> _handleDontShowAgain(int announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedKey = 'emergency_notice_dismissed_$announcementId';
    await prefs.setBool(dismissedKey, true);
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
          borderRadius: BorderRadius.circular(12.r),
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

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF246596), // Dark blue header
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              text: "Emergency Notice".tr,
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          CustomText(
            text: announcement.title,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.bold,
            color: const Color(0xFF111726),
          ),
          SizedBox(height: 12.h),

          // Content
          CustomText(
            text: announcement.content,
            fontSize: FontConstants.font_14,
            color: const Color(0xFF374151),
            height: 1.5,
          ),

          SizedBox(height: 24.h),

          // Action Buttons
          Row(
            children: [
              // Don't show again button
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await _handleDontShowAgain(announcement.id);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(color: borderColor),
                    ),
                    backgroundColor: Colors.grey.shade100,
                  ),
                  child: CustomText(
                    text: "Don't show again".tr,
                    fontSize: FontConstants.font_14,
                    color: const Color(0xFF374151),
                    align: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Confirm button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF246596),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: CustomText(
                    text: "Confirm".tr,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.semiBold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
