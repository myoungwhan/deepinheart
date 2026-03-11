import 'dart:convert';

import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// A simplified rating dialog for video/voice calls
/// that doesn't require a full Appointment object
class CallRatingDialog extends StatefulWidget {
  final int appointmentId;
  final int counselorId;
  final String counselorName;
  final String? counselorImage;
  final Duration callDuration;

  const CallRatingDialog({
    Key? key,
    required this.appointmentId,
    required this.counselorId,
    required this.counselorName,
    this.counselorImage,
    required this.callDuration,
  }) : super(key: key);

  @override
  State<CallRatingDialog> createState() => _CallRatingDialogState();
}

class _CallRatingDialogState extends State<CallRatingDialog>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
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
    _reviewController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      Get.snackbar(
        'Rating Required'.tr,
        'Please select a rating before submitting'.tr,
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
      final userId = userViewModel.userModel?.data.id;

      if (token == null || userId == null) {
        Get.snackbar(
          'Error'.tr,
          'User not authenticated'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiEndPoints.BASE_URL}review-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'counselor_id': widget.counselorId,
          'user_id': userId,
          'appointment_id': widget.appointmentId,
          'rating': _selectedRating,
          'content': _reviewController.text.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);
      print(responseData.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          Navigator.of(
            context,
          ).pop({'success': true, 'rating': _selectedRating});

          Get.snackbar(
            '🎉 Thank You!'.tr,
            'Your review has been submitted successfully'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        } else {
          // Get.snackbar(
          //   'Error'.tr,
          //   responseData['message'] ?? 'Failed to submit review'.tr,
          //   snackPosition: SnackPosition.TOP,
          //   backgroundColor: Colors.red,
          //   colorText: Colors.white,
          // );
          Get.back();
        }
      } else {
        // Get.snackbar(
        //   'Error'.tr,
        //   responseData['message'] ?? 'Failed to submit review'.tr,
        //   snackPosition: SnackPosition.TOP,
        //   backgroundColor: Colors.red,
        //   colorText: Colors.white,
        // );
        Get.back();
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      // Get.snackbar(
      //   'Error'.tr,
      //   'Failed to submit review. Please try again.'.tr,
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
      Get.back();
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor:
            isDarkMode ? theme.dialogBackgroundColor : Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 16,
        child: Container(
          width: Get.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            color: isDarkMode ? theme.dialogBackgroundColor : Colors.white,
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
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
                        CustomText(
                          text: "Rate Your Session".tr,
                          fontSize: FontConstants.font_18,
                          weight: FontWeightConstants.bold,
                          color: Colors.white,
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
                    UIHelper.verticalSpaceMd,

                    // Counselor info
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30.r,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage:
                                widget.counselorImage != null
                                    ? NetworkImage(widget.counselorImage!)
                                    : null,
                            child:
                                widget.counselorImage == null
                                    ? Icon(
                                      Icons.person,
                                      size: 30.w,
                                      color: Colors.white,
                                    )
                                    : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: widget.counselorName,
                                fontSize: FontConstants.font_16,
                                weight: FontWeightConstants.bold,
                                color: Colors.white,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14.w,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  SizedBox(width: 4.w),
                                  CustomText(
                                    text:
                                        "${"Call Duration:".tr} ${_formatDuration(widget.callDuration)}",
                                    fontSize: FontConstants.font_12,
                                    weight: FontWeightConstants.regular,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rating content
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    // Star rating
                    CustomText(
                      text: "How was your experience?".tr,
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.medium,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    UIHelper.verticalSpaceSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.all(8.w),
                            child: Icon(
                              index < _selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color:
                                  index < _selectedRating
                                      ? Colors.amber
                                      : Colors.grey[400],
                              size: 40.w,
                            ),
                          ),
                        );
                      }),
                    ),
                    UIHelper.verticalSpaceSm,

                    // Rating text
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Container(
                        key: ValueKey(_selectedRating),
                        child: CustomText(
                          text: _getRatingText(),
                          fontSize: FontConstants.font_16,
                          weight: FontWeightConstants.bold,
                          color: _getRatingColor(),
                        ),
                      ),
                    ),
                    UIHelper.verticalSpaceMd,

                    // Review text field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white10 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color:
                              isDarkMode ? Colors.white24 : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _reviewController,
                        maxLines: 3,
                        maxLength: 500,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Share your experience... (optional)".tr,
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.w),
                          counterStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                    UIHelper.verticalSpaceMd,

                    // Buttons row
                    Row(
                      children: [
                        // Skip button
                        Expanded(
                          child: SizedBox(
                            height: 50.h,
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      isDarkMode
                                          ? Colors.white38
                                          : Colors.grey[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: CustomText(
                                text: "Skip".tr,
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.medium,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Submit button
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitReview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child:
                                  _isSubmitting
                                      ? SizedBox(
                                        width: 24.w,
                                        height: 24.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 18.w,
                                          ),
                                          SizedBox(width: 8.w),
                                          CustomText(
                                            text: "Submit".tr,
                                            fontSize: FontConstants.font_14,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_selectedRating) {
      case 1:
        return "😞 Poor".tr;
      case 2:
        return "😐 Fair".tr;
      case 3:
        return "🙂 Good".tr;
      case 4:
        return "😊 Very Good".tr;
      case 5:
        return "🤩 Excellent!".tr;
      default:
        return "Tap to rate".tr;
    }
  }

  Color _getRatingColor() {
    switch (_selectedRating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
