import 'dart:async';
import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/screens/reservations/past_reservations_view.dart';
import 'package:deepinheart/screens/reservations/views/upcomming_reservations_view.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_nav_bar.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with SingleTickerProviderStateMixin {
  List<String> listTags = ["Upcoming".tr, "Past".tr];
  TabController? _tabController;
  Timer? _autoRefreshTimer; // Timer for auto-refresh every 1 minute

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: listTags.length,
      vsync: this,
      initialIndex: 0,
    );

    // Fetch reservations data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReservations();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  void _fetchReservations() {
    final bookingViewModel = Provider.of<BookingViewmodel>(
      context,
      listen: false,
    );

    // Fetch both upcoming and past reservations
    bookingViewModel.fetchReservations(status: 'upcoming');
    bookingViewModel.fetchReservations(status: 'past');
  }

  /// Start auto-refresh timer (every 1 minute)
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // Cancel existing timer if any
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchReservations();
      } else {
        timer.cancel();
      }
    });
  }

  /// Handle pull-to-refresh
  Future<void> _onRefresh() async {
    _fetchReservations();
    // Wait a bit to show refresh indicator
    await Future.delayed(Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Reservations".tr, centerTitle: false),
      bottomNavigationBar: CustomBottomNav(1),
      body: Container(
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              automaticIndicatorColorAdjustment: false,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: primaryColor,

              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 2,
              labelStyle: textStyleRobotoRegular(
                weight: FontWeightConstants.medium,
                fontSize: FontConstants.font_14,
              ),
              unselectedLabelStyle: textStyleRobotoRegular(
                weight: FontWeightConstants.medium,
                fontSize: FontConstants.font_14,
              ),
              tabs: [for (var tag in listTags) Tab(text: tag.tr)],
            ),
            UIHelper.verticalSpaceSm,
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  UpcommingReservationsView(onRefresh: _onRefresh),
                  PastReservationsView(onRefresh: _onRefresh),
                ],
              ),
            ),
          ],
        ),
      ).paddingSymmetric(horizontal: 15.r),
    );
  }
}
