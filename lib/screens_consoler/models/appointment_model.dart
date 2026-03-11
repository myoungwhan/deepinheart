class CounselorAppointmentResponse {
  final bool success;
  final String message;
  final List<AppointmentData> data;

  CounselorAppointmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CounselorAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return CounselorAppointmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((x) => AppointmentData.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class AppointmentData {
  final int id;
  final String? date; // Can be null for consult_now
  final String status; // upcoming, completed, cancelled, confirmed
  final String counselorStatus; // pending, accept, decline, in_progress
  final String method; // video_call, voice_call, chat
  final int methodCoins; // Coins required for this method
  final String? counsultaionContent;
  final String type; // appointment, consult_now
  final String? startTime;
  final String? endTime;
  final int reservedCoins;
  final String chanelId;
  final int rating; // Rating value, -1 means not rated
  final double? revenue; // Revenue for this appointment
  final CounselorInfo counselor;
  final CounselorInfo? user;
  final TimeSlotInfo? timeSlot; // Can be null for consult_now
  bool isTroat;

  AppointmentData({
    required this.id,
    this.date,
    required this.status,
    required this.counselorStatus,
    required this.method,
    required this.methodCoins,
    this.counsultaionContent,
    required this.type,
    this.startTime,
    this.endTime,
    required this.reservedCoins,
    required this.chanelId,
    required this.rating,
    this.revenue,
    required this.counselor,
    this.user,
    this.timeSlot,
    required this.isTroat,
    s,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    return AppointmentData(
      id: json['id'] ?? 0,
      date: json['date'],
      status: json['status'] ?? '',
      counselorStatus: json['counselor_status'] ?? 'pending',
      method: json['method'] ?? '',
      methodCoins: json['method_coins'] ?? 0,
      counsultaionContent: json['counsultaion_content'],
      type: json['type'] ?? 'appointment',
      startTime: json['start_time'],
      endTime: json['end_time'],
      reservedCoins: json['reserved_coins'] ?? 0,
      chanelId: json['chanel_id'] ?? '',
      isTroat: json.containsKey('is_tarot') ? json['is_tarot'] == 1 : false,
      rating: json['rating'] ?? -1,
      revenue: _parseToDouble(json['revenue']),
      counselor: CounselorInfo.fromJson(json['counselor'] ?? {}),
      user:
          json.containsKey('user') && json['user'] != null
              ? CounselorInfo.fromJson(json['user'] ?? {})
              : null,
      timeSlot:
          json.containsKey('time_slot') && json['time_slot'] != null
              ? TimeSlotInfo.fromJson(json['time_slot'] ?? {})
              : null,
    );
  }

  // Helper methods
  bool get isPending => counselorStatus.toLowerCase() == 'pending';
  bool get isAccepted => counselorStatus.toLowerCase() == 'accept';
  bool get isDeclined => counselorStatus.toLowerCase() == 'decline';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isInProgress => counselorStatus.toLowerCase() == 'in_progress';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isConsultNow => type.toLowerCase() == 'consult_now';
  bool get isAppointment => type.toLowerCase() == 'appointment';
  bool get isRated =>
      rating >= 0 && rating <= 5; // Rating is valid if between 0-5

  String get statusText {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In Progress';
    if (isConfirmed || isAccepted) return 'Confirmed';
    if (isPending) return 'Pending';
    if (isDeclined) return 'Declined';
    return counselorStatus;
  }

  String get methodText {
    switch (method.toLowerCase()) {
      case 'video_call':
        return 'Video Call';
      case 'voice_call':
        return 'Voice Call';
      case 'chat':
        return 'Chat';
      default:
        return method;
    }
  }

  String get displayDateTime {
    try {
      // For consult_now type, show "Immediate Consultation"
      if (isConsultNow) {
        return 'Immediate Consultation';
      }

      // For appointment type with date and time slot
      if (date != null && timeSlot != null) {
        final dateTime = DateTime.parse(date!);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${timeSlot!.displayTime}';
      }

      // Fallback
      return date ?? 'No date';
    } catch (e) {
      return date ?? 'No date';
    }
  }

  /// Helper method to parse string or number to double
  /// Handles both string and numeric values from API
  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;

    // If already a number, convert to double
    if (value is num) return value.toDouble();

    // If it's a string, try to parse it
    if (value is String) {
      // Remove any whitespace
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      // Try to parse as double
      final parsed = double.tryParse(trimmed);
      return parsed;
    }

    // For any other type, try to convert to double
    try {
      return double.tryParse(value.toString());
    } catch (e) {
      return null;
    }
  }
}

class CounselorInfo {
  final int id;
  final String name;
  final String? image;
  final bool isOnline;
  final String lastSeen;

  CounselorInfo({
    required this.id,
    required this.name,
    this.image,
    this.isOnline = false,
    this.lastSeen = 'Never',
  });

  factory CounselorInfo.fromJson(Map<String, dynamic> json) {
    final imageValue = json['image'];
    return CounselorInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image:
          imageValue != null && imageValue.toString().isNotEmpty
              ? imageValue.toString()
              : null,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] ?? 'Never',
    );
  }
}

class TimeSlotInfo {
  final int id;
  final String displayTime;
  final int isActive;

  TimeSlotInfo({
    required this.id,
    required this.displayTime,
    required this.isActive,
  });

  factory TimeSlotInfo.fromJson(Map<String, dynamic> json) {
    return TimeSlotInfo(
      id: json['id'] ?? 0,
      displayTime: json['display_time'] ?? '',
      isActive: json['is_active'] ?? 1,
    );
  }
}

class CounselorApprovalRequest {
  final int appointmentId;
  final String status; // accept or decline

  CounselorApprovalRequest({required this.appointmentId, required this.status});

  Map<String, dynamic> toJson() {
    return {'appointment_id': appointmentId, 'status': status};
  }
}

class CounselorApprovalResponse {
  final bool success;
  final String message;
  final dynamic data;

  CounselorApprovalResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CounselorApprovalResponse.fromJson(Map<String, dynamic> json) {
    return CounselorApprovalResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
