import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:deepinheart/Controller/Model/service_category_model.dart';
import 'package:deepinheart/Controller/Model/sub_category_model.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomBannerView extends StatelessWidget {
  final BannerModel bannerModel;

  // Constructor to accept BannerModel
  CustomBannerView({required this.bannerModel});

  // Function to launch the external URL
  Future<void> _launchURL() async {
    final Uri _url = Uri.parse(bannerModel.externalLink);
    if (await canLaunch(_url.toString())) {
      await launch(_url.toString());
    } else {
      throw 'Could not launch ${bannerModel.externalLink}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(15),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.00),
          end: Alignment(1.00, 0.00),
          colors: [const Color(0xFF246595), const Color(0xFF60A5FA)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9.33),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2.33,
            offset: Offset(0, 1.17),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Text (Dynamic from BannerModel)
                    CustomText(
                      text: bannerModel.bannerName,
                      fontSize: FontConstants.font_18,
                      weight: FontWeightConstants.medium,
                      color: Colors.white,
                    ),
                    UIHelper.verticalSpaceMd,

                    // Description Text (Dynamic from BannerModel)
                    CustomText(
                      text: bannerModel.couponDescription,
                      fontSize: FontConstants.font_15,
                      weight: FontWeightConstants.regular,
                      color: Colors.white.withAlpha(200),
                    ),
                    UIHelper.verticalSpaceMd,

                    // Action Button (Dynamic from BannerModel)
                    SizedBox(
                      width: 150,
                      height: 40,
                      child: CustomButton(
                        () =>
                            bannerModel.buttonClickAction != null
                                ? bannerModel.buttonClickAction!()
                                : _launchURL(), // Call _launchURL when the button is clicked
                        text: bannerModel.buttonText,
                        color: whiteColor,
                        textcolor: primaryColor,
                        fsize: FontConstants.font_16,
                        weight: FontWeightConstants.medium,
                      ),
                    ),
                    UIHelper.verticalSpaceSm,
                  ],
                ),
              ),
              UIHelper.horizontalSpaceMd,

              // Image/Icon (If Image URL is provided, use it)
              if (bannerModel.imageUrl.isNotEmpty)
                Image.network(
                  bannerModel.imageUrl,
                  width: 80,
                  fit: BoxFit.cover,
                )
              else if (bannerModel.isShowCoinIcon)
                SvgPicture.asset(
                  AppIcons
                      .coinsvg, // Default fallback image or icon (can be changed)
                  width: 80,
                  color: orangeColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
