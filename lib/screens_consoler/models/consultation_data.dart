enum ConsultationStatus { pending, confirmed, inProgress, completed }

enum ConsultationType { videoCall, voiceCall, inPerson }

enum ServiceType {
  relationshipCounseling,
  lifeCoaching,
  careerGuidance,
  therapy,
}

class ConsultationData {
  final String id;
  final String clientName;
  final bool isOnline;
  final ConsultationStatus status;
  final DateTime dateTime;
  final ServiceType serviceType;
  final ConsultationType consultationType;
  final int duration; // in minutes
  final double revenue;
  final double? rating;
  final String? notes;

  ConsultationData({
    required this.id,
    required this.clientName,
    required this.isOnline,
    required this.status,
    required this.dateTime,
    required this.serviceType,
    required this.consultationType,
    required this.duration,
    required this.revenue,
    this.rating,
    this.notes,
  });

  String get statusText {
    switch (status) {
      case ConsultationStatus.pending:
        return 'Pending';
      case ConsultationStatus.confirmed:
        return 'Confirmed';
      case ConsultationStatus.inProgress:
        return 'In Progress';
      case ConsultationStatus.completed:
        return 'Completed';
    }
  }

  String get serviceTypeText {
    switch (serviceType) {
      case ServiceType.relationshipCounseling:
        return 'Relationship Counseling';
      case ServiceType.lifeCoaching:
        return 'Life Coaching';
      case ServiceType.careerGuidance:
        return 'Career Guidance';
      case ServiceType.therapy:
        return 'Therapy';
    }
  }

  String get consultationTypeText {
    switch (consultationType) {
      case ConsultationType.videoCall:
        return 'Video Call';
      case ConsultationType.voiceCall:
        return 'Voice Call';
      case ConsultationType.inPerson:
        return 'In Person';
    }
  }

  String get formattedDateTime {
    final day = dateTime.day.toString().padLeft(2, '0');
    final startHour = dateTime.hour;
    final startMinute = dateTime.minute.toString().padLeft(2, '0');
    final endTime = dateTime.add(Duration(minutes: duration));
    final endHour = endTime.hour;
    final endMinute = endTime.minute.toString().padLeft(2, '0');

    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';

    final startHour12 =
        startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);
    final endHour12 =
        endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);

    return 'Dec $day, $startHour12:$startMinute $startPeriod - $endHour12:$endMinute $endPeriod';
  }

  factory ConsultationData.sample() {
    return ConsultationData(
      id: '1',
      clientName: 'Emily Johnson',
      isOnline: true,
      status: ConsultationStatus.pending,
      dateTime: DateTime(2024, 12, 31, 14, 30),
      serviceType: ServiceType.relationshipCounseling,
      consultationType: ConsultationType.videoCall,
      duration: 60,
      revenue: 120.0,
    );
  }

  static List<ConsultationData> getSampleData() {
    return [
      ConsultationData(
        id: '1',
        clientName: 'Emily Johnson',
        isOnline: true,
        status: ConsultationStatus.pending,
        dateTime: DateTime(2024, 12, 31, 14, 30),
        serviceType: ServiceType.relationshipCounseling,
        consultationType: ConsultationType.videoCall,
        duration: 60,
        revenue: 120.0,
      ),
      ConsultationData(
        id: '2',
        clientName: 'Michael Chen',
        isOnline: false,
        status: ConsultationStatus.confirmed,
        dateTime: DateTime(2024, 12, 31, 16, 0),
        serviceType: ServiceType.lifeCoaching,
        consultationType: ConsultationType.voiceCall,
        duration: 60,
        revenue: 100.0,
      ),
      ConsultationData(
        id: '3',
        clientName: 'Sarah Williams',
        isOnline: true,
        status: ConsultationStatus.inProgress,
        dateTime: DateTime(2025, 1, 1, 10, 0),
        serviceType: ServiceType.careerGuidance,
        consultationType: ConsultationType.videoCall,
        duration: 60,
        revenue: 150.0,
      ),
      ConsultationData(
        id: '4',
        clientName: 'Jessica Brown',
        isOnline: true,
        status: ConsultationStatus.completed,
        dateTime: DateTime(2024, 12, 30, 15, 0),
        serviceType: ServiceType.relationshipCounseling,
        consultationType: ConsultationType.videoCall,
        duration: 60,
        revenue: 120.0,
        rating: 5.0,
      ),
      ConsultationData(
        id: '5',
        clientName: 'David Martinez',
        isOnline: false,
        status: ConsultationStatus.completed,
        dateTime: DateTime(2024, 12, 30, 11, 0),
        serviceType: ServiceType.lifeCoaching,
        consultationType: ConsultationType.voiceCall,
        duration: 90,
        revenue: 180.0,
        rating: 4.0,
      ),
    ];
  }
}
