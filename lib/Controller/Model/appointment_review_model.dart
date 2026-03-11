/// Model for fetching review by appointment ID
class AppointmentReviewResponse {
  final bool success;
  final String message;
  final AppointmentReviewData data;

  AppointmentReviewResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AppointmentReviewResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentReviewResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: AppointmentReviewData.fromJson(json['data'] ?? {}),
    );
  }
}

class AppointmentReviewData {
  final ReviewSummary summary;
  final List<AppointmentReview> reviews;

  AppointmentReviewData({
    required this.summary,
    required this.reviews,
  });

  factory AppointmentReviewData.fromJson(Map<String, dynamic> json) {
    return AppointmentReviewData(
      summary: ReviewSummary.fromJson(json['summary'] ?? {}),
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => AppointmentReview.fromJson(r))
              .toList() ??
          [],
    );
  }

  /// Get the first review (for single appointment query)
  AppointmentReview? get firstReview =>
      reviews.isNotEmpty ? reviews.first : null;
}

class ReviewSummary {
  final double averageRating;
  final int totalReviews;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: _parseDouble(json['average_rating']),
      totalReviews: _parseInt(json['total_reviews']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

class AppointmentReview {
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
  final ReviewUser user;
  final String createdAt;

  AppointmentReview({
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
    required this.user,
    required this.createdAt,
  });

  factory AppointmentReview.fromJson(Map<String, dynamic> json) {
    return AppointmentReview(
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
      reviewReplies: (json['review_replies'] as List<dynamic>?)
              ?.map((r) => ReviewReply.fromJson(r))
              .toList() ??
          [],
      user: ReviewUser.fromJson(json['users'] ?? {}),
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Check if has counselor reply
  bool get hasReply =>
      replyStatus == 'replied' ||
      replyContent != null ||
      reviewReplies.isNotEmpty;

  /// Get counselor reply content
  String? get counselorReply {
    if (replyContent != null && replyContent!.isNotEmpty) {
      return replyContent;
    }
    if (reviewReplies.isNotEmpty) {
      return reviewReplies.first.reply;
    }
    return null;
  }

  /// Get counselor reply date
  String? get counselorReplyDate {
    if (repliedAt != null && repliedAt!.isNotEmpty) {
      try {
        final date = DateTime.parse(repliedAt!);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      } catch (e) {
        return repliedAt;
      }
    }
    if (reviewReplies.isNotEmpty) {
      return reviewReplies.first.formattedDate;
    }
    return null;
  }

  /// Get formatted date
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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

  /// Get formatted date
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return createdAt;
    }
  }
}

class ReviewUser {
  final int id;
  final String name;
  final String email;
  final String? profileImage;

  ReviewUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
    );
  }

  /// Get initial for avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Check if has profile image
  bool get hasProfileImage =>
      profileImage != null && profileImage!.isNotEmpty;
}

