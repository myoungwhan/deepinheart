import 'dart:convert';
import 'package:deepinheart/Controller/Model/appointment_review_model.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ReviewDetailDialog extends StatefulWidget {
  final int appointmentId;

  const ReviewDetailDialog({Key? key, required this.appointmentId})
    : super(key: key);

  @override
  State<ReviewDetailDialog> createState() => _ReviewDetailDialogState();
}

class _ReviewDetailDialogState extends State<ReviewDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  AppointmentReview? _review;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchReviewDetails();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviewDetails() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.COUNSELOR_REVIEWS}?appointment_id=${widget.appointmentId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reviewResponse = AppointmentReviewResponse.fromJson(data);

        if (reviewResponse.success && reviewResponse.data.reviews.isNotEmpty) {
          setState(() {
            _review = reviewResponse.data.firstReview;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'No review found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load review';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading review';
        _isLoading = false;
      });
      debugPrint('Error fetching review: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 400.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_review == null) {
      return _buildErrorState();
    }

    return _buildReviewContent();
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(40.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
          SizedBox(height: 16.h),
          CustomText(
            text: 'Loading review...',
            fontSize: FontConstants.font_14,
            color: lightGREY,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 48.w,
          ),
          SizedBox(height: 12.h),
          CustomText(
            text: _error ?? 'Something went wrong',
            fontSize: FontConstants.font_14,
            color: lightGREY,
          ),
          SizedBox(height: 20.h),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText(
              text: 'Close',
              fontSize: FontConstants.font_14,
              color: primaryColor,
              weight: FontWeightConstants.semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          _buildHeader(),

          // Rating section
          _buildRatingSection(),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Divider(color: borderColor, height: 1),
          ),

          // Review content
          _buildReviewSection(),

          // Counselor reply (if exists)
          if (_review!.hasReply) _buildCounselorReply(),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 16.w, 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Your Review',
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: const Color(0xFF111726),
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: _review!.formattedDate,
                  fontSize: FontConstants.font_12,
                  color: lightGREY,
                ),
              ],
            ),
          ),
          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.grey.shade600,
                  size: 20.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amber.shade200, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Star rating display
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final isFilled = index < _review!.rating;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? Colors.amber : Colors.amber.shade300,
                  size: 32.w,
                ),
              );
            }),
          ),
          SizedBox(width: 12.w),
          // Rating text
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomText(
              text: '${_review!.rating}.0',
              fontSize: FontConstants.font_20,
              weight: FontWeightConstants.bold,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: primaryColor.withOpacity(0.5),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              CustomText(
                text: 'Your Feedback',
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.semiBold,
                color: const Color(0xFF111726),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: borderColor),
            ),
            child: CustomText(
              text: _review!.content,
              fontSize: FontConstants.font_14,
              color: const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounselorReply() {
    final replyDate = _review!.counselorReplyDate;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.reply_rounded,
                  color: primaryColor,
                  size: 16.w,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Counselor\'s Response',
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.semiBold,
                      color: const Color(0xFF111726),
                    ),
                    if (replyDate != null) ...[
                      SizedBox(height: 2.h),
                      CustomText(
                        text: replyDate,
                        fontSize: FontConstants.font_11,
                        color: lightGREY,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.05),
                  primaryColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: CustomText(
              text: _review!.counselorReply ?? '',
              fontSize: FontConstants.font_14,
              color: const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
