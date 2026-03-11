class InquiryModel {
  final bool success;
  final String message;
  final List<Inquiry> data;

  InquiryModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((x) => Inquiry.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class Inquiry {
  final int id;
  final String inquiryType;
  final String title;
  final String detail;
  final String? attachment;
  final bool isUrgent;
  final String status;
  final String? response;
  final String? respondedAt;
  final String createdAt;
  final String updatedAt;

  Inquiry({
    required this.id,
    required this.inquiryType,
    required this.title,
    required this.detail,
    this.attachment,
    required this.isUrgent,
    required this.status,
    this.response,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] ?? 0,
      inquiryType: json['inquiry_type'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      attachment: json['attachment'],
      isUrgent: json['is_urgent'] == true || json['is_urgent'] == 1,
      status: json['status'] ?? 'pending',
      response: json['response'],
      respondedAt: json['responded_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String get inquiryTypeLabel {
    switch (inquiryType.toLowerCase()) {
      case 'general':
        return 'General';
      case 'technical':
        return 'Technical';
      case 'billing':
        return 'Billing';
      case 'complaint':
        return 'Complaint';
      default:
        return inquiryType;
    }
  }
}

