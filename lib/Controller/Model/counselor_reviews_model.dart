import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';

class CounselorReviewsModel {
  final bool success;
  final String message;
  final CounselorReviewsData data;

  CounselorReviewsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CounselorReviewsModel.fromJson(Map<String, dynamic> json) {
    return CounselorReviewsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CounselorReviewsData.fromJson(json['data'] ?? {}),
    );
  }
}

class CounselorReviewsData {
  final ReviewSummary summary;
  final List<CounselorReview> reviews;

  CounselorReviewsData({required this.summary, required this.reviews});

  factory CounselorReviewsData.fromJson(Map<String, dynamic> json) {
    return CounselorReviewsData(
      summary: ReviewSummary.fromJson(json['summary'] ?? {}),
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((e) => CounselorReview.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Calculate rating distribution for pie chart
  RatingDistributionData get ratingDistribution {
    int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;

    for (var review in reviews) {
      switch (review.rating) {
        case 5:
          fiveStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 1:
          oneStar++;
          break;
      }
    }

    return RatingDistributionData(
      fiveStar: fiveStar,
      fourStar: fourStar,
      threeStar: threeStar,
      twoStar: twoStar,
      oneStar: oneStar,
    );
  }
}

class ReviewSummary {
  final String averageRating;
  final int totalReviews;

  ReviewSummary({required this.averageRating, required this.totalReviews});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: json['average_rating']?.toString() ?? '0',
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}

class ReviewReply {
  final int id;
  final int reviewFeedbackId;
  final int userId;
  final String reply;
  final String createdAt;

  ReviewReply({
    required this.id,
    required this.reviewFeedbackId,
    required this.userId,
    required this.reply,
    required this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      id: json['id'] ?? 0,
      reviewFeedbackId: json['review_feed_back_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      reply: json['reply'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CounselorReview {
  final int id;
  final int counselorId;
  final int userId;
  final int appointmentId;
  final int rating;
  final String content;
  final String replyStatus;
  final String? replyContent;
  final String? repliedAt;
  final bool isReported;
  final String? reportReason;
  final String? reportedAt;
  final List<ReviewReply> reviewReplies;
  final ReviewUser users;
  final String createdAt;

  CounselorReview({
    required this.id,
    required this.counselorId,
    required this.userId,
    required this.appointmentId,
    required this.rating,
    required this.content,
    required this.replyStatus,
    this.replyContent,
    this.repliedAt,
    required this.isReported,
    this.reportReason,
    this.reportedAt,
    required this.reviewReplies,
    required this.users,
    required this.createdAt,
  });

  factory CounselorReview.fromJson(Map<String, dynamic> json) {
    return CounselorReview(
      id: json['id'] ?? 0,
      counselorId: json['counselor_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      appointmentId: json['appointment_id'] ?? 0,
      rating: json['rating'] ?? 0,
      content: json['content'] ?? '',
      replyStatus: json['reply_status'] ?? 'not_replied',
      replyContent: json['reply_content'],
      repliedAt: json['replied_at'],
      isReported: json['is_reported'] ?? false,
      reportReason: json['report_reason'],
      reportedAt: json['reported_at'],
      reviewReplies:
          (json['review_replies'] as List<dynamic>?)
              ?.map((e) => ReviewReply.fromJson(e))
              .toList() ??
          [],
      users: ReviewUser.fromJson(json['users'] ?? {}),
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Get time ago string
  String get timeAgo {
    try {
      final parts = createdAt.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          final reviewTime = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          final now = DateTime.now();
          final difference = now.difference(reviewTime);

          if (difference.inDays > 0) {
            return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
          } else if (difference.inHours > 0) {
            return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
          } else if (difference.inMinutes > 0) {
            return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
          } else {
            return 'Just now';
          }
        }
      }
      return createdAt;
    } catch (e) {
      return createdAt;
    }
  }

  /// Get avatar color based on rating
  Color get avatarColor {
    if (rating >= 5) return primaryColorConsulor;
    if (rating >= 4) return Color(0xFF16A24A);
    if (rating >= 3) return Color(0xFFF59E0B);
    if (rating >= 2) return Color(0xFFEF4444);
    return Color(0xFF8B5CF6);
  }
}

class ReviewUser {
  final int id;
  final String name;
  final String email;
  final String profileImage;

  ReviewUser({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'] ?? '',
    );
  }

  /// Get client initial from name
  String get initial {
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class RatingDistributionData {
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  RatingDistributionData({
    required this.fiveStar,
    required this.fourStar,
    required this.threeStar,
    required this.twoStar,
    required this.oneStar,
  });

  int get total => fiveStar + fourStar + threeStar + twoStar + oneStar;

  double get fiveStarPercentage => total > 0 ? (fiveStar / total) * 100 : 0;
  double get fourStarPercentage => total > 0 ? (fourStar / total) * 100 : 0;
  double get threeStarPercentage => total > 0 ? (threeStar / total) * 100 : 0;
  double get twoStarPercentage => total > 0 ? (twoStar / total) * 100 : 0;
  double get oneStarPercentage => total > 0 ? (oneStar / total) * 100 : 0;
}
