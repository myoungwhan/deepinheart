import 'package:deepinheart/Controller/Model/experience_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/color_service.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ProfileTabView extends StatelessWidget {
  ServiceModel? serviceModel;
  ProfileTabView({Key? key, required this.serviceModel}) : super(key: key);

  List<ExperienceModel> listExperiences = [
    ExperienceModel(
      title: 'Seoul National University Hospital',
      description: 'Clinical Psychologist (2018-Present)',
    ),
    ExperienceModel(
      title: 'Mind Counseling Center',
      description: 'Senior Counselor (2015-2018)',
    ),
    ExperienceModel(
      title: 'National Center for Mental Health',
      description: 'Clinical Psychologist (2012-2015)',
    ),
  ];

  List<ExperienceModel> listCertificate = [
    ExperienceModel(
      title: 'Level 1 Clinical Psychologist',
      description: 'Korean Clinical Psychology Association',
    ),
    ExperienceModel(
      title: 'Level 1 Mental Health Clinical Psychologist',
      description: 'Ministry of Health and Welfare',
    ),
    ExperienceModel(
      title: 'Cognitive Behavioral Therapy (CBT) Specialist',
      description: 'Korean Association of CBT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Consumer<ServiceProvider>(
        builder: (context, pr, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UIHelper.verticalSpaceSm,

              CustomTitleWithButton(title: "Specialties".tr),
              UIHelper.verticalSpaceSm,
              Visibility(
                visible: true,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),

                    child:
                        serviceModel != null
                            ? Builder(
                              builder: (context) {
                                // Collect all items first
                                final List<Widget> allItems = [
                                  // Add categories first
                                  ...serviceModel!.categories
                                      .map(
                                        (category) => SubCategoryChip(
                                          text:
                                              category.nameTranslated ??
                                              category.name,
                                          color: ColorService.getColor(
                                            serviceModel!.categories.indexOf(
                                              category,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),

                                  // Add taxonomies items
                                  ...serviceModel!.taxonomies
                                      .expand(
                                        (e) =>
                                            e.items
                                                .map(
                                                  (e1) => SubCategoryChip(
                                                    text:
                                                        e1.nameTranslated ??
                                                        e1.name,
                                                    //index vise fetch color from ColorService by index of e
                                                    color:
                                                        ColorService.getColor(
                                                          e.items.indexOf(e1),
                                                        ),
                                                  ),
                                                )
                                                .toList(),
                                      )
                                      .toList(),
                                ];

                                // Split items into 2 rows
                                final int totalItems = allItems.length;
                                final int itemsPerRow = (totalItems / 2).ceil();
                                final List<Widget> row1 =
                                    allItems.take(itemsPerRow).toList();
                                final List<Widget> row2 =
                                    allItems.skip(itemsPerRow).toList();

                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 70.h, // 2 lines height
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // First row
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              row1
                                                  .map(
                                                    (item) => Padding(
                                                      padding: EdgeInsets.only(
                                                        right: 5.r,
                                                        bottom: 5.r,
                                                      ),
                                                      child: item,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                        // Second row
                                        if (row2.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children:
                                                row2
                                                    .map(
                                                      (item) => Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              right: 5.r,
                                                            ),
                                                        child: item,
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                            : Container(),
                  ),
                ),
              ),

              serviceModel != null
                  ? Visibility(
                    visible: false,
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children:
                          serviceModel!.specialities.map((e) {
                            return SubCategoryChip(
                              text: e.name,
                              color: ColorService.getColor(
                                serviceModel!.specialities.indexOf(e),
                              ),
                            );
                          }).toList(),
                    ),
                  )
                  : Container(),
              UIHelper.verticalSpaceMd,

              // Experience Section
              if (serviceModel != null &&
                  serviceModel!.profileInformation.experience.isNotEmpty) ...[
                CustomTitleWithButton(title: "Experience".tr),
                UIHelper.verticalSpaceSm,
                Builder(
                  builder: (context) {
                    return _buildInfoCard(
                      icon: AppIcons.orgsvg,
                      content: serviceModel!.profileInformation.experience,
                    );
                  },
                ),
                UIHelper.verticalSpaceMd,
              ],

              // Certifications Section
              if (serviceModel != null &&
                  serviceModel!.profileInformation.certificate != null &&
                  serviceModel!.profileInformation.certificate
                      .toString()
                      .isNotEmpty) ...[
                CustomTitleWithButton(title: "Certifications".tr),
                UIHelper.verticalSpaceSm,
                Builder(
                  builder: (context) {
                    return _buildInfoCard(
                      icon: AppIcons.certificatesvg,
                      content:
                          serviceModel!.profileInformation.certificate
                              .toString(),
                    );
                  },
                ),
                UIHelper.verticalSpaceMd,
              ],

              // Education Section
              if (serviceModel != null &&
                  serviceModel!.profileInformation.education != null &&
                  serviceModel!.profileInformation.education
                      .toString()
                      .isNotEmpty) ...[
                CustomTitleWithButton(title: "Education".tr),
                UIHelper.verticalSpaceSm,
                Builder(
                  builder: (context) {
                    return _buildInfoCard(
                      icon: AppIcons.orgsvg,
                      content:
                          serviceModel!.profileInformation.education.toString(),
                    );
                  },
                ),
                UIHelper.verticalSpaceMd,
              ],

              // Counseling Approach Section
              CustomTitleWithButton(title: "Counseling Approach".tr),

              UIHelper.verticalSpaceSm,
              serviceModel != null &&
                      serviceModel!.profileInformation.training != null &&
                      serviceModel!.profileInformation.training
                          .toString()
                          .isNotEmpty
                  ? FutureBuilder(
                    future: translationService.translate(
                      serviceModel!.profileInformation.training.toString(),
                    ),
                    builder: (context, asyncSnapshot) {
                      return asyncSnapshot.data != null &&
                              asyncSnapshot.data!.isNotEmpty
                          ? _buildInfoCard(
                            icon: AppIcons.certificatesvg,
                            content: asyncSnapshot.data ?? '',
                          )
                          : Container();
                    },
                  )
                  : _buildInfoCard(
                    icon: AppIcons.certificatesvg,
                    content: '''''',
                  ),
              UIHelper.verticalSpaceMd,
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String icon, required String content}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMainDark ? Color(0xff2C2C2E) : Color(0xffE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isMainDark
                      ? Colors.white.withOpacity(0.1)
                      : primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                color: isMainDark ? Colors.white : primaryColor,
                width: 20,
                height: 20,
              ),
            ),
          ),
          UIHelper.horizontalSpaceSm,
          // Content
          Expanded(
            child: Html(
              data: content,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(FontConstants.font_14),
                  color: isMainDark ? Colors.white : Color(0xff374151),
                ),
                "p": Style(
                  margin: Margins.only(bottom: 8),
                  fontSize: FontSize(FontConstants.font_14),
                ),
                "ul": Style(
                  margin: Margins.only(left: 16, bottom: 8),
                  padding: HtmlPaddings.zero,
                ),
                "li": Style(
                  margin: Margins.only(bottom: 4),
                  fontSize: FontSize(FontConstants.font_14),
                ),
                "strong": Style(fontWeight: FontWeight.w600),
              },
            ),
          ),
        ],
      ),
    );
  }

  ListTile experienceTile(
    ExperienceModel model, {
    required bool isExperiecnce,
  }) {
    return ListTile(
      minLeadingWidth: 30,
      leading: CircleAvatar(
        backgroundColor: primaryColor,
        child: Center(
          child: SvgPicture.asset(
            isExperiecnce ? AppIcons.orgsvg : AppIcons.certificatesvg,
            color: whiteColor,
          ),
        ),
      ),
      title: CustomText(
        text: model.title,
        fontSize: FontConstants.font_16,
        weight: FontWeightConstants.medium,
      ),
      subtitle: CustomText(
        text: model.description,
        fontSize: FontConstants.font_14,
        weight: FontWeightConstants.regular,
        color: Color(0xff6B7280),
      ),
    );
  }
}
