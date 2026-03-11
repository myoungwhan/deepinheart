import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/reservation_model.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';

class ReservationDetailsDialog extends StatefulWidget {
  final Reservation reservation;
  final Appointment? appointment;

  const ReservationDetailsDialog({
    Key? key,
    required this.reservation,
    this.appointment,
  }) : super(key: key);

  @override
  State<ReservationDetailsDialog> createState() =>
      _ReservationDetailsDialogState();
}

class _ReservationDetailsDialogState extends State<ReservationDetailsDialog> {
  Timer? _updateTimer;
  String _remainingTime = "";
  Color _remainingTimeColor = Colors.grey;
  bool _canJoin = false;

  Reservation get reservation => widget.reservation;
  Appointment? get appointment => widget.appointment;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    // Update every 30 seconds for real-time feel
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = _getRemainingTime();
      _remainingTimeColor = _getRemainingTimeColor();
      _canJoin = _canUserJoin();
    });
  }

  // Get remaining time until appointment
  String _getRemainingTime() {
    if (appointment == null) return "N/A".tr;

    // For consult_now, check if counselor has accepted
    if (appointment!.isConsultNow) {
      if (appointment!.counselorStatus.toLowerCase() == 'accept' &&
          appointment!.status.toLowerCase() == 'upcoming') {
        return "Ready to Join".tr;
      } else if (appointment!.isPending) {
        return "Waiting for counselor...".tr;
      }
      return appointment!.statusText;
    }

    // For scheduled appointments
    if (appointment!.date == null || appointment!.timeSlot == null) {
      return appointment!.statusText;
    }

    try {
      final dateParts = appointment!.date!.split('-');
      if (dateParts.length != 3) return appointment!.statusText;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment!.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return appointment!.statusText;

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
        return "Ready to Join".tr;
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

    // For consult_now
    if (appointment!.isConsultNow) {
      if (appointment!.counselorStatus.toLowerCase() == 'accept') {
        return Colors.green;
      } else if (appointment!.isPending) {
        return Colors.orange;
      }
      return Colors.grey;
    }

    // For scheduled appointments
    if (appointment!.date == null || appointment!.timeSlot == null) {
      return Colors.grey;
    }

    try {
      final dateParts = appointment!.date!.split('-');
      if (dateParts.length != 3) return Colors.grey;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final displayTime = appointment!.timeSlot!.displayTime;
      final timeParts = displayTime.split(' - ');
      if (timeParts.isEmpty) return Colors.grey;

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
        return Colors.green; // Ready to join
      } else if (difference.inHours < 1) {
        return Colors.orange; // Less than 1 hour
      } else if (difference.inHours < 24) {
        return Colors.blue; // Today
      } else {
        return Colors.grey; // Future
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  // Check if appointment time has been reached
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

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      final now = DateTime.now();

      return now.isAfter(appointmentDateTime) ||
          now.isAtSameMomentAs(appointmentDateTime);
    } catch (e) {
      return false;
    }
  }

  // Check if user can join
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

  @override
  Widget build(BuildContext context) {
    final startFmt = DateFormat.jm().format(reservation.start);
    final endFmt = DateFormat.jm().format(
      reservation.start.add(reservation.duration),
    );
    // Get locale string for DateFormat - use ko_KR for Korean, en_US for others
    final localeString =
        Get.locale != null && Get.locale!.languageCode == 'ko'
            ? 'ko_KR'
            : 'en_US';
    final dateFmt = DateFormat(
      'EEEE, MMMM d, yyyy',
      localeString,
    ).format(reservation.start);

    // Check if this is a consult_now appointment
    final isConsultNow = appointment?.isConsultNow ?? false;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 10,
      child: Container(
        width: Get.width,
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: "Appointment Details".tr,
                        fontSize: FontConstants.font_18,
                        weight: FontWeightConstants.bold,
                        color: Colors.white,
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                  UIHelper.verticalSpaceMd,

                  // Counselor info
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 35.r,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 32.r,
                            backgroundImage: CachedNetworkImageProvider(
                              reservation.avatarUrl,
                            ),
                          ),
                        ),
                      ),
                      UIHelper.horizontalSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: reservation.name,
                              fontSize: FontConstants.font_20,
                              weight: FontWeightConstants.bold,
                              color: Colors.white,
                            ),
                            UIHelper.verticalSpaceSm,
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: CustomText(
                                    text:
                                        reservation.isUpcoming
                                            ? "Upcoming".tr
                                            : "Completed".tr,
                                    fontSize: FontConstants.font_12,
                                    weight: FontWeightConstants.medium,
                                    color: Colors.white,
                                  ),
                                ),
                                if (isConsultNow) ...[
                                  UIHelper.horizontalSpaceSm,
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.flash_on,
                                          color: Colors.white,
                                          size: 14.w,
                                        ),
                                        SizedBox(width: 4.w),
                                        CustomText(
                                          text: "Instant".tr,
                                          fontSize: FontConstants.font_12,
                                          weight: FontWeightConstants.medium,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time Section
                    _buildInfoSection(
                      icon: Icons.calendar_today,
                      title: "Date & Time".tr,
                      children: [
                        if (!isConsultNow) ...[
                          _buildInfoRow("Date".tr, dateFmt),
                          _buildInfoRow("Time".tr, "$startFmt - $endFmt"),
                          _buildInfoRow(
                            "Duration".tr,
                            "${reservation.duration.inMinutes} ${"min".tr}",
                          ),
                        ] else ...[
                          _buildInfoRow("Type".tr, "Immediate Consultation".tr),
                          _buildInfoRow("Started".tr, startFmt),
                        ],
                      ],
                    ),

                    UIHelper.verticalSpaceMd,

                    // Consultation Details Section
                    _buildInfoSection(
                      icon: Icons.psychology,
                      title: "Consultation Details".tr,
                      children: [
                        _buildInfoRow("Method".tr, reservation.method.tr),
                        if (appointment?.consultationContent?.isNotEmpty ??
                            false)
                          _buildInfoRow(
                            "Content".tr,
                            appointment?.consultationContent ?? '',
                          ),
                      ],
                    ),

                    UIHelper.verticalSpaceMd,

                    // Additional Info Section
                    _buildInfoSection(
                      icon: Icons.info_outline,
                      title: "Additional Information".tr,
                      children: [
                        _buildInfoRow(
                          "Status".tr,
                          reservation.isUpcoming
                              ? "Scheduled".tr
                              : "Completed".tr,
                        ),
                        _buildInfoRow(
                          "Consultation Type".tr,
                          _getConsultationType(reservation.method.tr),
                        ),
                        _buildInfoRow(
                          "Appointment Type".tr,
                          isConsultNow
                              ? "Immediate (Consult Now)".tr
                              : "Scheduled Appointment".tr,
                        ),
                        if (appointment?.reservedCoins != null &&
                            appointment!.reservedCoins > 0)
                          _buildInfoRow(
                            "Reserved Coins".tr,
                            "${appointment!.reservedCoins}",
                          ),
                      ],
                    ),

                    // Join button for upcoming appointments
                    if (reservation.isUpcoming) ...[
                      UIHelper.verticalSpaceMd,
                      _buildJoinButton(context),
                    ],

                    //   UIHelper.verticalSpaceMd,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: primaryColor, size: 20.w),
              ),
              UIHelper.horizontalSpaceSm,
              CustomText(
                text: title,
                fontSize: FontConstants.font_16,
                weight: FontWeightConstants.bold,
                color: Color(0xff1F2937),
              ),
            ],
          ),
          UIHelper.verticalSpaceSm,
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: CustomText(
              text: label,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.medium,
              color: Color(0xff6B7280),
            ),
          ),
          Expanded(
            child: CustomText(
              text: value,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Color(0xff1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    // Show remaining time info and join button based on state
    return Column(
      children: [
        // Remaining time indicator
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: _remainingTimeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _remainingTimeColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _canJoin ? Icons.check_circle : Icons.access_time,
                color: _remainingTimeColor,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              CustomText(
                text: _remainingTime,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.bold,
                color: _remainingTimeColor,
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Join button - enabled only when can join
        Container(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: _canJoin ? () => _handleJoinConsultation(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canJoin ? primaryColor : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getJoinIcon(reservation.method),
                  color: _canJoin ? Colors.white : Colors.grey[500],
                  size: 20.w,
                ),
                UIHelper.horizontalSpaceSm,
                CustomText(
                  text:
                      _canJoin
                          ? _getJoinButtonText(reservation.method)
                          : "Not Available Yet".tr,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.bold,
                  color: _canJoin ? Colors.white : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoinConsultation(BuildContext context) async {
    // Close the dialog first
    Get.back();

    if (appointment == null) {
      Get.snackbar(
        'Error'.tr,
        'Appointment information not available'.tr,
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
    if (reservation.method.contains('Video')) {
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
    } else if (reservation.method.contains('Phone')) {
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
    } else if (reservation.method.contains('Chat')) {
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

  String _getConsultationType(String method) {
    if (method.contains('Video')) return 'Video Call'.tr;
    if (method.contains('Phone')) return 'Voice Call'.tr;
    if (method.contains('Chat')) return 'Text Chat'.tr;
    return 'Consultation'.tr;
  }

  IconData _getJoinIcon(String method) {
    if (method.contains('Video')) return Icons.videocam;
    if (method.contains('Phone')) return Icons.phone;
    if (method.contains('Chat')) return Icons.chat;
    return Icons.play_arrow;
  }

  String _getJoinButtonText(String method) {
    if (method.contains('Video')) return 'Join Video Call'.tr;
    if (method.contains('Phone')) return 'Join Voice Call'.tr;
    if (method.contains('Chat')) return 'Open Chat'.tr;
    return 'Join Consultation'.tr;
  }
}
