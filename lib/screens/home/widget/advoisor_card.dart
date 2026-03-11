import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/counselor/counselor_detail_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_tile.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shape_of_view_null_safe/shape_of_view_null_safe.dart';

class AdvisorCardView extends StatelessWidget {
  CounselorData model;
  int sectionId;
  AdvisorCardView({Key? key, required this.model, this.sectionId = 0})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Listen to provider updates to get fresh counselor data
    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        // Find the current counselor in the provider's lists to get updated data
        CounselorData? updatedCounselor;

        // Search in all counselor lists (try-catch to handle not found)
        try {
          updatedCounselor = provider.counselorsFortune.firstWhere(
            (c) => c.id == model.id,
          );
        } catch (e) {
          try {
            updatedCounselor = provider.counselorsCounseling.firstWhere(
              (c) => c.id == model.id,
            );
          } catch (e) {
            try {
              updatedCounselor = provider.popularAdvisorsFortune.firstWhere(
                (c) => c.id == model.id,
              );
            } catch (e) {
              try {
                updatedCounselor = provider.popularAdvisorsCounseling
                    .firstWhere((c) => c.id == model.id);
              } catch (e) {
                updatedCounselor = null; // Not found in any list
              }
            }
          }
        }

        // Use updated counselor if found, otherwise use original
        final currentCounselor = updatedCounselor ?? model;

        return InkWell(
          onTap: () {
            Get.to(
              CounselorDetailScreen(
                model: currentCounselor,
                sectionId: sectionId,
              ),
            );
          },
          child: Card(
            color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
            child: Padding(
              padding: EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ShapeOfView(
                      shape: RoundRectShape(
                        borderRadius: BorderRadius.circular(9.0.r),
                      ),
                      height: 120.0.h,
                      elevation: 0.5,
                      width: Get.width,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl:
                            currentCounselor.profileImage.isNotEmpty
                                ? currentCounselor.profileImage
                                : testuserprofile,
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
                  ),
                  UIHelper.verticalSpaceSm,
                  CustomText(
                    text:
                        currentCounselor.nickName.isNotEmpty
                            ? currentCounselor.nickName
                            : currentCounselor.name,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                    maxlines: 1,
                  ),
                  UIHelper.verticalSpaceSm5,
                  CustomText(
                    text: () {
                      final userViewModel = Provider.of<UserViewModel>(
                        context,
                        listen: false,
                      );
                      final texnomyData = userViewModel.texnomyData;

                      // Helper function to get translated category name
                      String getCategoryName(dynamic category) {
                        if (texnomyData == null) return category.name;

                        // Try to find in fortune categories
                        try {
                          final fortuneCategory = texnomyData.fortune.categories
                              .firstWhere((c) => c.id == category.id);
                          return fortuneCategory.nameTranslated ??
                              fortuneCategory.name;
                        } catch (e) {
                          // Not found in fortune, try counseling
                        }

                        // Try to find in counseling categories
                        try {
                          final counselingCategory = texnomyData
                              .counseling
                              .categories
                              .firstWhere((c) => c.id == category.id);
                          return counselingCategory.nameTranslated ??
                              counselingCategory.name;
                        } catch (e) {
                          // Not found, return original name
                        }

                        return category.name;
                      }

                      // Helper function to get translated taxonomy name
                      String getTaxonomyName(dynamic taxonomy) {
                        if (texnomyData == null) return taxonomy.name;

                        // Try to find in fortune taxonomies
                        try {
                          final fortuneTaxonomy = texnomyData.fortune.taxonomies
                              .firstWhere((t) => t.id == taxonomy.id);
                          return fortuneTaxonomy.name;
                        } catch (e) {
                          // Not found in fortune, try counseling
                        }

                        // Try to find in counseling taxonomies
                        try {
                          final counselingTaxonomy = texnomyData
                              .counseling
                              .taxonomies
                              .firstWhere((t) => t.id == taxonomy.id);
                          return counselingTaxonomy.name;
                        } catch (e) {
                          // Not found, return original name
                        }

                        return taxonomy.name;
                      }

                      // First try to get categories with translated names
                      final categories =
                          currentCounselor.specialties
                              .expand((s) => s.categories)
                              .map((c) => getCategoryName(c))
                              .where((name) => name.isNotEmpty)
                              .take(2)
                              .toList();

                      // If categories are empty, fallback to taxonomies with translated names
                      if (categories.isEmpty) {
                        return currentCounselor.specialties
                            .expand((s) => s.taxonomies)
                            .map((t) => getTaxonomyName(t))
                            .where((name) => name.isNotEmpty)
                            .take(2)
                            .join(" | ");
                      }

                      return categories.join(" | ");
                    }(),
                    fontSize: FontConstants.font_13,
                    weight: FontWeightConstants.regular,
                    maxlines: 2,
                    color: isMainDark ? Colors.white : Color(0xff6B7280),
                  ),
                  UIHelper.verticalSpaceSm,

                  currentCounselor.introduction.isEmpty
                      ? Container()
                      : CustomText(
                        text: currentCounselor.introduction,
                        fontSize: FontConstants.font_13,
                        weight: FontWeightConstants.regular,
                        maxlines: 2,
                        color: Color(0xff4B5563),
                      ),

                  UIHelper.verticalSpaceSm5,
                  Row(
                    children: [
                      Icon(Icons.star, color: Color(0xffFACC15), size: 20.0),
                      // UIHelper.horizontalSpaceSm,
                      CustomText(
                        text:
                            "${currentCounselor.rating} (${currentCounselor.ratingCount})",
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                      ),
                      Spacer(),
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
                              currentCounselor.consultationMethod,
                            ) +
                            "/" +
                            "min".tr,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                      ),
                    ],
                  ),
                  //  UIHelper.verticalSpaceSm5,
                  SubCategoryChip(
                    height: 30.0.h,
                    text: getAvailabilityText(currentCounselor),
                    color: getAvailabilityColor(
                      currentCounselor,
                    ), // Gray for Offline
                    isHaveCircle: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String getAvailabilityText(CounselorData model) {
  // If counselor is logged in and available
  if (model.isOnline && model.isAvailable) {
    return "Available".tr; // "상담가능"
  }
  // If counselor is in a consultation session
  else if (model.in_session) {
    return "In Session".tr; // "상담중"
  }
  // If counselor is not logged in
  else {
    return "Reservable".tr; // "예약가능"
  }
}

Color getAvailabilityColor(CounselorData model) {
  if (model.isOnline && model.isAvailable) {
    return Color(0xff22C55E);
  } else if (model.in_session) {
    return Color(0xffEF4444);
  } else {
    return Color(0xff1E40AF);
  }
}
