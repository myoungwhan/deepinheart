import 'dart:convert';

import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens_consoler/models/feedback_data.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ReplyDialog extends StatefulWidget {
  final FeedbackData feedback;

  const ReplyDialog({
    Key? key,
    required this.feedback,
  }) : super(key: key);

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) {
      Get.snackbar(
        'Reply Required'.tr,
        'Please enter a reply message'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null) {
        Get.snackbar(
          'Error'.tr,
          'User not authenticated'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      debugPrint('📤 Submitting reply to review: ${widget.feedback.id}');

      final response = await http.post(
        Uri.parse(ApiEndPoints.REVIEW_REPLY),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'review_feedback_id': int.parse(widget.feedback.id),
          'reply': _replyController.text.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          // Close dialog and return the reply text
          Navigator.of(context).pop({
            'success': true,
            'reply': _replyController.text.trim(),
          });

          Get.snackbar(
            '✅ Reply Sent'.tr,
            'Your reply has been submitted successfully'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'Error'.tr,
            responseData['message'] ?? 'Failed to submit reply'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error'.tr,
          responseData['message'] ?? 'Failed to submit reply'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error submitting reply: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to submit reply. Please try again.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 16,
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColorConsulor,
                      primaryColorConsulor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              color: Colors.white,
                              size: 24.w,
                            ),
                            SizedBox(width: 10.w),
                            CustomText(
                              text: "Reply to Review".tr,
                              fontSize: FontConstants.font_18,
                              weight: FontWeightConstants.bold,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Original review card
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client info
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: widget.feedback.avatarColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CustomText(
                              text: widget.feedback.clientInitial,
                              fontSize: FontConstants.font_16,
                              weight: FontWeightConstants.bold,
                              color: widget.feedback.avatarColor,
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
                                text: widget.feedback.clientName,
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.semiBold,
                                color: Color(0xFF111726),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  MyRatingView(
                                    initialRating: widget.feedback.rating,
                                    isAllowRating: false,
                                    onRatingUpdate: (rating) {},
                                  ),
                                  SizedBox(width: 8.w),
                                  CustomText(
                                    text: widget.feedback.timeAgo,
                                    fontSize: FontConstants.font_11,
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
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Colors.grey[300],
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              text: widget.feedback.reviewText,
                              fontSize: FontConstants.font_13,
                              color: Color(0xFF374151),
                              maxlines: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Reply input section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: "Your Reply".tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.semiBold,
                      color: Color(0xFF374151),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _replyController,
                        maxLines: 4,
                        maxLength: 500,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Write a thoughtful reply to your client...".tr,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.w),
                          counterStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              UIHelper.verticalSpaceMd,

              // Submit button
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorConsulor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20.w,
                              ),
                              SizedBox(width: 8.w),
                              CustomText(
                                text: "Send Reply".tr,
                                fontSize: FontConstants.font_16,
                                weight: FontWeightConstants.bold,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

