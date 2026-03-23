import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/mypage/my_page_screen.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class UserMenuDropdown extends StatelessWidget {
  const UserMenuDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.only(
        top: 60.h,
        right: 16.w,
        left: Get.width - 200.w,
      ),
      child: Container(
        width: 180.w,
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
            // Profile Option
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Profile'.tr,
              onTap: () {
                Get.back();
                Get.to(() => MyPageScreen());
              },
            ),

            // Divider
            Divider(height: 1, color: Colors.grey[200]),

            // Logout Option
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout'.tr,
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Get.back();
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 20.w, color: iconColor ?? Colors.black87),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomText(
                text: title,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: textColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    UIHelper.showDialogOk(
      context,
      title: 'log out'.tr,
      message: 'Would you really log out?'.tr,
      onConfirm: () {
        Get.back();
        navigatorKey.currentContext!.read<UserViewModel>().clearUserModel();
      },
    );
  }
}
