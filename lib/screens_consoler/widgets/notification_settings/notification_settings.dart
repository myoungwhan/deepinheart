import 'dart:convert';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({Key? key}) : super(key: key);

  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  // Notification settings state
  bool _bookingNotifications = true;
  bool _paymentNotifications = true;
  bool _reviewNotifications = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final token = userViewModel.userModel?.data.token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiEndPoints.NOTIFICATION_SETTINGS),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _bookingNotifications =
                data['data']['appointment_notification'] == 1;
            _paymentNotifications = data['data']['payment_notification'] == 1;
            _reviewNotifications = data['data']['review_notification'] == 1;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification settings: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateSettings() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final token = userViewModel.userModel?.data.token;
    if (token == null) return;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.NOTIFICATION_SETTING),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_notification'] =
          _bookingNotifications ? '1' : '0';
      request.fields['payment_notification'] =
          _paymentNotifications ? '1' : '0';
      request.fields['review_notification'] = _reviewNotifications ? '1' : '0';

      final response = await request.send();
      print(response.toString());
      if (response.statusCode != 200) {
        debugPrint('Failed to update notification setting');
      }
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: borderColor),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SizedBox(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UIHelper.verticalSpaceSm,
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    align: TextAlign.start,
                    text: 'Notification Settings'.tr,
                    fontSize: FontConstants.font_18,
                    height: 1.3,
                    weight: FontWeightConstants.semiBold,
                    color: Color(0xFF111726),
                  ),
                  Spacer(),
                ],
              ),
            ),
            Divider(thickness: 1, color: borderColor),
            UIHelper.verticalSpaceSm,
            // notification settings list
            _buildNotificationTiles(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTiles() {
    return Column(
      children: [
        if (_isLoading)
          Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _buildNotificationTile(
            title: 'Booking Notifications'.tr,
            description: 'Get notified for new booking requests'.tr,
            value: _bookingNotifications,
            onChanged: (value) {
              setState(() => _bookingNotifications = value);
              _updateSettings();
            },
          ),
          _buildNotificationTile(
            title: 'Payment Notifications'.tr,
            description: 'Get notified when payments are processed'.tr,
            value: _paymentNotifications,
            onChanged: (value) {
              setState(() => _paymentNotifications = value);
              _updateSettings();
            },
          ),
          _buildNotificationTile(
            title: 'Review Notifications'.tr,
            description: 'Get notified for new reviews'.tr,
            value: _reviewNotifications,
            onChanged: (value) {
              setState(() => _reviewNotifications = value);
              _updateSettings();
            },
          ),
        ],
        UIHelper.verticalSpaceSm,
      ],
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      child: Row(
        children: [
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.semiBold,
                  color: Color(0xFF111726),
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: description,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: lightGREY,
                ),
              ],
            ),
          ),

          // Toggle switch (same size as dashboard top on/off)
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 46.w,
              height: 26.h,
              decoration: BoxDecoration(
                color: value ? primaryColorConsulor : Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 200),
                    left: value ? 22.w : 2.w,
                    top: 2.h,
                    child: Container(
                      width: 20.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
