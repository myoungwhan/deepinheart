import 'package:deepinheart/screens_consoler/models/feedback_data.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'feedback_card.dart';
import 'reply_dialog.dart';

class AllFeedbackScreen extends StatefulWidget {
  final List<FeedbackData> feedbacks;

  AllFeedbackScreen({Key? key, required this.feedbacks}) : super(key: key);

  @override
  _AllFeedbackScreenState createState() => _AllFeedbackScreenState();
}

class _AllFeedbackScreenState extends State<AllFeedbackScreen> {
  late List<FeedbackData> _feedbacks;

  @override
  void initState() {
    super.initState();
    // Create a copy of the feedbacks list to allow modifications
    _feedbacks = List.from(widget.feedbacks);
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
      final index = _feedbacks.indexWhere((f) => f.id == feedback.id);
      if (index != -1) {
        setState(() {
          // Update the feedback with the new reply
          _feedbacks[index] = _feedbacks[index].copyWithReply(replyText);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the updated feedbacks when going back
        Get.back(result: _feedbacks);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: _feedbacks.isEmpty ? _buildEmptyState() : _buildFeedbackList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Color(0xFF111726), size: 20.w),
        onPressed: () => Get.back(result: _feedbacks),
      ),
      title: CustomText(
        text: 'All Feedback'.tr,
        fontSize: FontConstants.font_18,
        weight: FontWeightConstants.bold,
        color: Color(0xFF111726),
      ),
      centerTitle: true,
      actions: [
        // Feedback count badge
        Container(
          margin: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: primaryColorConsulor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: CustomText(
                text: '${_feedbacks.length} ${"Reviews".tr}',
                fontSize: FontConstants.font_12,
                weight: FontWeightConstants.semiBold,
                color: primaryColorConsulor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80.w, color: Colors.grey[300]),
          UIHelper.verticalSpaceMd,
          CustomText(
            text: 'No feedback yet'.tr,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
            color: Colors.grey[500],
          ),
          UIHelper.verticalSpaceSm,
          CustomText(
            text: 'Your client reviews will appear here'.tr,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.regular,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Optionally implement refresh functionality
        await Future.delayed(Duration(milliseconds: 500));
      },
      color: primaryColorConsulor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final feedback = _feedbacks[index];
          return FeedbackCard(
            feedback: feedback,
            index: index,
            onReplyTap: () => _handleReply(feedback),
          );
        },
      ),
    );
  }
}
