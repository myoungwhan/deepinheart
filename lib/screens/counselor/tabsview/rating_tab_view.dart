import 'package:deepinheart/Controller/Model/counselor_reviews_model.dart';
import 'package:deepinheart/Controller/Model/faq_and_reviews_model.dart'
    as faq_model;
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Views/text_styles.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/counselor/starreviews/starreviews.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/retings/widget/rating_tileview.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class RatingTabView extends StatefulWidget {
  final int counselorId;

  const RatingTabView({Key? key, required this.counselorId}) : super(key: key);

  @override
  State<RatingTabView> createState() => _RatingTabViewState();
}

class _RatingTabViewState extends State<RatingTabView> {
  CounselorReviewsData? _reviewsData;
  bool _isLoading = true;
  String? _error;
  int _sortOrder = 0; // 0 = Latest, 1 = Oldest

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final serviceProvider = Provider.of<ServiceProvider>(
        context,
        listen: false,
      );
      final reviewsData = await serviceProvider.fetchCounselorReviews(
        widget.counselorId,
      );

      if (mounted) {
        setState(() {
          _reviewsData = reviewsData;
          _isLoading = false;
          if (reviewsData == null) {
            _error = 'Failed to load reviews';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading reviews: $e';
        });
      }
    }
  }

  List<CounselorReview> get _sortedReviews {
    if (_reviewsData == null) return [];
    final reviews = List<CounselorReview>.from(_reviewsData!.reviews);
    if (_sortOrder == 0) {
      // Latest first (newest to oldest)
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Oldest first (oldest to newest)
      reviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return reviews;
  }

  List<double> _calculateRatingDistribution() {
    if (_reviewsData == null || _reviewsData!.reviews.isEmpty) {
      return [0.0, 0.0, 0.0, 0.0, 0.0];
    }

    final distribution = _reviewsData!.ratingDistribution;
    final total = distribution.total;

    if (total == 0) {
      return [0.0, 0.0, 0.0, 0.0, 0.0];
    }

    return [
      distribution.fiveStar / total,
      distribution.fourStar / total,
      distribution.threeStar / total,
      distribution.twoStar / total,
      distribution.oneStar / total,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      child: SingleChildScrollView(
        child: Column(
          children: [
            UIHelper.verticalSpaceL,

            Row(
              children: [
                Expanded(
                  child: CustomTitleWithButton(title: "Counseling Reviews".tr),
                ),
                DropdownButton<int>(
                  borderRadius: BorderRadius.circular(25),
                  padding: EdgeInsets.symmetric(horizontal: 0),
                  elevation: 2,
                  value: _sortOrder,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: CustomText(text: "Latest".tr),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: CustomText(text: "Oldest".tr),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sortOrder = val;
                      });
                    }
                  },
                ),
              ],
            ),
            UIHelper.verticalSpaceMd,

            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            else if (_error != null)
              Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    CustomText(
                      text: _error!,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchReviews,
                      child: CustomText(text: "Retry".tr),
                    ),
                  ],
                ),
              )
            else if (_reviewsData == null || _reviewsData!.reviews.isEmpty)
              Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.reviews_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    CustomText(
                      text: "No reviews available yet".tr,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              )
            else ...[
              StarReviewsHorizontal(
                total: _reviewsData!.summary.totalReviews,
                starNames: ["5", "4", "3", "2", "1"],
                averageNumberTextStyle: textStyleRobotoRegular(
                  fontSize: 35.0,
                  color: isMainDark ? Colors.white : Colors.black,
                ),
                showProgressBarBorder: false,
                valueColor: primaryColor,
                progressBarBackgroundColor: Colors.grey.withOpacity(0.2),
                values: _calculateRatingDistribution(),
                showPercentage: true,
                starColor: isMainDark ? Colors.white : Colors.black,
                average:
                    double.tryParse(_reviewsData!.summary.averageRating) ?? 0.0,
              ),
              UIHelper.verticalSpaceMd,
              ListView.builder(
                itemCount: _sortedReviews.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final review = _sortedReviews[index];
                  return RatingTileview(
                    isHorizontalCard: false,
                    review: _convertToReviewItem(review),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Convert CounselorReview to ReviewItem format for RatingTileview
  faq_model.ReviewItem _convertToReviewItem(CounselorReview review) {
    return faq_model.ReviewItem(
      id: review.id,
      counselorId: review.counselorId,
      userId: review.userId,
      appointmentId: review.appointmentId,
      rating: review.rating,
      content: review.content,
      replyStatus: review.replyStatus,
      replyContent: review.replyContent,
      repliedAt: review.repliedAt,
      isReported: review.isReported,
      reportReason: review.reportReason,
      reportedAt: review.reportedAt,
      users: faq_model.ReviewUser(
        id: review.users.id,
        name: review.users.name,
        email: review.users.email,
        profileImage: review.users.profileImage,
      ),
      createdAt: review.createdAt,
    );
  }
}
