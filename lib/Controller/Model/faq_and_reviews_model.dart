class FaqAndReviewsModel {
  final bool success;
  final String message;
  final FaqAndReviewsData data;

  FaqAndReviewsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FaqAndReviewsModel.fromJson(Map<String, dynamic> json) {
    return FaqAndReviewsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: FaqAndReviewsData.fromJson(json['data'] ?? {}),
    );
  }
}

class FaqAndReviewsData {
  final List<FaqItem> faqs;
  final List<ReviewItem> reviews;

  FaqAndReviewsData({
    required this.faqs,
    required this.reviews,
  });

  factory FaqAndReviewsData.fromJson(Map<String, dynamic> json) {
    return FaqAndReviewsData(
      faqs: (json['faqs'] as List<dynamic>?)
              ?.map((e) => FaqItem.fromJson(e))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class FaqItem {
  final int id;
  final String title;
  final String detail;

  FaqItem({
    required this.id,
    required this.title,
    required this.detail,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
    );
  }

  /// Returns plain text from HTML detail
  String get plainDetail {
    // Remove HTML tags
    String text = detail.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    return text.trim();
  }
}

class ReviewItem {
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
  final ReviewUser users;
  final String createdAt;

  ReviewItem({
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
    required this.users,
    required this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
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
      users: ReviewUser.fromJson(json['users'] ?? {}),
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Returns formatted date string
  String get formattedDate {
    try {
      final parts = createdAt.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
        }
      }
      return createdAt;
    } catch (e) {
      return createdAt;
    }
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
}

