import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:deepinheart/screens/mypage/views/change_password_dialog.dart';
import 'package:deepinheart/screens/mypage/views/delete_account_dialog.dart';
import 'package:deepinheart/screens/mypage/views/language_settings_dialog.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:get/get.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool notifications = true;
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: customAppBar(
        title: "Settings".tr,
        isLogo: false,
        action: [UIHelper.horizontalSpaceMd],
      ),
      body: Container(
        width: Get.width,
        height: Get.height,
        child: ListView(
          children: [
            SettingsTile(
              themeController: themeController,
              leadingIcon: SvgPicture.asset(
                'images/lock.svg',
                width: 24,
                color: Colors.blue,
              ),
              title: 'Change Password'.tr,
              subtitle: 'Change regularly for security'.tr,
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // navigate to change password
                showDialog(
                  context: context,
                  builder: (_) => ChangePasswordDialog(),
                );
              },
            ),
            SettingsTile(
              themeController: themeController,
              leadingIcon: SvgPicture.asset(
                'images/language.svg',
                width: 24,
                color: Colors.purple,
              ),
              title: 'Language Settings'.tr,
              subtitle:
                  Get.locale!.languageCode == 'ko'
                      ? 'Korean'
                      : Get.locale!.languageCode == 'en'
                      ? 'English'
                      : 'Other',
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                showDialog(context: context, builder: (_) => LanguageDialog());
              },
            ),
            SettingsTile(
              themeController: themeController,
              leadingIcon: SvgPicture.asset(
                'images/moon.svg',
                width: 24,
                color:
                    themeController.isDarkMode.value
                        ? Colors.white
                        : Colors.black54,
              ),
              title: 'Dark Mode'.tr,
              subtitle: 'Adjust screen brightness'.tr,
              trailing: Obx(
                () => Switch(
                  value: themeController.isDarkMode.value,
                  trackOutlineColor: WidgetStateProperty.all(primaryColor),
                  activeThumbColor: Colors.white,
                  inactiveThumbColor: primaryColor,
                  activeColor: primaryColor,
                  activeTrackColor: primaryColor,

                  onChanged: (v) {
                    themeController.toggleDarkMode();
                  },
                ),
              ),
            ),
            SettingsTile(
              themeController: themeController,
              leadingIcon: SvgPicture.asset(
                'images/bell.svg',
                width: 24,
                color: Colors.orange,
              ),
              title: 'Notifications'.tr,
              subtitle: 'Push notifications and marketing preferences'.tr,
              trailing: StatefulBuilder(
                builder:
                    (ctx, setState) => Switch(
                      value: notifications,
                      trackOutlineColor: WidgetStateProperty.all(primaryColor),
                      activeThumbColor: Colors.white,
                      inactiveThumbColor: primaryColor,
                      activeColor: primaryColor,
                      activeTrackColor: primaryColor,
                      onChanged: (v) => setState(() => notifications = v),
                    ),
              ),
            ),
            SettingsTile(
              themeController: themeController,
              leadingIcon: SvgPicture.asset(
                'images/trash.svg',
                width: 24,
                color: Colors.red,
              ),
              title: 'Delete Account'.tr,
              subtitle: 'Delete account and personal information'.tr,
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // show delete confirmation
                showDialog(
                  context: context,
                  builder:
                      (_) => DeleteAccountDialog(
                        onWithdraw: (password) async {
                          // call your controller or API
                          //   await userController.withdrawMembership(password);
                        },
                      ),
                );
              },
            ),
          ],
        ),
      ).paddingAll(15.r),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final Widget leadingIcon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final ThemeController themeController;

  const SettingsTile({
    Key? key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.themeController,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      //  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      // padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12),
      //   boxShadow: [
      //     BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      //   ],
      // ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            children: [
              // Leading icon
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      themeController.isDarkMode.value
                          ? Colors.white10
                          : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: leadingIcon,
              ),

              UIHelper.horizontalSpaceMd,

              // Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: title,
                      fontSize: 16,
                      weight: FontWeight.w500,
                      // color: Colors.black,
                    ),
                    UIHelper.verticalSpaceSm5,
                    CustomText(
                      text: subtitle,
                      fontSize: 14,
                      weight: FontWeight.w400,
                      color: Colors.grey[600]!,
                    ),
                  ],
                ),
              ),

              // Trailing widget (arrow or switch)
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
