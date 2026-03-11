import 'package:auto_size_text/auto_size_text.dart';
import 'package:deepinheart/screens/mypage/views/language_settings_dialog.dart';
import 'package:deepinheart/screens_consoler/account/tab_views/change_password_view.dart';
import 'package:deepinheart/screens_consoler/account/tab_views/personal_view.dart';
import 'package:deepinheart/screens_consoler/account/tab_views/services/service_views.dart';
import 'package:deepinheart/screens_consoler/account/tab_views/upload_document_view.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/consuler_custom_nav_bar.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Make listTags a getter so translations update when locale changes
  List<String> get listTags => [
    "Personal Info".tr,
    "Password".tr,
    "Document".tr,
    "Services".tr,
  ];

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(
      length: listTags.length,
      vsync: this,
      initialIndex: 0,
    );
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar(
        title: 'Account Settings'.tr,
        action: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.black),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => LanguageDialog(),
              );
              // Rebuild widget when language dialog closes to update translations
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: ConsulerCustomBottomNav(3),
      body: Container(
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              automaticIndicatorColorAdjustment: false,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: primaryColorConsulor,

              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColorConsulor,
              dividerColor: borderColor,
              indicatorWeight: 2,
              labelStyle: textStyleRobotoRegular(
                weight: FontWeightConstants.medium,
                fontSize: FontConstants.font_12,
              ),
              unselectedLabelStyle: textStyleRobotoRegular(
                weight: FontWeightConstants.medium,
                fontSize: FontConstants.font_12,
              ),
              tabs: [
                for (var tag in listTags)
                  Tab(
                    child: AutoSizeText(
                      tag, // Already translated in listTags getter
                      textAlign: TextAlign.center,
                      maxFontSize: 12.0,
                      minFontSize: 10,
                    ),
                  ),
              ],
            ),

            Expanded(
              child: TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  PersonalView(),

                  ChangePasswordView(),
                  UploadDocumentView(),
                  ServiceViews(),
                ],
                controller: _tabController,
              ),
            ),
          ],
        ),
      ).paddingAll(15),
    );
  }
}
