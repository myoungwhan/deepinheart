import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:deepinheart/Controller/Model/time_slot_model.dart';
import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/screens_consoler/models/appointment_model.dart';
import 'package:deepinheart/screens_consoler/widgets/consultation_management/appointment_details_dialog.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens_consoler/widgets/consultation_management/consultation_tab_bar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class ConsultaionCardview extends StatefulWidget {
  final ConsultationTab type;
  final AppointmentData appointment;

  const ConsultaionCardview({
    Key? key,
    required this.type,
    required this.appointment,
  }) : super(key: key);

  @override
  State<ConsultaionCardview> createState() => _ConsultaionCardviewState();
}

class _ConsultaionCardviewState extends State<ConsultaionCardview>
    with SingleTickerProviderStateMixin {
  Timer? _updateTimer;
  String _remainingTime = "";
  Color _remainingTimeColor = Colors.grey;
  bool _canJoin = false;
  late AnimationController _blinkController;
  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    // Initialize blink animation controller
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Blink every 500ms
    );

    // Start blinking if this is a consult_now request
    if (_isConsultNowRequest(widget.appointment)) {
      _blinkController.repeat(reverse: true);
    }

    _updateRemainingTime();

    // Check if this is a consult_now request and play sound
    _checkAndPlaySound();

    // Update every 15 seconds for real-time feel
    _updateTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _updateRemainingTime();
        // Also refresh appointments silently in the background
        _refreshAppointmentsSilently();
        // Check for new consult_now requests
        _checkAndPlaySound();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  // Check if this is a consult_now request and play sound
  void _checkAndPlaySound() {
    final isConsultNowRequest =
        appointment.type.toLowerCase() == 'consult_now' &&
        appointment.statusText.toLowerCase() == 'pending' &&
        appointment.counselorStatus.toLowerCase() == 'pending';

    if (isConsultNowRequest) {
      // Play sound if we haven't played it yet for this request
      // The sound will play once when the request first appears
      if (!_hasPlayedSound) {
        _playNotificationSound();
        _hasPlayedSound = true;
      }
    } else {
      // Reset sound flag if status changes (so it can play again for new requests)
      _hasPlayedSound = false;
    }
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = _getRemainingTime();
      _remainingTimeColor = _getRemainingTimeColor();
      _canJoin = _canCounselorJoin();
    });
  }

  void _refreshAppointmentsSilently() {
    // Refresh appointments without showing loading indicator
    if (mounted) {
      context.read<CounselorAppointmentProvider>().fetchAppointmentsSilently(
        context,
      );
    }
  }

  AppointmentData get appointment => widget.appointment;
  ConsultationTab get type => widget.type;

  // Start video/voice call based on appointment method
  void _startCall(BuildContext context) async {
    // Get channel name from appointment
    final channelName = appointment.chanelId;

    // Generate unique user ID for counselor
    final userId = AgoraConfig.generateUserId();

    // Get client/user name
    final clientName = appointment.user?.name ?? 'Client';

    // Counselor rate (you can get this from service data if available, using default 50.0)
    final counselorRate =
        appointment.reservedCoins > 0
            ? appointment.reservedCoins.toDouble()
            : 50.0;

    print('=== Starting Call ===');
    print('Channel Name: $channelName');
    print('User ID: $userId');
    print('Client: $clientName');
    print('Method: ${appointment.methodText}');
    print('Rate: $counselorRate');
    print('==================');

    // Check if this is a reservation (scheduled appointment) and user is offline
    final isReservation = appointment.type.toLowerCase() == 'appointment';
    final isUserOffline = appointment.user?.isOnline != true;

    if (isReservation && isUserOffline) {
      // For reservations: if user is offline, send message and play sound
      await _sendWaitingMessage(context);
      _playNotificationSound();
      return; // Don't start the call, just notify the user
    }

    // Navigate based on consultation method
    if (appointment.method.toLowerCase() == 'video_call') {
      await Get.to(
        () => VideoCallScreen(
          counslername: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointment.id, // Pass appointment ID for coin updates
          isCounsler: true,
          isTroat: appointment.isTroat,
        ),
      );
      _refreshAppointmentsSilently();
    } else if (appointment.method.toLowerCase() == 'voice_call') {
      await Get.to(
        () => VoiceCallScreen(
          isCounselor: true,
          counslername: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointment.id, // Pass appointment ID for coin updates
          isTroat: appointment.isTroat,
        ),
      );

      _refreshAppointmentsSilently();
    } else if (appointment.method.toLowerCase() == 'chat') {
      await Get.to(
        () => ChatScreen(
          isCounselor: true,
          counselorName: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointment.id,
          isTroat: appointment.isTroat,
        ),
      );
      _refreshAppointmentsSilently();
    } else {
      // Default to video call
      await Get.to(
        () => VideoCallScreen(
          counslername: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: appointment.id, // Pass appointment ID for coin updates
          isCounsler: true,
          isTroat: appointment.isTroat,
        ),
      );
      _refreshAppointmentsSilently();
    }
  }

  // Send push notification when user is offline
  Future<void> _sendWaitingMessage(BuildContext context) async {
    try {
      // Get user_id from appointment
      final userId = appointment.user?.id;
      if (userId == null) {
        debugPrint('❌ No user_id available to send notification');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}send-notification'),
      );

      final waitingMessage = "Now waiting for consultation".tr;
      request.fields.addAll({
        'user_id': userId.toString(),
        'title': 'Consultation Request'.tr,
        'body': waitingMessage,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        debugPrint('✅ Push notification sent successfully: $responseData');
        Get.snackbar(
          'Message Sent'.tr,
          waitingMessage,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        final errorMessage = response.reasonPhrase ?? 'Unknown error';
        debugPrint(
          '❌ Failed to send push notification: ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
    }
  }

  // Play notification sound
  void _playNotificationSound() {
    try {
      // Play system notification sound
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  // Get color based on appointment status
  Color _getStatusColor() {
    if (appointment.isPending) {
      return Colors.orange; // Yellow/Orange for pending
    } else if (appointment.isCompleted || appointment.isAccepted) {
      return greenColor; // Green for confirmed or completed
    } else if (appointment.isDeclined) {
      return Colors.red; // Red for declined
    } else if (appointment.isInProgress) {
      return primaryColorConsulor; // Blue for in progress
    }
    return Colors.grey; // Default
  }

  // Format display time to fix invalid formats like "24:00" to "00:00"
  String _formatDisplayTime(String displayTime) {
    try {
      // Check if it's a time range (e.g., "10:00 - 11:00" or "24:00 - 01:00")
      if (displayTime.contains(' - ')) {
        final parts = displayTime.split(' - ');
        if (parts.length == 2) {
          final startTime = _formatSingleTime(parts[0].trim());
          final endTime = _formatSingleTime(parts[1].trim());
          return '$startTime - $endTime';
        }
      }

      // Single time format
      return _formatSingleTime(displayTime);
    } catch (e) {
      // If formatting fails, return original
      return displayTime;
    }
  }

  // Format a single time string to 12-hour format with AM/PM (e.g., "24:00" -> "12:00 AM", "20:00" -> "8:00 PM")
  String _formatSingleTime(String time) {
    try {
      // Check if already in 12-hour format with AM/PM
      final hasAM = time.toUpperCase().contains('AM');
      final hasPM = time.toUpperCase().contains('PM');

      if (hasAM || hasPM) {
        // Already in 12-hour format, just clean it up
        String timeOnly = time.replaceAll(RegExp(r'[APM\s]'), '').trim();
        final parts = timeOnly.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          final minute = parts[1];

          // Ensure hour is valid (0-12)
          if (hour > 12) hour = hour % 12;
          if (hour == 0) hour = 12;

          final period = hasPM ? 'PM' : 'AM';
          return '$hour:$minute $period';
        }
        return time;
      }

      // Convert from 24-hour format to 12-hour format
      String timeOnly = time.replaceAll(RegExp(r'[APM\s]'), '').trim();
      final parts = timeOnly.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];

        // Fix invalid hour "24" to "00"
        if (hour == 24) {
          hour = 0;
        } else if (hour > 23) {
          hour = hour % 24;
        }

        // Convert to 12-hour format
        String period = 'AM';
        int displayHour = hour;

        if (hour == 0) {
          displayHour = 12; // Midnight (00:00) -> 12:00 AM
        } else if (hour == 12) {
          period = 'PM'; // Noon (12:00) -> 12:00 PM
        } else if (hour > 12) {
          displayHour =
              hour -
              12; // Afternoon/Evening (13:00-23:59) -> 1:00 PM - 11:59 PM
          period = 'PM';
        } else {
          // Morning (01:00-11:59) -> 1:00 AM - 11:59 AM
          period = 'AM';
        }

        // Format as H:mm AM/PM (no leading zero for hour in 12-hour format)
        return '$displayHour:$minute $period';
      }

      return time;
    } catch (e) {
      return time;
    }
  }

  // Get remaining time until appointment
  String _getRemainingTime() {
    if (appointment.date == null || appointment.timeSlot == null) {
      return appointment.statusText;
    }

    try {
      // Parse appointment date
      final dateParts = appointment.date!.split('-');
      if (dateParts.length != 3) return appointment.statusText;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time from displayTime (e.g., "10:00 AM - 11:00 AM" or "10:00 - 11:00")
      final displayTime = appointment.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return appointment.statusText;

      final startTimeStr = timeParts[0].trim();

      // Parse start time
      int hour = 0;
      int minute = 0;

      if (startTimeStr.contains('AM') || startTimeStr.contains('PM')) {
        // 12-hour format (e.g., "10:00 AM")
        final isPM = startTimeStr.contains('PM');
        final timeOnly = startTimeStr.replaceAll(RegExp(r'[APM\s]'), '');
        final hm = timeOnly.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        // 24-hour format (e.g., "10:00")
        final hm = startTimeStr.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;
      }

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final now = DateTime.now();
      final difference = appointmentDateTime.difference(now);

      if (difference.isNegative) {
        return "Started".tr;
      }

      if (difference.inDays > 0) {
        return "${difference.inDays}d ${difference.inHours % 24}h ${"left".tr}";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ${difference.inMinutes % 60}m ${"left".tr}";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ${"left".tr}";
      } else {
        return "Starting soon".tr;
      }
    } catch (e) {
      return appointment.statusText;
    }
  }

  // Get color for remaining time
  Color _getRemainingTimeColor() {
    if (appointment.date == null || appointment.timeSlot == null) {
      return _getStatusColor();
    }

    try {
      final dateParts = appointment.date!.split('-');
      if (dateParts.length != 3) return _getStatusColor();

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return _getStatusColor();

      final startTimeStr = timeParts[0].trim();

      int hour = 0;
      int minute = 0;

      if (startTimeStr.contains('AM') || startTimeStr.contains('PM')) {
        final isPM = startTimeStr.contains('PM');
        final timeOnly = startTimeStr.replaceAll(RegExp(r'[APM\s]'), '');
        final hm = timeOnly.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        final hm = startTimeStr.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;
      }

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final now = DateTime.now();
      final difference = appointmentDateTime.difference(now);

      if (difference.isNegative) {
        return Colors.blue; // Started
      } else if (difference.inHours < 1) {
        return Colors.orange; // Less than 1 hour
      } else if (difference.inHours < 24) {
        return greenColor; // Today
      } else {
        return Colors.grey; // Future
      }
    } catch (e) {
      return _getStatusColor();
    }
  }

  // Check if appointment time has been reached (for showing Join button)
  bool _isAppointmentTimeReached() {
    if (appointment.date == null || appointment.timeSlot == null) {
      return false;
    }

    try {
      final dateParts = appointment.date!.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return false;

      final startTimeStr = timeParts[0].trim();

      int hour = 0;
      int minute = 0;

      if (startTimeStr.contains('AM') || startTimeStr.contains('PM')) {
        final isPM = startTimeStr.contains('PM');
        final timeOnly = startTimeStr.replaceAll(RegExp(r'[APM\s]'), '');
        final hm = timeOnly.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;

        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        final hm = startTimeStr.split(':');
        hour = int.parse(hm[0]);
        minute = hm.length > 1 ? int.parse(hm[1]) : 0;
      }

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final now = DateTime.now();

      // Time is reached if current time is at or after appointment time
      return now.isAfter(appointmentDateTime) ||
          now.isAtSameMomentAs(appointmentDateTime);
    } catch (e) {
      return false;
    }
  }

  // Check if counselor can join
  bool _canCounselorJoin() {
    // For scheduled appointments: time reached + status confirmed
    final isScheduledAppointmentReady =
        appointment.type.toLowerCase() == 'appointment' &&
        _isAppointmentTimeReached() &&
        appointment.statusText == "Confirmed";

    // For consult_now: counselor accepted + status upcoming
    final isConsultNowReady =
        appointment.type.toLowerCase() == 'consult_now' &&
        appointment.counselorStatus.toLowerCase() == 'accept' &&
        appointment.status.toLowerCase() == 'upcoming';

    return isScheduledAppointmentReady || isConsultNowReady;
  }

  // Check if this is a consult_now request (pending status)
  bool _isConsultNowRequest(AppointmentData apt) {
    return apt.type.toLowerCase() == 'consult_now' &&
        apt.statusText.toLowerCase() == 'pending' &&
        apt.counselorStatus.toLowerCase() == 'pending';
  }

  // Build the status chip with blinking animation for "Requesting" status
  Widget _buildRequestingStatusChip(AppointmentData currentAppointment) {
    final isRequesting = _isConsultNowRequest(currentAppointment);

    if (isRequesting) {
      // Start blinking animation if not already running
      if (!_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }

      // Show blinking "Requesting" chip
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Opacity(
            opacity:
                0.5 +
                (_blinkController.value * 0.5), // Blink between 0.5 and 1.0
            child: SubCategoryChip(
              text: "Requesting".tr,
              color: _getStatusColor(),
            ),
          );
        },
      );
    } else {
      // Stop blinking animation if status changed
      if (_blinkController.isAnimating) {
        _blinkController.stop();
      }

      // Show normal status chip
      return SubCategoryChip(
        text: currentAppointment.statusText.tr,
        color: _getStatusColor(),
      );
    }
  }

  // View chat history for completed chat appointments (no coin deduction)
  void _viewChatHistory(BuildContext context) {
    final channelName = appointment.chanelId;
    final userId = AgoraConfig.generateUserId();
    final clientName = appointment.user?.name ?? 'Client';

    Get.to(
      () => ChatScreen(
        isCounselor: true,
        counselorName: clientName,
        channelName: channelName,
        userId: userId,
        appointmentId: appointment.id,
        isViewOnly: true, // View-only mode - no coin deduction
        isTroat: appointment.isTroat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider updates to get fresh appointment data
    return Consumer<CounselorAppointmentProvider>(
      builder: (context, provider, child) {
        // Find the current appointment in the provider's list to get updated data
        final updatedAppointment = provider.appointments.firstWhere(
          (apt) => apt.id == appointment.id,
          orElse: () => appointment, // Fallback to original if not found
        );

        // Use updated appointment if found, otherwise use original
        final currentAppointment =
            updatedAppointment.id == appointment.id
                ? updatedAppointment
                : appointment;

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) =>
                      AppointmentDetailsDialog(appointment: currentAppointment),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor, width: .5),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: SizedBox(
              width: Get.width,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                text:
                                    currentAppointment.user?.name ??
                                    appointment.user?.name ??
                                    'Client',
                                align: TextAlign.start,
                                weight: FontWeightConstants.medium,
                              ),
                              UIHelper.horizontalSpaceSm,
                              type == ConsultationTab.reservation
                                  ?
                                  // SubCategoryChip(
                                  //   text: "Online",
                                  //   color: Colors.green,
                                  //   isHaveCircle: true,
                                  // )
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              currentAppointment
                                                          .user
                                                          ?.isOnline ==
                                                      true
                                                  ? GreenColor
                                                  : Colors.red,
                                        ),
                                      ),
                                      UIHelper.horizontalSpaceSm5,
                                      CustomText(
                                        text:
                                            currentAppointment.user?.isOnline ==
                                                    true
                                                ? "Online".tr
                                                : "Offline".tr,
                                        fontSize: FontConstants.font_12,
                                        color:
                                            currentAppointment.user?.isOnline ==
                                                    true
                                                ? greenColor
                                                : Colors.red,
                                      ),
                                    ],
                                  )
                                  : appointment.rating != -1
                                  ? MyRatingView(
                                    initialRating:
                                        appointment.rating.toDouble(),
                                    isAllowRating: false,
                                    itemSize: 12.0,
                                    fsize: FontConstants.font_12,
                                    text: appointment.rating.toString(),
                                  )
                                  : Container(),
                            ],
                          ),
                          UIHelper.verticalSpaceSm5,
                          CustomText(
                            text: appointment.displayDateTime.tr,
                            fontSize: FontConstants.font_12,
                            color: lightGREY,
                          ),
                          UIHelper.verticalSpaceSm5,
                          CustomText(
                            text:
                                "${(appointment.methodText).tr}${appointment.timeSlot?.displayTime != null ? ' · ${_formatDisplayTime(appointment.timeSlot!.displayTime)}' : ''}",
                            fontSize: FontConstants.font_12,
                            color: lightGREY,
                          ),
                          UIHelper.verticalSpaceSm5,
                          type != ConsultationTab.reservation
                              ? CustomText(
                                text:
                                    appointment.counsultaionContent ??
                                    "${'Revenue:'.tr} $appCurrency${appointment.revenue?.toStringAsFixed(0) ?? '0'}"
                                        .tr,
                                fontSize: FontConstants.font_12,
                                color: greenColor,
                              )
                              : Container(),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        type == ConsultationTab.completed
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SubCategoryChip(
                                  text: 'Completed'.tr,
                                  color: greenColor,
                                ),
                                SizedBox(height: 8.h),
                                // Show View Chat button for chat method appointments
                                if (appointment.method.toLowerCase() == 'chat')
                                  GestureDetector(
                                    onTap: () => _viewChatHistory(context),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.blue.shade700,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          CustomText(
                                            text: "View Chat".tr,
                                            fontSize: FontConstants.font_11,
                                            weight: FontWeightConstants.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  MaterialButton(
                                    height: 30.h,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                    onPressed: () {},
                                    child: CustomText(
                                      text: 'Details'.tr,
                                      color: Colors.black,
                                      fontSize: FontConstants.font_12,
                                    ),
                                  ),
                              ],
                            )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Show Join button if appointment time reached and confirmed
                                // Otherwise show remaining time for appointment type, status for consult_now
                                _canJoin
                                    ? GestureDetector(
                                      onTap: () => _startCall(context),
                                      child: SubCategoryChipCategory(
                                        text: "Join Now".tr,
                                        color: primaryColorConsulor,
                                        fontSize: FontConstants.font_12,
                                        isBackgroundDark: true,
                                      ),
                                    )
                                    : currentAppointment.type.toLowerCase() ==
                                            'appointment' &&
                                        appointment.statusText == "Confirmed"
                                    ? SubCategoryChip(
                                      text: _remainingTime,
                                      color: _remainingTimeColor,
                                    )
                                    : _buildRequestingStatusChip(
                                      currentAppointment,
                                    ),

                                //    UIHelper.verticalSpaceSm5,
                                appointment.statusText == "Pending"
                                    ? Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          //accept and decline small text buttons
                                          GestureDetector(
                                            onTap: () async {
                                              final success = await context
                                                  .read<
                                                    CounselorAppointmentProvider
                                                  >()
                                                  .acceptAppointment(
                                                    context: context,
                                                    appointmentId:
                                                        appointment.id,
                                                  );

                                              // If acceptance successful, start the call
                                              if (success) {
                                                if (appointment.type
                                                        .toLowerCase() ==
                                                    'consult_now') {
                                                  _startCall(context);
                                                }
                                              }
                                            },
                                            child: SubCategoryChipCategory(
                                              text: "Accept".tr,
                                              color: primaryColorConsulor,
                                              fontSize: FontConstants.font_10,
                                              isBackgroundDark: true,
                                            ),
                                          ),
                                          UIHelper.horizontalSpaceSm5,
                                          GestureDetector(
                                            onTap: () async {
                                              // confirmation dialog
                                              UIHelper.showDialogOk(
                                                context,
                                                title: 'Decline Appointment'.tr,
                                                message:
                                                    'Are you sure you want to decline this appointment?'
                                                        .tr,
                                                onConfirm: () {
                                                  Get.back();
                                                  // decline appointment
                                                  context
                                                      .read<
                                                        CounselorAppointmentProvider
                                                      >()
                                                      .declineAppointment(
                                                        context: context,
                                                        appointmentId:
                                                            appointment.id,
                                                      );
                                                },
                                              );
                                            },
                                            child: SubCategoryChipCategory(
                                              text: "Decline".tr,
                                              color: Colors.red,
                                              fontSize: FontConstants.font_10,
                                              isBackgroundDark: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child:
                                          appointment.statusText == "Confirmed"
                                              ? GestureDetector(
                                                onTap: () {
                                                  _showRescheduleConfirmation(
                                                    context,
                                                  );
                                                },
                                                child: SubCategoryChipCategory(
                                                  text: "Reschedule".tr,
                                                  color: Colors.white,
                                                  textColor: Colors.black,
                                                  borderColor: Colors.grey,
                                                ),
                                              )
                                              : appointment.statusText ==
                                                  enumServiceStatus
                                                      .Declined
                                                      .name
                                              ? Container()
                                              : SubCategoryChip(
                                                text: "End Session".tr,
                                                color: Colors.red,
                                              ),
                                    ),
                              ],
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Show reschedule confirmation dialog
  void _showRescheduleConfirmation(BuildContext context) {
    UIHelper.showDialogOk(
      context,
      title: 'Reschedule Appointment'.tr,
      message: 'Are you sure you want to reschedule this appointment?'.tr,
      onConfirm: () {
        Get.back();
        _showRescheduleDialog(context);
      },
    );
  }

  // Show reschedule dialog with date and time slot selection
  void _showRescheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) =>
              _RescheduleDialog(appointment: widget.appointment),
    );
  }
}

// Reschedule Dialog Widget
class _RescheduleDialog extends StatefulWidget {
  final AppointmentData appointment;

  const _RescheduleDialog({Key? key, required this.appointment})
    : super(key: key);

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String? selectedSlot;
  int? selectedSlotId;
  bool _isRescheduling = false;

  // Note: For fetching availability, we need section_id which is not available in the appointment
  // Using a default section_id = 1 for now. This should be updated based on your backend structure.
  final int _defaultSectionId = 1;

  @override
  void initState() {
    super.initState();
    _fetchAvailabilityForSelectedDate();
  }

  void _fetchAvailabilityForSelectedDate() {
    final bookingVm = Provider.of<BookingViewmodel>(context, listen: false);
    final dateStr = DateFormat(
      "yyyy-MM-dd",
    ).format(_selectedDay ?? DateTime.now());

    // Get counselor ID from appointment
    // For counselor side: use widget.appointment.user?.id (the user who booked)
    // For now, using counselor.id as we're on counselor side
    final counselorId = widget.appointment.counselor.id;

    setState(() {
      selectedSlot = null;
      selectedSlotId = null;
    });

    bookingVm.fetchAvailability(
      sectionId: _defaultSectionId,
      date: dateStr,
      counselorId: counselorId,
    );
  }

  Future<void> _rescheduleAppointment() async {
    if (selectedSlotId == null || _selectedDay == null) {
      Get.snackbar(
        'Error'.tr,
        'Please select a date and time slot'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isRescheduling = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final headers = {'Authorization': 'Bearer $token'};

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}reschedule-appointment'),
      );

      request.fields.addAll({
        'appointment_id': widget.appointment.id.toString(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
        'time_slot_id': selectedSlotId.toString(),
      });

      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data['success'] == true) {
          Get.back(); // Close dialog
          Get.snackbar(
            'Success'.tr,
            data['message'] ?? 'Appointment rescheduled successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Refresh appointments
          final provider = Provider.of<CounselorAppointmentProvider>(
            context,
            listen: false,
          );
          provider.fetchAppointments(context);
        } else {
          throw Exception(
            data['message'] ?? 'Failed to reschedule appointment',
          );
        }
      } else {
        throw Exception(
          'Failed to reschedule appointment: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }

  Map<String, List<TimeSlot>> _groupSlotsByPeriod(List<TimeSlot> slots) {
    Map<String, List<TimeSlot>> grouped = {'Morning': [], 'Afternoon': []};

    for (var slot in slots) {
      try {
        final timeParts = slot.label.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);

          if (hour < 12) {
            grouped['Morning']!.add(slot);
          } else {
            grouped['Afternoon']!.add(slot);
          }
        }
      } catch (e) {
        grouped['Morning']!.add(slot);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.r),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      content: Container(
        width: Get.width * 0.9,
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.dialogBackgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'Reschedule Appointment'.tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.semiBold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            UIHelper.verticalSpaceMd,

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current appointment info
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: 'Current Appointment'.tr,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.medium,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          UIHelper.verticalSpaceSm,
                          CustomText(
                            text:
                                '${widget.appointment.date} - ${widget.appointment.timeSlot?.displayTime ?? "N/A"}',
                            fontSize: FontConstants.font_13,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ],
                      ),
                    ),
                    UIHelper.verticalSpaceMd,

                    // Calendar
                    CustomText(
                      text: 'Select New Date'.tr,
                      fontSize: FontConstants.font_15,
                      weight: FontWeightConstants.medium,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    UIHelper.verticalSpaceSm,
                    _buildCalendar(isDarkMode),
                    UIHelper.verticalSpaceMd,

                    // Time slots
                    CustomText(
                      text: 'Select Time Slot'.tr,
                      fontSize: FontConstants.font_15,
                      weight: FontWeightConstants.medium,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    UIHelper.verticalSpaceSm,
                    _buildTimeSlots(isDarkMode),
                  ],
                ),
              ),
            ),

            UIHelper.verticalSpaceMd,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRescheduling ? null : () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: CustomText(
                      text: 'Cancel'.tr,
                      fontSize: FontConstants.font_14,
                      color: Colors.black,
                    ),
                  ),
                ),
                UIHelper.horizontalSpaceSm,
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRescheduling ? null : _rescheduleAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child:
                        _isRescheduling
                            ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : CustomText(
                              text: 'Confirm'.tr,
                              fontSize: FontConstants.font_14,
                              color: Colors.white,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDarkMode) {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 365)),
      focusedDay: _focusedDay,
      availableGestures: AvailableGestures.horizontalSwipe,
      locale: Get.locale!.languageCode == 'ko' ? 'ko_KR' : 'en_US',
      availableCalendarFormats: {
        CalendarFormat.week: 'Week'.tr,
        CalendarFormat.month: 'Month'.tr,
      },
      headerStyle: HeaderStyle(
        titleCentered: true,
        leftChevronVisible: true,
        rightChevronVisible: true,
        formatButtonVisible: true,
        titleTextStyle: textStyleRobotoRegular(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 14.0,
          weight: fontWeightBold,
        ),
        formatButtonTextStyle: textStyleRobotoRegular(
          color: Colors.white,
          fontSize: 14.0,
          weight: fontWeightBold,
        ),
        formatButtonDecoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(5),
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        decoration: BoxDecoration(shape: BoxShape.rectangle),
        weekdayStyle: textStyleRobotoRegular(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 13.5,
          weight: FontWeightConstants.medium,
        ),
        weekendStyle: textStyleRobotoRegular(
          color: Colors.red,
          fontSize: 13.5,
          weight: FontWeightConstants.medium,
        ),
      ),
      calendarFormat: _calendarFormat,
      daysOfWeekHeight: 20.0,
      calendarStyle: CalendarStyle(
        selectedTextStyle: textStyleRobotoRegular(
          color: Colors.white,
          fontSize: 14.0,
          weight: fontWeightBold,
        ),
        defaultTextStyle: textStyleRobotoRegular(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 14.0,
          weight: FontWeightConstants.regular,
        ),
        weekendTextStyle: textStyleRobotoRegular(
          color: Colors.red,
          fontSize: 14.0,
          weight: FontWeightConstants.regular,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          color: primaryColor.withAlpha(100),
        ),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          color: primaryColor,
        ),
      ),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) async {
        if (!selectedDay.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _fetchAvailabilityForSelectedDate();
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  Widget _buildTimeSlots(bool isDarkMode) {
    return Consumer<BookingViewmodel>(
      builder: (context, pr, child) {
        if (pr.isLoadingSlots) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (pr.slots.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: CustomText(
                text: 'No available slots for selected date'.tr,
                fontSize: FontConstants.font_13,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          );
        }

        final groupedSlots = _groupSlotsByPeriod(pr.slots);

        return Container(
          width: Get.width,
          padding: EdgeInsets.symmetric(horizontal: 12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Morning Section
              if (groupedSlots['Morning']!.isNotEmpty) ...[
                CustomText(
                  text: "Morning".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                UIHelper.verticalSpaceSm,
                _buildTimeSlotGrid(groupedSlots['Morning']!, isDarkMode),
                UIHelper.verticalSpaceMd,
              ],

              // Afternoon Section
              if (groupedSlots['Afternoon']!.isNotEmpty) ...[
                CustomText(
                  text: "Afternoon".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                UIHelper.verticalSpaceSm,
                _buildTimeSlotGrid(groupedSlots['Afternoon']!, isDarkMode),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlot> slots, bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          slots.map((slot) {
            final isSelected = selectedSlot == slot.label;

            Color backgroundColor;
            Color textColor;
            Color? borderColor;

            if (!slot.available) {
              backgroundColor = Color(0xffF3F4F6);
              textColor = Color(0xffD1D5DB);
            } else if (isSelected) {
              backgroundColor = primaryColor;
              textColor = Colors.white;
              borderColor = primaryColor;
            } else {
              backgroundColor =
                  isDarkMode ? Colors.grey.shade800 : Color(0xffF3F4F6);
              textColor = isDarkMode ? Colors.white : Color(0xff374151);
            }

            return InkWell(
              onTap:
                  slot.available
                      ? () {
                        setState(() {
                          selectedSlot = slot.label;
                          selectedSlotId = slot.id;
                        });
                      }
                      : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      borderColor != null
                          ? Border.all(color: borderColor, width: 1.5)
                          : null,
                ),
                child: CustomText(
                  text: slot.label,
                  color: textColor,
                  fontSize: FontConstants.font_14,
                  weight:
                      isSelected
                          ? FontWeightConstants.semiBold
                          : FontWeightConstants.regular,
                ),
              ),
            );
          }).toList(),
    );
  }
}
