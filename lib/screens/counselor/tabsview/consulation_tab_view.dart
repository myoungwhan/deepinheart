import 'package:deepinheart/Controller/Model/consultation_package_model.dart';
import 'package:deepinheart/Controller/Model/counselor_model.dart';
import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Model/time_slot_model.dart';
import 'package:deepinheart/Controller/Viewmodel/booking_viewmodel.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';

import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/counselor/views/consulation_package_view.dart';
import 'package:deepinheart/screens/counselor/views/product_information_notice.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/text_styles.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class ConsulationTabView extends StatefulWidget {
  final ServiceModel? servicesData;
  final int? sectionId;
  final int? counselorId;
  final CounselorData counsler;
  ConsulationTabView({
    Key? key,
    required this.servicesData,
    this.sectionId,
    this.counselorId,
    required this.counsler,
  }) : super(key: key);

  @override
  ConsulationTabViewState createState() => ConsulationTabViewState();
}

class ConsulationTabViewState extends State<ConsulationTabView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String? todayDate;
  int selectedChipIndex = 0;
  int selectedMethodIndex = -1;
  List<Map<String, dynamic>> options = [];
  List<ConsultationPackage> packages = [];
  String? selectedSlot; // Track selected time slot
  int? selectedSlotId; // Track selected time slot ID
  int? selectedPackageId; // Track selected package ID
  final TextEditingController consultationContentController =
      TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  DateTime firstDate = DateTime(1900);
  DateTime lastDate = DateTime.now();

  // DOB Calendar state
  DateTime? _dobFocusedDay;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchAvailabilityForSelectedDate();
  }

  @override
  void dispose() {
    consultationContentController.dispose();
    dobController.dispose();
    timeController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Initialize consultation methods from ServiceModel
    if (widget.servicesData != null) {
      options = [];
      final method = widget.servicesData!.counsultationMethod;

      if (method.videoCallAvailable == 1) {
        options.add({
          'icon': Icons.videocam,
          'label': 'Video Call',
          'color': Colors.blue,
          'coins': method.videoCallCoin,
        });
      }
      if (method.voiceCallAvailable == 1) {
        options.add({
          'icon': Icons.call,
          'label': 'Voice Call',
          'color': Colors.green,
          'coins': method.voiceCallCoin,
        });
      }
      if (method.chatAvailable == 1) {
        options.add({
          'icon': Icons.chat,
          'label': 'Chat',
          'color': Colors.purple,
          'coins': method.chatCoin,
        });
      }

      // Initialize packages from ServiceModel
      packages =
          widget.servicesData!.packages.map((pkg) {
            // Parse discount rate safely
            double discountRate = 0;
            try {
              discountRate = double.parse(pkg.discountRate);
            } catch (e) {
              print(
                'Error parsing discount rate: ${pkg.discountRate}, error: $e',
              );
              discountRate = 0;
            }

            return ConsultationPackage(
              title: pkg.name,
              subtitle:
                  '${pkg.duration}${'-minute consultation x'.tr}${pkg.session} ${'sessions'.tr}',
              originalPrice: pkg.coins.toDouble(),
              discountedPrice: (pkg.coins * (1 - discountRate / 100)),
              discountPercent: discountRate.toInt(),
            );
          }).toList();
    }
  }

  void _fetchAvailabilityForSelectedDate() {
    if (widget.sectionId != null && widget.counselorId != null) {
      // Reset selected slot when changing date
      setState(() {
        selectedSlot = null;
        selectedSlotId = null;
      });

      final bookingVm = Provider.of<BookingViewmodel>(context, listen: false);
      final dateStr = DateFormat(
        "yyyy-MM-dd",
      ).format(_selectedDay ?? DateTime.now());
      bookingVm.fetchAvailability(
        sectionId: widget.sectionId!,
        date: dateStr,
        counselorId: widget.counselorId!,
      );
    }
  }

  // Get consultation method string for API (public method)
  String? getSelectedMethod() {
    if (selectedMethodIndex < 0 || selectedMethodIndex >= options.length) {
      return null;
    }

    final label = options[selectedMethodIndex]['label'];
    switch (label) {
      case 'Video Call':
        return 'video_call';
      case 'Voice Call':
        return 'voice_call';
      case 'Chat':
        return 'chat';
      default:
        return null;
    }
  }

  // Store appointment via API
  Future<Map<String, dynamic>?> storeAppointment(bool isTroat) async {
    // Validate required fields
    if (widget.sectionId == null) {
      print('Error: service_id is required');
      return {'success': false, 'message': 'Service ID is required'.tr};
    }

    if (widget.counselorId == null) {
      print('Error: counselor_id is required');
      return {'success': false, 'message': 'Counselor ID is required'.tr};
    }

    if (_selectedDay == null) {
      print('Error: date is required');
      return {'success': false, 'message': 'Please select a date'.tr};
    }

    if (selectedSlotId == null) {
      print('Error: time_slot_id is required');
      return {'success': false, 'message': 'Please select a time slot'.tr};
    }

    if (selectedMethodIndex < 0) {
      print('Error: method is required');
      return {
        'success': false,
        'message': 'Please select a consultation method'.tr,
      };
    }

    try {
      final bookingVm = Provider.of<BookingViewmodel>(context, listen: false);

      // Prepare request data
      final requestData = {
        'service_id': widget.servicesData!.id,
        'counselor_id': widget.counselorId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
        'time_slot_id': selectedSlotId,
        'method': getSelectedMethod(),
        'dob': dobController.text + "," + timeController.text,
        'is_tarot': isTroat ? 1 : 0,
        if (selectedPackageId != null) 'package_id': selectedPackageId,
        'counsultaion_content': consultationContentController.text.trim(),
      };

      print('Booking appointment with data: $requestData');

      // Call API
      final response = await bookingVm.storeAppointment(requestData);

      return response;
    } catch (e) {
      print('Error storing appointment: $e');
      return {'success': false, 'message': 'Failed to book appointment: $e'};
    }
  }

  // Validate if booking can be made
  bool canBook() {
    return widget.sectionId != null &&
        widget.counselorId != null &&
        _selectedDay != null &&
        selectedSlotId != null &&
        selectedMethodIndex >= 0;
  }

  // Public getters for accessing private variables
  DateTime? get selectedDay => _selectedDay;

  String _getSelectedCoins() {
    String coinValue;
    if (selectedMethodIndex >= 0 && selectedMethodIndex < options.length) {
      coinValue = options[selectedMethodIndex]['coins'] ?? "0";
    } else if (options.isNotEmpty) {
      // Return default coin value from first available method
      coinValue = options[0]['coins'] ?? "0";
    } else {
      coinValue = "0";
    }

    // Remove .0 or .00 from the end if it's a whole number
    try {
      double parsedValue = double.parse(coinValue);
      if (parsedValue == parsedValue.toInt()) {
        return parsedValue.toInt().toString();
      }
      return parsedValue.toString();
    } catch (e) {
      return coinValue;
    }
  }

  // Group slots by time period (Morning and Afternoon only)
  Map<String, List<TimeSlot>> _groupSlotsByPeriod(List<TimeSlot> slots) {
    Map<String, List<TimeSlot>> grouped = {'Morning': [], 'Afternoon': []};

    for (var slot in slots) {
      try {
        // Parse time from slot label (e.g., "09:00", "14:30")
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
        // If parsing fails, add to Morning as default
        grouped['Morning']!.add(slot);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: Get.width,
        child: Consumer<BookingViewmodel>(
          builder: (context, pr, child) {
            return Column(
              children: [
                UIHelper.verticalSpaceL,

                CustomTitleWithButton(title: "Select Date".tr),
                UIHelper.verticalSpaceSm,

                calnderView(),
                UIHelper.verticalSpaceMd,
                CustomTitleWithButton(title: "Available Time Slots".tr),
                UIHelper.verticalSpaceMd,
                availableSlots(pr, context),
                UIHelper.verticalSpaceMd,
                UIHelper.verticalSpaceSm,

                CustomTitleWithButton(title: "Consultation Method".tr),
                UIHelper.verticalSpaceSm,

                Row(
                  children: [
                    // SvgPicture.asset(
                    //   AppIcons.coinsvg,
                    //   color: Color(0xffEAB308),
                    // ),
                    // //  UIHelper.horizontalSpaceSm5,
                    // CustomText(
                    //   text: _getSelectedCoins() + " coins/min".tr,
                    //   weight: FontWeightConstants.medium,
                    // ),
                    Spacer(),
                    if (widget
                            .servicesData
                            ?.counsultationMethod
                            .taxInvoiceAvailable ==
                        1)
                      CustomText(
                        text: "Tax invoice available".tr,
                        fontSize: 13.0,
                        color: Colors.black45,
                      ),
                  ],
                ),
                UIHelper.verticalSpaceMd,
                options.isEmpty
                    ? Center(
                      child: CustomText(
                        text: "No consultation methods available".tr,
                        color: Colors.grey,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(options.length, (i) {
                        final opt = options[i];
                        return SelectableCard(
                          icon: opt['icon'] as IconData,
                          label: opt['label'] as String,
                          color: opt['color'] as Color,
                          coins:
                              double.tryParse(
                                opt['coins'],
                              )?.toStringAsFixed(0) ??
                              "0",
                          selectedColor: (opt['color'] as Color).withOpacity(
                            0.2,
                          ),
                          selected: selectedMethodIndex == i,
                          onTap: () => setState(() => selectedMethodIndex = i),
                        );
                      }),
                    ),

                UIHelper.verticalSpaceMd,

                if (packages.isNotEmpty) ...[
                  UIHelper.verticalSpaceSm,
                  CustomTitleWithButton(
                    title: "Consultation Package (Optional)".tr,
                  ),
                  UIHelper.verticalSpaceMd,
                  ConsultationSelectorWithRadio(
                    packages: packages,
                    onChanged: (packageIndex) {
                      if (packageIndex >= 0) {
                        setState(() {
                          selectedPackageId =
                              widget.servicesData!.packages[packageIndex].id;
                        });
                        print('Selected package ID: $selectedPackageId');
                      } else {
                        setState(() {
                          selectedPackageId = null;
                        });
                      }
                    },
                  ),
                ],
                UIHelper.verticalSpaceMd,

                CustomTitleWithButton(title: "Consultation Content".tr),
                UIHelper.verticalSpaceMd,
                Customtextfield(
                  controller: consultationContentController,
                  required: true,
                  hint: "brief".tr,
                  keyboard: TextInputType.multiline,
                ),
                UIHelper.verticalSpaceMd,
                widget.servicesData!.profileInformation.timeInput == 1
                    ? Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTitleWithButton(title: "Date of Birth".tr),
                          UIHelper.verticalSpaceSm,

                          //생년월일시 (양력 기준)
                          _buildDOBSelector(),
                        ],
                      ),
                    )
                    : Container(),
                UIHelper.verticalSpaceMd,

                CustomTitleWithButton(
                  title: "Cancellation and Refund Policy".tr,
                ),
                UIHelper.verticalSpaceSm,
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Html(data: pr.cancelationAndRefundPoicy),

                  // child: Column(
                  //   children: [
                  //     CustomText(
                  //       text:
                  //           "This service automatically deducts coins in proportion to the real-time consultation duration, and therefore separate purchase cancellations are not possible."
                  //               .tr,
                  //     ),
                  //     UIHelper.verticalSpaceSm,
                  //     CustomText(
                  //       text:
                  //           "${'However, as an exceptional situation requiring purchase cancellation,'.tr} <strong>&ldquo;${'Consultation Packages'.tr}&rdquo;</strong> ${'can be cancelled and refunded before the service begins.'.tr}",
                  //     ),
                  //     UIHelper.verticalSpaceSm,
                  //   ],
                  // ),
                ),

                InfoTable(
                  items: [
                    InfoItem(
                      label: 'Service Provider'.tr,
                      value: widget.counsler.name,
                      onViewDetails: () {
                        _showCounselorDetails(context);
                      },
                    ),
                    InfoItem(
                      label: 'Cancellation/Refund Terms'.tr,
                      value: 'See Cancellation and Refund Policy'.tr,

                      // onViewDetails: () {
                      //   UIHelper.launchInBrowser1(
                      //     Uri.parse(
                      //       context
                      //               .read<SettingProvider>()
                      //               .settingsModel
                      //               ?.data
                      //               ?.refundPolicySection ??
                      //           '',
                      //     ),
                      //   );
                      // },
                    ),
                    InfoItem(
                      label: 'Cancellation/Refund Method'.tr,
                      value: 'See Cancellation and Refund Policy'.tr,
                    ),
                    InfoItem(
                      label: 'Terms of Use CertificationsPermits'.tr,
                      value: 'See Product Details'.tr,
                    ),
                    InfoItem(
                      label: 'Customer Service'.tr,
                      value: 'Customer Center\n1544-6254',
                    ),
                  ],
                ),

                UIHelper.verticalSpaceL,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget availableSlots(BookingViewmodel pr, BuildContext context) {
    if (pr.isLoadingSlots) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (pr.slots.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CustomText(
            text: "No available slots for this date".tr,
            color: isMainDark ? Colors.white : Colors.grey,
            fontSize: 14.0,
          ),
        ),
      );
    }

    // Group slots by period
    final groupedSlots = _groupSlotsByPeriod(pr.slots);

    return Container(
      width: Get.width,
      padding: EdgeInsets.symmetric(horizontal: 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Morning Section
          if (groupedSlots['Morning']!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: CustomText(
                text: "Morning".tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: isMainDark ? Colors.white70 : Colors.black87,
              ),
            ),
            UIHelper.verticalSpaceSm,
            _buildTimeSlotGrid(groupedSlots['Morning']!),
            UIHelper.verticalSpaceMd,
          ],

          // Afternoon Section
          if (groupedSlots['Afternoon']!.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,

              child: CustomText(
                text: "Afternoon".tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: isMainDark ? Colors.white70 : Colors.black87,
              ),
            ),
            UIHelper.verticalSpaceSm,
            _buildTimeSlotGrid(groupedSlots['Afternoon']!),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlot> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlot == slot.label;

        return GestureDetector(
          onTap:
              slot.available
                  ? () {
                    // _showTimeSlotConfirmation(slot);
                    setState(() {
                      selectedSlot = slot.label;
                      selectedSlotId = slot.id;
                    });
                    print('Selected slot: ${slot.label} (ID: ${slot.id})');
                  }
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color:
                  !slot.available
                      ? Color(0xffF3F4F6)
                      : isSelected
                      ? primaryColor
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    !slot.available
                        ? borderColor
                        : isSelected
                        ? primaryColor
                        : borderColor,
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Center(
              child: CustomText(
                text: slot.label,
                color:
                    !slot.available
                        ? Color(0xffD1D5DB)
                        : isSelected
                        ? Colors.white
                        : Colors.black87,
                fontSize: 12,
                weight: isSelected ? FontWeight.bold : FontWeight.normal,
                maxlines: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTimeSlotConfirmation(TimeSlot slot) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isMainDark ? Color(0xff1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: primaryColor, size: 40.w),
                SizedBox(height: 16.h),
                CustomText(
                  text: 'Select Time Slot'.tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: isMainDark ? Colors.white : Colors.black87,
                ),
                SizedBox(height: 12.h),
                CustomText(
                  text: slot.label,
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.semiBold,
                  color: primaryColor,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor:
                              isMainDark
                                  ? Color(0xff374151)
                                  : Color(0xffF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: CustomText(
                          text: 'Cancel'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          color: isMainDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedSlot = slot.label;
                            selectedSlotId = slot.id;
                          });
                          print(
                            'Selected slot: ${slot.label} (ID: ${slot.id})',
                          );
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: CustomText(
                          text: 'Confirm'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.semiBold,
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
      },
    );
  }

  Widget calnderView() {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      availableGestures: AvailableGestures.horizontalSwipe,
      locale: Get.locale!.languageCode == 'ko' ? 'ko_KR' : 'en_US',

      //disable on scroll
      availableCalendarFormats: {
        CalendarFormat.week: 'Week'.tr,
        CalendarFormat.month: 'Month'.tr,
      },

      headerStyle: HeaderStyle(
        titleCentered: true,
        leftChevronVisible: false,
        rightChevronVisible: false,
        formatButtonVisible: true,

        titleTextStyle: textStyleRobotoRegular(
          color: isMainDark ? Colors.white : Colors.black,
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
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        decoration: BoxDecoration(shape: BoxShape.rectangle),
        weekdayStyle: textStyleRobotoRegular(
          color: isMainDark ? Colors.white : Colors.black,
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
          color: isMainDark ? Colors.white : Colors.black,
          fontSize: 14.0,
          weight: FontWeightConstants.regular,
        ),
        todayDecoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          color: primaryColor.withAlpha(100),
          // image: DecorationImage(image: AssetImage("images/reddate.png")),
        ),
        selectedDecoration: BoxDecoration(
          //  color: Colors.red.withOpacity(0.3),
          // image: DecorationImage(image: AssetImage("images/reddate.png")),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          color: primaryColor,
        ),
      ),
      selectedDayPredicate: (day) {
        // Use `selectedDayPredicate` to determine which day is currently selected.
        // If this returns true, then `day` will be marked as selected.

        // Using `isSameDay` is recommended to disregard
        // the time-part of compared DateTime objects.
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) async {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          todayDate = DateFormat("yyyy-MM-dd").format(selectedDay);
        });

        // Fetch availability for the newly selected date
        _fetchAvailabilityForSelectedDate();
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          // Call `setState()` when updating calendar format
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        // No need to call `setState()` here
        _focusedDay = focusedDay;
      },
    );
  }

  void _showRefundPolicy(BuildContext context) {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    final link =
        settingProvider.settingsModel?.data?.refundPolicySection?.toString();

    if (link == null || link.isEmpty || link == 'null') {
      Get.snackbar(
        'Error'.tr,
        'Policy link not available'.tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
  }

  void _showCounselorDetails(BuildContext context) {
    final counselor = widget.counsler;
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    final customerServicePhone =
        settingProvider.settingsModel?.data?.customerPhoneService ??
        '1544-0000';

    // Format phone number
    final phoneStr = counselor.phone.toString();
    final formattedPhone =
        phoneStr.length > 4 ? phoneStr.substring(0, 4) : phoneStr;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Container(
            width: Get.width * 0.9,
            constraints: BoxConstraints(maxWidth: Get.width * 0.9),
            padding: EdgeInsets.all(0.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: 'Counselor Details'.tr,
                      fontSize: FontConstants.font_18,
                      weight: FontWeightConstants.bold,
                      color: Colors.black87,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: 24.w,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Counselor Information Fields
                _buildInfoRow(
                  label: 'Name/Trade Name'.tr,
                  value: 'Individual'.tr,
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  label: 'Representative Name'.tr,
                  value: counselor.name,
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(label: 'Phone Number'.tr, value: formattedPhone),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  label: 'Email Address'.tr,
                  value: counselor.email,
                ),
                SizedBox(height: 20.h),

                // Legal Disclaimer
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: CustomText(
                    text:
                        '${'Counselor information (phone number, email, address, etc.) cannot be used for commercial marketing, advertising, or other purposes without the explicit consent of the counselor. If information is used without consent, it may be subject to fines and criminal penalties in accordance with the Information and Communications Network Act and related laws. For disputes regarding the viewing of counselor information, please contact Customer Center at'.tr} $customerServicePhone ${'based on the terms of service.'.tr}',
                    fontSize: FontConstants.font_12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: CustomText(
            text: label,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.medium,
            color: Colors.black54,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: CustomText(
            text: value,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.regular,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showTimeSlotMenu() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.6,
              maxWidth: 300.w,
            ),
            decoration: BoxDecoration(
              color: isMainDark ? Color(0xff1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isMainDark ? Color(0xff374151) : Color(0xffF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Select Time'.tr,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.bold,
                        color: isMainDark ? Colors.white : Colors.black87,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: isMainDark ? Colors.white70 : Colors.black54,
                          size: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
                // Time slots list
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Column(children: _buildTimeSlotMenuItems()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTimeSlotMenuItems() {
    // Define time slots similar to the attached image
    final List<Map<String, String>> timeSlots = [
      {'label': '子 (23:30-01:29)', 'value': '23:30 - 01:29'},
      {'label': '丑 (01:30-03:29)', 'value': '01:30 - 03:29'},
      {'label': '寅 (03:30-05:29)', 'value': '03:30 - 05:29'},
      {'label': '卯 (05:30-07:29)', 'value': '05:30 - 07:29'},
      {'label': '辰 (07:30-09:29)', 'value': '07:30 - 09:29'},
      {'label': '巳 (09:30-11:29)', 'value': '09:30 - 11:29'},
      {'label': '午 (11:30-13:29)', 'value': '11:30 - 13:29'},
      {'label': '未 (13:30-15:29)', 'value': '13:30 - 15:29'},
      {'label': '申 (15:30-17:29)', 'value': '15:30 - 17:29'},
      {'label': '酉 (17:30-19:29)', 'value': '17:30 - 19:29'},
      {'label': '戌 (19:30-21:29)', 'value': '19:30 - 21:29'},
      {'label': '亥 (21:30-23:29)', 'value': '21:30 - 23:29'},
    ];

    return timeSlots.map((slot) {
      final isSelected = timeController.text == slot['value'];
      return InkWell(
        onTap: () {
          setState(() {
            timeController.text = slot['value']!;
          });
          Navigator.of(context).pop();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color:
                isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color:
                    isMainDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check, color: primaryColor, size: 20.w),
              if (isSelected) SizedBox(width: 8.w),
              Expanded(
                child: CustomText(
                  text: slot['label']!,
                  fontSize: FontConstants.font_14,
                  weight:
                      isSelected
                          ? FontWeightConstants.semiBold
                          : FontWeightConstants.regular,
                  color:
                      isSelected
                          ? primaryColor
                          : (isMainDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // Reusable date selector button widget
  Widget _buildDateSelectorButton({
    required String text,
    required VoidCallback onTap,
    bool hasBackground = false,
    bool isHint = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 35.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color:
              hasBackground
                  ? primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: text,
              fontSize:
                  text.length > 10
                      ? FontConstants.font_12
                      : FontConstants.font_14,
              weight:
                  isHint
                      ? FontWeightConstants.regular
                      : FontWeightConstants.regular,
              color: isHint ? Colors.grey : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDOBSelector() {
    final currentDate = DateTime.now();
    final isDateNull = _dobFocusedDay == null;

    return Row(
      children: [
        // Year Selector
        Expanded(
          flex: 3,
          child: _buildDateSelectorButton(
            text:
                isDateNull
                    ? 'Year'.tr
                    : DateFormat.y(
                      Get.locale!.languageCode,
                    ).format(_dobFocusedDay!),
            isHint: isDateNull,
            onTap: () async {
              final selectedYear = await _showYearPicker(
                context,
                _dobFocusedDay?.year ?? currentDate.year,
              );
              if (selectedYear != null) {
                setState(() {
                  if (_dobFocusedDay == null) {
                    _dobFocusedDay = DateTime(selectedYear, 1, 1);
                  } else {
                    _dobFocusedDay = DateTime(
                      selectedYear,
                      _dobFocusedDay!.month,
                      _dobFocusedDay!.day,
                    );
                  }
                  dobController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_dobFocusedDay!);
                });
              }
            },
          ),
        ),
        UIHelper.horizontalSpaceSm,
        // Month Selector
        Expanded(
          flex: 2,
          child: _buildDateSelectorButton(
            text:
                isDateNull
                    ? 'Month'.tr
                    : DateFormat.MMMM(
                      Get.locale!.languageCode,
                    ).format(_dobFocusedDay!),
            isHint: isDateNull,
            onTap: () async {
              final selectedMonth = await _showMonthPicker(
                context,
                _dobFocusedDay?.month ?? currentDate.month,
              );
              if (selectedMonth != null) {
                setState(() {
                  if (_dobFocusedDay == null) {
                    _dobFocusedDay = DateTime(
                      currentDate.year,
                      selectedMonth,
                      1,
                    );
                  } else {
                    // Adjust day if needed (e.g., Feb 30 -> Feb 28)
                    final daysInMonth =
                        DateTime(
                          _dobFocusedDay!.year,
                          selectedMonth + 1,
                          0,
                        ).day;
                    final day =
                        _dobFocusedDay!.day > daysInMonth
                            ? daysInMonth
                            : _dobFocusedDay!.day;
                    _dobFocusedDay = DateTime(
                      _dobFocusedDay!.year,
                      selectedMonth,
                      day,
                    );
                  }
                  dobController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_dobFocusedDay!);
                });
              }
            },
          ),
        ),
        UIHelper.horizontalSpaceSm,
        // Day Selector
        Expanded(
          flex: 2,
          child: _buildDateSelectorButton(
            text:
                isDateNull
                    ? 'Day'.tr
                    : DateFormat.d(
                      Get.locale!.languageCode,
                    ).format(_dobFocusedDay!),
            isHint: isDateNull,
            onTap: () async {
              if (_dobFocusedDay == null) {
                // If date is null, initialize with current date
                _dobFocusedDay = currentDate;
              }
              final selectedDay = await _showDayPicker(
                context,
                _dobFocusedDay!.day,
                _dobFocusedDay!.year,
                _dobFocusedDay!.month,
              );
              if (selectedDay != null) {
                setState(() {
                  _dobFocusedDay = DateTime(
                    _dobFocusedDay!.year,
                    _dobFocusedDay!.month,
                    selectedDay,
                  );
                  dobController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_dobFocusedDay!);
                });
              }
            },
          ),
        ),
        UIHelper.horizontalSpaceSm,
        Expanded(
          flex: 3,
          child: _buildDateSelectorButton(
            text: timeController.text.isEmpty ? 'Time'.tr : timeController.text,
            isHint: timeController.text.isEmpty,
            onTap: () {
              _showTimeSlotMenu();
            },
          ),
        ),
      ],
    );
  }

  Future<int?> _showYearPicker(BuildContext context, int currentYear) async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.6,
              maxWidth: 300.w,
            ),
            decoration: BoxDecoration(
              color: isMainDark ? Color(0xff1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isMainDark ? Color(0xff374151) : Color(0xffF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Select Year'.tr,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.bold,
                        color: isMainDark ? Colors.white : Colors.black87,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: isMainDark ? Colors.white70 : Colors.black54,
                          size: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
                // Year list
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: lastDate.year - firstDate.year + 1,
                    itemBuilder: (context, index) {
                      final year = lastDate.year - index;
                      final isSelected = year == currentYear;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(year),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    isMainDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: primaryColor,
                                  size: 20.w,
                                ),
                              if (isSelected) SizedBox(width: 8.w),
                              Expanded(
                                child: CustomText(
                                  text: '$year',
                                  fontSize: FontConstants.font_14,
                                  weight:
                                      isSelected
                                          ? FontWeightConstants.semiBold
                                          : FontWeightConstants.regular,
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : (isMainDark
                                              ? Colors.white
                                              : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showMonthPicker(BuildContext context, int currentMonth) async {
    final months = List.generate(12, (index) {
      final monthDate = DateTime(2000, index + 1);
      return {
        'number': index + 1,
        'name': DateFormat.MMMM(Get.locale!.languageCode).format(monthDate),
      };
    });

    return await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.6,
              maxWidth: 300.w,
            ),
            decoration: BoxDecoration(
              color: isMainDark ? Color(0xff1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isMainDark ? Color(0xff374151) : Color(0xffF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Select Month'.tr,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.bold,
                        color: isMainDark ? Colors.white : Colors.black87,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: isMainDark ? Colors.white70 : Colors.black54,
                          size: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
                // Month list
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final month = months[index];
                      final isSelected = month['number'] == currentMonth;
                      return InkWell(
                        onTap:
                            () => Navigator.of(
                              context,
                            ).pop(month['number'] as int),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    isMainDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: primaryColor,
                                  size: 20.w,
                                ),
                              if (isSelected) SizedBox(width: 8.w),
                              Expanded(
                                child: CustomText(
                                  text: month['name'] as String,
                                  fontSize: FontConstants.font_14,
                                  weight:
                                      isSelected
                                          ? FontWeightConstants.semiBold
                                          : FontWeightConstants.regular,
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : (isMainDark
                                              ? Colors.white
                                              : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showDayPicker(
    BuildContext context,
    int currentDay,
    int year,
    int month,
  ) async {
    // Get the number of days in the selected month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = List.generate(daysInMonth, (index) => index + 1);

    return await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: Get.height * 0.6,
              maxWidth: 300.w,
            ),
            decoration: BoxDecoration(
              color: isMainDark ? Color(0xff1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isMainDark ? Color(0xff374151) : Color(0xffF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Select Day'.tr,
                        fontSize: FontConstants.font_16,
                        weight: FontWeightConstants.bold,
                        color: isMainDark ? Colors.white : Colors.black87,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close,
                          color: isMainDark ? Colors.white70 : Colors.black54,
                          size: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
                // Day list
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isSelected = day == currentDay;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(day),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    isMainDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: primaryColor,
                                  size: 20.w,
                                ),
                              if (isSelected) SizedBox(width: 8.w),
                              Expanded(
                                child: CustomText(
                                  text: '$day',
                                  fontSize: FontConstants.font_14,
                                  weight:
                                      isSelected
                                          ? FontWeightConstants.semiBold
                                          : FontWeightConstants.regular,
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : (isMainDark
                                              ? Colors.white
                                              : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SelectableCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final Color selectedColor;
  String coins;

  SelectableCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.selectedColor,
    required this.coins,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = !selected ? selectedColor : primaryColor;
    final iconColor = selected ? Colors.white : color;
    final textColor = !selected ? color : Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          width: Get.width * 0.27,
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16.w),
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border:
                selected
                    ? Border.all(width: selected ? 1 : 0, color: primaryColor)
                    : Border(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: 6),
              Text(
                label.tr,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              CustomText(
                text: coins + " coins/min".tr,
                color: textColor,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.regular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
