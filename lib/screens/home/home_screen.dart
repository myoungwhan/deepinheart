import 'dart:async';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/theme_controller.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/home/category_detail_screen.dart';
import 'package:deepinheart/screens/home/detail_screens/counsling_details/psychology_consuling_screen.dart';
import 'package:deepinheart/screens/home/detail_screens/counsling_details/psychology_test_screen.dart';
import 'package:deepinheart/screens/home/detail_screens/fortune_telling_screen.dart';
import 'package:deepinheart/screens/home/detail_screens/tarot_reading_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/advoisor_tile.dart';
import 'package:deepinheart/screens/home/widget/custom_banner_view.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/service_category_card.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/home/widget/user_menu_dropdown.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_nav_bar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/screens/calls/widgets/rejoin_call_dialog.dart';
import 'package:deepinheart/services/call_state_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;
  Category? selectedCategory;
  bool _expanded = false;
  final int _initialItems = 6; // how many to show before expand
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this, initialIndex: 0)
      ..addListener(() {
        if (_controller.indexIsChanging) {}
      });

    // Check for interrupted calls when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForInterruptedCall();
    });

    // Start periodic refresh for real-time counselor status updates
    _startPeriodicRefresh();
  }

  /// Check for interrupted call and show rejoin dialog
  Future<void> _checkForInterruptedCall() async {
    try {
      final callState = await CallStateManager.getCallState();

      if (callState != null && mounted) {
        // Show rejoin dialog
        await Get.dialog(
          RejoinCallDialog(callState: callState),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking for interrupted call: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Start periodic refresh to update counselor online status in real-time
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _refreshCounselorDataSilently();
      }
    });
  }

  // Silently refresh counselor data without showing loading indicator
  Future<void> _refreshCounselorDataSilently() async {
    try {
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      await serviceProvider.pullRefreshSilently();
      setState(() {});
    } catch (e) {
      debugPrint('Error refreshing counselor data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNav(0),
      appBar: customAppBar(title: ""),
      body: Container(
        width: Get.width,
        height: Get.height,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: RefreshIndicator(
          onRefresh: () async {
            ServiceProvider serviceProvider = Provider.of<ServiceProvider>(
              context,
              listen: false,
            );
            await serviceProvider.pullRefresh();
            setState(() {});
          },
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TabBar(
                      controller: _controller,
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      onTap: (index) {
                        setState(() {});
                      },
                      isScrollable: false,
                      labelColor: primaryColor,

                      unselectedLabelColor:
                          isMainDark ? Colors.white : Color(0xff6B7280),
                      indicatorColor: primaryColor,
                      indicatorWeight: 2,
                      labelStyle: textStyleRobotoRegular(
                        weight: FontWeightConstants.medium,
                        fontSize: FontConstants.font_14,
                      ),
                      unselectedLabelStyle: textStyleRobotoRegular(
                        weight: FontWeightConstants.medium,
                        fontSize: FontConstants.font_14,
                      ),
                      tabs: [
                        Tab(text: '${enumServiceSection.Fortune.name}'.tr),
                        Tab(text: '${enumServiceSection.Counseling.name}'.tr),
                      ],
                    ),
                  ),
                  Expanded(child: Container()),
                  UIHelper.horizontalSpaceSm,
                  IconButton(
                    onPressed: () {
                      Get.dialog(UserMenuDropdown());
                    },
                    icon: Icon(Icons.more_vert),
                  ),
                ],
              ),

              UIHelper.verticalSpaceMd,

              Expanded(
                child: Consumer<UserViewModel>(
                  builder: (context, pr, child) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) {
                              List<Category> listCatgories =
                                  _controller.index == 0
                                      ? pr.texnomyData!.fortune.categories
                                      : pr.texnomyData!.counseling.categories;
                              List<Taxonomy> listTaxonomy =
                                  _controller.index == 0
                                      ? pr.texnomyData!.fortune.taxonomies
                                      : pr.texnomyData!.counseling.taxonomies;

                              if (selectedCategory == null &&
                                  listCatgories.isNotEmpty) {
                                selectedCategory = listCatgories.first;
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  categoriesView(
                                    listCatgories,
                                    _controller.index,
                                  ),
                                  UIHelper.verticalSpaceSm,

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        listTaxonomy
                                            .map(
                                              (e) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  _controller.index == 0
                                                      ? fortuneToxnomy(e)
                                                      : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          UIHelper
                                                              .verticalSpaceMd,
                                                          CustomText(
                                                            text: e.name.tr,
                                                            fontSize:
                                                                FontConstants
                                                                    .font_16,
                                                            weight:
                                                                FontWeightConstants
                                                                    .medium,
                                                          ),
                                                          UIHelper
                                                              .verticalSpaceMd,
                                                          if (e.position == "1")
                                                            psycologyTestTags(
                                                              e,
                                                            ),
                                                          if (e.position == "2")
                                                            consulingTypeTags(
                                                              e,
                                                            ),
                                                        ],
                                                      ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              );
                            },
                          ),

                          UIHelper.verticalSpaceMd,

                          //  UIHelper.verticalSpaceL,
                          CustomTitleWithButton(
                            title: "Popular Advisors".tr,
                            onButtonPressed: () {},
                          ),

                          // UIHelper.verticalSpaceSm,
                          Consumer<ServiceProvider>(
                            builder: (context, pro, child) {
                              List<CounselorData> listCounslers =
                                  _controller.index == 0
                                      ? pro.popularAdvisorsFortune.toList()
                                      : pro.popularAdvisorsCounseling.toList();
                              return listCounslers.isEmpty
                                  ? _buildEmptyState()
                                  : GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2, // 2 items per row
                                          crossAxisSpacing:
                                              5.0.sp, // Space between columns
                                          mainAxisSpacing:
                                              5.0.sp, // Space between rows
                                          childAspectRatio:
                                              0.625, // Custom height (height/width ratio)
                                        ),
                                    itemCount: listCounslers.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return AdvisorCardView(
                                        model: listCounslers[index],
                                        sectionId:
                                            _controller.index == 0
                                                ? pr.texnomyData!.fortune.id
                                                : pr.texnomyData!.counseling.id,
                                      ); // AdvisorCardView widget
                                    },
                                  );
                            },
                          ),

                          UIHelper.verticalSpaceMd,

                          CustomBannerView(
                            bannerModel: BannerModel(
                              bannerName: 'Coin Charging Event'.tr,
                              bannerType: 'text', // Image banner or text banner
                              imageUrl:
                                  '', // Empty for text banners, URL for image banners
                              externalLink: 'https://example.com',
                              exposureBegin: DateTime.now(),

                              exposureEnd: DateTime.now().add(
                                Duration(days: 30),
                              ),
                              couponDescription:
                                  'Get 20% bonus when charging over 10,000 coins!'
                                      .tr,
                              buttonText: 'Charge Now'.tr,
                              buttonColor:
                                  Colors.blue, // Customize button color
                              buttonClickAction: () {
                                Get.to(CoinChargingScreen());
                              },
                            ),
                          ),

                          UIHelper.verticalSpaceMd,
                          CustomTitleWithButton(
                            title: "Available Counselors".tr,
                          ),
                          UIHelper.verticalSpaceMd,

                          Consumer<ServiceProvider>(
                            builder: (context, pro, child) {
                              List<CounselorData> listCounslers =
                                  _controller.index == 0
                                      ? pro.counselorsFortune.toList()
                                      : pro.counselorsCounseling.toList();
                              return listCounslers.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                    // separatorBuilder: (context, index) {
                                    //   return Divider(color: Color(0xffE5E7EB));
                                    // },
                                    itemCount: listCounslers.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return AdvoisorTile(
                                        sectionId:
                                            _controller.index == 0
                                                ? pr.texnomyData!.fortune.id
                                                : pr.texnomyData!.counseling.id,
                                        model: listCounslers[index],
                                      );
                                    },
                                  );
                            },
                          ),
                          UIHelper.verticalSpaceMd,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column consulingTypeTags(Taxonomy e) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            final itemsToShow =
                _expanded
                    ? e.taxonomieItems.length
                    : _initialItems.clamp(0, e.taxonomieItems.length);
            final rows = (itemsToShow / 2).ceil();
            final rowHeight = 40.0; // adjust to your chip height
            final targetHeight = rows * rowHeight + (rows - 1) * 5;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              height: targetHeight, // 👈 now height animates
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsToShow,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 per row like screenshot
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 5, // wide pill look
                ),
                itemBuilder: (context, index) {
                  final item = e.taxonomieItems[index];

                  return SubCategoryChipCategory(
                    fontSize: FontConstants.font_13,
                    text: item.name,
                    color: UIHelper.getColor(item.color),
                  );
                },
              ),
            );
          },
        ),
        // const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _expanded ? "Show Less".tr : "Show More".tr,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),

        //arrow button to expand and collapse animation container
      ],
    );
  }

  SizedBox psycologyTestTags(Taxonomy e) {
    return SizedBox(
      height: 38.h,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 5),
            child: SubCategoryChipCategory(
              fontSize: FontConstants.font_13,
              text: e.taxonomieItems[index].name,
              img: e.taxonomieItems[index].iconUrl,

              color: UIHelper.getColor(e.taxonomieItems[index].color),
              isHaveCircle: true,
            ),
          );
        },
        itemCount: e.taxonomieItems.length,
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget fortuneToxnomy(Taxonomy e) {
    final items = e.taxonomieItems;
    final itemWidth = (Get.width / 4) - 8.w; // 4 items per row (25% width each)
    final itemHeight = 40.h; // Fixed height for each chip
    final spacing = 4.w; // Spacing between items

    // Split items into two rows sequentially (first half in first row, second half in second row)
    final itemsPerRow = (items.length / 2).ceil();
    final firstRowItems = items.take(itemsPerRow).toList();
    final secondRowItems = items.skip(itemsPerRow).toList();

    // Calculate total width needed (based on the row with more items)
    final maxItemsPerRow =
        firstRowItems.length > secondRowItems.length
            ? firstRowItems.length
            : secondRowItems.length;
    final totalWidth =
        maxItemsPerRow * itemWidth + (maxItemsPerRow - 1) * spacing;

    return SizedBox(
      height: (itemHeight * 2) + 6.h, // Two rows + spacing
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First row
              SizedBox(
                height: itemHeight,
                child: Row(
                  children: List.generate(firstRowItems.length, (index) {
                    final item = firstRowItems[index];
                    return Container(
                      width: itemWidth,
                      margin: EdgeInsets.only(
                        right: index < firstRowItems.length - 1 ? spacing : 0,
                      ),
                      child: Center(
                        child: toxinCategoryChip(
                          text: item.name,
                          img: item.iconUrl,
                          color: UIHelper.getColor(item.color),
                          height: itemHeight,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 6.h),
              // Second row
              SizedBox(
                height: itemHeight,
                child: Row(
                  children: List.generate(secondRowItems.length, (index) {
                    final item = secondRowItems[index];
                    return Container(
                      width: itemWidth,
                      margin: EdgeInsets.only(
                        right: index < secondRowItems.length - 1 ? spacing : 0,
                      ),
                      child: Center(
                        child: toxinCategoryChip(
                          text: item.name,
                          img: item.iconUrl,
                          color: UIHelper.getColor(item.color),
                          height: itemHeight,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 48.w,
              color: Colors.grey.shade400,
            ),
          ),

          SizedBox(height: 24.h),

          // Title
          CustomText(
            text: "No Counselors Available".tr,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
            color: Colors.grey.shade700,
            align: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // Subtitle
          CustomText(
            text:
                "We're working on adding more expert counselors to help you. Please check back soon!"
                    .tr,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.regular,
            color: Colors.grey.shade500,
            align: TextAlign.center,
            maxlines: 3,
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget categoriesView(List<Category> listCatgories, int index) {
    final shouldScroll = listCatgories.length > 3;

    return SizedBox(
      height: 140.h,
      child:
          shouldScroll
              ? ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: listCatgories.length,
                itemBuilder: (context, i) {
                  final e = listCatgories[i];
                  return Container(
                    width: Get.width * 0.32,
                    margin: EdgeInsets.only(
                      right: i < listCatgories.length - 1 ? 8.w : 0,
                    ),
                    child: ServiceCategoryCard(
                      model: e,
                      isActive: false,
                      callBack: (Category e) {
                        print("category..........." + e.name);
                        print(e.image);
                        //for fortunes section
                        if (index == 0) {
                          if (e.name.contains('Tarot') ||
                              e.name.contains('타로')) {
                            Get.to(TarotReadingScreen(model: e));
                          } else {
                            Get.to(FortuneTellingScreen(model: e));
                          }
                        } else {
                          if (e.position == "1") {
                            Get.to(PsychologyTestScreen(model: e));
                          } else if (e.position == "2") {
                            Get.to(PsychologyConsulingScreen(model: e));
                          } else {
                            Get.to(PsychologyTestScreen(model: e));

                            // Get.to(CounselingScreen(model: e));
                          }
                        }
                      },
                      fSize: FontConstants.font_10,
                    ),
                  );
                },
              )
              : Row(
                children:
                    listCatgories
                        .map(
                          (e) =>
                              (_controller.index == 0
                                      ? listCatgories.length < 2
                                      : listCatgories.length < 3)
                                  ? Container(
                                    width: Get.width * 0.32,
                                    child: ServiceCategoryCard(
                                      model: e,
                                      isActive: false,
                                      callBack: (Category e) {
                                        print(e.name);
                                        //for fortunes section
                                        if (index == 0) {
                                          if (e.name.contains('Tarot') ||
                                              e.name.contains('타로')) {
                                            Get.to(
                                              TarotReadingScreen(model: e),
                                            );
                                          } else {
                                            Get.to(
                                              FortuneTellingScreen(model: e),
                                            );
                                          }
                                        } else {
                                          if (e.position == "1") {
                                            Get.to(
                                              PsychologyTestScreen(model: e),
                                            );
                                          } else if (e.position == "2") {
                                            Get.to(
                                              PsychologyConsulingScreen(
                                                model: e,
                                              ),
                                            );
                                          } else {
                                            Get.to(
                                              PsychologyTestScreen(model: e),
                                            );

                                            // Get.to(CounselingScreen(model: e));
                                          }
                                        }
                                      },
                                      fSize: FontConstants.font_14,
                                    ),
                                  )
                                  : Expanded(
                                    child: ServiceCategoryCard(
                                      model: e,
                                      isActive: false,
                                      callBack: (Category e) {
                                        print(e.name);
                                        //for fortunes section
                                        if (index == 0) {
                                          if (e.name.contains('Tarot') ||
                                              e.name.contains('타로')) {
                                            Get.to(
                                              TarotReadingScreen(model: e),
                                            );
                                          } else {
                                            Get.to(
                                              FortuneTellingScreen(model: e),
                                            );
                                          }
                                        } else {
                                          if (e.position == "1") {
                                            Get.to(
                                              PsychologyTestScreen(model: e),
                                            );
                                          } else if (e.position == "2") {
                                            Get.to(
                                              PsychologyConsulingScreen(
                                                model: e,
                                              ),
                                            );
                                          } else {
                                            Get.to(
                                              PsychologyTestScreen(model: e),
                                            );

                                            // Get.to(CounselingScreen(model: e));
                                          }
                                        }
                                      },
                                      fSize: FontConstants.font_14,
                                    ),
                                  ),
                        )
                        .toList(),
              ),
    );
  }
}
