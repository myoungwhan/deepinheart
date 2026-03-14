import 'package:deepinheart/Controller/Viewmodel/loading_provider.dart';
import 'package:deepinheart/screens/reservations/reservation_screen.dart';
import 'package:deepinheart/services/translation_helper.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ConfirmationReservationDialog extends StatefulWidget {
  final String counselorName;
  final String date;
  final String time;
  final String method;
  final String? packageName;
  final Future<Map<String, dynamic>?> Function() onConfirm;

  const ConfirmationReservationDialog({
    Key? key,
    required this.counselorName,
    required this.date,
    required this.time,
    required this.method,
    this.packageName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _ConfirmationReservationDialogState createState() =>
      _ConfirmationReservationDialogState();
}

class _ConfirmationReservationDialogState
    extends State<ConfirmationReservationDialog> {
  bool isChecked = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(15),
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title:
          !isChecked ? null : Center(child: SvgPicture.asset(AppIcons.donesvg)),
      content: Container(
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text:
                  !isChecked
                      ? "Reservation for consultation".tr
                      : "Reservation has been completed".tr,
              fontSize: FontConstants.font_17,
              weight: FontWeightConstants.bold,
            ),
            !isChecked
                ? Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: CustomText(
                    text: "Would you like to make a reservation with".tr
                        .replaceAll('%name%', widget.counselorName),
                    fontSize: FontConstants.font_14,
                  ),
                )
                : Container(height: 0),
            UIHelper.verticalSpaceSm,
            Container(
              width: Get.width,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.84),
                color: Color(0xffF9FAFB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: "Reservation information".tr,
                    weight: FontWeightConstants.medium,
                    fontSize: FontConstants.font_14,
                  ),
                  UIHelper.verticalSpaceSm,
                  CustomText(
                    text: "${"Date".tr}: ${widget.date}",
                    fontSize: FontConstants.font_14,
                  ),
                  CustomText(
                    text: "${"Time".tr}: ${widget.time}",
                    fontSize: FontConstants.font_14,
                  ),
                  CustomText(
                    text: "${"Counseling method".tr}: ${widget.method.tr}",
                    fontSize: FontConstants.font_14,
                  ),
                  if (widget.packageName != null) ...[
                    CustomText(
                      text: "${"Package".tr}: ${widget.packageName}",
                      fontSize: FontConstants.font_14,
                    ),
                  ],
                ],
              ),
            ),
            if (errorMessage != null) ...[
              UIHelper.verticalSpaceSm,
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomText(
                  text: errorMessage!,
                  color: Colors.red,
                  fontSize: FontConstants.font_12,
                ),
              ),
            ],
            UIHelper.verticalSpaceMd,
            Row(
              children: [
                !isChecked
                    ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CustomButton(
                          () {
                            Get.back();
                          },
                          text: "cancellation".tr,
                          textcolor: Colors.black,
                          color: Colors.white,
                          buttonBorderColor: Colors.grey,
                        ),
                      ),
                    )
                    : Container(),
                Expanded(
                  child: CustomButton(() async {
                    if (!isChecked) {
                      // Call actual booking API
                      context.read<LoadingProvider>().showLoading();

                      try {
                        final response = await widget.onConfirm();

                        context.read<LoadingProvider>().hideLoading();

                        if (response != null && response['success'] == true) {
                          setState(() {
                            isChecked = true;
                            errorMessage = null;
                          });
                          Get.to(ReservationScreen());
                        } else {
                          String
                          message = await TranslationHelper.translateError(
                            response?['message'] ??
                                'Failed to book appointment. Please try again.',
                          );

                          setState(() {
                            errorMessage =
                                message ??
                                'Failed to book appointment. Please try again.'
                                    .tr;
                          });
                        }
                      } catch (e) {
                        context.read<LoadingProvider>().hideLoading();
                        setState(() {
                          errorMessage = "An error occurred:".tr + ' $e';
                        });
                      }
                    } else {
                      Get.back();
                    }
                  }, text: "Check".tr),
                ),
              ],
            ),
            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }
}
