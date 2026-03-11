class RevenueStatementsModel {
  final bool success;
  final String message;
  final RevenueStatementsData data;

  RevenueStatementsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RevenueStatementsModel.fromJson(Map<String, dynamic> json) {
    return RevenueStatementsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: RevenueStatementsData.fromJson(json['data'] ?? {}),
    );
  }
}

class RevenueStatementsData {
  final int accumulatedCoins;
  final int coinToRevenue;
  final int thisMonthRevenue;
  int withdrawable_coins;
  final List<ConsultationHistoryItem> consultationHistory;
  final List<WithdrawHistoryItem> withdrawHistory;

  RevenueStatementsData({
    required this.accumulatedCoins,
    required this.coinToRevenue,
    required this.thisMonthRevenue,
    required this.consultationHistory,
    required this.withdrawHistory,
    required this.withdrawable_coins,
  });

  factory RevenueStatementsData.fromJson(Map<String, dynamic> json) {
    return RevenueStatementsData(
      accumulatedCoins: json['accumulated_coins'] ?? 0,
      coinToRevenue: json['coin_to_revenue'] ?? 0,
      thisMonthRevenue: json['this_month_revenue'] ?? 0,
      withdrawable_coins: json['withdrawable_coins'] ?? 0,
      consultationHistory:
          (json['consultation_history'] as List<dynamic>?)
              ?.map((e) => ConsultationHistoryItem.fromJson(e))
              .toList() ??
          [],
      withdrawHistory:
          (json['withdraw_history'] as List<dynamic>?)
              ?.map((e) => WithdrawHistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ConsultationHistoryItem {
  final int id;
  final String date;
  final String status;
  final String counselorStatus;
  final String method;
  final int methodCoins;
  final String? consultationContent;
  final String type;
  final String? startTime;
  final String? endTime;
  final int reservedCoins;
  final String channelId;
  final int rating;
  final ConsultationPerson counselor;
  final ConsultationPerson user;
  final TimeSlotInfo? timeSlot;
  bool isTroat;

  ConsultationHistoryItem({
    required this.id,
    required this.date,
    required this.status,
    required this.counselorStatus,
    required this.method,
    required this.methodCoins,
    this.consultationContent,
    required this.type,
    this.startTime,
    this.endTime,
    required this.reservedCoins,
    required this.channelId,
    required this.rating,
    required this.counselor,
    required this.user,
    this.timeSlot,
    required this.isTroat,
  });

  factory ConsultationHistoryItem.fromJson(Map<String, dynamic> json) {
    return ConsultationHistoryItem(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      counselorStatus: json['counselor_status'] ?? '',
      method: json['method'] ?? '',
      methodCoins: json['method_coins'] ?? 0,
      consultationContent: json['counsultaion_content'],
      type: json['type'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      reservedCoins: json['reserved_coins'] ?? 0,
      channelId: json['chanel_id'] ?? '',
      rating: json['rating'] ?? -1,
      counselor: ConsultationPerson.fromJson(json['counselor'] ?? {}),
      user: ConsultationPerson.fromJson(json['user'] ?? {}),
      isTroat: json.containsKey('is_tarot') ? json['is_tarot'] == 1 : false,
      timeSlot:
          json['time_slot'] != null
              ? TimeSlotInfo.fromJson(json['time_slot'])
              : null,
    );
  }

  /// Check if this is a consult_now type
  bool get isConsultNow => type.toLowerCase() == 'consult_now';

  /// Check if this is an appointment type
  bool get isAppointment => type.toLowerCase() == 'appointment';

  /// Check if completed
  bool get isCompleted =>
      status.toLowerCase() == 'confirmed' ||
      status.toLowerCase() == 'completed';

  /// Check if pending/upcoming
  bool get isPending =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'upcoming';

  /// Check if cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Get formatted method name
  String get methodDisplayName {
    switch (method.toLowerCase()) {
      case 'chat':
        return 'Chat';
      case 'video_call':
        return 'Video Call';
      case 'voice_call':
        return 'Voice Call';
      default:
        return method;
    }
  }

  /// Get formatted date
  String get formattedDate {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  /// Get formatted time range
  String get formattedTimeRange {
    if (startTime != null && endTime != null) {
      final start = _formatTime(startTime!);
      final end = _formatTime(endTime!);
      return '$start - $end';
    } else if (timeSlot != null) {
      return timeSlot!.displayTime;
    }
    return 'N/A';
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  /// Check if has rating
  bool get hasRating => rating > 0;

  /// Calculate duration in minutes
  int get durationInMinutes {
    if (startTime == null || endTime == null) return 0;
    try {
      final start = DateTime.parse('2000-01-01 $startTime');
      final end = DateTime.parse('2000-01-01 $endTime');
      return end.difference(start).inMinutes;
    } catch (e) {
      return 0;
    }
  }
}

class ConsultationPerson {
  final int id;
  final String name;
  final String image;

  ConsultationPerson({
    required this.id,
    required this.name,
    required this.image,
  });

  factory ConsultationPerson.fromJson(Map<String, dynamic> json) {
    return ConsultationPerson(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
    );
  }

  /// Get initials from name
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class TimeSlotInfo {
  final int id;
  final String displayTime;
  final bool isActive;

  TimeSlotInfo({
    required this.id,
    required this.displayTime,
    required this.isActive,
  });

  factory TimeSlotInfo.fromJson(Map<String, dynamic> json) {
    return TimeSlotInfo(
      id: json['id'] ?? 0,
      displayTime: json['display_time'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

class WithdrawHistoryItem {
  final int id;
  final int counselorId;
  final int coins;
  final int amount;
  final int fee;
  final String status;
  final String createdAt;

  WithdrawHistoryItem({
    required this.id,
    required this.counselorId,
    required this.coins,
    required this.amount,
    required this.fee,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawHistoryItem.fromJson(Map<String, dynamic> json) {
    return WithdrawHistoryItem(
      id: json['id'] ?? 0,
      counselorId: json['counselor_id'] ?? 0,
      coins: json['coins'] ?? 0,
      amount: json['amount'] ?? 0,
      fee: json['fee'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Check if pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if completed/approved
  bool get isCompleted =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'approved';

  /// Check if rejected
  bool get isRejected => status.toLowerCase() == 'rejected';

  /// Get net amount after fee
  int get netAmount => amount - fee;

  /// Get formatted date
  String get formattedDate {
    try {
      final parts = createdAt.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length == 3) {
          return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';
        }
      }
      return createdAt;
    } catch (e) {
      return createdAt;
    }
  }

  /// Get formatted time
  String get formattedTime {
    try {
      final parts = createdAt.split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = timeParts[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          return '$displayHour:$minute $period';
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
