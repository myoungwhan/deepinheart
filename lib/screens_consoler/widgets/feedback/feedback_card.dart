import 'package:deepinheart/Controller/color_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:get/get.dart';
import '../../models/feedback_data.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackData feedback;
  final VoidCallback? onReplyTap;
  final int index;

  FeedbackCard({
    Key? key,
    required this.feedback,
    this.onReplyTap,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return oldDesign();
  }

  Container oldDesign() {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar, name, rating, and time
          Row(
            children: [
              // Avatar
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: ColorService.getColor(index).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomText(
                    text: feedback.clientInitial,
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.black,
                    color: ColorService.getColor(index),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: feedback.clientName,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: Color(0xFF111726),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        MyRatingView(
                          initialRating: feedback.rating,
                          isAllowRating: false,
                          onRatingUpdate: (rating) {},
                        ),
                        SizedBox(width: 8.w),
                        CustomText(
                          text: feedback.timeAgo,
                          fontSize: FontConstants.font_12,
                          weight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          UIHelper.verticalSpaceSm,

          // Review text
          feedback.reviewText.isNotEmpty
              ? CustomText(
                text: feedback.reviewText,
                fontSize: FontConstants.font_14,

                color: Color(0xFF374151),
                maxlines: 3,
              )
              : Container(),

          // Counselor reply (show only latest)
          if (feedback.counselorReply != null) ...[
            UIHelper.verticalSpaceSm,
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: feedback.counselorReply!,
                    fontSize: FontConstants.font_14,
                    weight: FontWeight.w400,
                    color: Color(0xFF374151),
                  ),
                  SizedBox(height: 5.h),
                  CustomText(
                    text: 'Counselor Reply'.tr,
                    fontSize: FontConstants.font_12,
                    weight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ],

          // Reply button (if no counselor reply)
          if (feedback.counselorReply == null) ...[
            UIHelper.verticalSpaceSm,
            GestureDetector(
              onTap: onReplyTap,
              child: CustomText(
                text: 'Write Reply'.tr,
                fontSize: FontConstants.font_12,
                color: primaryColorConsulor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
