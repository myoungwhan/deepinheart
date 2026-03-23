import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart';
import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/home/detail_screens/tarot_reading_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/custom_banner_view.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/freq_question_tile.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/retings/widget/rating_tileview.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PsychologyConsulingScreen extends StatefulWidget {
  final Category model;
  const PsychologyConsulingScreen({Key? key, required this.model})
    : super(key: key);

  @override
  _PsychologyConsulingScreenState createState() =>
      _PsychologyConsulingScreenState();
}

class _PsychologyConsulingScreenState extends State<PsychologyConsulingScreen> {
  List<CounselorData> counselors = [];
  bool isLoading = true;
  bool showAll = false;

  // FAQ and Reviews data
  List<FaqItem> faqs = [];
  List<ReviewItem> reviews = [];
  bool isLoadingFaqAndReviews = true;

  @override
  void initState() {
    super.initState();
    _loadCounselors();
    _loadFaqAndReviews();
  }

  Future<void> _loadCounselors() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    setState(() {
      isLoading = true;
    });

    try {
      final result = await serviceProvider.fetchCounselorsByCategory(
        widget.model.id.toString(),
      );
      setState(() {
        counselors = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading counselors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFaqAndReviews() async {
    final serviceProvider = Provider.of<ServiceProvider>(
      context,
      listen: false,
    );
    setState(() {
      isLoadingFaqAndReviews = true;
    });

    try {
      final result = await serviceProvider.fetchFaqAndReviews(widget.model.id);
      if (result != null) {
        setState(() {
          faqs = result.faqs;
          reviews = result.reviews;
          isLoadingFaqAndReviews = false;
        });
      } else {
        setState(() {
          isLoadingFaqAndReviews = false;
        });
      }
    } catch (e) {
      print('Error loading FAQ and Reviews: $e');
      setState(() {
        isLoadingFaqAndReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        title: widget.model.name,
        action: [
          // coin icon
          IconButton(
            onPressed: () {
              // Get.to(CoinChargingScreen());
            },
            icon: SvgPicture.asset(AppIcons.coinsvg, color: Color(0xffE6B325)),
          ),
        ],
        isLogo: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Header(),
            UIHelper.verticalSpaceSm,
            Container(
              padding: EdgeInsets.all(15.r),
              child: Column(
                children: [
                  // horizontal list of test types
                  Builder(
                    builder: (context) {
                      List<SubCategory> listTestTypes =
                          context
                              .read<UserViewModel>()
                              .texnomyData!
                              .counseling
                              .taxonomies[1]
                              .taxonomieItems;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          childAspectRatio:
                              3, // Adjust for chip width/height ratio
                        ),
                        itemBuilder: (context, index) {
                          return SubCategoryChipCategory(
                            text: listTestTypes[index].name,
                            // isBackgroundDark: true,
                            fontSize: FontConstants.font_12,

                            color: listTestTypes[index].getColor(),
                          );
                        },
                        itemCount: listTestTypes.length,
                      );
                    },
                  ),

                  UIHelper.verticalSpaceSm,
                  CustomTitleWithButton(title: "Popular Counselors".tr),
                  UIHelper.verticalSpaceMd,

                  // Counselors List
                  isLoading
                      ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.h),
                          child: CircularProgressIndicator(),
                        ),
                      )
                      : counselors.isEmpty
                      ? _buildEmptyState()
                      : Column(
                        children: [
                          // GridView with show more functionality
                          Consumer<UserViewModel>(
                            builder: (context, pr, child) {
                              final itemsToShow =
                                  showAll
                                      ? counselors.length
                                      : (counselors.length > 6
                                          ? 6
                                          : counselors.length);

                              return GridView.builder(
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
                                itemCount: itemsToShow,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return AdvisorCardView(
                                    model: counselors[index],
                                    sectionId: pr.texnomyData!.counseling.id,
                                  );
                                },
                              );
                            },
                          ),

                          // View More Button
                          if (counselors.length > 6)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    showAll = !showAll;
                                  });
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomText(
                                      text:
                                          showAll
                                              ? "view less counselors".tr
                                              : "view more counselors".tr,
                                      fontSize: FontConstants.font_14,
                                      color: Colors.grey[600],
                                      weight: FontWeightConstants.medium,
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      showAll
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey[600],
                                      size: 20.w,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          UIHelper.verticalSpaceMd,
                          CustomBannerView(
                            bannerModel: BannerModel(
                              bannerName:
                                  'Special First Consultation Discount'.tr,
                              bannerType: 'text', // Image banner or text banner
                              imageUrl:
                                  '', // Empty for text banners, URL for image banners
                              externalLink: 'https://example.com',
                              exposureBegin: DateTime.now(),
                              exposureEnd: DateTime.now().add(
                                Duration(days: 30),
                              ),
                              couponDescription:
                                  'Get 30% off on your first consultation as a new member.'
                                      .tr,
                              buttonText: 'Start Now'.tr,
                              buttonColor:
                                  Colors.blue, // Customize button color
                              isShowCoinIcon: false,
                            ),
                          ),
                          UIHelper.verticalSpaceMd,
                          CustomTitleWithButton(
                            title: "Features of ${widget.model.name}".tr,
                          ),
                          UIHelper.verticalSpaceMd,
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: 1.15,
                            children:
                                (widget.model.features.isNotEmpty
                                        ? widget.model.features
                                        : ServiceProvider
                                            .PsycologycounselingFeatures)
                                    .map(
                                      (e) => buildFeatureCard(
                                        icon: e.image ?? '',
                                        title: e.title,
                                        description: e.text,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                      ),
                                    )
                                    .toList(),
                          ),
                          UIHelper.verticalSpaceMd,
                          CustomTitleWithButton(
                            title: "Reviews".tr,
                            onButtonPressed: () {},
                          ),
                          UIHelper.verticalSpaceSm,

                          // Reviews List from API
                          isLoadingFaqAndReviews
                              ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.h),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : reviews.isEmpty
                              ? _buildEmptyReviews()
                              : SizedBox(
                                height: 205.0.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: reviews.length,
                                  itemBuilder: (context, index) {
                                    return RatingTileview(
                                      review: reviews[index],
                                    );
                                  },
                                ),
                              ),

                          UIHelper.verticalSpaceMd,
                          CustomTitleWithButton(
                            title: "Frequently Asked Questions".tr,
                          ),
                          UIHelper.verticalSpaceSm,

                          // FAQ List from API
                          isLoadingFaqAndReviews
                              ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.h),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : faqs.isEmpty
                              ? _buildEmptyFaqs()
                              : Column(children: _buildFAQListFromApi()),

                          UIHelper.verticalSpaceMd,
                        ],
                      ),

                  UIHelper.verticalSpaceMd,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: CustomText(
          text: "No reviews available yet".tr,
          fontSize: FontConstants.font_14,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildEmptyFaqs() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: CustomText(
          text: "No FAQs available yet".tr,
          fontSize: FontConstants.font_14,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  // Build FAQ List from API data
  List<Widget> _buildFAQListFromApi() {
    return faqs
        .map(
          (faq) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: FreqQuestionTile(
              model: FreqQuestionModel(
                qestion: faq.title,
                ans: faq.plainDetail,
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48.w, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          CustomText(
            text: "No Counselors Available".tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.semiBold,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: "Please check back later".tr,
            fontSize: FontConstants.font_14,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  Container Header() {
    return Container(
      width: 1.sw,
      height: 0.45.sh,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: CachedNetworkImageProvider(
            widget.model.background_image.isNotEmpty
                ? widget.model.background_image
                : widget.model.image,
          ),
        ),
      ),
      child: BlurryContainer(
        blur: 0,
        elevation: 1,

        padding: EdgeInsets.all(15.r),
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: "Professional Psychological Assessment".tr,
              fontSize: FontConstants.font_24,
              color: Colors.white,
              weight: FontWeightConstants.bold,
            ),
            UIHelper.verticalSpaceMd,
            CustomText(
              text: widget.model.description,
              fontSize: FontConstants.font_14,
              color: Colors.white,
              height: 1.8,
            ),

            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }
}
