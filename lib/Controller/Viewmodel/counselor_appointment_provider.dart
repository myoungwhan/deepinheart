import 'package:deepinheart/Controller/Model/favorite_client_model.dart';
import 'package:deepinheart/Controller/Model/revenue_statements_model.dart';
import 'package:deepinheart/Controller/Viewmodel/api_client.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens_consoler/models/appointment_model.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CounselorAppointmentProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AppointmentData> _appointments = [];
  bool _isLoading = false;
  String? _error;

  // Favorite clients state
  List<FavoriteClient> _favoriteClients = [];
  bool _isFavoriteClientsLoading = false;
  String? _favoriteClientsError;

  // Favorite clients getters
  List<FavoriteClient> get favoriteClients => _favoriteClients;
  bool get isFavoriteClientsLoading => _isFavoriteClientsLoading;
  String? get favoriteClientsError => _favoriteClientsError;

  // Get only upcoming/active appointments (not completed or passed)
  List<AppointmentData> get appointments {
    return _appointments.where((appointment) {
      // Include upcoming/active appointments
      return true;
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter appointments by status
  // List<AppointmentData> get pendingAppointments =>
  //     _appointments
  //         .where((a) => a.counselorStatus.toLowerCase() == 'pending')
  //         .toList();

  // List<AppointmentData> get acceptedAppointments =>
  //     _appointments
  //         .where(
  //           (a) =>
  //               a.counselorStatus.toLowerCase() == 'accept' ||
  //               a.counselorStatus.toLowerCase() == 'in_progress',
  //         )
  //         .toList();

  List<AppointmentData> get completedAppointments {
    return _appointments.where((appointment) {
      // Include if status is completed
      if (appointment.status.toLowerCase() == 'confirmed') {
        return true;
      } else {
        return false;
      }

      // Include if date and time slot has passed
    }).toList();
  }

  // Get dates that have appointments (for calendar view)
  List<DateTime> get appointmentDates {
    return _appointments
        .where(
          (appointment) => appointment.date != null,
        ) // Filter out null dates
        .map((appointment) {
          try {
            final date = DateTime.parse(appointment.date!);
            return DateTime(date.year, date.month, date.day);
          } catch (e) {
            return DateTime.now();
          }
        })
        .toSet()
        .toList();
  }

  /// Fetch all counselor appointments
  Future<void> fetchAppointments(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _apiClient.request(
        url: '${ApiEndPoints.BASE_URL}counselor-appointment',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        context: context,
      );

      final appointmentResponse = CounselorAppointmentResponse.fromJson(
        response,
      );

      if (appointmentResponse.success) {
        _appointments = appointmentResponse.data;
        _error = null;
      } else {
        _error = appointmentResponse.message;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch appointments silently (without loading indicator) for background refresh
  Future<void> fetchAppointmentsSilently(BuildContext context) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        return; // Silently fail if not authenticated
      }

      final response = await _apiClient.request(
        url: '${ApiEndPoints.BASE_URL}counselor-appointment',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        context: context,
      );

      final appointmentResponse = CounselorAppointmentResponse.fromJson(
        response,
      );

      if (appointmentResponse.success) {
        _appointments = appointmentResponse.data;
        _error = null;
        notifyListeners(); // Update UI without loading state
      }
    } catch (e) {
      // Silently handle errors for background refresh
      debugPrint('Silent refresh error: $e');
    }
  }

  /// Accept or decline an appointment
  Future<bool> updateAppointmentStatus({
    required BuildContext context,
    required int appointmentId,
    required String status, // 'accept' or 'decline'
  }) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final request = CounselorApprovalRequest(
        appointmentId: appointmentId,
        status: status,
      );

      final response = await _apiClient.request(
        url: '${ApiEndPoints.BASE_URL}counselor-approval',
        method: 'POST',
        body: request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      final approvalResponse = CounselorApprovalResponse.fromJson(response);

      if (approvalResponse.success) {
        // Show success message
        UIHelper.showBottomFlash(
          context,
          title: 'Success',
          message: approvalResponse.message,
          isError: false,
        );

        // Refresh the appointments list
        await fetchAppointments(context);

        return true;
      } else {
        // Show error message
        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: approvalResponse.message,
          isError: true,
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      UIHelper.showBottomFlash(
        context,
        title: 'Error',
        message: 'Failed to update appointment status',
        isError: true,
      );
      return false;
    }
  }

  /// Accept appointment
  Future<bool> acceptAppointment({
    required BuildContext context,
    required int appointmentId,
  }) async {
    return await updateAppointmentStatus(
      context: context,
      appointmentId: appointmentId,
      status: 'accept',
    );
  }

  /// Decline appointment
  Future<bool> declineAppointment({
    required BuildContext context,
    required int appointmentId,
  }) async {
    return await updateAppointmentStatus(
      context: context,
      appointmentId: appointmentId,
      status: 'decline',
    );
  }

  /// Start immediate consultation (consult-now)
  Future<Map<String, dynamic>?> startConsultNow({
    required BuildContext context,
    required int counselorId,
    required int serviceId,
    required String selectedMethod,
    required bool isTroat,
    required String dob,
  }) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final token = userViewModel.userModel?.data.token;

    try {
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }
      userViewModel.setLoading(true);

      final response = await _apiClient.request(
        url: ApiEndPoints.CONSULT_NOW,
        method: 'POST',
        body: {
          'counselor_id': counselorId,
          'service_id': serviceId,
          'method': selectedMethod,
          'is_tarot': isTroat ? 1 : 0,
          'dob': dob,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        context: context,
      );

      if (response['success'] == true) {
        debugPrint('Consult now initiated successfully');
        userViewModel.setLoading(false);

        // Return the response data including chanel_id
        return response['data'];
      } else {
        userViewModel.setLoading(false);

        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: response['message'] ?? 'Failed to start consultation',
          isError: true,
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error starting consult now: $e');
      userViewModel.setLoading(false);

      UIHelper.showBottomFlash(
        context,
        title: 'Error',
        message: 'Failed to start consultation',
        isError: true,
      );
      return null;
    }
  }

  /// Fetch counselor revenue statements
  Future<RevenueStatementsData?> fetchRevenueStatements({
    required BuildContext context,
    required int counselorId,
  }) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _apiClient.request(
        url: '${ApiEndPoints.COUNSELOR_REVENUE}?counselor_id=$counselorId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        context: context,
      );

      if (response['success'] == true) {
        final model = RevenueStatementsModel.fromJson(response);
        return model.data;
      } else {
        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: response['message'] ?? 'Failed to fetch revenue data',
          isError: true,
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching revenue statements: $e');
      UIHelper.showBottomFlash(
        context,
        title: 'Error',
        message: 'Failed to load revenue data',
        isError: true,
      );
      return null;
    }
  }

  /// Get appointments for a specific date
  List<AppointmentData> getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      try {
        if (appointment.date == null) return false;
        final appointmentDate = DateTime.parse(appointment.date!);
        return appointmentDate.year == date.year &&
            appointmentDate.month == date.month &&
            appointmentDate.day == date.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Fetch favorite clients
  Future<void> fetchFavoriteClients(BuildContext context) async {
    try {
      _isFavoriteClientsLoading = true;
      _favoriteClientsError = null;
      //notifyListeners();

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _apiClient.request(
        url: ApiEndPoints.FAVORITE_CLIENTS,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        context: context,
      );

      final favoriteResponse = FavoriteClientsResponse.fromJson(response);

      if (favoriteResponse.success) {
        _favoriteClients =
            favoriteResponse.data.map((item) => item.client).toList();
        _favoriteClientsError = null;
      } else {
        _favoriteClientsError = favoriteResponse.message;
      }
    } catch (e) {
      _favoriteClientsError = e.toString();
      debugPrint('Error fetching favorite clients: $e');
    } finally {
      _isFavoriteClientsLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _appointments = [];
    _isLoading = false;
    _error = null;
    _favoriteClients = [];
    _isFavoriteClientsLoading = false;
    _favoriteClientsError = null;
    notifyListeners();
  }
}
