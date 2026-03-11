// reservation.dart
class Reservation {
  final String name;
  final String avatarUrl;
  final DateTime start;
  final Duration duration;
  final String method;
  final bool isUpcoming;

  Reservation({
    required this.name,
    required this.avatarUrl,
    required this.start,
    required this.duration,
    required this.method,
    this.isUpcoming = true,
  });
}

// API Response Models
class ReservationGroup {
  final String title;
  final List<Appointment> appointments;

  ReservationGroup({required this.title, required this.appointments});

  factory ReservationGroup.fromJson(Map<String, dynamic> json) {
    return ReservationGroup(
      title: json['title'] ?? '',
      appointments:
          (json['appointments'] as List<dynamic>?)
              ?.map((appointment) => Appointment.fromJson(appointment))
              .toList() ??
          [],
    );
  }
}

class Appointment {
  final int id;
  final String? date; // Nullable for consult_now appointments
  final String status;
  final String counselorStatus;
  final String method;
  final String? consultationContent;
  final String type; // 'appointment' or 'consult_now'
  final String? startTime;
  final String? endTime;
  final int reservedCoins;
  final String chanelId;
  final bool isTroat;
  final Counselor counselor;
  final Counselor? user; // User who booked the appointment
  final TimeSlotInfo? timeSlot; // Nullable for consult_now appointments
  // rating
  final double? rating;
  final String category;

  Appointment({
    required this.id,
    this.date,
    required this.status,
    required this.counselorStatus,
    required this.method,
    this.consultationContent,
    required this.type,
    this.startTime,
    this.endTime,
    required this.reservedCoins,
    required this.chanelId,
    required this.counselor,
    this.user,
    this.timeSlot,
    this.rating,
    this.category = '',
    required this.isTroat,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      date: json['date'],
      status: json['status'] ?? '',
      counselorStatus: json['counselor_status'] ?? 'pending',
      method: json['method'] ?? '',
      consultationContent: json['counsultaion_content'],
      type: json['type'] ?? 'appointment',
      startTime: json['start_time'],
      endTime: json['end_time'],
      reservedCoins: json['reserved_coins'] ?? 0,
      chanelId: json['chanel_id'] ?? '',
      isTroat: json.containsKey('is_tarot') ? json['is_tarot'] == 1 : false,
      counselor: Counselor.fromJson(json['counselor'] ?? {}),
      user:
          json.containsKey('user') && json['user'] != null
              ? Counselor.fromJson(json['user'])
              : null,
      timeSlot:
          json.containsKey('time_slot') && json['time_slot'] != null
              ? TimeSlotInfo.fromJson(json['time_slot'])
              : null,
      rating:
          json['rating'] != null
              ? double.tryParse(json['rating'].toString()) ?? 0.0
              : null,
      category: json['category'] ?? '',
    );
  }

  // Helper getters
  bool get isPending => counselorStatus.toLowerCase() == 'pending';
  bool get isAccepted => counselorStatus.toLowerCase() == 'accept';
  bool get isDeclined => counselorStatus.toLowerCase() == 'decline';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isInProgress => counselorStatus.toLowerCase() == 'in_progress';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isConsultNow => type.toLowerCase() == 'consult_now';
  bool get isAppointment => type.toLowerCase() == 'appointment';
  bool get isRated => rating != null && rating! > 0;

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
      if (isConsultNow) {
        return 'Immediate Consultation';
      }
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
      return date ?? 'No date';
    } catch (e) {
      return date ?? 'No date';
    }
  }

  // Convert to legacy Reservation format for compatibility
  Reservation toLegacyReservation() {
    // Parse date and time
    DateTime appointmentDateTime;

    if (isConsultNow) {
      // For consult_now, use current date with start_time if available
      if (startTime != null && startTime!.isNotEmpty) {
        try {
          // If startTime is just time (HH:mm:ss), combine with current date
          final now = DateTime.now();
          final timeParts = startTime!.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? now.hour;
            final minute = int.tryParse(timeParts[1]) ?? now.minute;
            final second =
                timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
            appointmentDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
              second,
            );
          } else {
            appointmentDateTime = DateTime.now();
          }
        } catch (e) {
          appointmentDateTime = DateTime.now();
        }
      } else {
        appointmentDateTime = DateTime.now();
      }
    } else if (date != null && timeSlot != null) {
      try {
        appointmentDateTime = DateTime.parse(
          '$date ${timeSlot!.displayTime}:00',
        );
      } catch (e) {
        appointmentDateTime = DateTime.now();
      }
    } else {
      // Fallback to current time
      appointmentDateTime = DateTime.now();
    }

    // Determine duration based on method (default 30 minutes)
    Duration duration = Duration(minutes: 30);
    if (method == 'video_call' || method == 'voice_call') {
      duration = Duration(minutes: 30);
    }

    return Reservation(
      name: user?.name ?? counselor.name, // Use user name if available
      avatarUrl:
          (user?.image ?? counselor.image).isNotEmpty
              ? (user?.image ?? counselor.image)
              : 'https://i.pravatar.cc/100?img=${user?.id ?? counselor.id}',
      start: appointmentDateTime,
      duration: duration,
      method: methodText,
      isUpcoming: status == 'upcoming',
    );
  }
}

class Counselor {
  final int id;
  final String name;
  final String image;

  Counselor({required this.id, required this.name, required this.image});

  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
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
      isActive: json['is_active'] ?? 0,
    );
  }
}
