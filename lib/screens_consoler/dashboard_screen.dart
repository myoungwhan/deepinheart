import 'dart:async';

import 'package:deepinheart/Controller/Model/counselor_dashboard_model.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:http/http.dart' as http;
import 'package:deepinheart/screens_consoler/widgets/fav_clients/fav_clients.dart';
import 'package:deepinheart/screens_consoler/widgets/notification_icon_widget.dart';
import 'package:deepinheart/screens_consoler/widgets/feedback/custom_feednack.dart';
import 'package:deepinheart/screens_consoler/widgets/notification_settings/notification_settings.dart';
import 'package:deepinheart/views/consuler_custom_nav_bar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'widgets/sessions_card.dart';
import 'widgets/revenue_card.dart';
import 'widgets/scheduled_sessions_card.dart';
import 'widgets/rating_card.dart';
import 'widgets/consultation_management/consultation_management_view.dart';
import 'models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isConsultationRoomActive = true;
  TimePeriod selectedTimePeriod = TimePeriod.day;
  late DashboardData dashboardData;
  Timer? _backgroundRefreshTimer;

  @override
  void initState() {
    super.initState();
    dashboardData = DashboardData.sample();
    // Initialize consultation room status from user model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = context.read<UserViewModel>();
      final isAvailable = userViewModel.userModel?.data.isAvailable ?? true;
      if (mounted) {
        setState(() {
          isConsultationRoomActive = isAvailable;
        });
      }
      userViewModel.callConsulerDashboardData();
    });

    // Start background refresh timer (every 30 seconds)
    _backgroundRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    _backgroundRefreshTimer?.cancel();
    super.dispose();
  }

  // Silent refresh without loading indicators
  void _silentRefresh() {
    context.read<CounselorAppointmentProvider>().fetchAppointmentsSilently(
      context,
    );
  }

  Future<void> _refreshDashboard() async {
    await context.read<UserViewModel>().callConsulerDashboardData();
    context.read<CounselorAppointmentProvider>().fetchAppointments(context);
  }

  /// Get formatted revenue value based on selected time period
  String _getRevenueValue(CounselorDashboardData? apiData, TimePeriod period) {
    if (apiData == null) {
      return dashboardData.revenue.getFormattedRevenue(period);
    }

    num revenueAmount;
    switch (period) {
      case TimePeriod.day:
        revenueAmount = apiData.revenue.daily;
        break;
      case TimePeriod.week:
        revenueAmount = apiData.revenue.weekly;
        break;
      case TimePeriod.month:
        revenueAmount = apiData.revenue.monthly;
        break;
    }

    return '$appCurrency ${revenueAmount.toStringAsFixed(0)}';
  }

  /// Get change percentage and comparison text based on selected time period
  String _getChangePercentage(
    CounselorDashboardData? apiData,
    TimePeriod period,
  ) {
    if (apiData == null) {
      return '+${dashboardData.revenue.changePercentage}% ${"vs Yesterday".tr}';
    }

    num changeValue;
    String comparisonText;
    switch (period) {
      case TimePeriod.day:
        changeValue = apiData.revenue.dailyVsYesterday;
        comparisonText = "vs Yesterday".tr;
        break;
      case TimePeriod.week:
        changeValue = apiData.revenue.weeklyVsLastWeek;
        comparisonText = "vs Last Week".tr;
        break;
      case TimePeriod.month:
        changeValue = apiData.revenue.monthlyVsLastMonth;
        comparisonText = "vs Last Month".tr;
        break;
    }

    final sign = changeValue >= 0 ? '+' : '';
    return '$sign${changeValue.toStringAsFixed(0)}% $comparisonText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appbar(),
      bottomNavigationBar: ConsulerCustomBottomNav(0),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Grid
                Consumer<UserViewModel>(
                  builder: (context, userViewModel, child) {
                    final apiData = userViewModel.counselorDashboard;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 13.w,
                      mainAxisSpacing: 13.h,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.1,
                      children: [
                        // Today's Sessions Card
                        SessionsCard(
                          sessionCount:
                              apiData?.todaySession.toString() ??
                              dashboardData.sessions.todayCount.toString(),
                          totalTime:
                              apiData?.todaySessionTime ??
                              '${"Total".tr} ${dashboardData.sessions.totalTime}',
                          isOnline: dashboardData.sessions.isOnline,
                          onTap: () {
                            // Handle sessions card tap
                            _showSessionsDetails();
                          },
                        ),

                        // Revenue Card with Time Period Selector
                        RevenueCard(
                          revenue: _getRevenueValue(
                            apiData,
                            selectedTimePeriod,
                          ),
                          changePercentage: _getChangePercentage(
                            apiData,
                            selectedTimePeriod,
                          ),
                          selectedPeriod: selectedTimePeriod,
                          onPeriodChanged: (period) {
                            setState(() {
                              selectedTimePeriod = period;
                            });
                          },
                          onTap: () {
                            // Handle revenue card tap
                            _showRevenueDetails();
                          },
                        ),

                        // Scheduled Sessions Card
                        ScheduledSessionsCard(
                          currentSessions:
                              apiData?.weeklySession.toString() ??
                              dashboardData.scheduledSessions.currentSessions
                                  .toString(),
                          totalSessions:
                              dashboardData.scheduledSessions.totalSessions
                                  .toString(),
                          nextSessionTime:
                              dashboardData.scheduledSessions.nextSessionTime,
                          onTap: () {
                            // Handle scheduled sessions card tap
                            _showScheduledSessionsDetails();
                          },
                        ),

                        // Rating Card
                        RatingCard(
                          rating:
                              apiData?.rating.toString() ??
                              dashboardData.rating.averageRating.toString(),
                          totalReviews:
                              apiData?.rating_count.toString() ??
                              dashboardData.rating.totalReviews.toString(),
                          onTap: () {
                            // Handle rating card tap
                            _showRatingDetails();
                          },
                        ),
                      
                      ],
                    );
                  },
                ),

                UIHelper.verticalSpaceMd,

                // Consultation Management View
                Container(
                  width: Get.width,
                  child: ConsultationManagementView(),
                ),

                UIHelper.verticalSpaceSm,

                // Feedback View
                Container(width: Get.width, child: CustomFeednack()),

                UIHelper.verticalSpaceSm,

                // Favorite Clients View
                Container(width: Get.width, child: FavClients()),

                UIHelper.verticalSpaceSm,

                // Notification Settings View
                Container(width: Get.width, child: NotificationSettings()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSize appbar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(120.h),
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 2,
              offset: Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Expanded(
                  flex: 2,
                  child: CustomText(
                    text: 'Counselor Dashboard'.tr,
                    height: 1.2,
                    fontSize: FontConstants.font_18,
                    weight: FontWeightConstants.bold,
                  ),
                ),

                // Consultation Room Text and Switch
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomText(
                        text: 'Consultation\nRoom'.tr,
                        color: Color(0xFF4A5462),
                      ),
                      SizedBox(width: 12.w),

                      // Switch Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isConsultationRoomActive =
                                !isConsultationRoomActive;
                          });
                          _updateAvailability();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 46.w,
                          height: 26.h,
                          decoration: BoxDecoration(
                            color:
                                isConsultationRoomActive
                                    ? primaryColorConsulor
                                    : Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: Duration(milliseconds: 200),
                                left: isConsultationRoomActive ? 22.w : 2.w,
                                top: 2.h,
                                child: Container(
                                  width: 20.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Notification Icon with Badge
                      NotificationIconWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionsDetails() {
    // TODO: Navigate to sessions details screen
    print('Sessions details tapped');
  }

  void _showRevenueDetails() {
    // TODO: Navigate to revenue details screen
    print('Revenue details tapped');
  }

  void _showScheduledSessionsDetails() {
    // TODO: Navigate to scheduled sessions details screen
    print('Scheduled sessions details tapped');
  }

  void _showRatingDetails() {
    // TODO: Navigate to rating details screen
    print('Rating details tapped');
  }

  /// Update counselor availability status
  Future<void> _updateAvailability() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;
      final counselorId = userViewModel.userModel?.data.id;

      if (token == null || token.isEmpty || counselorId == null) {
        debugPrint('Cannot update availability: Missing token or counselor ID');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.UPDATE_IS_AVAILABLE),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['counselor_id'] = counselorId.toString();
      request.fields['is_available'] = isConsultationRoomActive ? '1' : '0';

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        debugPrint('✅ Availability updated successfully: $responseBody');
        UIHelper.showBottomFlash(
          context,
          title: 'Success',
          message: 'Availability updated successfully'.tr,
          isError: false,
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint(
          '❌ Failed to update availability: ${response.statusCode} - $responseBody',
        );
        // Revert the state on failure
        setState(() {
          isConsultationRoomActive = !isConsultationRoomActive;
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating availability: $e');
      // Revert the state on error
      setState(() {
        isConsultationRoomActive = !isConsultationRoomActive;
      });
    }
  }
}
