import 'package:flutter/material.dart';

class NotificationResponse {
  final bool success;
  final String message;
  final List<NotificationItem> data;

  NotificationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((x) => NotificationItem.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class NotificationItem {
  final String id;
  final NotificationData notificationData;
  final String? readAt;
  final String createdAt;
  String type;

  NotificationItem({
    required this.id,
    required this.notificationData,
    this.readAt,
    required this.createdAt,
    required this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? "",
      notificationData: NotificationData.fromJson(
        json['notification_data'] ?? {},
      ),
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
      type: json['type'] ?? '',
    );
  }

  bool get isRead => readAt != null && readAt!.isNotEmpty;

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return createdAt;
    }
  }
}

class NotificationData {
  // Consult Now request fields
  final int? userId;
  final int? counselorId;
  final int? serviceId;
  final String? message;

  // Message fields
  final int? messageId;
  final String? appointmentId;
  final int? senderId;
  final int? receiverId;

  NotificationData({
    this.userId,
    this.counselorId,
    this.serviceId,
    this.message,
    this.messageId,
    this.appointmentId,
    this.senderId,
    this.receiverId,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      userId: json['user_id'],
      counselorId: json['counselor_id'],
      serviceId: json['service_id'],
      message: json['message'],
      messageId: json['message_id'],
      appointmentId: json['appointment_id']?.toString(),
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
    );
  }

  bool get isConsultNowRequest =>
      userId != null && counselorId != null && serviceId != null;

  bool get isMessage => messageId != null && appointmentId != null;

  String get displayMessage {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    if (isConsultNowRequest) {
      return 'New Consult Now request received.';
    }
    if (isMessage) {
      return 'New message received.';
    }
    return 'New notification';
  }

  IconData get notificationIcon {
    if (isConsultNowRequest) {
      return Icons.video_call;
    }
    if (isMessage) {
      return Icons.chat;
    }
    return Icons.notifications;
  }

  Color get notificationIconColor {
    if (isConsultNowRequest) {
      return Color(0xFF10B981); // Green
    }
    if (isMessage) {
      return Color(0xFF3B82F6); // Blue
    }
    return Color(0xFF6B7280); // Gray
  }
}
