import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CancelReservationDialog extends StatefulWidget {
  final int appointmentId;
  final VoidCallback? onCancelled;

  const CancelReservationDialog({
    Key? key,
    required this.appointmentId,
    this.onCancelled,
  }) : super(key: key);

  @override
  State<CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<CancelReservationDialog> {
  bool _isCancelling = false;

  Future<void> _cancelAppointment() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final bookingViewModel = Provider.of<BookingViewmodel>(
        context,
        listen: false,
      );

      final response = await bookingViewModel.cancelAppointment(
        widget.appointmentId,
      );

      setState(() {
        _isCancelling = false;
      });

      if (response['success'] == true) {
        // Close dialog
        Get.back();

        // Show success message
        UIHelper.showBottomFlash(
          context,
          title: 'Success',
          message: response['message'] ?? 'Appointment cancelled successfully',
          isError: false,
        );

        // Refresh reservations
        await bookingViewModel.fetchReservations(status: 'upcoming');
        await bookingViewModel.fetchReservations(status: 'past');

        // Call callback if provided
        widget.onCancelled?.call();
      } else {
        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: response['message'] ?? 'Failed to cancel appointment',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isCancelling = false;
      });

      UIHelper.showBottomFlash(
        context,
        title: 'Error',
        message: 'Failed to cancel appointment: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Center(child: SvgPicture.asset(AppIcons.cancelsvg)),
      content: SizedBox(
        width: Get.width * 0.8,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: "Would you like to cancel your reservation?".tr,
                weight: FontWeightConstants.medium,
                align: TextAlign.center,
                fontSize: FontConstants.font_15,
              ),
              UIHelper.verticalSpaceSm,
              CustomText(
                text:
                    "The number of cancellations is recorded internally when canceled."
                        .tr,
                fontSize: FontConstants.font_12,
                align: TextAlign.center,
              ),
              UIHelper.verticalSpaceMd,
              CustomButton(
                _isCancelling ? () {} : _cancelAppointment,
                text:
                    _isCancelling
                        ? "Cancelling...".tr
                        : "Canceling reservation".tr,
                color: Colors.red,
                textcolor: whiteColor,
              ),
              UIHelper.verticalSpaceSm,
              CustomButton(
                () {
                  Get.back();
                },
                text: "Return".tr,
                isCancelButton: true,
              ),
              UIHelper.verticalSpaceMd,
            ],
          ),
        ),
      ),
    );
  }
}
