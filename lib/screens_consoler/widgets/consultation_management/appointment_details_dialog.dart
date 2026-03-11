import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/screens/calls/chat_screen.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/screens_consoler/models/appointment_model.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/rating_view.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsDialog extends StatefulWidget {
  final AppointmentData appointment;

  const AppointmentDetailsDialog({Key? key, required this.appointment})
    : super(key: key);

  @override
  State<AppointmentDetailsDialog> createState() =>
      _AppointmentDetailsDialogState();
}

class _AppointmentDetailsDialogState extends State<AppointmentDetailsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Start video/voice/chat call
  void _startCall(BuildContext context) {
    final channelName = widget.appointment.chanelId;
    final userId = AgoraConfig.generateUserId();
    final clientName = widget.appointment.user?.name ?? 'Client';
    final counselorRate =
        widget.appointment.reservedCoins > 0
            ? widget.appointment.reservedCoins.toDouble()
            : 50.0;

    Get.back(); // Close dialog first

    if (widget.appointment.method.toLowerCase() == 'video_call') {
      Get.to(
        () => VideoCallScreen(
          counslername: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: widget.appointment.id,
          isCounsler: true,
          isTroat: widget.appointment.isTroat,
        ),
      );
    } else if (widget.appointment.method.toLowerCase() == 'voice_call') {
      Get.to(
        () => VoiceCallScreen(
          isCounselor: true,
          counslername: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: widget.appointment.id,
          isTroat: widget.appointment.isTroat,
        ),
      );
    } else if (widget.appointment.method.toLowerCase() == 'chat') {
      Get.to(
        () => ChatScreen(
          isCounselor: true,
          counselorName: clientName,
          channelName: channelName,
          userId: userId,
          counselorRate: counselorRate,
          appointmentId: widget.appointment.id,
          isTroat: widget.appointment.isTroat,
        ),
      );
    }
  }

  // View chat history for completed appointments
  void _viewChatHistory(BuildContext context) {
    final channelName = widget.appointment.chanelId;
    final userId = AgoraConfig.generateUserId();
    final clientName = widget.appointment.user?.name ?? 'Client';

    Get.back(); // Close dialog first

    Get.to(
      () => ChatScreen(
        isCounselor: true,
        counselorName: clientName,
        channelName: channelName,
        userId: userId,
        appointmentId: widget.appointment.id,
        isViewOnly: true,
        isTroat: widget.appointment.isTroat,
      ),
    );
  }

  // Accept appointment
  Future<void> _acceptAppointment(BuildContext context) async {
    final success = await context
        .read<CounselorAppointmentProvider>()
        .acceptAppointment(
          context: context,
          appointmentId: widget.appointment.id,
        );

    if (success) {
      Get.back(); // Close dialog
      if (widget.appointment.type.toLowerCase() == 'consult_now') {
        _startCall(context);
      }
    }
  }

  // Decline appointment
  void _declineAppointment(BuildContext context) {
    UIHelper.showDialogOk(
      context,
      title: 'Decline Appointment'.tr,
      message: 'Are you sure you want to decline this appointment?'.tr,
      onConfirm: () {
        Get.back(); // Close confirmation dialog
        Get.back(); // Close details dialog
        context.read<CounselorAppointmentProvider>().declineAppointment(
          context: context,
          appointmentId: widget.appointment.id,
        );
      },
    );
  }

  // Format date and time
  String _formatDateTime() {
    if (widget.appointment.isConsultNow) {
      return 'Immediate Consultation'.tr;
    }

    if (widget.appointment.date != null &&
        widget.appointment.timeSlot != null) {
      try {
        final dateTime = DateTime.parse(widget.appointment.date!);
        final formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
        return '$formattedDate ${widget.appointment.timeSlot!.displayTime}';
      } catch (e) {
        return widget.appointment.date ?? 'No date'.tr;
      }
    }

    return widget.appointment.date ?? 'No date'.tr;
  }

  // Format duration if start and end time available
  String? _formatDuration() {
    if (widget.appointment.startTime != null &&
        widget.appointment.endTime != null) {
      try {
        final start = widget.appointment.startTime!.split(':');
        final end = widget.appointment.endTime!.split(':');
        if (start.length >= 2 && end.length >= 2) {
          final startHour = int.parse(start[0]);
          final startMin = int.parse(start[1]);
          final endHour = int.parse(end[0]);
          final endMin = int.parse(end[1]);

          final startTotal = startHour * 60 + startMin;
          final endTotal = endHour * 60 + endMin;
          final duration = endTotal - startTotal;

          if (duration > 0) {
            final hours = duration ~/ 60;
            final minutes = duration % 60;
            if (hours > 0) {
              return '${hours}h ${minutes}m';
            }
            return '${minutes}m';
          }
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final clientName = appointment.user?.name ?? 'Client';
    final clientImage = appointment.user?.image;
    final duration = _formatDuration();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 16,
        child: Container(
          width: Get.width,
          constraints: BoxConstraints(maxHeight: Get.height * 0.85),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
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
                    colors: [
                      primaryColorConsulor,
                      primaryColorConsulor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                          size: 24.w,
                        ),
                        SizedBox(width: 10.w),
                        CustomText(
                          text: 'Appointment Details'.tr,
                          fontSize: FontConstants.font_18,
                          weight: FontWeightConstants.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Info Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                color: primaryColorConsulor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  clientImage != null && clientImage.isNotEmpty
                                      ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: clientImage,
                                          width: 56.w,
                                          height: 56.w,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Container(
                                                width: 56.w,
                                                height: 56.w,
                                                decoration: BoxDecoration(
                                                  color: primaryColorConsulor
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 20.w,
                                                    height: 20.w,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            primaryColorConsulor,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          errorWidget:
                                              (context, url, error) =>
                                                  _buildInitialAvatar(
                                                    clientName,
                                                  ),
                                        ),
                                      )
                                      : _buildInitialAvatar(clientName),
                            ),
                            SizedBox(width: 16.w),
                            // Client details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: clientName,
                                    fontSize: FontConstants.font_16,
                                    weight: FontWeightConstants.bold,
                                    color: Colors.black87,
                                  ),
                                  SizedBox(height: 4.h),
                                  if (appointment.rating != -1) ...[
                                    Row(
                                      children: [
                                        MyRatingView(
                                          initialRating:
                                              appointment.rating.toDouble(),
                                          isAllowRating: false,
                                          itemSize: 14.0,
                                          fsize: FontConstants.font_12,
                                        ),
                                        SizedBox(width: 8.w),
                                        CustomText(
                                          text: appointment.rating.toString(),
                                          fontSize: FontConstants.font_12,
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ] else
                                    CustomText(
                                      text: 'New client'.tr,
                                      fontSize: FontConstants.font_12,
                                      color: Colors.grey[600],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      UIHelper.verticalSpaceMd,

                      // Appointment Details
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date & Time'.tr,
                        value: _formatDateTime(),
                      ),

                      UIHelper.verticalSpaceSm,

                      _buildDetailRow(
                        icon: _getMethodIcon(appointment.method),
                        label: 'Consultation Method'.tr,
                        value: appointment.methodText.tr,
                      ),

                      UIHelper.verticalSpaceSm,

                      if (duration != null)
                        _buildDetailRow(
                          icon: Icons.access_time,
                          label: 'Duration'.tr,
                          value: duration,
                        ),

                      if (duration != null) UIHelper.verticalSpaceSm,

                      _buildDetailRow(
                        icon: Icons.info_outline,
                        label: 'Status'.tr,
                        value: appointment.statusText.tr,
                        valueColor: _getStatusColor(appointment),
                      ),

                      UIHelper.verticalSpaceSm,

                      _buildDetailRow(
                        icon: Icons.category,
                        label: 'Type'.tr,
                        value:
                            appointment.isConsultNow
                                ? 'Immediate Consultation'.tr
                                : 'Scheduled Appointment'.tr,
                      ),

                      UIHelper.verticalSpaceSm,

                      _buildDetailRow(
                        icon: Icons.monetization_on,
                        label: 'Coins'.tr,
                        value: '${appointment.reservedCoins} ${"coins".tr}',
                      ),

                      if (appointment.counsultaionContent != null &&
                          appointment.counsultaionContent!.isNotEmpty) ...[
                        UIHelper.verticalSpaceMd,
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: 18.w,
                                    color: Colors.blue[700],
                                  ),
                                  SizedBox(width: 8.w),
                                  CustomText(
                                    text: 'Consultation Content'.tr,
                                    fontSize: FontConstants.font_14,
                                    weight: FontWeightConstants.semiBold,
                                    color: Colors.blue[700],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              CustomText(
                                text: appointment.counsultaionContent!,
                                fontSize: FontConstants.font_13,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: _buildActionButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: CustomText(
        text: initial,
        fontSize: FontConstants.font_20,
        weight: FontWeightConstants.bold,
        color: primaryColorConsulor,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.w, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                fontSize: FontConstants.font_12,
                color: Colors.grey[600],
              ),
              SizedBox(height: 4.h),
              CustomText(
                text: value,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: valueColor ?? Colors.black87,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'video_call':
        return Icons.videocam;
      case 'voice_call':
        return Icons.phone;
      case 'chat':
        return Icons.chat_bubble;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(AppointmentData appointment) {
    if (appointment.isPending) {
      return Colors.orange;
    } else if (appointment.isCompleted || appointment.isAccepted) {
      return greenColor;
    } else if (appointment.isDeclined) {
      return Colors.red;
    } else if (appointment.isInProgress) {
      return primaryColorConsulor;
    }
    return Colors.grey;
  }

  Widget _buildActionButtons(BuildContext context) {
    final appointment = widget.appointment;
    final isPending = appointment.isPending;
    final isCompleted = appointment.isCompleted;
    final canJoin = _canCounselorJoin();

    // Completed appointments
    if (isCompleted) {
      if (appointment.method.toLowerCase() == 'chat') {
        return SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton.icon(
            onPressed: () => _viewChatHistory(context),
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: CustomText(
              text: 'View Chat'.tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.bold,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: CustomText(
              text: 'Close'.tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.black87,
            ),
          ),
        );
      }
    }

    // Pending appointments - Accept/Decline
    if (isPending) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: OutlinedButton(
                onPressed: () => _declineAppointment(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: CustomText(
                  text: 'Decline'.tr,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => _acceptAppointment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorConsulor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: CustomText(
                  text: 'Accept'.tr,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Confirmed/Ready appointments - Join Now
    if (canJoin) {
      return SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton.icon(
          onPressed: () => _startCall(context),
          icon: Icon(Icons.video_call, color: Colors.white),
          label: CustomText(
            text: 'Join Now'.tr,
            fontSize: FontConstants.font_16,
            weight: FontWeightConstants.bold,
            color: Colors.white,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorConsulor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      );
    }

    // Default - Close button
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: CustomText(
          text: 'Close'.tr,
          fontSize: FontConstants.font_16,
          weight: FontWeightConstants.medium,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Check if counselor can join
  bool _canCounselorJoin() {
    final appointment = widget.appointment;

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

  // Check if appointment time has been reached
  bool _isAppointmentTimeReached() {
    final appointment = widget.appointment;
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

      return now.isAfter(appointmentDateTime) ||
          now.isAtSameMomentAs(appointmentDateTime);
    } catch (e) {
      return false;
    }
  }
}
