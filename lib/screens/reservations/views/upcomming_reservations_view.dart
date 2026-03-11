import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/screens/reservations/views/reservation_card.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class UpcommingReservationsView extends StatefulWidget {
  final Future<void> Function()? onRefresh;

  const UpcommingReservationsView({Key? key, this.onRefresh}) : super(key: key);

  @override
  _UpcommingReservationsViewState createState() =>
      _UpcommingReservationsViewState();
}

class _UpcommingReservationsViewState extends State<UpcommingReservationsView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewmodel>(
      builder: (context, pr, child) {
        final reservationGroups = pr.upcomingReservations;

        // Only show loading indicator on initial load (when no data exists)
        // Don't show loading during background auto-refresh (when data already exists)
        if (pr.isLoadingReservations && reservationGroups.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (reservationGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                UIHelper.verticalSpaceMd,
                CustomText(
                  text: "No upcoming reservations".tr,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.medium,
                  color: Colors.grey[600],
                ),
                UIHelper.verticalSpaceSm,
                CustomText(
                  text: "Your upcoming appointments will appear here".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Colors.grey[500],
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          color: primaryColor,
          child: ListView.builder(
            itemCount: reservationGroups.length,
            itemBuilder: (context, groupIndex) {
              final group = reservationGroups[groupIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header
                  FutureBuilder<String>(
                    future: translationService.translate(group.title),
                    builder: (context, asyncSnapshot) {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(
                          top: groupIndex > 0 ? 20 : 0,
                          bottom: 0,
                        ),
                        color: primaryColor.withAlpha(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child:
                              asyncSnapshot.hasData
                                  ? CustomText(
                                    text: asyncSnapshot.data ?? group.title,
                                    fontSize: FontConstants.font_14,
                                    weight: FontWeightConstants.medium,
                                    color:
                                        Get.isDarkMode
                                            ? Colors.white
                                            : Color(0xff374151),
                                  )
                                  : SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                  // Appointments in this group
                  ...group.appointments.map((appointment) {
                    final reservation = appointment.toLegacyReservation();
                    return ReservationCard(
                      res: reservation,
                      appointment: appointment,
                      isUpcomming: true,
                    );
                  }).toList(),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
