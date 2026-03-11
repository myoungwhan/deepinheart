import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/counselor/counselor_detail_screen.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:provider/provider.dart';

class AdvoisorTile extends StatelessWidget {
  final CounselorData model;
  final int sectionId;
  AdvoisorTile({Key? key, required this.model, required this.sectionId})
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

        return Padding(
          padding: EdgeInsets.only(bottom: 7.h),
          child: SizedBox(
            width: Get.width,

            // child: ListTile(
            //   // minLeadingWidth: 40,
            //   contentPadding: EdgeInsets.zero,

            //   title: Row(
            //     children: [
            //       CustomText(
            //         text: "Kim Taehee",
            //         fontSize: FontConstants.font_16,
            //         weight: FontWeightConstants.medium,
            //       ),
            //       Spacer(),
            //       SvgPicture.asset(
            //         AppIcons.coinsvg,
            //         width: 30.0,
            //         fit: BoxFit.cover,
            //         color: Color(0xffFACC15),
            //       ),
            //       // UIHelper.horizontalSpaceSm,
            //       CustomText(
            //         text: "100/" + "min".tr,
            //         fontSize: FontConstants.font_12,
            //         weight: FontWeightConstants.regular,
            //       ),
            //     ],
            //   ),
            //   subtitle: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       CustomText(
            //         text: "Tarot | Saju",
            //         fontSize: FontConstants.font_12,
            //         weight: FontWeightConstants.regular,
            //         color: hintColor,
            //       ),
            //       //UIHelper.verticalSpaceSm,
            //       CustomText(
            //         text:
            //             "20 years experienced tarot expert, specializing in love and reconciliation-115",
            //         fontSize: FontConstants.font_13,
            //         weight: FontWeightConstants.regular,
            //         maxlines: 2,
            //       ),
            //       // UIHelper.verticalSpaceSm5,
            //       Row(
            //         children: [
            //           Icon(Icons.star, color: Color(0xffFACC15), size: 20.0),
            //           // UIHelper.horizontalSpaceSm,
            //           CustomText(
            //             text: "4.9 (328)",
            //             fontSize: FontConstants.font_12,
            //             weight: FontWeightConstants.regular,
            //           ),
            //           Spacer(),
            //           SubCategoryChip(
            //             text: "Available",
            //             color: Color(0xff22C55E),
            //             isHaveCircle: true,
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),

            //   leading: CircleAvatar(
            //     radius: 40,

            //     backgroundImage: CachedNetworkImageProvider(testuserprofile),
            //   ),
            // ),
            child: InkWell(
              onTap: () {
                Get.to(
                  CounselorDetailScreen(
                    model: currentCounselor,
                    sectionId: sectionId,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 Leading Photo
                    CircleAvatar(
                      radius: 25, // 👈 Thoda bada kiya
                      backgroundImage: CachedNetworkImageProvider(
                        currentCounselor.profileImage,
                      ),
                      backgroundColor: primaryColor.withOpacity(0.1),
                    ),
                    const SizedBox(width: 12),

                    // 📋 Text and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Title Row (Name + Coins)'   v
                          Row(
                            children: [
                              CustomText(
                                text:
                                    currentCounselor.nickName.isNotEmpty
                                        ? currentCounselor.nickName
                                        : currentCounselor.name,

                                fontSize: FontConstants.font_16,
                                weight: FontWeightConstants.medium,
                              ),
                              const Spacer(),
                              SvgPicture.asset(
                                AppIcons.coinsvg,
                                width: 28,
                                fit: BoxFit.cover,
                                color: const Color(0xffFACC15),
                              ),
                              const SizedBox(width: 4),
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

                          const SizedBox(height: 4),

                          // 🔹 Subtitle (Category)
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
                                  final fortuneCategory = texnomyData
                                      .fortune
                                      .categories
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
                                  final fortuneTaxonomy = texnomyData
                                      .fortune
                                      .taxonomies
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
                            fontSize: FontConstants.font_12,
                            weight: FontWeightConstants.regular,
                            color: hintColor,
                          ),

                          const SizedBox(height: 2),

                          // 🔹 Description
                          currentCounselor.introduction.isNotEmpty
                              ? CustomText(
                                text: currentCounselor.introduction,
                                fontSize: FontConstants.font_13,
                                weight: FontWeightConstants.regular,
                                maxlines: 2,
                              )
                              : SizedBox.shrink(),

                          const SizedBox(height: 6),

                          // 🔹 Rating & Availability
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xffFACC15),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              CustomText(
                                text:
                                    currentCounselor.rating.toString() +
                                    "(${currentCounselor.ratingCount})",
                                fontSize: FontConstants.font_12,
                                weight: FontWeightConstants.regular,
                              ),
                              const Spacer(),
                              SubCategoryChip(
                                text: getAvailabilityText(currentCounselor),
                                color: getAvailabilityColor(currentCounselor),
                                isHaveCircle: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper function to get the primary consultation method price
String getPrimaryConsultationPrice(CounsultationMethod model) {
  final consultationMethod = model;

  // Priority order: Video Call > Voice Call > Chat
  if (consultationMethod.videoCallAvailable == 1 &&
      consultationMethod.videoCallCoin.isNotEmpty) {
    return consultationMethod.videoCallCoin;
  } else if (consultationMethod.voiceCallAvailable == 1 &&
      consultationMethod.voiceCallCoin.isNotEmpty) {
    return consultationMethod.voiceCallCoin;
  } else if (consultationMethod.chatAvailable == 1 &&
      consultationMethod.chatCoin.isNotEmpty) {
    return consultationMethod.chatCoin;
  }

  // Fallback to default or first available price
  return consultationMethod.videoCallCoin.isNotEmpty
      ? consultationMethod.videoCallCoin
      : consultationMethod.voiceCallCoin.isNotEmpty
      ? consultationMethod.voiceCallCoin
      : consultationMethod.chatCoin.isNotEmpty
      ? consultationMethod.chatCoin
      : "0";
}
