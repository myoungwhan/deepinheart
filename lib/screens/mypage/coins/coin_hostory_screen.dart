import 'package:deepinheart/Controller/Viewmodel/payment_provider.dart';
import 'package:deepinheart/Controller/locale_controller.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/screens/mypage/coins/coin_charging_screen.dart';
import 'package:deepinheart/screens/mypage/views/custom_chip_selection.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_button.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:provider/provider.dart';

class CoinHistoryPage extends StatefulWidget {
  @override
  _CoinHistoryPageState createState() => _CoinHistoryPageState();
}

class _CoinHistoryPageState extends State<CoinHistoryPage>
    with SingleTickerProviderStateMixin {
  int _selectedPeriodIndex = 0;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sortOrder = 'Latest';
  final List<String> _periods = [
    'Last 1 Month',
    'Last 3 Months',
    'Last 6 Months',
  ];
  final List<String> _sortOptions = ['Latest', 'Oldest'];

  // API data
  bool _isLoading = true;
  int _totalAvailable = 0;
  int _totalUsed = 0;
  List<CoinHistoryItem> _histories = [];

  @override
  void initState() {
    super.initState();
    _fetchCoinHistory();
  }

  Future<void> _fetchCoinHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      final response = await paymentProvider.fetchCoinHistory();

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _totalAvailable = data['total_available'] ?? 0;
          _totalUsed = data['total_used'] ?? 0;

          _histories =
              (data['histories'] as List?)
                  ?.map((item) => CoinHistoryItem.fromJson(item))
                  .toList() ??
              [];

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: response['message'] ?? 'Failed to fetch coin history',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      UIHelper.showBottomFlash(
        context,
        title: 'Error',
        message: 'Failed to load coin history: $e',
        isError: true,
      );
    }
  }

  List<CoinHistoryItem> get _filteredItems {
    List<CoinHistoryItem> filtered = List.from(_histories);

    // Apply date filters if set
    if (_fromDate != null) {
      filtered =
          filtered.where((item) {
            return item.dateTime.isAfter(_fromDate!) ||
                item.dateTime.isAtSameMomentAs(_fromDate!);
          }).toList();
    }

    if (_toDate != null) {
      filtered =
          filtered.where((item) {
            final endOfDay = DateTime(
              _toDate!.year,
              _toDate!.month,
              _toDate!.day,
              23,
              59,
              59,
            );
            return item.dateTime.isBefore(endOfDay) ||
                item.dateTime.isAtSameMomentAs(endOfDay);
          }).toList();
    }

    // Apply sorting
    if (_sortOrder == 'Latest') {
      filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } else {
      filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF9FAFB),
      appBar: customAppBar(
        isLogo: false,
        centerTitle: false,
        title: "Coin History".tr,
        action: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 120.0,
              height: 36.0,
              child: CustomButton(
                () {
                  // recharge action
                  Get.to(CoinChargingScreen());
                },
                text: 'Recharge'.tr,
                fsize: FontConstants.font_14,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _fetchCoinHistory,
                  child: Column(
                    children: [
                      // Summary card
                      UIHelper.verticalSpaceMd,
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'Available Coins'.tr,
                                      fontSize: FontConstants.font_14,
                                      color: lightGREY,
                                    ),
                                    UIHelper.verticalSpaceSm5,
                                    CustomText(
                                      text:
                                          '${_totalAvailable.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${'Coins'.tr}',
                                      fontSize: FontConstants.font_20,
                                      weight: FontWeightConstants.bold,
                                      color: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      text: 'Used This Month'.tr,
                                      fontSize: FontConstants.font_14,
                                      color: lightGREY,
                                    ),
                                    UIHelper.verticalSpaceSm5,
                                    CustomText(
                                      text:
                                          '${_totalUsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${'Coins'.tr}',
                                      fontSize: FontConstants.font_20,
                                      weight: FontWeightConstants.bold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Period tabs
                      //   UIHelper.verticalSpaceMd,
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.r),
                          child: Column(
                            children: [
                              CustomSelectionChip(
                                chips: _periods,
                                selectedChip: _periods[_selectedPeriodIndex],
                                onSelected: (value) {
                                  setState(() {
                                    _selectedPeriodIndex = _periods.indexWhere(
                                      (e) => e == value,
                                    );
                                  });
                                },
                              ),

                              UIHelper.verticalSpaceMd,

                              // Date pickers
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CustomDatePicker(
                                        initialDate: _fromDate,
                                        onDateChanged: (newDate) {
                                          setState(() {
                                            _fromDate = newDate;
                                          });
                                        },
                                        label: 'From Date'.tr,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: CustomText(
                                        text: '~',
                                        fontSize: 16,
                                        weight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomDatePicker(
                                        initialDate: _toDate,
                                        onDateChanged: (newDate) {
                                          setState(() {
                                            _toDate = newDate;
                                          });
                                        },
                                        label: 'To Date'.tr,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      UIHelper.verticalSpaceSm,

                      // Sort + Label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            CustomText(
                              text: 'Coin/Coupon Usage History'.tr,
                              fontSize: FontConstants.font_16,
                              weight: FontWeightConstants.bold,
                              color: Colors.black,
                            ),
                            Spacer(),
                            DropdownButton<String>(
                              value: _sortOrder,
                              underline: SizedBox(),
                              borderRadius: BorderRadius.circular(5),
                              items:
                                  _sortOptions
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: CustomText(
                                            text: s.tr,
                                            fontSize: 14,
                                            weight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _sortOrder = v!),
                            ),
                          ],
                        ),
                      ),

                      UIHelper.verticalSpaceSm,

                      // History List
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(10.r),
                            child:
                                _filteredItems.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          UIHelper.verticalSpaceMd,
                                          CustomText(
                                            text: 'No history found'.tr,
                                            fontSize: FontConstants.font_16,
                                            weight: FontWeightConstants.medium,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    )
                                    : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      itemCount: _filteredItems.length,
                                      separatorBuilder:
                                          (_, __) => Divider(thickness: 0.2),
                                      itemBuilder: (ctx, i) {
                                        final item = _filteredItems[i];
                                        final isNegative = item.coins < 0;
                                        final color =
                                            isNegative
                                                ? Colors.red
                                                : Colors.green;
                                        final sign = isNegative ? '' : '+';

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 5,
                                            top: 5,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    CustomText(
                                                      text:
                                                          item.action ==
                                                                  "charge"
                                                              ? item.title.tr
                                                              : (item.category) +
                                                                  " " +
                                                                  "Consultation"
                                                                      .tr,
                                                      fontSize: 14,
                                                      weight: FontWeight.w500,
                                                      color: Colors.black,
                                                    ),
                                                    UIHelper.verticalSpaceSm5,
                                                    FutureBuilder(
                                                      future: translationService
                                                          .translate(
                                                            item.createdAt,
                                                          ),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        return CustomText(
                                                          text:
                                                              snapshot.hasData
                                                                  ? snapshot
                                                                      .data!
                                                                  : item
                                                                      .createdAt,
                                                          fontSize: 12,
                                                          weight:
                                                              FontWeight.w400,
                                                          color:
                                                              Colors.grey[600]!,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  CustomText(
                                                    text:
                                                        '$sign${item.coins.abs()} ${'Coins'.tr}',
                                                    fontSize: 14,
                                                    weight: FontWeight.w600,
                                                    color: color,
                                                  ),
                                                  UIHelper.verticalSpaceSm5,
                                                  CustomText(
                                                    text:
                                                        (item.action.capitalizeFirst ??
                                                                item.action)
                                                            .tr,
                                                    fontSize: 12,
                                                    weight: FontWeight.w400,
                                                    color: Colors.grey[600]!,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

// Coin History Item Model
class CoinHistoryItem {
  final int id;
  final String title;
  final String action;
  final int coins;
  final String createdAt;
  final DateTime dateTime;
  final String category;

  CoinHistoryItem({
    required this.id,
    required this.title,
    required this.action,
    required this.coins,
    required this.createdAt,
    required this.dateTime,
    required this.category,
  });

  factory CoinHistoryItem.fromJson(Map<String, dynamic> json) {
    // Parse the created_at string to DateTime
    DateTime parsedDate;
    try {
      // Try to parse the date format: "18 Oct 2025, 09:50 PM"
      parsedDate = DateFormat(
        'dd MMM yyyy, hh:mm a',
        Get.locale!.languageCode,
      ).parse(json['created_at']);
    } catch (e) {
      // If parsing fails, use current date as fallback
      debugPrint('Error parsing date: ${json['created_at']}');
      parsedDate = DateTime.now();
    }

    return CoinHistoryItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      action: json['action'] ?? '',
      coins: int.tryParse(json['coins'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      dateTime: parsedDate,
      category: json['category'] ?? '',
    );
  }
}

class CustomDatePicker extends StatelessWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateChanged;
  final String label;

  const CustomDatePicker({
    Key? key,
    required this.initialDate,
    required this.onDateChanged,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateFormat df = DateFormat('yyyy-MM-dd'); // Date format for display

    return GestureDetector(
      onTap: () async {
        DateTime? selectedDate = await _pickDate(context);
        if (selectedDate != null) {
          onDateChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              initialDate == null ? '– $label –' : df.format(initialDate!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the date picker dialog
  Future<DateTime?> _pickDate(BuildContext context) async {
    DateTime initialDate = this.initialDate ?? DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    return pickedDate;
  }
}
