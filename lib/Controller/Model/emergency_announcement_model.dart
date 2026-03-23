class EmergencyAnnouncementModel {
  final bool success;
  final String message;
  final List<EmergencyAnnouncement> data;

  EmergencyAnnouncementModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory EmergencyAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return EmergencyAnnouncementModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
              ?.map((x) => EmergencyAnnouncement.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class EmergencyAnnouncement {
  final int id;
  final String title;
  final String category;
  final String content;
  final String type;
  final String startDate;
  final String endDate;
  final String exposureTarget;
  final bool topFixed;
  final String priority; // 'high', 'medium', 'low'
  final int views;
  final String status;
  final String statusLabel;
  final bool isActive;
  final bool isScheduled;
  final bool isEnded;
  final String createdAt;

  EmergencyAnnouncement({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.exposureTarget,
    required this.topFixed,
    required this.priority,
    required this.views,
    required this.status,
    required this.statusLabel,
    required this.isActive,
    required this.isScheduled,
    required this.isEnded,
    required this.createdAt,
  });

  factory EmergencyAnnouncement.fromJson(Map<String, dynamic> json) {
    return EmergencyAnnouncement(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      exposureTarget: json['exposure_target']?.toString() ?? '',
      topFixed: json['top_fixed'] == true,
      priority: json['priority']?.toString() ?? 'low',
      views: json['views'] is int ? json['views'] as int : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      isActive: json['is_active'] == true,
      isScheduled: json['is_scheduled'] == true,
      isEnded: json['is_ended'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  /// Check if the announcement is currently active based on date range
  bool get isCurrentlyActive {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return now.isAfter(start.subtract(Duration(seconds: 1))) &&
          now.isBefore(end.add(Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  /// Get priority level as enum for easier comparison
  PriorityLevel get priorityLevel {
    switch (priority.toLowerCase()) {
      case 'high':
        return PriorityLevel.high;
      case 'medium':
        return PriorityLevel.medium;
      case 'low':
        return PriorityLevel.low;
      default:
        return PriorityLevel.low;
    }
  }
}

enum PriorityLevel {
  high,
  medium,
  low,
}

