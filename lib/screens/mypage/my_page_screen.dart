import 'package:deepinheart/Controller/Model/reservation_model.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/auth/edit_profile_dialog.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/screens/mypage/coins/coin_hostory_screen.dart';
import 'package:deepinheart/screens/mypage/coins/counseltation_history_screen.dart';
import 'package:deepinheart/screens/mypage/coins/fav_counsolers_scrren.dart';
import 'package:deepinheart/screens/mypage/coupons/my_coupons_screen.dart';
import 'package:deepinheart/screens/mypage/customer_service/customer_service_screen.dart';
import 'package:deepinheart/screens/mypage/setting_screen.dart';
import 'package:deepinheart/screens/mypage/announcements/announcements_screen.dart';
import 'package:deepinheart/screens/mypage/views/profile_tile.dart';
import 'package:deepinheart/screens/mypage/views/session_tile.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_nav_bar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  List<Appointment> _recentAppointments = [];

  @override
  void initState() {
    super.initState();
    // Refresh user data and load recent appointments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
      _fetchRecentAppointments();
    });
  }

  Future<void> _refreshUserData() async {
    try {
      await Provider.of<UserViewModel>(context, listen: false).fetchUserData();
      print('User data refreshed in my page screen');
    } catch (e) {
      print('Error refreshing user data in my page screen: $e');
    }
  }

  Future<void> _fetchRecentAppointments() async {
    try {
      final response = await ApiClient().request(
        url: ApiEndPoints.RECENT_APPOINTMENTS,
        method: "GET",
        context: context,
      );

      if (response != null && response['success'] == true) {
        final List data = response['data'] ?? [];
        final appointments = data.map((e) => Appointment.fromJson(e)).toList();
        setState(() {
          _recentAppointments = appointments;
        });
      }
    } catch (e) {
      print('Error fetching recent appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<UserViewModel>(
          context,
          listen: false,
        ).fetchUserData();
      },
      child: Scaffold(
        bottomNavigationBar: CustomBottomNav(3),
        appBar: customAppBar(
          title: "My Page".tr,
          centerTitle: false,
          isLogo: false,

          leading: Container(width: 0),
          action: [
            IconButton(
              onPressed: () {
                Get.to(SettingScreen());
              },
              icon: Icon(Icons.settings),
            ),
          ],
        ),
        body: Container(
          width: Get.width,
          child: SingleChildScrollView(
            child: Consumer<UserViewModel>(
              builder: (context, pr, child) {
                return Column(
                  children: [
                    //   UIHelper.verticalSpaceSm,
                    pr.userModel == null
                        ? Container()
                        : ProfileTile(
                          imageUrl:
                              pr.userModel!.data.profileImage.isNotEmpty
                                  ? pr.userModel!.data.profileImage
                                  : testuserprofile,
                          name: pr.userModel!.data.name,
                          phone: pr.userModel!.data.phone,
                          email: pr.userModel!.data.email,
                          onEditProfile: () {
                            print('Edit profile tapped');
                            // Show edit profile dialog
                            showDialog(
                              context: context,
                              builder: (context) => EditProfileDialog(),
                              barrierDismissible: false,
                            );
                          },
                        ),
                    UIHelper.verticalSpaceMd,
                    coinBanner(
                      double.parse(pr.userModel!.data.coins!.toString()),
                    ),
                    UIHelper.verticalSpaceMd,
                    UIHelper.verticalSpaceSm,

                    CustomTitleWithButton(title: "My Activities".tr),
                    UIHelper.verticalSpaceMd,
                    Row(
                      children: [
                        activityItem(
                          title: "Coin History".tr,
                          color: Color(0xff3B82F6),
                          icon: AppIcons.coinhistorySvg,
                          onTap: () {
                            Get.to(CoinHistoryPage());
                          },
                        ),
                        activityItem(
                          title: "Favorite Counselors".tr,
                          color: Color(0xffEC4899),
                          icon: AppIcons.favsvg,
                          onTap: () {
                            Get.to(FavoriteCounselorsScreen());
                          },
                        ),
                        activityItem(
                          title: "Coupons".tr,
                          color: Color(0xffEAB308),
                          icon: AppIcons.couponsvg,
                          onTap: () {
                            Get.to(MyCouponsScreen());
                          },
                        ),
                      ],
                    ),
                    UIHelper.verticalSpaceMd,
                    CustomTitleWithButton(
                      title: "Recent Consultations".tr,
                      onButtonPressed: () {
                        Get.to(
                          ConsultationHistoryPage(
                            recentAppointments: _recentAppointments,
                          ),
                        );
                      },
                    ),
                    UIHelper.verticalSpaceMd,
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount:
                          _recentAppointments.length > 2
                              ? 2
                              : _recentAppointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _recentAppointments[index];
                        //  final reservation = appointment.toLegacyReservation();

                        return SessionTile(
                          imageUrl: appointment.counselor.image,
                          name: appointment.counselor.name,
                          category: _getCategory(appointment).tr,
                          date: appointment.date ?? '',
                          duration:
                              appointment.reservedCoins.toString() +
                              ' ' +
                              'Coins'.tr,
                          description: appointment.consultationContent ?? '',
                          method: appointment.methodText.tr,
                        );
                      },
                    ),

                    UIHelper.verticalSpaceMd,
                    CustomTitleWithButton(title: "Customer Support".tr),
                    UIHelper.verticalSpaceMd,
                    supportTile(
                      title: "Announcements".tr,
                      icon: Icons.announcement,
                      onTap: () {
                        Get.to(() => AnnouncementsScreen());
                      },
                    ),
                    Divider(thickness: 0.3),
                    supportTile(
                      title: "Customer Service".tr,
                      icon: Icons.support_agent,
                      onTap: () {
                        Get.to(() => CustomerServiceScreen());
                      },
                    ),
                    Divider(thickness: 0.3),
                    supportTile(
                      title: "Terms of Service".tr,
                      icon: Icons.pages,
                      onTap: () {
                        UIHelper.launchInBrowser1(
                          Uri.parse(
                            context
                                .read<SettingProvider>()
                                .settingsModel!
                                .data
                                .privacyPolicyLink,
                          ),
                        );
                      },
                    ),
                    Divider(thickness: 0.3),
                    context
                            .read<SettingProvider>()
                            .settingsModel!
                            .data
                            .termsOfUseLink
                            .isNotEmpty
                        ? supportTile(
                          title: "Privacy Policy".tr,
                          icon: Icons.policy,
                          onTap: () {},
                        )
                        : SizedBox.shrink(),
                    UIHelper.verticalSpaceL,
                    CustomButton(
                      () {
                        UIHelper.showDialogOk(
                          context,
                          title: 'log out'.tr,
                          message: 'Would you really log out?'.tr,
                          onConfirm: () {
                            Get.back();
                            context.read<UserViewModel>().clearUserModel();
                          },
                        );
                      },
                      text: "Logout".tr,
                      color: Colors.white,
                      textcolor: Colors.black,
                      buttonBorderColor: Color(0xffD1D5DB),
                    ),
                    UIHelper.verticalSpaceL,
                  ],
                );
              },
            ),
          ),
        ).paddingAll(15.w),
      ),
    );
  }

  /// Get category for appointment, fallback to method if category is empty
  String _getCategory(Appointment appointment) {
    if (appointment.category.isNotEmpty) {
      return appointment.category;
    }
    // Fallback to method text if category is not available
    return appointment.methodText;
  }

  ListTile supportTile({required title, required icon, onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.all(0),
      leading: Icon(icon, color: isMainDark ? Colors.white : Color(0xff6B7280)),
      title: CustomText(text: title, weight: FontWeightConstants.regular),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: isMainDark ? Colors.white : Color(0xff6B7280),
        size: 15.0,
      ),
    );
  }
}

Container coinBanner(double coinCount, {txt, bool isShowChargeButton = true}) {
  return Container(
    //  height: 113,
    height: 96.h,
    width: Get.width,
    padding: const EdgeInsets.symmetric(horizontal: 17.8, vertical: 12),
    decoration: ShapeDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF246595), Color(0xFF3B81F5)],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Left: “My Coins” + count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,

                children: [
                  SvgPicture.asset(
                    AppIcons.coinsvg,
                    width: 35.w,
                    color: Color(0xffFDE047),
                  ),
                  UIHelper.horizontalSpaceSm5,
                  CustomText(
                    text: txt ?? 'My Coins'.tr,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: Colors.white,
                  ),
                ],
              ),
              UIHelper.verticalSpaceSm5,
              CustomText(
                text: UIHelper.getCurrencyFormate(coinCount) + ' ' + 'Coins'.tr,
                fontSize: FontConstants.font_20,
                weight: FontWeightConstants.bold,
                color: Colors.white,
              ),
            ],
          ),
        ),

        // Right: Recharge button
        isShowChargeButton
            ? SizedBox(
              width: 125.w,
              height: 36.h,
              child: CustomButton(
                () {
                  Get.to(CoinChargingScreen());
                },
                text: 'Recharge'.tr,
                color: Colors.white,
                textcolor: const Color(0xFF246595),
                fsize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
              ),
            )
            : Container(),
      ],
    ),
  );
}

Widget activityItem({
  required title,
  required icon,
  required Color color,
  onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(40),
            ),
            padding: EdgeInsets.all(15.r),
            child: SvgPicture.asset(icon, color: color, width: 15.r),
          ),

          UIHelper.verticalSpaceSm,

          CustomText(
            text: title,
            align: TextAlign.center,
            fontSize: FontConstants.font_12,
          ),
        ],
      ),
    ),
  );
}
