import 'package:deepinheart/Controller/Model/availability_model.dart';
import 'package:deepinheart/Controller/Model/reservation_model.dart';
import 'package:deepinheart/Controller/Model/time_slot_model.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/main.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class BookingViewmodel extends ChangeNotifier {
  UserViewModel userViewModel =
      navigatorKey.currentContext!.read<UserViewModel>();
  List<TimeSlot> slots = [
    TimeSlot('13:00'),
    TimeSlot('13:30', available: false),
    TimeSlot('14:00'),
    TimeSlot('14:30'),
    TimeSlot('15:00'),
    TimeSlot('15:30', available: false),
    TimeSlot('16:00'),
    TimeSlot('16:30'),
    TimeSlot('17:00'),
    TimeSlot('17:30'),
    TimeSlot('18:00'),
    TimeSlot('18:30'),
    TimeSlot('19:00'),
    TimeSlot('19:30'),
    TimeSlot('20:00', available: false),
  ];

  ApiClient apiClient = ApiClient();
  bool isLoadingSlots = false;
  bool isLoadingReservations = false;

  // Real reservation data from API
  List<ReservationGroup> _upcomingReservations = [];
  List<ReservationGroup> pastReservations = [];

  // Fetch availability from API
  Future<void> fetchAvailability({
    required int sectionId,
    required String date,
    required int counselorId,
  }) async {
    try {
      isLoadingSlots = true;
      notifyListeners();

      final url =
          '${ApiEndPoints.BASE_URL}appointment-availability?section_id=$sectionId&date=$date&counselor_id=$counselorId';

      final response = await apiClient.request(url: url, method: 'GET');

      if (response != null) {
        final availabilityResponse = AvailabilityResponse.fromJson(response);

        if (availabilityResponse.success && availabilityResponse.data != null) {
          // Update slots based on API response
          slots.clear();

          for (var dayAvailability in availabilityResponse.data!.availability) {
            for (var slotItem in dayAvailability.slots) {
              slots.add(
                TimeSlot(
                  slotItem.slot.displayTime,
                  id: slotItem.slot.id,
                  available: slotItem.isAvailable,
                ),
              );
            }
          }
        } else {
          // No availability found, clear slots
          slots.clear();
        }
      }
    } catch (e) {
      debugPrint('Error fetching availability: $e');
      // Keep existing slots on error
    } finally {
      isLoadingSlots = false;
      notifyListeners();
    }
  }

  // Store appointment
  Future<Map<String, dynamic>?> storeAppointment(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final url = '${ApiEndPoints.BASE_URL}appointment-store';

      final response = await apiClient.request(
        url: url,
        method: 'POST',
        body: requestData,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userViewModel.userModel!.data.token}',
        },
      );

      print(requestData.toString());
      if (response != null) {
        return response;
      }

      return {'success': false, 'message': 'Failed to store appointment'};
    } catch (e) {
      debugPrint('Error storing appointment: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Fetch reservations from API
  Future<void> fetchReservations({required String status}) async {
    try {
      isLoadingReservations = true;
      notifyListeners();

      final url = '${ApiEndPoints.BASE_URL}reservation?status=$status';

      final response = await apiClient.request(
        url: url,
        method: 'GET',
        headers: {
          'Authorization': 'Bearer ${userViewModel.userModel!.data.token}',
        },
      );

      if (response != null && response['success'] == true) {
        List<dynamic> data = response['data'] ?? [];

        if (status == 'upcoming') {
          _upcomingReservations =
              data.map((group) => ReservationGroup.fromJson(group)).toList();
          print('🔍 Upcoming reservations: ${_upcomingReservations.length}');
        } else if (status == 'past') {
          // Past reservations come as flat list of appointments
          // Parse and group them by date
          pastReservations = _parsePastReservations(data);
        }
      } else {
        // Handle error case
        if (status == 'upcoming') {
          _upcomingReservations = [];
        } else if (status == 'past') {
          pastReservations = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching reservations: $e');
      // Keep existing data on error
    } finally {
      isLoadingReservations = false;
      notifyListeners();
    }
  }

  /// Parse past reservations from flat list and group by date
  List<ReservationGroup> _parsePastReservations(List<dynamic> data) {
    // Parse appointments
    List<Appointment> appointments =
        data.map((item) => Appointment.fromJson(item)).toList();

    // Sort by date (newest first)
    appointments.sort((a, b) {
      final dateA = a.date ?? '';
      final dateB = b.date ?? '';
      return dateB.compareTo(dateA);
    });

    // Group by date
    Map<String, List<Appointment>> groupedByDate = {};
    for (var appointment in appointments) {
      final dateKey = appointment.date ?? 'Unknown Date';
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(appointment);
    }

    // Convert to ReservationGroup list
    List<ReservationGroup> result = [];
    groupedByDate.forEach((date, appointmentList) {
      String title = _formatDateTitle(date);
      result.add(ReservationGroup(title: title, appointments: appointmentList));
    });

    return result;
  }

  /// Format date string to readable title
  String _formatDateTitle(String date) {
    try {
      final dateParts = date.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final dateTime = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(Duration(days: 1));

        if (dateTime == today) {
          return 'Today';
        } else if (dateTime == yesterday) {
          return 'Yesterday';
        } else {
          const months = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          return '${months[month - 1]} $day, $year';
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return date;
  }

  /// Cancel appointment
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    try {
      final url =
          '${ApiEndPoints.BASE_URL}appointment-cancel?appointment_id=$appointmentId';

      final response = await apiClient.request(
        url: url,
        method: 'GET',
        headers: {
          'Authorization': 'Bearer ${userViewModel.userModel!.data.token}',
        },
      );

      if (response != null && response['success'] == true) {
        debugPrint('Appointment cancelled successfully: $response');
        return response;
      } else {
        debugPrint('Failed to cancel appointment: $response');
        return {
          'success': false,
          'message': response?['message'] ?? 'Failed to cancel appointment',
        };
      }
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return {'success': false, 'message': 'Failed to connect to server: $e'};
    }
  }

  // Helper to check if an appointment should be considered as "past/completed"
  bool _isAppointmentCompleted(Appointment appointment) {
    // Explicitly completed
    if (appointment.isCompleted) return true;

    // For scheduled appointments: confirmed + accepted + date has passed
    if (appointment.isAppointment) {
      if (appointment.isConfirmed && appointment.isAccepted) {
        // Check if appointment date and time has passed
        if (appointment.date != null && appointment.timeSlot != null) {
          try {
            final dateParts = appointment.date!.split('-');
            if (dateParts.length == 3) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);

              // Parse time from displayTime
              final displayTime = appointment.timeSlot!.displayTime;
              final timeParts = displayTime.split(' - ');
              if (timeParts.isNotEmpty) {
                final endTimeStr =
                    timeParts.length > 1
                        ? timeParts[1].trim()
                        : timeParts[0].trim();

                int hour = 0;
                int minute = 0;

                if (endTimeStr.contains('AM') || endTimeStr.contains('PM')) {
                  final isPM = endTimeStr.contains('PM');
                  final timeOnly = endTimeStr.replaceAll(
                    RegExp(r'[APM\s]'),
                    '',
                  );
                  final hm = timeOnly.split(':');
                  hour = int.parse(hm[0]);
                  minute = hm.length > 1 ? int.parse(hm[1]) : 0;

                  if (isPM && hour != 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;
                } else {
                  final hm = endTimeStr.split(':');
                  hour = int.parse(hm[0]);
                  minute = hm.length > 1 ? int.parse(hm[1]) : 0;
                }

                final appointmentEndTime = DateTime(
                  year,
                  month,
                  day,
                  hour,
                  minute,
                );
                final now = DateTime.now();

                // If end time has passed, it's completed
                if (now.isAfter(appointmentEndTime)) {
                  return true;
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing appointment date: $e');
          }
        }
      }
    }

    // For consult_now: confirmed + accepted = completed (since it's immediate)
    if (appointment.isConsultNow) {
      if ((appointment.isConfirmed ||
              appointment.status.toLowerCase() == 'confirmed') &&
          appointment.isAccepted) {
        return true;
      }
    }

    return false;
  }

  // Getters for reservation data with proper filtering
  List<ReservationGroup> get upcomingReservations {
    List<ReservationGroup> filteredGroups = [];

    for (var group in _upcomingReservations) {
      List<Appointment> upcomingAppointments = [];

      for (var appointment in group.appointments) {
        // Only include if NOT completed
        // if (!_isAppointmentCompleted(appointment)) {
        upcomingAppointments.add(appointment);
        // }
      }

      if (upcomingAppointments.isNotEmpty) {
        filteredGroups.add(
          ReservationGroup(
            title: group.title,
            appointments: upcomingAppointments,
          ),
        );
      }
    }

    return filteredGroups;
  }

  // Legacy getters for compatibility with existing UI
  List<Reservation> get upcoming {
    List<Reservation> allUpcoming = [];
    for (var group in upcomingReservations) {
      for (var appointment in group.appointments) {
        allUpcoming.add(appointment.toLegacyReservation());
      }
    }
    return allUpcoming;
  }

  List<Reservation> get past {
    List<Reservation> allPast = [];
    for (var group in pastReservations) {
      for (var appointment in group.appointments) {
        allPast.add(appointment.toLegacyReservation());
      }
    }
    return allPast;
  }

  String get cancelationAndRefundPoicy {
    return """<div style="padding:0px; line-height:1.4;">
  <p>
    ${'This service automatically deducts coins in proportion to the real-time consultation duration, and therefore separate purchase cancellations are not possible.'.tr}
  </p>
  <p>
    ${'However, as an exceptional situation requiring purchase cancellation,'.tr} <strong>&ldquo;${'Consultation Packages'.tr}&rdquo;</strong> ${'can be cancelled and refunded before the service begins.'.tr}
    ${'After the service has begun:'.tr}
  </p>
  <ol style="margin-left:16px; line-height:1.6;">
    <li>
      <strong>${'Divisible services:'.tr}</strong> ${'Cancellation and refund possible for unused portions'.tr}
    </li>
    <li>
      <strong>${'Indivisible services:'.tr}</strong> ${'No cancellation or refund possible'.tr}
    </li>
  </ol>
  <p>
    ${'For transaction amount settlements, you must directly negotiate cancellation and refund with the respective counselor.'.tr}
  </p>
  <p>
    ${'You can check coin usage and balance status on the'.tr} <strong>[${'Coin History'.tr}]</strong> ${'page, where you can also request refunds for unused amounts after recharging.'.tr}
  </p>
</div>

""";
  }

  // Legacy getter for all reservations (combines upcoming and past)
  List<Reservation> get all {
    List<Reservation> allReservations = [];
    allReservations.addAll(upcoming);
    allReservations.addAll(past);
    return allReservations;
  }
}
