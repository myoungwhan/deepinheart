import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/reservation_model.dart';
import 'package:deepinheart/Controller/Model/time_slot_model.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/reservations/views/cancel_reservation_dialog.dart';
import 'package:deepinheart/screens/reservations/views/reservation_details_dialog.dart';
import 'package:deepinheart/screens/reservations/views/rating_dialog.dart';
import 'package:deepinheart/screens/reservations/views/review_detail_dialog.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:table_calendar/table_calendar.dart';

class ReservationCard extends StatefulWidget {
  final Reservation res;
  final bool isUpcomming;
  final Appointment? appointment;

  ReservationCard({
    Key? key,
    required this.res,
    this.isUpcomming = true,
    this.appointment,
  }) : super(key: key);

  @override
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard>
    with SingleTickerProviderStateMixin {
  bool _hasRated = false;
  int _localRating = 0;
  late AnimationController _blinkController;
  bool _hasPlayedSound = false;
  String? _previousStatusText;
  Timer? _updateTimer;
  String _remainingTime = "";
  Color _remainingTimeColor = Colors.grey;

  Reservation get res => widget.res;
  bool get isUpcomming => widget.isUpcomming;
  Appointment? get appointment => widget.appointment;

  @override
  void initState() {
    super.initState();
    _hasRated = appointment?.isRated ?? false;
    _localRating = appointment?.rating?.toInt() ?? 0;

    // Initialize blink animation controller
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Blink every 500ms
    );

    // Store initial status
    _previousStatusText = _getStatusText();

    // Check if status is ready and play sound
    _checkAndPlaySound();

    // Start blinking if status is ready
    if (_isStatusReady()) {
      _blinkController.repeat(reverse: true);
    }

    // Initialize remaining time
    _updateRemainingTime();

    // Update every 15 seconds for real-time feel
    _updateTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReservationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if status changed to ready
    final currentStatusText = _getStatusText();
    if (currentStatusText != _previousStatusText) {
      _previousStatusText = currentStatusText;
      _checkAndPlaySound();

      if (_isStatusReady()) {
        if (!_blinkController.isAnimating) {
          _blinkController.repeat(reverse: true);
        }
      } else {
        if (_blinkController.isAnimating) {
          _blinkController.stop();
        }
      }
    }
  }

  // Check if status is "Ready" (counselor has joined)
  bool _isStatusReady() {
    if (appointment == null || !isUpcomming) return false;

    // For consult_now: counselor accepted
    if (appointment!.isConsultNow) {
      return appointment!.counselorStatus.toLowerCase() == 'accept';
    }

    // For scheduled appointments: time reached + status confirmed
    return appointment!.isAppointment &&
        _isAppointmentTimeReached() &&
        appointment!.statusText == "Confirmed";
  }

  // Check if status is ready and play sound
  void _checkAndPlaySound() {
    if (_isStatusReady() && !_hasPlayedSound) {
      _playNotificationSound();
      _hasPlayedSound = true;
    } else if (!_isStatusReady()) {
      // Reset sound flag if status changed
      _hasPlayedSound = false;
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

  void _onRatingSubmitted(int rating) {
    setState(() {
      _hasRated = true;
      _localRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a consult_now appointment
    final isConsultNow = appointment?.isConsultNow ?? false;

    // Format date and time based on appointment type
    String dateTimeText;
    if (isConsultNow) {
      // For consult_now, show "Consult Now" with the booking date
      final bookingDate =
          appointment?.date != null
              ? _formatDateFromString(appointment!.date!)
              : 'Today';
      dateTimeText = '$bookingDate (Consult Now)';
    } else {
      // For scheduled appointments, show the full date and time
      final startFmt = DateFormat.jm().format(res.start);
      final endFmt = DateFormat.jm().format(res.start.add(res.duration));
      final dateText = _formatDate(res.start);
      dateTimeText =
          '$dateText $startFmt – $endFmt (${res.duration.inMinutes}min)';
    }

    // Get status text and color
    final statusText = _getStatusText();
    final statusColor = _getStatusColor();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                radius: 25,
                backgroundImage: CachedNetworkImageProvider(
                  appointment!.counselor.image,
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            text: appointment?.counselor.name ?? '',
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.black,
                            color:
                                Get.isDarkMode
                                    ? Colors.white
                                    : Color(0xff1F2937),
                          ),
                        ),
                        // Show remaining time for confirmed appointments that haven't started
                        _canUserJoin()
                            ? _buildStatusChip(statusText, statusColor)
                            : appointment != null &&
                                appointment!.isAppointment &&
                                appointment!.statusText == "Confirmed" &&
                                appointment!.date != null &&
                                appointment!.timeSlot != null
                            ? SubCategoryChip(
                              text: _remainingTime,
                              color: _remainingTimeColor,
                              fontSize: FontConstants.font_12,
                            )
                            : _buildStatusChip(statusText, statusColor),
                      ],
                    ),

                    //   SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isConsultNow ? Icons.flash_on : Icons.schedule,
                          size: 14,
                          color: isConsultNow ? Colors.orange : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: FutureBuilder(
                            future: translationService.translate(dateTimeText),
                            builder: (context, asyncSnapshot) {
                              return asyncSnapshot.hasData
                                  ? CustomText(
                                    text: asyncSnapshot.data ?? dateTimeText,
                                    fontSize: FontConstants.font_12,
                                    weight: FontWeightConstants.regular,
                                    color:
                                        Get.isDarkMode
                                            ? Colors.white
                                            : Color(0xff4B5563),
                                  )
                                  : SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          res.method.contains('Chat')
                              ? Icons.chat_bubble_outline
                              : res.method.contains('Voice Call')
                              ? Icons.phone
                              : Icons.videocam_outlined,
                          size: 14,
                          color: Get.isDarkMode ? Colors.white : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          text: res.method.tr,
                          fontSize: FontConstants.font_12,
                          weight: FontWeightConstants.regular,
                          color:
                              Get.isDarkMode ? Colors.white : Color(0xff4B5563),
                        ),
                        Spacer(),
                        // Show rating indicator for past appointments
                        if (!isUpcomming) _buildRatingIndicator(),
                      ],
                    ),
                    SizedBox(height: 12),
                    isUpcomming
                        ? Container(
                          height: 30.0,
                          alignment: Alignment.centerRight,
                          child: Row(
                            children: [
                              // Show Join Now button if appointment is active
                              if (_canUserJoin())
                                Expanded(
                                  child: SizedBox(
                                    height: 30.0,
                                    child: CustomButton(
                                      () => _handleJoinConsultation(context),
                                      text: "Join Now".tr,
                                      color: primaryColor,
                                      textcolor: Colors.white,
                                      fsize: FontConstants.font_10,
                                    ),
                                  ),
                                ),
                              if (_canUserJoin()) SizedBox(width: 4),
                              // View Details button
                              Expanded(
                                child: SizedBox(
                                  height: 30.0,
                                  child: CustomButton(
                                    () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) =>
                                                ReservationDetailsDialog(
                                                  reservation: res,
                                                  appointment: appointment,
                                                ),
                                      );
                                    },
                                    text: "View Details".tr,
                                    isCancelButton: true,
                                    fsize: FontConstants.font_10,
                                  ),
                                ),
                              ),
                              // Reschedule button - show if appointment (not consult_now) and confirmed
                              if (!_canUserJoin() &&
                                  !appointment!.isConsultNow &&
                                  appointment!.isAccepted &&
                                  appointment!.status.toLowerCase() ==
                                      'upcoming') ...[
                                SizedBox(width: 4),
                                Expanded(
                                  child: SizedBox(
                                    height: 30.0,
                                    child: CustomButton(
                                      () {
                                        _showRescheduleConfirmation(context);
                                      },
                                      text: "Reschedule".tr,
                                      buttonBorderColor: primaryColor,
                                      textcolor: primaryColor,
                                      color: Colors.white,
                                      fsize: FontConstants.font_10,
                                    ),
                                  ),
                                ),
                              ],
                              // Cancel button - only show if not ready to join
                              if (!_canUserJoin() &&
                                  appointment!.status.toLowerCase() ==
                                      'upcoming') ...[
                                SizedBox(width: 4),
                                Expanded(
                                  child: SizedBox(
                                    height: 30.0,
                                    child: CustomButton(
                                      () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) =>
                                                  CancelReservationDialog(
                                                    appointmentId:
                                                        appointment?.id ?? 0,
                                                  ),
                                        );
                                      },
                                      text: "Cancel".tr,
                                      buttonBorderColor: Colors.red,
                                      textcolor: Colors.red,
                                      color: Colors.white,
                                      fsize: FontConstants.font_10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        : _buildPastAppointmentButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format date based on whether it's today, tomorrow, or a specific date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == tomorrow) {
      return 'Tomorrow';
    } else {
      // Format as "Month Day" (e.g., "June 10")
      return DateFormat('MMMM d').format(date);
    }
  }

  /// Format date from string (e.g., "2025-12-04")
  String _formatDateFromString(String dateStr) {
    try {
      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return dateStr;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final date = DateTime(year, month, day);

      return _formatDate(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// Get status text based on appointment type and status
  String _getStatusText() {
    if (!isUpcomming) return "Completed".tr;

    if (appointment == null) return 'Upcoming'.tr;

    // Check if this should be marked as completed (date passed + confirmed + accepted)
    if (_isAppointmentCompleted()) {
      return "Completed".tr;
    }

    // For consult_now
    if (appointment!.isConsultNow) {
      if (appointment!.counselorStatus.toLowerCase() == 'accept') {
        return "Ready".tr;
      } else if (appointment!.isPending) {
        return "Pending".tr;
      }
    }

    // For scheduled appointments
    return appointment!.statusText.tr;
  }

  // Update remaining time
  void _updateRemainingTime() {
    if (mounted) {
      setState(() {
        _remainingTime = _getRemainingTime();
        _remainingTimeColor = _getRemainingTimeColor();
      });
    }
  }

  // Get remaining time string
  String _getRemainingTime() {
    if (appointment == null) return "";
    if (appointment!.date == null || appointment!.timeSlot == null) {
      return appointment!.statusText;
    }

    try {
      // Parse appointment date
      final dateParts = appointment!.date!.split('-');
      if (dateParts.length != 3) return appointment!.statusText;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      // Parse time from displayTime (e.g., "10:00 AM - 11:00 AM" or "10:00 - 11:00")
      final displayTime = appointment!.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return appointment!.statusText;

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
      return appointment!.statusText;
    }
  }

  // Get color for remaining time
  Color _getRemainingTimeColor() {
    if (appointment == null) return Colors.grey;
    if (appointment!.date == null || appointment!.timeSlot == null) {
      return _getStatusColor();
    }

    try {
      final dateParts = appointment!.date!.split('-');
      if (dateParts.length != 3) return _getStatusColor();

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment!.timeSlot!.displayTime;
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

  // Build status chip with blinking animation for "Requesting" when status is ready
  Widget _buildStatusChip(String statusText, Color statusColor) {
    final isReady = _isStatusReady();

    if (isReady) {
      // Show blinking "Requesting" chip when status is ready
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Opacity(
            opacity:
                0.5 +
                (_blinkController.value * 0.5), // Blink between 0.5 and 1.0
            child: SubCategoryChip(
              text: "Requesting".tr,
              fontSize: FontConstants.font_12,
              color: statusColor,
            ),
          );
        },
      );
    } else {
      // Show normal status chip
      return SubCategoryChip(
        text: statusText,
        fontSize: FontConstants.font_12,
        color: statusColor,
      );
    }
  }

  /// Check if appointment is completed (date passed + confirmed + accepted)
  bool _isAppointmentCompleted() {
    if (appointment == null) return false;

    // Explicitly completed
    if (appointment!.isCompleted) return true;

    // For consult_now: confirmed + accepted = completed
    if (appointment!.isConsultNow) {
      if ((appointment!.isConfirmed ||
              appointment!.status.toLowerCase() == 'confirmed') &&
          appointment!.isAccepted) {
        return true;
      }
    }

    // For scheduled appointments: confirmed + accepted + date/time has passed
    if (appointment!.isAppointment) {
      if (appointment!.isConfirmed && appointment!.isAccepted) {
        if (appointment!.date != null && appointment!.timeSlot != null) {
          try {
            final dateParts = appointment!.date!.split('-');
            if (dateParts.length == 3) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);

              // Parse end time from displayTime
              final displayTime = appointment!.timeSlot!.displayTime;
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

                if (now.isAfter(appointmentEndTime)) {
                  return true;
                }
              }
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }
    }

    return false;
  }

  /// Check if user can join the consultation
  bool _canUserJoin() {
    if (appointment == null) return false;

    // For scheduled appointments: time reached + status confirmed
    final isScheduledAppointmentReady =
        appointment!.isAppointment &&
        _isAppointmentTimeReached() &&
        appointment!.statusText == "Confirmed";

    // For consult_now: counselor accepted + status upcoming
    final isConsultNowReady =
        appointment!.isConsultNow &&
        appointment!.counselorStatus.toLowerCase() == 'accept' &&
        appointment!.status.toLowerCase() == 'upcoming';

    return isScheduledAppointmentReady || isConsultNowReady;
  }

  /// Check if appointment time has been reached
  bool _isAppointmentTimeReached() {
    if (appointment == null) return false;
    if (appointment!.date == null || appointment!.timeSlot == null) {
      return false;
    }

    try {
      final dateParts = appointment!.date!.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment!.timeSlot!.displayTime;
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

      final appointmentStartTime = DateTime(year, month, day, hour, minute);
      final now = DateTime.now();

      // Allow joining 5 minutes before the appointment
      final joinableTime = appointmentStartTime.subtract(Duration(minutes: 5));
      return now.isAfter(joinableTime);
    } catch (e) {
      return false;
    }
  }

  /// Handle join consultation
  Future<void> _handleJoinConsultation(BuildContext context) async {
    if (appointment == null) {
      Get.snackbar(
        'Error',
        'Appointment information not available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Generate channel name and user ID
    final channelName = AgoraConfig.generateChannelName(appointment!.id);
    final userId = AgoraConfig.generateUserId();

    // Navigate to appropriate call screen based on method
    if (res.method.contains('Video')) {
      await Get.to(
        () => VideoCallScreen(
          counslername: appointment!.counselor.name,
          channelName: channelName,
          userId: userId,
          appointmentId: appointment!.id,
          counselorId: appointment!.counselor.id,
          counselorImage: appointment!.counselor.image,
          isCounsler: false,
          isTroat: appointment!.isTroat,
        ),
      );
    } else if (res.method.contains('Phone') || res.method.contains('Voice')) {
      Get.to(
        () => VoiceCallScreen(
          isCounselor: false,
          counslername: appointment!.counselor.name,
          channelName: channelName,
          userId: userId,
          appointmentId: appointment!.id,
          counselorId: appointment!.counselor.id,
          counselorImage: appointment!.counselor.image,
          isTroat: appointment!.isTroat,
        ),
      );
    } else if (res.method.contains('Chat')) {
      await Get.to(
        () => ChatScreen(
          counselorName: appointment!.counselor.name,
          channelName: channelName,
          userId: userId,
          appointmentId: appointment!.id,
          counselorId: appointment!.counselor.id,
          isCounselor: false,
          isTroat: appointment!.isTroat,
        ),
      );
      // Refresh reservations after returning from chat screen
      if (context.mounted) {
        Provider.of<BookingViewmodel>(
          context,
          listen: false,
        ).fetchReservations(status: 'upcoming');
        Provider.of<BookingViewmodel>(
          context,
          listen: false,
        ).fetchReservations(status: 'past');
      }
    } else {
      // Default to video call
      Get.to(
        () => VideoCallScreen(
          counslername: appointment!.counselor.name,
          channelName: channelName,
          userId: userId,
          appointmentId: appointment!.id,
          counselorId: appointment!.counselor.id,
          counselorImage: appointment!.counselor.image,
          isCounsler: false,
          isTroat: appointment!.isTroat,
        ),
      );
    }
  }

  /// Get status color based on appointment type and status
  Color _getStatusColor() {
    if (!isUpcomming || _isAppointmentCompleted()) return Colors.green;

    if (appointment == null) return Color(0xff1976D2);

    // For consult_now
    if (appointment!.isConsultNow) {
      if (appointment!.counselorStatus.toLowerCase() == 'accept') {
        return Colors.green;
      } else if (appointment!.isPending) {
        return Colors.orange;
      }
    }

    // For scheduled appointments
    if (appointment!.isConfirmed || appointment!.isAccepted) {
      return Colors.green;
    } else if (appointment!.isPending) {
      return Colors.orange;
    } else if (appointment!.isDeclined) {
      return Colors.red;
    }

    return Color(0xff1976D2);
  }

  /// Build rating indicator widget (stars + number or Rate Now button)
  Widget _buildRatingIndicator() {
    if (appointment == null) return Container();

    // Check if already rated (local state or from API)
    final isRated = _hasRated || appointment!.isRated;
    final rating =
        _localRating > 0 ? _localRating : (appointment!.rating?.toInt() ?? 0);

    if (isRated && rating > 0) {
      // Show compact rated indicator - clickable to view review details
      return GestureDetector(
        onTap: () => _showReviewDetail(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filled stars (compact - show only filled)
              ...List.generate(rating, (index) {
                return Icon(Icons.star_rounded, color: Colors.amber, size: 12);
              }),
              SizedBox(width: 4),
              CustomText(
                text: "$rating.0",
                fontSize: FontConstants.font_11,
                weight: FontWeightConstants.bold,
                color: Colors.amber[700],
              ),
            ],
          ),
        ),
      );
    } else {
      // Show Rate Now button
      return GestureDetector(
        onTap: () async {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => RatingDialog(appointment: appointment!),
          );

          // If rating was submitted, update local state
          if (result != null && result['success'] == true) {
            _onRatingSubmitted(result['rating'] as int);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Colors.white, size: 12),
              SizedBox(width: 4),
              CustomText(
                text: "Rate".tr,
                fontSize: FontConstants.font_11,
                weight: FontWeightConstants.bold,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Show review detail dialog
  void _showReviewDetail() {
    if (appointment == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ReviewDetailDialog(appointmentId: appointment!.id),
    );
  }

  /// Build buttons for past appointments
  Widget _buildPastAppointmentButtons(BuildContext context) {
    // Show "View Chat" button for chat method appointments
    if (res.method.contains('Chat') && appointment != null) {
      return GestureDetector(
        onTap: () => _viewChatHistory(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200, width: 1),
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
      );
    }
    return Container();
  }

  /// Open chat history in view-only mode (no coin deduction)
  Future<void> _viewChatHistory(BuildContext context) async {
    if (appointment == null) return;

    // Generate channel name (same as original)
    final channelName = AgoraConfig.generateChannelName(appointment!.id);
    final userId = AgoraConfig.generateUserId();

    await Get.to(
      () => ChatScreen(
        counselorName: appointment!.counselor.name,
        channelName: channelName,
        userId: userId,
        appointmentId: appointment!.id,
        counselorId: appointment!.counselor.id,
        isCounselor: false,
        isViewOnly: true, // View-only mode - no coin deduction
        isTroat: appointment!.isTroat,
      ),
    );
    // Refresh reservations after returning from chat history
    if (context.mounted) {
      Provider.of<BookingViewmodel>(
        context,
        listen: false,
      ).fetchReservations(status: 'upcoming');
      Provider.of<BookingViewmodel>(
        context,
        listen: false,
      ).fetchReservations(status: 'past');
    }
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
              _UserRescheduleDialog(appointment: appointment!),
    );
  }
}

// User Reschedule Dialog Widget
class _UserRescheduleDialog extends StatefulWidget {
  final Appointment appointment;

  const _UserRescheduleDialog({Key? key, required this.appointment})
    : super(key: key);

  @override
  State<_UserRescheduleDialog> createState() => _UserRescheduleDialogState();
}

class _UserRescheduleDialogState extends State<_UserRescheduleDialog> {
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

    // Get counselor ID from appointment (for user side)
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

          // Refresh appointments for both upcoming and past
          if (mounted) {
            final provider = Provider.of<BookingViewmodel>(
              context,
              listen: false,
            );
            provider.fetchReservations(status: 'upcoming');
            provider.fetchReservations(status: 'past');
          }
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
