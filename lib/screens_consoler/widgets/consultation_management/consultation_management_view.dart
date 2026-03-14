import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/screens_consoler/models/appointment_model.dart';
import 'package:deepinheart/screens_consoler/widgets/consultation_management/consultaion_cardview.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'consultation_tab_bar.dart';
import 'consultation_calendar.dart';

class ConsultationManagementView extends StatefulWidget {
  const ConsultationManagementView({Key? key}) : super(key: key);

  @override
  _ConsultationManagementViewState createState() =>
      _ConsultationManagementViewState();
}

class _ConsultationManagementViewState
    extends State<ConsultationManagementView> {
  ConsultationTab selectedTab = ConsultationTab.reservation;
  DateTime? selectedDate;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CounselorAppointmentProvider>(
        context,
        listen: false,
      );
      provider.fetchAppointments(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: borderColor),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SizedBox(
        width: Get.width,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    align: TextAlign.start,
                    text: 'Consultation\nManagement'.tr,
                    fontSize: FontConstants.font_15,
                    height: 1.3,
                    weight: FontWeightConstants.semiBold,
                    color: Color(0xFF111726),
                  ),
                  UIHelper.horizontalSpaceMd,
                  Expanded(
                    flex: 3,
                    child: ConsultationTabBar(
                      selectedTab: selectedTab,
                      onTabChanged: (tab) {
                        setState(() {
                          selectedTab = tab;
                          _currentPage =
                              1; // Reset to first page when switching tabs
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(thickness: 1, color: borderColor),

            //UIHelper.verticalSpaceMd,

            // Content based on selected tab
            _buildTabContent(),
            UIHelper.verticalSpaceMd,
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<CounselorAppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Padding(
            padding: EdgeInsets.all(50),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: '${"Error".tr}: ${provider.error}',
                    color: Colors.red,
                    fontSize: FontConstants.font_14,
                  ),
                  UIHelper.verticalSpaceSm,
                  ElevatedButton(
                    onPressed: () => provider.fetchAppointments(context),
                    child: CustomText(text: 'Retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        switch (selectedTab) {
          case ConsultationTab.reservation:
            return _buildAppointmentList(
              provider.appointments
                  .where(
                    (appointment) =>
                        appointment.status.toLowerCase() != 'confirmed',
                  )
                  .toList(),
            );

          case ConsultationTab.completed:
            return _buildAppointmentList(provider.completedAppointments);

          case ConsultationTab.schedule:
            return _buildScheduleView(provider);
        }
      },
    );
  }

  Widget _buildAppointmentList(List<AppointmentData> appointments) {
    if (appointments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: CustomText(
            text: 'No appointments found'.tr,
            color: lightGREY,
            fontSize: FontConstants.font_14,
          ),
        ),
      );
    }

    // Calculate pagination
    final totalPages = (appointments.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, appointments.length);
    final paginatedAppointments = appointments.sublist(startIndex, endIndex);

    return Builder(
      builder: (context) {
        return Column(
          children: [
            // Appointment list
            ListView.builder(
              itemCount: paginatedAppointments.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder:
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ConsultaionCardview(
                      type: selectedTab,
                      appointment: paginatedAppointments[index],
                    ),
                  ),
            ),
            // Pagination controls (only show if more than 10 items)
            if (appointments.length > _itemsPerPage) ...[
              UIHelper.verticalSpaceSm,
              _buildPaginationControls(totalPages, appointments.length),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalItems) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Page info - Flexible to prevent overflow
          Flexible(
            flex: 2,
            child: Text(
              '${"Page".tr} $_currentPage / $totalPages (${totalItems} ${"items".tr})',
              style: TextStyle(
                fontSize: FontConstants.font_12,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          // Navigation buttons - Scrollable if needed
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous button
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed:
                        _currentPage > 1
                            ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                            : null,
                    color:
                        _currentPage > 1 ? primaryColorConsulor : Colors.grey,
                    iconSize: 24,
                    padding: EdgeInsets.all(4.w),
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.h,
                    ),
                  ),
                  // Page numbers (show max 5 page numbers)
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                    int pageNumber;
                    if (totalPages <= 5) {
                      pageNumber = index + 1;
                    } else {
                      // Show pages around current page
                      if (_currentPage <= 3) {
                        pageNumber = index + 1;
                      } else if (_currentPage >= totalPages - 2) {
                        pageNumber = totalPages - 4 + index;
                      } else {
                        pageNumber = _currentPage - 2 + index;
                      }
                    }

                    final isCurrentPage = pageNumber == _currentPage;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPage = pageNumber;
                        });
                      },
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color:
                              isCurrentPage ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color:
                                isCurrentPage
                                    ? primaryColor
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: CustomText(
                            text: '$pageNumber',
                            fontSize: FontConstants.font_12,
                            color:
                                isCurrentPage
                                    ? Colors.white
                                    : Colors.grey.shade700,
                            weight:
                                isCurrentPage
                                    ? FontWeightConstants.semiBold
                                    : FontWeightConstants.regular,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Next button
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed:
                        _currentPage < totalPages
                            ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                            : null,
                    color:
                        _currentPage < totalPages ? primaryColor : Colors.grey,
                    iconSize: 24,
                    padding: EdgeInsets.all(4.w),
                    constraints: BoxConstraints(
                      minWidth: 32.w,
                      minHeight: 32.h,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(CounselorAppointmentProvider provider) {
    final consultationDates = provider.appointmentDates;

    return ConsultationCalendar(
      selectedDate: selectedDate,
      onDateSelected: (date) {
        setState(() {
          selectedDate = date;
        });
      },
      consultationDates: consultationDates,
    );
  }
}
