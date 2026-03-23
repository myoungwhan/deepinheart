import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart';
import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/Controller/Model/service_category_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/Controller/color_service.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/screens/counselor/counselor_detail_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/advoisor_tile.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/freq_question_tile.dart';
import 'package:deepinheart/screens/home/widget/popular_laber_view.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/home/widget/view_more_tellers_button.dart';
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

class TarotReadingScreen extends StatefulWidget {
  Category model;
  TarotReadingScreen({Key? key, required this.model}) : super(key: key);

  @override
  _TarotReadingScreenState createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> {
  bool isForune = true;
  List<CounselorData> counselors = [];
  bool isLoading = true;

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
      appBar: customAppBar(title: "Tarot Reading".tr, isLogo: false),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // tarot reading card
            tarotHeader(),
            Container(
              margin: EdgeInsets.all(15.r),
              width: 1.sw,
              child: Column(
                children: [
                  CustomTitleWithButton(title: "Popular Tarot Readers".tr),
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
                      : ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: counselors.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder:
                            (context, index) => UIHelper.verticalSpaceMd,
                        itemBuilder: (context, index) {
                          return _buildCounselorCard(counselors[index]);
                        },
                      ),
                  UIHelper.verticalSpaceMd,
                  CustomTitleWithButton(title: "Features of Tarot Reading".tr),
                  UIHelper.verticalSpaceMd,

                  // Features GridView: from API when available, else fallback
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.25,
                    children:
                        widget.model.features.isNotEmpty
                            ? widget.model.features
                                .asMap()
                                .entries
                                .map(
                                  (e) => buildFeatureCard(
                                    icon: e.value.image ?? '',
                                    title: e.value.title,
                                    description: e.value.text,
                                    color:
                                        _tarotFeatureColors[e.key %
                                            _tarotFeatureColors.length],
                                  ),
                                )
                                .toList()
                            : [],
                  ),

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
                      : Column(children: _buildFAQList()),

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

  Container tarotHeader() {
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
              text: "Tarot Reading".tr,
              fontSize: FontConstants.font_24,
              weight: FontWeightConstants.bold,
              color: Colors.white,
            ),
            UIHelper.verticalSpaceMd,
            CustomText(
              text: widget.model.description,
              fontSize: FontConstants.font_14,
              color: Colors.white,
              height: 2.h,
            ),
            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }

  // Counselor Card matching the photo design
  Widget _buildCounselorCard(CounselorData counselor) {
    return InkWell(
      onTap: () {
        Get.to(
          CounselorDetailScreen(
            model: counselor,
            sectionId: context.read<UserViewModel>().texnomyData!.fortune.id,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with online indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: CachedNetworkImage(
                    imageUrl: counselor.profileImage ?? '',
                    width: 64.r,
                    height: 64.r,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person, color: Colors.grey),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person, color: Colors.grey),
                        ),
                  ),
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: Color(0xff22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Star Rating
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: counselor.name,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          maxlines: 1,
                        ),
                      ),
                      Icon(Icons.star, color: Color(0xffFACC15), size: 18.w),
                      SizedBox(width: 5.w),
                      CustomText(
                        text: "${counselor.rating} (${counselor.rating ?? 0})",
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Categories badges from service_specialties
                  if (counselor.serviceSpecialties.isNotEmpty)
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children:
                          counselor.serviceSpecialties
                              .take(3) // Show maximum 3 badges
                              .map(
                                (specialty) => SubCategoryChip(
                                  text: specialty,
                                  color: ColorService.getColor(
                                    counselor.serviceSpecialties.indexOf(
                                      specialty,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                  SizedBox(height: 6.h),

                  // Coins and Status Row
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppIcons.coinsvg,
                        width: 30.0,
                        fit: BoxFit.cover,
                        color: Color(0xffFACC15),
                      ),
                      // UIHelper.horizontalSpaceSm,
                      CustomText(
                        text:
                            getPrimaryConsultationPrice(
                              counselor.consultationMethod,
                            ) +
                            "/" +
                            "min".tr,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                      ),

                      SizedBox(width: 8.w),

                      // Available status
                      SubCategoryChip(
                        text: "Available for Consultation".tr,
                        color: Color(0xff22C55E),
                        isHaveCircle: true,
                        fontSize: 11.sp,
                        height: 24.h,
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  // Description
                  CustomText(
                    text: counselor.introduction,
                    fontSize: FontConstants.font_12,
                    weight: FontWeightConstants.regular,
                    color: Colors.grey.shade600,
                    maxlines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: CustomText(
        text: text,
        fontSize: FontConstants.font_11,
        weight: FontWeightConstants.medium,
        color: color,
      ),
    );
  }

  String _getPrimaryPrice(CounsultationMethod method) {
    if (method.videoCallAvailable == 1 && method.videoCallCoin.isNotEmpty) {
      return method.videoCallCoin;
    } else if (method.voiceCallAvailable == 1 &&
        method.voiceCallCoin.isNotEmpty) {
      return method.voiceCallCoin;
    } else if (method.chatAvailable == 1 && method.chatCoin.isNotEmpty) {
      return method.chatCoin;
    }
    return "300";
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

  // Build FAQ List from API data
  List<Widget> _buildFAQList() {
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

  // Feature Card Widget
}

const _tarotFeatureColors = [
  Color(0xff3B82F6),
  Color(0xff8B5CF6),
  Color(0xff06B6D4),
  Color(0xff8B5CF6),
];

Widget buildFeatureCard({
  required String icon,
  required String title,
  required String description,
  required Color color,
}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.r),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        // Container(
        //   padding: EdgeInsets.all(10.w),
        //   decoration: BoxDecoration(
        //     color: color.withOpacity(0.3),
        //     borderRadius: BorderRadius.circular(30.r),
        //   ),
        //   child: Icon(icon, color: color, size: 24.w),
        // ),
        CachedNetworkImage(
          imageUrl: icon,
          width: 45.w,
          height: 45.w,
          fit: BoxFit.cover,
        ),
        UIHelper.verticalSpaceSm,

        // Title
        CustomText(
          text: title,
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.medium,
          maxlines: 2,
        ),

        // Description
        UIHelper.verticalSpaceSm5,
        CustomText(
          text: description,
          fontSize: FontConstants.font_12,
          weight: FontWeightConstants.regular,
          color: lightGREY,

          // maxlines: 2,
        ),
      ],
    ),
  );
}
