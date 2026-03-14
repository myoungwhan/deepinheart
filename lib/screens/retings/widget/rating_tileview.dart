import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class RatingTileview extends StatelessWidget {
  final bool isHorizontalCard;
  final ReviewItem? review;

  const RatingTileview({Key? key, this.isHorizontalCard = true, this.review})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use review data if provided, otherwise use default values
    final userName = review?.users.name ?? "Yoon Ji-Min";
    final userImage = review?.users.profileImage ?? testuserprofile;
    final date = review?.formattedDate ?? "23-08-2025";
    final rating = review?.rating.toDouble() ?? 5.0;
    final content =
        review?.content ??
        "Amazingly Accurate Reading of My Situation. Following the Advisor's Guidance LED to Positive Changes. I'll definitely consult Again!";

    return Card(
      color: isMainDark ? Color(0xff2C2C2E) : Colors.white,
      child: SizedBox(
        width: isHorizontalCard ? Get.width * 0.8 : Get.width,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(0),
                minLeadingWidth: 40,

                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(userImage),
                  child: Text(userName.substring(0, 1)),
                ),
                title: CustomText(
                  text: userName,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                ),
                subtitle: CustomText(
                  text: date,
                  fontSize: FontConstants.font_12,
                  weight: FontWeightConstants.regular,
                ),
                trailing: MyRatingView(
                  initialRating: rating,
                  itemSize: 18.0,

                  // isAllowRating: false,
                ),
              ),
              CustomText(
                text: content,
                maxlines: 3,
                fontSize: FontConstants.font_13,
              ),
              // UIHelper.verticalSpaceSm,

              // SubCategoryChip(text: "Love", color: Colors.green),
              // UIHelper.verticalSpaceSm,
            ],
          ),
        ),
      ),
    );
  }
}
