import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/mypage/coupons/coupons_list.dart';
import 'package:deepinheart/screens/mypage/coupons/coupons_registeration_dialog.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({Key? key}) : super(key: key);

  @override
  _MyCouponsScreenState createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> listTags = ["Available Coupons".tr, "Expired Coupons".tr];
  TextEditingController registerCouponController = TextEditingController();
  bool _isRegistering = false;
  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(
      length: listTags.length,
      vsync: this,
      initialIndex: 0,
    );
    super.initState();
    // Fetch registered coupons on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = context.read<UserViewModel>();
      userViewModel.fetchRegisteredCoupons();
    });
  }

  @override
  void dispose() {
    registerCouponController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _registerCoupon() async {
    // hide key
    FocusScope.of(context).unfocus();
    if (registerCouponController.text.trim().isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Please enter a coupon code'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await userViewModel.registerCoupon(
      registerCouponController.text.trim(),
    );

    setState(() {
      _isRegistering = false;
    });

    // Extract error message - check for validation errors in data field first
    String errorMessage = '';

    if (result['data'] != null && result['data'] is Map<String, dynamic>) {
      final data = result['data'] as Map<String, dynamic>;
      if (data['coupon_code'] != null && data['coupon_code'] is List) {
        final couponCodeErrors = data['coupon_code'] as List;
        if (couponCodeErrors.isNotEmpty) {
          errorMessage = couponCodeErrors[0].toString();
        }
      }
    }

    // Fall back to message field if no validation error found
    if (errorMessage.isEmpty) {
      errorMessage =
          result['message']?.toString() ?? 'Failed to register coupon';
    }

    String message = await translationService.translate(errorMessage);

    if (result['success'] == true) {
      registerCouponController.clear();
      // Refresh registered coupons after successful registration
      userViewModel.fetchRegisteredCoupons();
      Get.snackbar(
        'Success'.tr,
        message.isNotEmpty ? message : 'Coupon registered successfully'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error'.tr,
        message.isNotEmpty ? message : 'Failed to register coupon'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar(
        title: "My Coupons".tr,
        action: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CouponsRegisterationDialog();
                },
              );
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolle) {
          return [
            SliverAppBar(
              expandedHeight: 180,

              toolbarHeight: 0.0,

              floating: false,
              leadingWidth: 0,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: true,
              surfaceTintColor: Colors.white,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Color(0xffEFF0F6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    overlayColor: WidgetStatePropertyAll(Colors.transparent),

                    onTap: (ta) {
                      setState(() {});
                    },
                    dividerHeight: 0.0,

                    isScrollable: false, // Enable scrolling
                    indicatorSize: TabBarIndicatorSize.tab,

                    automaticIndicatorColorAdjustment: true,
                    // give the indicator a decoration (color and border radius)
                    indicator: BoxDecoration(
                      boxShadow: [
                        // BoxShadow(
                        //     color: Color.fromRGBO(
                        //         0, 0, 0, 0.30000000149011612),
                        //     offset: Offset(0, 10),
                        //     blurRadius: 5)
                      ],
                      borderRadius: BorderRadius.circular(25.0),
                      color: primaryColor,
                    ),

                    indicatorPadding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 5,
                    ),
                    labelColor: Colors.white,
                    indicatorColor: Color(0xffF3F4F6),

                    labelStyle: textStylemontserratRegular(
                      fontSize: 13.0,
                      weight: fontWeightSemiBold,
                    ),
                    unselectedLabelColor: primaryColor,
                    unselectedLabelStyle: textStylemontserratRegular(
                      fontSize: 14.0,
                      weight: fontWeightSemiBold,
                    ),

                    tabs: [for (var tag in listTags) Tab(text: tag.tr)],
                  ),
                ),
              ),

              flexibleSpace: FlexibleSpaceBar(
                background: headerWidget(context),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            CouponsList(isExpired: false),
            CouponsList(isExpired: true),
          ],
        ),
      ),
    );
  }

  Widget headerWidget(BuildContext context) {
    return Container(
      width: Get.width,
      // height: 120,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTitleWithButton(title: "Register coupon".tr),
            UIHelper.verticalSpaceMd,
            Customtextfield(
              required: false,
              controller: registerCouponController,
              hint: "Enter Coupon Code".tr,
              suffix: MaterialButton(
                onPressed: _isRegistering ? null : _registerCoupon,
                color: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child:
                    _isRegistering
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              whiteColor,
                            ),
                          ),
                        )
                        : CustomText(text: "Register".tr, color: whiteColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
