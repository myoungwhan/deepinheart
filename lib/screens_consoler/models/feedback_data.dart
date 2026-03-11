import 'package:deepinheart/Controller/Model/counselor_reviews_model.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';

class FeedbackData {
  final String id;
  final String clientName;
  final String clientInitial;
  final double rating;
  final String reviewText;
  final DateTime timestamp;
  String? counselorReply; // Made mutable to update after reply
  final List<String> counselorReplies; // All replies from review_replies
  final Color avatarColor;
  final String? clientImage;

  FeedbackData({
    required this.id,
    required this.clientName,
    required this.clientInitial,
    required this.rating,
    required this.reviewText,
    required this.timestamp,
    this.counselorReply,
    this.counselorReplies = const [],
    required this.avatarColor,
    this.clientImage,
  });

  /// Create a copy with updated counselor reply
  FeedbackData copyWithReply(String reply) {
    return FeedbackData(
      id: id,
      clientName: clientName,
      clientInitial: clientInitial,
      rating: rating,
      reviewText: reviewText,
      timestamp: timestamp,
      counselorReply: reply,
      counselorReplies: [...counselorReplies, reply],
      avatarColor: avatarColor,
      clientImage: clientImage,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  /// Create FeedbackData from CounselorReview API model
  factory FeedbackData.fromCounselorReview(CounselorReview review) {
    // Parse the timestamp
    DateTime timestamp;
    try {
      final parts = review.createdAt.split(' ');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length >= 2) {
          timestamp = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );
        } else {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Extract all replies from review_replies array
    final List<String> replies =
        review.reviewReplies
            .map((reply) => reply.reply)
            .where((reply) => reply.isNotEmpty)
            .toList();

    // Use the latest reply as counselorReply for backward compatibility
    final String? latestReply =
        replies.isNotEmpty ? replies.last : review.replyContent;

    return FeedbackData(
      id: review.id.toString(),
      clientName: review.users.name,
      clientInitial: review.users.initial,
      rating: review.rating.toDouble(),
      reviewText: review.content,
      timestamp: timestamp,
      counselorReply: latestReply,
      counselorReplies: replies,
      avatarColor: review.avatarColor,
      clientImage: review.users.profileImage,
    );
  }

  /// Convert list of CounselorReview to list of FeedbackData
  static List<FeedbackData> fromCounselorReviewList(
    List<CounselorReview> reviews,
  ) {
    return reviews
        .map((review) => FeedbackData.fromCounselorReview(review))
        .toList();
  }

  static List<FeedbackData> getSampleData() {
    return [
      FeedbackData(
        id: '1',
        clientName: 'Emily Johnson',
        clientInitial: 'E',
        rating: 5.0,
        reviewText:
            'Really helpful session! Thank you for your kind and professional guidance.',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        avatarColor: primaryColorConsulor,
      ),
      FeedbackData(
        id: '2',
        clientName: 'Michael Chen',
        clientInitial: 'M',
        rating: 4.5,
        reviewText:
            'Would have liked a longer session, but still very helpful. Thank you!',
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        counselorReply:
            'Thank you for your valuable feedback. I\'ll make sure to provide more comprehensive sessions next time.',
        avatarColor: Color(0xFF16A24A),
      ),
      FeedbackData(
        id: '3',
        clientName: 'Sarah Williams',
        clientInitial: 'S',
        rating: 4.0,
        reviewText:
            'Great session, very insightful and helpful for my situation.',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        avatarColor: Color(0xFF8B5CF6),
      ),
      FeedbackData(
        id: '4',
        clientName: 'David Martinez',
        clientInitial: 'D',
        rating: 3.0,
        reviewText: 'Session was okay, but I expected more detailed guidance.',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        avatarColor: Color(0xFFF59E0B),
      ),
      FeedbackData(
        id: '5',
        clientName: 'Jessica Brown',
        clientInitial: 'J',
        rating: 2.0,
        reviewText:
            'The session didn\'t meet my expectations. Need more personalized approach.',
        timestamp: DateTime.now().subtract(Duration(days: 3)),
        avatarColor: Color(0xFFEF4444),
      ),
    ];
  }
}

class RatingDistribution {
  final int fiveStar;
  final int fourStar;
  final int threeStar;
  final int twoStar;
  final int oneStar;

  RatingDistribution({
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

  static RatingDistribution fromFeedbackList(List<FeedbackData> feedbacks) {
    int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;

    for (var feedback in feedbacks) {
      if (feedback.rating >= 4.5) {
        fiveStar++;
      } else if (feedback.rating >= 3.5) {
        fourStar++;
      } else if (feedback.rating >= 2.5) {
        threeStar++;
      } else if (feedback.rating >= 1.5) {
        twoStar++;
      } else {
        oneStar++;
      }
    }

    return RatingDistribution(
      fiveStar: fiveStar,
      fourStar: fourStar,
      threeStar: threeStar,
      twoStar: twoStar,
      oneStar: oneStar,
    );
  }

  /// Create from API RatingDistributionData
  factory RatingDistribution.fromApiData(RatingDistributionData data) {
    return RatingDistribution(
      fiveStar: data.fiveStar,
      fourStar: data.fourStar,
      threeStar: data.threeStar,
      twoStar: data.twoStar,
      oneStar: data.oneStar,
    );
  }
}
