import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart';
import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/custom_banner_view.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/freq_question_tile.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/retings/widget/rating_tileview.dart';
import 'package:deepinheart/services/translation_service.dart';
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

class FortuneTellingScreen extends StatefulWidget {
  final Category model;
  const FortuneTellingScreen({Key? key, required this.model}) : super(key: key);

  @override
  _FortuneTellingScreenState createState() => _FortuneTellingScreenState();
}

class _FortuneTellingScreenState extends State<FortuneTellingScreen> {
  bool isForune = true;
  List<CounselorData> counselors = [];
  bool isLoading = true;
  bool _expanded = false;
  final int _initialItems = 6; // how many to show before expand

  // FAQ and Reviews data
  List<FaqItem> faqs = [];
  List<ReviewItem> reviews = [];
  bool isLoadingFaqAndReviews = true;

  @override
  void initState() {
    super.initState();
    if (widget.model.name != enumServiceSection.Fortune.name) {
      setState(() {
        isForune = false;
      });
    }
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
      print(result?.faqs.length.toString() ?? '0' + "faq****");
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
      appBar: customAppBar(title: "Fortune Telling".tr, isLogo: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DetailHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.r),
              child: Column(
                children: [
                  UIHelper.verticalSpaceMd,
                  CustomTitleWithButton(title: "Popular Fortune Tellers".tr),
                  UIHelper.verticalSpaceMd,

                  // Counselors GridView
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
                          Consumer<UserViewModel>(
                            builder: (context, pr, child) {
                              final itemsToShow =
                                  _expanded
                                      ? counselors.length
                                      : _initialItems.clamp(
                                        0,
                                        counselors.length,
                                      );
                              final rows = (itemsToShow / 2).ceil();
                              final rowHeight =
                                  268.0; // adjust to your card height
                              final targetHeight =
                                  rows * rowHeight + (rows - 1) * 5;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                height: targetHeight, // 👈 now height animates
                                child: GridView.builder(
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
                                      sectionId:
                                          context
                                              .read<UserViewModel>()
                                              .texnomyData!
                                              .fortune
                                              .id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                          // Show More/Less Button
                          if (counselors.length > _initialItems)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        setState(() => _expanded = !_expanded),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _expanded
                                          ? "Show Less".tr
                                          : "Show More".tr,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _expanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                  UIHelper.verticalSpaceSm,

                  // show more button
                  UIHelper.verticalSpaceMd,
                  CustomBannerView(
                    bannerModel: BannerModel(
                      bannerName: 'Special First Consultation Discount'.tr,
                      bannerType: 'text', // Image banner or text banner
                      imageUrl:
                          '', // Empty for text banners, URL for image banners
                      externalLink: 'https://example.com',
                      exposureBegin: DateTime.now(),
                      exposureEnd: DateTime.now().add(Duration(days: 30)),
                      couponDescription:
                          'Get 50% off on your first consultation as a new member.'
                              .tr,
                      buttonText: 'Start Now'.tr,
                      buttonColor: Colors.blue, // Customize button color
                      isShowCoinIcon: false,
                    ),
                  ),

                  UIHelper.verticalSpaceMd,
                  CustomTitleWithButton(
                    title:
                        "Features of".tr +
                        " ${widget.model.name.tr} " +
                        "Reading".tr,
                  ),
                  UIHelper.verticalSpaceMd,

                  // Features: from API when available, else fallback by category name
                  widget.model.features.isNotEmpty
                      ? _buildDynamicFeatures()
                      : widget.model.name.toLowerCase().contains('saju')
                      ? _buildSajuFeatures()
                      : widget.model.name.toLowerCase().contains('divine') ||
                          widget.model.name.toLowerCase().contains('spiritual')
                      ? _buildDivineFeatures()
                      : _buildDefaultFeatures(),

                  UIHelper.verticalSpaceMd,
                  CustomTitleWithButton(title: "Reviews".tr),
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
                        height: 150.0.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            return RatingTileview(review: reviews[index]);
                          },
                        ),
                      ),

                  UIHelper.verticalSpaceMd,
                  CustomTitleWithButton(title: "Frequently Asked Questions".tr),
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

  Container DetailHeader() {
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
              text: widget.model.name,
              fontSize: FontConstants.font_24,
              color: Colors.white,
              weight: FontWeightConstants.bold,
            ),
            UIHelper.verticalSpaceMd,
            CustomText(
              text: widget.model.description,
              fontSize: FontConstants.font_14,
              color: Colors.white,
              height: 2.h,
            ),
            UIHelper.verticalSpaceSm,
            fortuneToxnomy(
              context
                  .read<UserViewModel>()
                  .texnomyData!
                  .fortune
                  .taxonomies
                  .first,
            ),

            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }

  GridView fortuneToxnomy(Taxonomy e) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5, // tweak to make chips look good: width / height
      children:
          e.taxonomieItems.map((item) {
            return Center(
              child: SubCategoryChipCategory(
                text: item.name,
                isBackgroundDark: true,
                // img: item.iconUrl,
                fontSize: FontConstants.font_12,
                color: UIHelper.getColor(item.color),
              ),
            );
          }).toList(),
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
                "We're working on adding more expert fortune tellers to help you. Please check back soon!"
                    .tr +
                "Please check back later".tr,
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

  /// Builds feature list from API when category has features.
  Widget _buildDynamicFeatures() {
    return Column(
      children:
          widget.model.features
              .map(
                (item) => _buildFeatureListItem(
                  imageUrl: item.image,
                  iconData: Icons.article_outlined,
                  title: item.title,
                  description: item.text,
                ),
              )
              .toList(),
    );
  }

  // Saju features (fallback when API has no features)
  Widget _buildSajuFeatures() {
    final features = [
      {
        "icon": Icons.person_outline,
        "title": "Personal Destiny and Character Analysis",
        "description":
            "Analyze Your Innate Personality and Life Direction Through Birth Date and Time.",
      },
      {
        "icon": Icons.timeline,
        "title": "Life Flow Prediction",
        "description":
            "Predict Changes and Developments in Fortune Through Major and Minor Life Cycles.",
      },
      {
        "icon": Icons.work_outline,
        "title": "Career and Wealth Guidance",
        "description":
            "Advice on Suitable Careers, Wealth Flow, and Success Potential Based on Your Fortune.",
      },
      {
        "icon": Icons.people_outline,
        "title": "Compatibility and Relationship Analysis",
        "description":
            "Diagnose Relationship Harmony Through Fortune Compatibility Analysis.",
      },
    ];
    return Column(
      children:
          features
              .map(
                (f) => _buildFeatureListItem(
                  iconData: f["icon"] as IconData,
                  title: (f["title"] as String).tr,
                  description: (f["description"] as String).tr,
                ),
              )
              .toList(),
    );
  }

  // Divine/Spiritual Features
  Widget _buildDivineFeatures() {
    final features = [
      {
        "icon": Icons.auto_awesome_outlined,
        "title": "Interpretation Through Spiritual Connection",
        "description":
            "Guidance on the Flow of Destiny Through Spiritual Communication.",
      },
      {
        "icon": Icons.lightbulb_outline,
        "title": "Immediate Problem-Solving Direction",
        "description":
            "Clear Answers to Urgent Questions and Prompts Realistic Advice and Soluti.",
      },
      {
        "icon": Icons.family_restroom_outlined,
        "title": "Analysis of the Influence of Ancestors and Energy",
        "description":
            "Examine Ancestral Karma and the Impact on the Spirits and Their Current Lives.",
      },
      {
        "icon": Icons.thumb_up_outlined,
        "title": "Proposal Propostle for Good and Slander",
        "description":
            "Practical Methods of Blessings, Wards off evil Spirits and Improves Energy.",
      },
    ];

    return Column(
      children:
          features
              .map(
                (feature) => _buildFeatureListItem(
                  iconData: feature["icon"] as IconData,
                  title: (feature["title"] as String).tr,
                  description: (feature["description"] as String).tr,
                ),
              )
              .toList(),
    );
  }

  // Default Features for other fortune telling types
  Widget _buildDefaultFeatures() {
    final features = [
      {
        "icon": Icons.remove_red_eye_outlined,
        "title": "Intuitive Insight",
        "description": "Special insights through fortune telling",
      },
      {
        "icon": Icons.question_mark_outlined,
        "title": "Future Guidance",
        "description": "Future predictions for better choices",
      },
      {
        "icon": Icons.favorite_border,
        "title": "Psychological Healing",
        "description": "Inner peace and mental stability",
      },
      {
        "icon": Icons.people_outline,
        "title": "Expert Interpretation",
        "description": "Accurate and reliable consultation",
      },
    ];

    return Column(
      children:
          features
              .map(
                (feature) => _buildFeatureListItem(
                  iconData: feature["icon"] as IconData,
                  title: (feature["title"] as String).tr,
                  description: (feature["description"] as String).tr,
                ),
              )
              .toList(),
    );
  }

  // Feature List Item Widget
  Widget _buildFeatureListItem({
    String? imageUrl,
    IconData? iconData,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: 35.w,
              height: 35.w,
              fit: BoxFit.cover,
            )
          else
            Icon(
              iconData ?? Icons.article_outlined,
              color: Color(0xff3B82F6),
              size: 20.w,
            ),

          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.semiBold,
                  maxlines: 2,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: description,
                  fontSize: FontConstants.font_13,
                  weight: FontWeightConstants.regular,
                  color: Colors.grey.shade600,
                  maxlines: 3,
                  height: 1.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
