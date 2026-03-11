import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/screens/reservations/views/reservation_card.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PastReservationsView extends StatelessWidget {
  final Future<void> Function()? onRefresh;

  const PastReservationsView({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final refreshCallback = onRefresh;
    return Consumer<BookingViewmodel>(
      builder: (context, pr, child) {
        final reservationGroups = pr.pastReservations;

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
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                UIHelper.verticalSpaceMd,
                CustomText(
                  text: "No past reservations".tr,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.medium,
                  color: Colors.grey[600],
                ),
                UIHelper.verticalSpaceSm,
                CustomText(
                  text: "Your completed appointments will appear here".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Colors.grey[500],
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: refreshCallback ?? () async {},
          color: primaryColor,
          child: ListView.builder(
          itemCount: reservationGroups.length,
          itemBuilder: (context, groupIndex) {
            final group = reservationGroups[groupIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    top: groupIndex > 0 ? 20 : 0,
                    bottom: 10,
                  ),
                  color: Colors.grey.withAlpha(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: CustomText(
                      text: group.title,
                      fontSize: FontConstants.font_16,
                      weight: FontWeightConstants.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),

                // Appointments in this group
                ...group.appointments.map((appointment) {
                  final reservation = appointment.toLegacyReservation();
                  return ReservationCard(
                    res: reservation,
                    appointment: appointment,
                    isUpcomming: false,
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
