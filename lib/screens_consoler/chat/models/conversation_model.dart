/// Model for Conversations API response
class ConversationsResponse {
  final bool success;
  final String message;
  final List<ConversationData> data;

  ConversationsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => ConversationData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ConversationData {
  final LastMessage lastMessage;
  final ConversationAppointment appointment;

  ConversationData({required this.lastMessage, required this.appointment});

  factory ConversationData.fromJson(Map<String, dynamic> json) {
    return ConversationData(
      lastMessage: LastMessage.fromJson(json['last_message'] ?? {}),
      appointment: ConversationAppointment.fromJson(json['appointment'] ?? {}),
    );
  }

  /// Get the other user's name (for counselor view, this is the client)
  String get clientName => appointment.user?.name ?? 'Unknown';

  /// Get the other user's image
  String? get clientImage => appointment.user?.image;

  /// Get client initial for avatar
  String get clientInitial =>
      clientName.isNotEmpty ? clientName[0].toUpperCase() : '?';

  /// Check if has unread messages
  bool get hasUnread => lastMessage.readAt == null;

  /// Get formatted time
  String get formattedTime {
    try {
      final date = DateTime.parse(lastMessage.createdAt);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        // Today - show time
        final hour =
            date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
      } else if (messageDate == today.subtract(Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  /// Get display message (filter system messages)
  String get displayMessage {
    final msg = lastMessage.message;
    if (msg == '[SESSION_ENDED_BY_USER]') {
      return 'Session ended';
    }
    return msg;
  }
}

class LastMessage {
  final int id;
  final int appointmentId;
  final int senderId;
  final int receiverId;
  final String message;
  final String? file;
  final String createdAt;
  final String? readAt;
  final MessageUser? sender;
  final MessageUser? receiver;

  LastMessage({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.file,
    required this.createdAt,
    this.readAt,
    this.sender,
    this.receiver,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'] ?? 0,
      appointmentId: json['appointment_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      message: json['message'] ?? '',
      file: json['file'],
      createdAt: json['created_at'] ?? '',
      readAt: json['read_at'],
      sender:
          json['sender'] != null ? MessageUser.fromJson(json['sender']) : null,
      receiver:
          json['receiver'] != null
              ? MessageUser.fromJson(json['receiver'])
              : null,
    );
  }
}

class MessageUser {
  final int id;
  final String name;
  final String? image;
  final bool isOnline;
  final String lastSeen;

  MessageUser({
    required this.id,
    required this.name,
    this.image,
    this.isOnline = false,
    this.lastSeen = 'Never',
  });

  factory MessageUser.fromJson(Map<String, dynamic> json) {
    return MessageUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] ?? 'Never',
    );
  }
}

class ConversationAppointment {
  final int id;
  final String? date;
  final String status;
  final String counselorStatus;
  final String method;
  final int methodCoins;
  final String? consultationContent;
  final String type;
  final String? startTime;
  final String? endTime;
  final int reservedCoins;
  final String chanelId;
  final double? rating;
  final AppointmentPerson? counselor;
  final AppointmentPerson? user;
  final bool isTroat;

  ConversationAppointment({
    required this.id,
    this.date,
    required this.status,
    required this.counselorStatus,
    required this.method,
    required this.methodCoins,
    this.consultationContent,
    required this.type,
    this.startTime,
    this.endTime,
    required this.reservedCoins,
    required this.chanelId,
    this.rating,
    this.counselor,
    this.user,
    required this.isTroat,
  });

  factory ConversationAppointment.fromJson(Map<String, dynamic> json) {
    return ConversationAppointment(
      id: json['id'] ?? 0,
      date: json['date'],
      status: json['status'] ?? '',
      counselorStatus: json['counselor_status'] ?? '',
      method: json['method'] ?? '',
      methodCoins: json['method_coins'] ?? 0,
      consultationContent: json['counsultaion_content'],
      type: json['type'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      reservedCoins: json['reserved_coins'] ?? 0,
      chanelId: json['chanel_id'] ?? '',
      rating: _parseDouble(json['rating']),
      counselor:
          json['counselor'] != null
              ? AppointmentPerson.fromJson(json['counselor'])
              : null,
      user:
          json['user'] != null
              ? AppointmentPerson.fromJson(json['user'])
              : null,
      isTroat: json.containsKey('is_tarot') ? json['is_tarot'] == 1 : false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Check if session is completed
  bool get isCompleted =>
      status.toLowerCase() == 'confirmed' ||
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'cancelled';
}

class AppointmentPerson {
  final int id;
  final String name;
  final String? image;
  final bool isOnline;
  final String lastSeen;

  AppointmentPerson({
    required this.id,
    required this.name,
    this.image,
    this.isOnline = false,
    this.lastSeen = 'Never',
  });

  factory AppointmentPerson.fromJson(Map<String, dynamic> json) {
    return AppointmentPerson(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] ?? 'Never',
    );
  }
}
