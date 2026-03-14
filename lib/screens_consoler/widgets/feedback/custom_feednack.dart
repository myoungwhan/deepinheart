import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../models/feedback_data.dart';
import 'rating_pie_chart.dart';
import 'feedback_card.dart';
import 'reply_dialog.dart';
import 'all_feedback_screen.dart';

class CustomFeednack extends StatefulWidget {
  const CustomFeednack({Key? key}) : super(key: key);

  @override
  _CustomFeednackState createState() => _CustomFeednackState();
}

class _CustomFeednackState extends State<CustomFeednack> {
  List<FeedbackData> feedbacks = [];
  RatingDistribution? distribution;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  Future<void> _loadFeedbackData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get counselor ID from user model
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final counselorId = userViewModel.userModel?.data.id;

      if (counselorId != null) {
        final serviceProvider = Provider.of<ServiceProvider>(
          context,
          listen: false,
        );

        final reviewsData = await serviceProvider.fetchCounselorReviews(
          counselorId,
        );

        if (reviewsData != null && mounted) {
          setState(() {
            // Convert API data to FeedbackData
            feedbacks = FeedbackData.fromCounselorReviewList(
              reviewsData.reviews,
            );
            // Get rating distribution for pie chart
            distribution = RatingDistribution.fromApiData(
              reviewsData.ratingDistribution,
            );
            isLoading = false;
          });
        } else {
          // Fallback to sample data if API fails
          setState(() {
            // feedbacks = FeedbackData.getSampleData();
            distribution = RatingDistribution.fromFeedbackList(feedbacks);
            isLoading = false;
          });
        }
      } else {
        // Fallback to sample data if no counselor ID
        setState(() {
        //  feedbacks = FeedbackData.getSampleData();
          distribution = RatingDistribution.fromFeedbackList(feedbacks);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feedback data: $e');
      // Fallback to sample data on error
      setState(() {
     //   feedbacks = FeedbackData.getSampleData();
        distribution = RatingDistribution.fromFeedbackList(feedbacks);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: borderColor),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SizedBox(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UIHelper.verticalSpaceSm,
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomText(
                      align: TextAlign.start,
                      text: 'Customer Feedback'.tr,
                      fontSize: FontConstants.font_18,
                      height: 1.3,
                      weight: FontWeightConstants.semiBold,
                      color: Color(0xFF111726),
                    ),
                  ),
                  feedbacks.length > 3
                      ? GestureDetector(
                        onTap: () => _openAllFeedbacks(),
                        child: CustomText(
                          text: "View All".tr,
                          color: primaryColorConsulor,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
            Divider(thickness: 1, color: borderColor),
            UIHelper.verticalSpaceSm,

            // Loading state
            if (isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20.h),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Pie Chart
              if (distribution != null && distribution!.total > 0)
                RatingPieChart(distribution: distribution!),

              // Empty state
              if (feedbacks.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: CustomText(
                      text: 'No feedback yet'.tr,
                      fontSize: FontConstants.font_14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),

              // Feedback List
              if (feedbacks.isNotEmpty) ...[
                UIHelper.verticalSpaceSm,
                Container(
                  child: ListView.builder(
                    itemCount: feedbacks.length > 3 ? 3 : feedbacks.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final feedback = feedbacks[index];
                      return FeedbackCard(
                        feedback: feedback,
                        index: index,
                        onReplyTap: () => _handleReply(feedback),
                      );
                    },
                  ),
                ),
              ],
            ],
            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }

  void _handleReply(FeedbackData feedback) async {
    // Show reply dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReplyDialog(feedback: feedback),
    );

    // If reply was submitted successfully, update the feedback
    if (result != null && result['success'] == true) {
      final replyText = result['reply'] as String;

      // Find the feedback in the list and update it
      final index = feedbacks.indexWhere((f) => f.id == feedback.id);
      if (index != -1) {
        setState(() {
          // Update the feedback with the new reply
          feedbacks[index] = feedbacks[index].copyWithReply(replyText);
        });
      }
    }
  }

  void _openAllFeedbacks() async {
    // Navigate to all feedbacks screen and wait for result
    final result = await Get.to<List<FeedbackData>>(
      () => AllFeedbackScreen(feedbacks: feedbacks),
    );

    // If feedbacks were updated (replies added), update the local list
    if (result != null) {
      setState(() {
        feedbacks = result;
      });
    }
  }
}
