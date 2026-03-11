import 'dart:convert';

import 'package:deepinheart/Controller/Model/bank_account_model.dart';
import 'package:deepinheart/Controller/Model/revenue_statements_model.dart';
import 'package:deepinheart/Controller/Viewmodel/counselor_appointment_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:deepinheart/screens_consoler/account/tab_views/services/tabview/add_fortuneservice_tabview.dart';
import 'package:deepinheart/views/app_icons.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/consuler_custom_nav_bar.dart';
import 'package:deepinheart/views/custom_appbar.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/custom_textfiled.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RevenueSattlementsScreen extends StatefulWidget {
  const RevenueSattlementsScreen({Key? key}) : super(key: key);

  @override
  _RevenueSattlementsScreenState createState() =>
      _RevenueSattlementsScreenState();
}

class _RevenueSattlementsScreenState extends State<RevenueSattlementsScreen> {
  TextEditingController _withdrawalController = TextEditingController();
  double _requestAmount = 0.0;
  double _feeAmount = 0.0;
  double _netAmount = 0.0;

  // API data
  bool _isLoading = true;
  RevenueStatementsData? _revenueData;

  // Convenience getters
  int get _accumulatedCoins => _revenueData?.accumulatedCoins ?? 0;
  int get _coinToRevenue => _revenueData?.coinToRevenue ?? 0;
  int get _thisMonthRevenue => _revenueData?.thisMonthRevenue ?? 0;
  int get _withdrawableCoins => _revenueData?.withdrawable_coins ?? 0;
  List<ConsultationHistoryItem> get _consultationHistory =>
      _revenueData?.consultationHistory ?? [];
  List<WithdrawHistoryItem> get _withdrawHistory =>
      _revenueData?.withdrawHistory ?? [];

  // Tab state
  int _selectedTab = 0; // 0 for Consultation History, 1 for Withdrawal History

  // Consultation Filter states
  DateTime? _consultationFromDate;
  DateTime? _consultationToDate;
  String _consultationStatusFilter =
      'All'; // All, Completed, Pending, Cancelled

  // Withdrawal Filter states
  DateTime? _withdrawalFromDate;
  DateTime? _withdrawalToDate;
  String _withdrawalStatusFilter = 'All'; // All, Completed, Pending, Rejected

  // Bank Account
  BankAccount? _bankAccount;
  bool _isLoadingBankAccount = false;

  // Withdrawal validation
  String? _coinsError;

  // Pagination state
  int _consultationCurrentPage = 1;
  int _withdrawalCurrentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _withdrawalController.addListener(_calculateAmounts);
    _fetchRevenueData();
    _fetchBankAccount();
  }

  Future<void> _fetchRevenueData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final counselorId = userViewModel.userModel?.data.id;

      if (counselorId == null) {
        throw Exception('Counselor ID not found');
      }

      final provider = Provider.of<CounselorAppointmentProvider>(
        context,
        listen: false,
      );

      final data = await provider.fetchRevenueStatements(
        context: context,
        counselorId: counselorId,
      );

      setState(() {
        _revenueData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      UIHelper.showBottomFlash(
        context,
        title: 'Error'.tr,
        message: '${'Failed to load revenue data:'.tr} $e',
        isError: true,
      );
    }
  }

  void _calculateAmounts() {
    setState(() {
      final coins = int.tryParse(_withdrawalController.text) ?? 0;

      // Validate coins don't exceed available balance
      if (coins > _withdrawableCoins && _withdrawalController.text.isNotEmpty) {
        _coinsError =
            '${'Cannot exceed available balance'.tr} ($_withdrawableCoins ${'coins'.tr})';
        _requestAmount = 0.0;
        _feeAmount = 0.0;
        _netAmount = 0.0;
      } else {
        _coinsError = null;
        // Calculate monetary value using SettingProvider
        final settingProvider = Provider.of<SettingProvider>(
          context,
          listen: false,
        );
        _requestAmount = settingProvider.calculateCoinValue(coins);
        _feeAmount = _requestAmount * 0; // 10% fee
        _netAmount = _requestAmount - _feeAmount;
      }
    });
  }

  /// Fetch bank account from API
  Future<void> _fetchBankAccount() async {
    setState(() {
      _isLoadingBankAccount = true;
    });

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Bank Account API: No token available');
        setState(() {
          _isLoadingBankAccount = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiEndPoints.BASE_URL}bank-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final model = BankAccountModel.fromJson(data);
          setState(() {
            _bankAccount = model.data;
            _isLoadingBankAccount = false;
          });
          debugPrint('✅ Bank Account fetched successfully');
        } else {
          debugPrint('❌ Bank Account API error: ${data['message']}');
          setState(() {
            _isLoadingBankAccount = false;
          });
        }
      } else {
        debugPrint(
          '❌ Bank Account API failed: ${response.statusCode} - ${response.body}',
        );
        setState(() {
          _isLoadingBankAccount = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching bank account: $e');
      setState(() {
        _isLoadingBankAccount = false;
      });
    }
  }

  /// Add or update bank account
  Future<void> _addOrUpdateBankAccount({
    required String bankName,
    required String accountNumber,
    required String holderName,
  }) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error'.tr,
          'User not authenticated'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}bank-account'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['bank_name'] = bankName;
      request.fields['account_number'] = accountNumber;
      request.fields['holder_name'] = holderName;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Close loading
      Get.back();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Get.snackbar(
            'Success'.tr,
            'Bank account saved successfully'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // Refresh bank account data
          _fetchBankAccount();
        } else {
          Get.snackbar(
            'Error'.tr,
            data['message'] ?? 'Failed to save bank account'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar(
          'Error',
          data['message'] ?? 'Failed to save bank account',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading if open
      debugPrint('❌ Error saving bank account: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to save bank account. Please try again.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Request withdrawal API call
  Future<void> _requestWithdrawal() async {
    // Check if there's a validation error
    if (_coinsError != null) {
      Get.snackbar(
        'Error',
        _coinsError!,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Validate coins input
    final coinsText = _withdrawalController.text.trim();
    if (coinsText.isEmpty) {
      Get.snackbar(
        'Error'.tr,
        'Please enter coins to withdraw'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final coins = int.tryParse(coinsText);
    if (coins == null || coins <= 0) {
      Get.snackbar(
        'Error'.tr,
        'Please enter a valid number of coins'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Check if coins exceed available balance
    if (coins > _withdrawableCoins) {
      Get.snackbar(
        'Error'.tr,
        '${'Insufficient coins. You have'.tr} $_withdrawableCoins ${'coins available.'.tr}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Check if bank account is added
    if (_bankAccount == null) {
      Get.snackbar(
        'Error'.tr,
        'Please add a bank account before requesting withdrawal'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error'.tr,
          'User not authenticated'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Calculate amount (net amount after fee)
      final amount = _netAmount.toInt();

      final response = await http.post(
        Uri.parse('${ApiEndPoints.BASE_URL}withdraw'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coins': coins, 'amount': amount}),
      );

      // Close loading
      Get.back();

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          Get.snackbar(
            'Success'.tr,
            data['message'] ?? 'Withdrawal request submitted successfully'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );

          // Clear the input field
          _withdrawalController.clear();
          setState(() {
            _requestAmount = 0.0;
            _feeAmount = 0.0;
            _netAmount = 0.0;
          });

          // Refresh revenue data to update accumulated coins
          _fetchRevenueData();
        } else {
          Get.snackbar(
            'Error'.tr,
            data['message'] ?? 'Failed to submit withdrawal request'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          data['message'] ?? 'Failed to submit withdrawal request',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading if open
      debugPrint('❌ Error requesting withdrawal: $e');
      Get.snackbar(
        'Error'.tr,
        'Failed to submit withdrawal request. Please try again.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show dialog to add or change bank account
  void _showBankAccountDialog() {
    final bankNameController = TextEditingController(
      text: _bankAccount?.bankName ?? '',
    );
    final accountNumberController = TextEditingController(
      text: _bankAccount?.accountNumber ?? '',
    );
    final holderNameController = TextEditingController(
      text: _bankAccount?.holderName ?? '',
    );

    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Container(
          width: Get.width,
          padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              CustomText(
                text:
                    _bankAccount == null
                        ? 'Add Account'.tr
                        : 'Change Account'.tr,
                fontSize: FontConstants.font_18,
                weight: FontWeightConstants.bold,
                color: Color(0xFF111726),
              ),
              SizedBox(height: 24.h),

              // Select Bank
              CustomText(
                text: 'Select Bank'.tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: Color(0xFF111726),
              ),
              SizedBox(height: 8.h),
              _buildSimpleTextField(
                controller: bankNameController,
                hint: 'Select or enter bank name'.tr,
              ),
              SizedBox(height: 16.h),

              // Account Number
              CustomText(
                text: 'Account Number'.tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: Color(0xFF111726),
              ),
              SizedBox(height: 8.h),
              _buildSimpleTextField(
                controller: accountNumberController,
                hint: 'Enter account number (no dashes)'.tr,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),

              // Account Holder Name
              CustomText(
                text: 'Account Holder Name'.tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: Color(0xFF111726),
              ),
              SizedBox(height: 8.h),
              _buildSimpleTextField(
                controller: holderNameController,
                hint: 'Enter account holder name'.tr,
              ),
              SizedBox(height: 24.h),

              // Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: CustomText(
                        text: 'Cancel'.tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Save Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final bankName = bankNameController.text.trim();
                        final accountNumber =
                            accountNumberController.text.trim();
                        final holderName = holderNameController.text.trim();

                        if (bankName.isEmpty) {
                          Get.snackbar(
                            'Error'.tr,
                            'Please enter bank name'.tr,
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        if (accountNumber.isEmpty) {
                          Get.snackbar(
                            'Error'.tr,
                            'Please enter account number'.tr,
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        if (holderName.isEmpty) {
                          Get.snackbar(
                            'Error'.tr,
                            'Please enter account holder name'.tr,
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        Get.back(); // Close dialog
                        _addOrUpdateBankAccount(
                          bankName: bankName,
                          accountNumber: accountNumber,
                          holderName: holderName,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3B82F6),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: CustomText(
                        text: 'Save'.tr,
                        fontSize: FontConstants.font_14,
                        weight: FontWeightConstants.medium,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14.sp, color: Color(0xFF111726)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14.sp, color: Color(0xFF9CA3AF)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // Filter consultations based on date and status
  List<ConsultationHistoryItem> get _filteredConsultations {
    List<ConsultationHistoryItem> filtered = List.from(_consultationHistory);

    // Filter to only show consultations with reservedCoins > 0
    filtered = filtered.where((item) => item.reservedCoins > 0).toList();

    // Apply status filter
    if (_consultationStatusFilter != 'All') {
      filtered =
          filtered.where((item) {
            if (_consultationStatusFilter == 'Completed') {
              return item.status.toLowerCase() == 'completed' ||
                  item.status.toLowerCase() == 'confirmed';
            } else if (_consultationStatusFilter == 'Pending') {
              return item.status.toLowerCase() == 'upcoming';
            } else if (_consultationStatusFilter == 'Cancelled') {
              return item.status.toLowerCase() == 'cancelled';
            }

            return true;
          }).toList();
    }

    // Apply date filters if set
    if (_consultationFromDate != null || _consultationToDate != null) {
      filtered =
          filtered.where((item) {
            DateTime itemDate;

            // Parse date, use today's date if empty or invalid
            if (item.date.isEmpty) {
              itemDate = DateTime.now();
            } else {
              try {
                itemDate = DateTime.parse(item.date);
              } catch (e) {
                debugPrint(
                  'Error parsing date: ${item.date}, using current date',
                );
                itemDate = DateTime.now();
              }
            }

            // Check from date
            if (_consultationFromDate != null) {
              final fromDateStart = DateTime(
                _consultationFromDate!.year,
                _consultationFromDate!.month,
                _consultationFromDate!.day,
              );
              if (itemDate.isBefore(fromDateStart)) {
                return false;
              }
            }

            // Check to date
            if (_consultationToDate != null) {
              final toDateEnd = DateTime(
                _consultationToDate!.year,
                _consultationToDate!.month,
                _consultationToDate!.day,
                23,
                59,
                59,
              );
              if (itemDate.isAfter(toDateEnd)) {
                return false;
              }
            }

            return true;
          }).toList();
    }

    return filtered;
  }

  // Filter withdrawals based on date and status
  List<WithdrawHistoryItem> get _filteredWithdrawals {
    List<WithdrawHistoryItem> filtered = List.from(_withdrawHistory);

    // Apply status filter
    if (_withdrawalStatusFilter != 'All') {
      filtered =
          filtered.where((item) {
            if (_withdrawalStatusFilter == 'Completed') {
              return item.isCompleted;
            } else if (_withdrawalStatusFilter == 'Pending') {
              return item.isPending;
            } else if (_withdrawalStatusFilter == 'Rejected') {
              return item.isRejected;
            }
            return true;
          }).toList();
    }

    // Apply date filters if set
    if (_withdrawalFromDate != null || _withdrawalToDate != null) {
      filtered =
          filtered.where((item) {
            DateTime itemDate;

            // Parse date from createdAt
            try {
              final datePart = item.createdAt.split(' ')[0];
              itemDate = DateTime.parse(datePart);
            } catch (e) {
              debugPrint(
                'Error parsing date: ${item.createdAt}, using current date',
              );
              itemDate = DateTime.now();
            }

            // Check from date
            if (_withdrawalFromDate != null) {
              final fromDateStart = DateTime(
                _withdrawalFromDate!.year,
                _withdrawalFromDate!.month,
                _withdrawalFromDate!.day,
              );
              if (itemDate.isBefore(fromDateStart)) {
                return false;
              }
            }

            // Check to date
            if (_withdrawalToDate != null) {
              final toDateEnd = DateTime(
                _withdrawalToDate!.year,
                _withdrawalToDate!.month,
                _withdrawalToDate!.day,
                23,
                59,
                59,
              );
              if (itemDate.isAfter(toDateEnd)) {
                return false;
              }
            }

            return true;
          }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _withdrawalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        title: 'Revenue Settlements'.tr,
        action: [Container()],
      ),
      bottomNavigationBar: ConsulerCustomBottomNav(2),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColorConsulor,
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchRevenueData,
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.all(16.w),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 1,
                              ),
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildRevenueCard(
                                title: 'Total Accumulated Coins'.tr,
                                value: _accumulatedCoins
                                    .toString()
                                    .replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]},',
                                    ),
                                subtitle: '≈ ${_coinToRevenue}',
                                iconColor: Color(0xFF2563EB),
                                icon: AppIcons.circlecoinsvg,
                              );
                            } else {
                              return _buildRevenueCard(
                                title: 'This Month\'s Revenue'.tr,
                                value: _thisMonthRevenue.toString(),
                                subtitle:
                                    _thisMonthRevenue > 0
                                        ? '↑ +${((_thisMonthRevenue / (_accumulatedCoins > 0 ? _accumulatedCoins : 1)) * 100).toStringAsFixed(1)}%'
                                        : 'No revenue yet'.tr,
                                iconColor: Color(0xFFD1FAE5),
                                icon: AppIcons.circlegraphsvg,
                                subtitleColor: Color(0xFF16A34A),
                              );
                            }
                          },
                        ),
                        UIHelper.verticalSpaceMd,
                        _buildConsultationHistory(),
                        UIHelper.verticalSpaceMd,
                        _buildWithdrawalForm(),
                        UIHelper.verticalSpaceMd,
                        _buildExchangeInformationCard(),
                        UIHelper.verticalSpaceMd,
                        _buildSettlementGuideCard(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required String icon,
    Color? subtitleColor,
  }) {
    return Container(
      padding: EdgeInsets.all(17.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFE4E7EB)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon section
          Container(
            padding: EdgeInsets.only(bottom: 8.h),
            child: SvgPicture.asset(icon),
          ),
          // Title section
          Container(
            padding: EdgeInsets.only(bottom: 4.h),
            child: CustomText(
              text: title,
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.regular,
              color: Color(0xFF4A5462),
              height: 1.33,
            ),
          ),
          // Value section
          Container(
            padding: EdgeInsets.only(bottom: 4.h),
            child: CustomText(
              text: value,
              fontSize: FontConstants.font_20,
              weight: FontWeightConstants.bold,
              color: Color(0xFF111726),
              height: 1.40,
            ),
          ),
          // Subtitle section
          CustomText(
            text: subtitle,
            fontSize: FontConstants.font_12,
            weight: FontWeightConstants.regular,
            color: subtitleColor ?? Color(0xFF6A7280),
            height: 1.33,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationHistory() {
    return Container(
      width: Get.width,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFE4E7EB)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        shadows: [boxShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab('Consultation History'.tr, 0),
              SizedBox(width: 16.w),
              _buildTab('Withdrawal History'.tr, 1),
            ],
          ),

          UIHelper.verticalSpaceMd,

          // Date Pickers Row - Different for Consultation vs Withdrawal
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  date:
                      _selectedTab == 0
                          ? _consultationFromDate
                          : _withdrawalFromDate,
                  onDateSelected: (date) {
                    setState(() {
                      if (_selectedTab == 0) {
                        _consultationFromDate = date;
                      } else {
                        _withdrawalFromDate = date;
                      }
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: CustomText(
                  text: '~',
                  fontSize: FontConstants.font_16,
                  weight: FontWeightConstants.medium,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: _buildDatePicker(
                  date:
                      _selectedTab == 0
                          ? _consultationToDate
                          : _withdrawalToDate,
                  onDateSelected: (date) {
                    setState(() {
                      if (_selectedTab == 0) {
                        _consultationToDate = date;
                        _consultationCurrentPage = 1; // Reset pagination
                      } else {
                        _withdrawalToDate = date;
                        _withdrawalCurrentPage = 1; // Reset pagination
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          UIHelper.verticalSpaceMd,

          // Status Filter Chips - Different for Consultation vs Withdrawal
          if (_selectedTab == 0)
            // Consultation filters
            Row(
              children: [
                _buildConsultationStatusChip('All', 'All'.tr),
                SizedBox(width: 8.w),
                _buildConsultationStatusChip('Completed', 'Completed'.tr),
                SizedBox(width: 8.w),
                _buildConsultationStatusChip('Pending', 'Pending'.tr),
                SizedBox(width: 8.w),
                _buildConsultationStatusChip('Cancelled', 'Cancelled'.tr),
              ],
            )
          else
            // Withdrawal filters
            Row(
              children: [
                _buildWithdrawalStatusChip('All', 'All'.tr),
                SizedBox(width: 8.w),
                _buildWithdrawalStatusChip('Completed', 'Completed'.tr),
                SizedBox(width: 8.w),
                _buildWithdrawalStatusChip('Pending', 'Pending'.tr),
                SizedBox(width: 8.w),
                _buildWithdrawalStatusChip('Rejected', 'Rejected'.tr),
              ],
            ),

          UIHelper.verticalSpaceMd,

          // List of consultations/withdrawals
          if (_selectedTab == 0)
            _buildConsultationList()
          else
            _buildWithdrawalList(),
        ],
      ),
    );
  }

  Widget _buildConsultationList() {
    final filteredList = _filteredConsultations;

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.h),
          child: Column(
            children: [
              Icon(Icons.history, size: 64.sp, color: Colors.grey[400]),
              UIHelper.verticalSpaceSm,
              CustomText(
                text: 'No consultation history found'.tr,
                fontSize: FontConstants.font_14,
                color: Colors.grey[600]!,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate pagination
    final totalPages = (filteredList.length / _itemsPerPage).ceil();
    final startIndex = (_consultationCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredList.length);
    final paginatedList = filteredList.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: paginatedList.length,
          separatorBuilder: (_, __) => Divider(height: 0.1, color: lightGREY),
          itemBuilder: (context, index) {
            final item = paginatedList[index];
            return _buildConsultationItem(item);
          },
        ),
        // Pagination controls (only show if more than 10 items)
        if (filteredList.length > _itemsPerPage) ...[
          UIHelper.verticalSpaceSm,
          _buildPaginationControls(
            totalPages,
            filteredList.length,
            _consultationCurrentPage,
            (page) {
              setState(() {
                _consultationCurrentPage = page;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWithdrawalList() {
    final filteredList = _filteredWithdrawals;

    if (filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.h),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64.sp,
                color: Colors.grey[400],
              ),
              UIHelper.verticalSpaceSm,
              CustomText(
                text: 'No withdrawal history found'.tr,
                fontSize: FontConstants.font_14,
                color: Colors.grey[600]!,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate pagination
    final totalPages = (filteredList.length / _itemsPerPage).ceil();
    final startIndex = (_withdrawalCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredList.length);
    final paginatedList = filteredList.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: paginatedList.length,
          itemBuilder: (context, index) {
            return _buildWithdrawalItem(paginatedList[index]);
          },
        ),
        // Pagination controls (only show if more than 10 items)
        if (filteredList.length > _itemsPerPage) ...[
          UIHelper.verticalSpaceSm,
          _buildPaginationControls(
            totalPages,
            filteredList.length,
            _withdrawalCurrentPage,
            (page) {
              setState(() {
                _withdrawalCurrentPage = page;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildWithdrawalItem(WithdrawHistoryItem item) {
    // Get status colors
    Color statusColor;
    Color statusBgColor;
    String statusText;

    if (item.isCompleted) {
      statusColor = Color(0xFF059669);
      statusBgColor = Color(0xFFD1FAE5);
      statusText = 'Completed'.tr;
    } else if (item.isRejected) {
      statusColor = Color(0xFFDC2626);
      statusBgColor = Color(0xFFFEE2E2);
      statusText = 'Rejected'.tr;
    } else {
      statusColor = Color(0xFFF59E0B);
      statusBgColor = Color(0xFFFEF3C7);
      statusText = 'Pending'.tr;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Left side - Withdrawal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(
                      text: '${item.coins} ${'Coins'.tr}',
                      fontSize: FontConstants.font_16,
                      weight: FontWeightConstants.semiBold,
                      color: Color(0xFF111726),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: CustomText(
                        text: statusText,
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.medium,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                UIHelper.verticalSpaceSm,
                Row(
                  children: [
                    CustomText(
                      text: '${'Amount:'.tr} ₩${item.amount}',
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.regular,
                      color: Color(0xFF6B7280),
                    ),
                    if (item.fee > 0) ...[
                      SizedBox(width: 8.w),
                      CustomText(
                        text: '(${'Fee:'.tr} ₩${item.fee})',
                        fontSize: FontConstants.font_12,
                        weight: FontWeightConstants.regular,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ],
                ),
                UIHelper.verticalSpaceSm,
                CustomText(
                  text: item.formattedDate,
                  fontSize: FontConstants.font_12,
                  weight: FontWeightConstants.regular,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          // Right side - Net amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                text: '₩${item.netAmount}',
                fontSize: FontConstants.font_18,
                weight: FontWeightConstants.bold,
                color: item.isCompleted ? Color(0xFF059669) : Color(0xFF111726),
              ),
              CustomText(
                text: 'Net Amount'.tr,
                fontSize: FontConstants.font_12,
                weight: FontWeightConstants.regular,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationItem(ConsultationHistoryItem item) {
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (item.status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
        statusColor = Color(0xFF059669);
        statusBgColor = Color(0xFFD1FAE5);
        statusText = 'Completed'.tr;
        break;
      case 'upcoming':
      case 'pending':
        statusColor = Color(0xFFF59E0B);
        statusBgColor = Color(0xFFFEF3C7);
        statusText = 'Pending'.tr;
        break;
      case 'cancelled':
        statusColor = Color(0xFFDC2626);
        statusBgColor = Color(0xFFFEE2E2);
        statusText = 'Cancelled'.tr;
        break;
      default:
        statusColor = Color(0xFF6B7280);
        statusBgColor = Color(0xFFF3F4F6);
        statusText = 'Unsettled'.tr;
    }

    // Format date - use model's formatted date or current date
    String formattedDate;
    if (item.date.isNotEmpty) {
      try {
        formattedDate = DateFormat(
          'yyyy.MM.dd',
        ).format(DateTime.parse(item.date));
      } catch (e) {
        debugPrint('Error formatting date: ${item.date}');
        formattedDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
      }
    } else {
      formattedDate = DateFormat('yyyy.MM.dd').format(DateTime.now());
    }

    // Format time using model's helper
    String formattedTime = item.formattedTimeRange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.r),
        // border: Border.all(color: Color(0xFFE4E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Row: Date/Time and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: formattedDate,
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.medium,
                    color: Colors.black87,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: formattedTime,
                    fontSize: FontConstants.font_12,
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: CustomText(
                  text: statusText,
                  fontSize: FontConstants.font_13,
                  weight: FontWeightConstants.medium,
                  color: statusColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Second Row: Client and Coins
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text:
                          '${'Client:'.tr} ${item.user.name.isNotEmpty ? item.user.name : 'N/A'.tr}',
                      fontSize: FontConstants.font_14,
                      weight: FontWeightConstants.regular,
                      color: Colors.black87,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text:
                          '${item.durationInMinutes} ${'min ×'.tr} ${item.methodCoins} ${'coins/min'.tr}',
                      fontSize: FontConstants.font_14,
                      color: Colors.grey[600]!,
                    ),
                  ],
                ),
              ),
              CustomText(
                text:
                    '${item.reservedCoins.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${'coins'.tr}',
                fontSize: FontConstants.font_18,
                weight: FontWeightConstants.bold,
                color: Colors.black87,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          // Reset pagination when switching tabs
          _consultationCurrentPage = 1;
          _withdrawalCurrentPage = 1;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? primaryColorConsulor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive ? primaryColorConsulor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: CustomText(
          text: label,
          fontSize: FontConstants.font_13,
          weight: FontWeightConstants.medium,
          color: isActive ? Colors.white : Colors.grey[700]!,
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text:
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : '-/-/-',
              fontSize: FontConstants.font_14,
              color: date != null ? Colors.black87 : Colors.grey[500]!,
            ),
            Icon(Icons.calendar_today, size: 18.sp, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationStatusChip(String filterValue, String displayText) {
    bool isActive = _consultationStatusFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _consultationStatusFilter = filterValue;
          _consultationCurrentPage =
              1; // Reset to first page when filter changes
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? primaryColorConsulor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: CustomText(
          text: displayText,
          fontSize: FontConstants.font_13,
          weight: FontWeightConstants.medium,
          color: isActive ? Colors.white : Colors.grey[700]!,
        ),
      ),
    );
  }

  Widget _buildWithdrawalStatusChip(String filterValue, String displayText) {
    bool isActive = _withdrawalStatusFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _withdrawalStatusFilter = filterValue;
          _withdrawalCurrentPage = 1; // Reset to first page when filter changes
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? primaryColorConsulor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: CustomText(
          text: displayText,
          fontSize: FontConstants.font_13,
          weight: FontWeightConstants.medium,
          color: isActive ? Colors.white : Colors.grey[700]!,
        ),
      ),
    );
  }

  Widget _buildWithdrawalForm() {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(17.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: const Color(0xFFE4E7EB)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Withdrawable Coins Section
          Container(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              width: Get.width,
              padding: EdgeInsets.all(16.w),
              decoration: ShapeDecoration(
                color: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(
                          text: 'Withdrawable Coins'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          color: Color(0xFF374050),
                          height: 1.43,
                        ),
                        CustomText(
                          text: _withdrawableCoins.toString(),
                          fontSize: FontConstants.font_24,
                          weight: FontWeightConstants.bold,
                          color: primaryColorConsulor,
                          height: 1.33,
                        ),
                      ],
                    ),
                  ),
                  CustomText(
                    text: '≈ ₩$_coinToRevenue ${'(excluding fees)'.tr}',
                    fontSize: FontConstants.font_14,
                    weight: FontWeightConstants.regular,
                    color: Color(0xFF4A5462),
                    height: 1.43,
                  ),
                ],
              ),
            ),
          ),

          // Withdrawal Request Section
          Container(
            width: Get.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Customtextfield(
                      required: true,
                      hint: 'Enter coins to withdraw'.tr,
                      text: 'Withdrawal Request Coins'.tr,
                      controller: _withdrawalController,
                      keyboard: TextInputType.number,
                      fontSize: FontConstants.font_14,
                      // borderColor: _coinsError != null ? Colors.red : null,
                      suffix: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: CustomText(
                          text: 'Coins'.tr,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      onChanged: (value) {
                        // Trigger calculation which includes validation
                        _calculateAmounts();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter coins to withdraw'.tr;
                        }
                        return null;
                      },
                    ),
                    if (_coinsError != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h, left: 4.w),
                        child: CustomText(
                          text: _coinsError!,
                          fontSize: FontConstants.font_12,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),

                // Fee Calculation Section
                Container(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Container(
                    width: Get.width,
                    padding: EdgeInsets.all(16.w),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF9FAFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Request Amount
                        Container(
                          width: Get.width,
                          height: 20.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: 'Request Amount'.tr,
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.regular,
                                color: Color(0xFF4A5462),
                                height: 1.43,
                              ),
                              CustomText(
                                text: '₩${_requestAmount.toStringAsFixed(0)}',
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.medium,
                                color: Colors.black,
                                height: 1.43,
                              ),
                            ],
                          ),
                        ),

                        // Fee
                        Container(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: 'Fee (10%)'.tr,
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.regular,
                                color: Color(0xFF4A5462),
                                height: 1.43,
                              ),
                              CustomText(
                                text: '-₩${_feeAmount.toStringAsFixed(0)}',
                                fontSize: FontConstants.font_14,
                                weight: FontWeightConstants.medium,
                                color: Color(0xFFDB2525),
                                height: 1.43,
                              ),
                            ],
                          ),
                        ),

                        Divider(color: borderColor),

                        // Separator and Net Amount
                        Container(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Container(
                            width: Get.width,
                            height: 28.h,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: 'Net Amount',
                                  fontSize: FontConstants.font_14,
                                  weight: FontWeightConstants.medium,
                                  color: Color(0xFF111726),
                                  height: 1.50,
                                ),
                                CustomText(
                                  text: '₩${_netAmount.toStringAsFixed(0)}',
                                  fontSize: FontConstants.font_18,
                                  weight: FontWeightConstants.bold,
                                  color: Color(0xFF3B81F5),
                                  height: 1.56,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Withdrawal Account Section
                Container(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: CustomText(
                          text: 'Withdrawal Account'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          color: Color(0xFF374050),
                          height: 1.43,
                        ),
                      ),
                      Container(
                        width: Get.width,
                        padding: EdgeInsets.all(12.w),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF9FAFA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child:
                            _isLoadingBankAccount
                                ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.h),
                                    child: SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              primaryColorConsulor,
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                                : _bankAccount != null
                                ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: _bankAccount!.displayText,
                                      fontSize: FontConstants.font_14,
                                      weight: FontWeightConstants.regular,
                                      color: Color(0xFF111726),
                                      height: 1.43,
                                    ),
                                    CustomText(
                                      text: _bankAccount!.holderName,
                                      fontSize: FontConstants.font_14,
                                      weight: FontWeightConstants.regular,
                                      color: Color(0xFF4A5462),
                                      height: 1.43,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: GestureDetector(
                                        onTap: _showBankAccountDialog,
                                        child: CustomText(
                                          text: 'Change Account'.tr,
                                          fontSize: FontConstants.font_14,
                                          weight: FontWeightConstants.regular,
                                          color: Color(0xFF3B81F5),
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'No bank account added'.tr,
                                      fontSize: FontConstants.font_14,
                                      weight: FontWeightConstants.regular,
                                      color: Color(0xFF6B7280),
                                      height: 1.43,
                                    ),
                                    Container(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: GestureDetector(
                                        onTap: _showBankAccountDialog,
                                        child: CustomText(
                                          text: 'Add Account'.tr,
                                          fontSize: FontConstants.font_14,
                                          weight: FontWeightConstants.medium,
                                          color: Color(0xFF3B81F5),
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ],
                  ),
                ),

                // Request Withdrawal Button
                Container(
                  padding: EdgeInsets.only(top: 16.h),
                  child: GestureDetector(
                    onTap: _requestWithdrawal,
                    child: Container(
                      width: Get.width,
                      height: 45.h,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF3B81F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Center(
                        child: CustomText(
                          text: 'Request Withdrawal'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.medium,
                          color: Colors.white,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeInformationCard() {
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    final coinRate = settingProvider.coinPricePerUnit;
    final formattedCoinRate =
        coinRate % 1 == 0
            ? '₩${coinRate.toInt()}'
            : '₩${coinRate.toStringAsFixed(2)}';

    return Container(
      width: Get.width,
      padding: EdgeInsets.all(17.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(16.r),
        ),
        shadows: [boxShadow()],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Container(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Container(
              width: Get.width,
              height: 28.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    text: 'Exchange Information'.tr,
                    fontSize: FontConstants.font_18,
                    weight: FontWeightConstants.semiBold,
                    color: Color(0xFF111726),
                    height: 1.56,
                  ),
                ],
              ),
            ),
          ),

          // Information Rows
          infoRow(text: '1 coin exchange rate'.tr, value: formattedCoinRate),
          UIHelper.verticalSpaceSm,
          infoRow(text: 'Withdrawal fee'.tr, value: '10%'),
          UIHelper.verticalSpaceSm,
          infoRow(text: 'Minimum withdrawal'.tr, value: '1,000 coins'.tr),
        ],
      ),
    );
  }

  Widget infoRow({required String text, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomText(
          text: text,
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.regular,
          color: Color(0xFF4A5462),
          height: 1.43,
        ),
        Spacer(),
        CustomText(
          text: value,
          fontSize: FontConstants.font_14,
          weight: FontWeightConstants.medium,
          color: Color(0xFF111726),
          height: 1.50,
        ),
      ],
    );
  }

  Widget _buildSettlementGuideCard() {
    return Container(
      width: Get.width,
      padding: EdgeInsets.all(17.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(16.r),
        ),
        shadows: [boxShadow()],
      ),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section with Icon
          Container(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Row(
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  child: Icon(
                    Icons.info_outline,
                    size: 20.sp,
                    color: Color(0xFF111726),
                  ),
                ),
                // Title
                Container(
                  padding: EdgeInsets.only(left: 8.w),
                  child: CustomText(
                    text: 'Settlement Guide'.tr,
                    fontSize: FontConstants.font_18,
                    weight: FontWeightConstants.semiBold,
                    color: Color(0xFF111726),
                    height: 1.56,
                  ),
                ),
              ],
            ),
          ),

          // Guide Items
          guideRow(
            text: 'Settlement processing occurs on the 10th of each month'.tr,
          ),
          guideRow(
            text:
                'Funds are deposited within 3-5 business days after withdrawal request'
                    .tr,
          ),
          guideRow(text: 'Minimum withdrawal amount is 1,000 coins'.tr),
          guideRow(text: 'A 10% fee is deducted upon withdrawal'.tr),
          guideRow(text: 'Withdrawal requests are processed manually'.tr),
        ],
      ),
    );
  }

  Widget guideRow({required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 8.h),
            child: Container(
              width: 6.w,
              height: 6.h,
              decoration: ShapeDecoration(
                color: const Color(0xFF9CA2AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          UIHelper.horizontalSpaceSm,
          Expanded(
            child: CustomText(
              text: text,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Color(0xFF4A5462),
              height: 1.43,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(
    int totalPages,
    int totalItems,
    int currentPage,
    Function(int) onPageChanged,
  ) {
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
              '${"Page".tr} $currentPage / $totalPages (${totalItems} ${"items".tr})',
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
                        currentPage > 1
                            ? () {
                              onPageChanged(currentPage - 1);
                            }
                            : null,
                    color: currentPage > 1 ? primaryColorConsulor : Colors.grey,
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
                      if (currentPage <= 3) {
                        pageNumber = index + 1;
                      } else if (currentPage >= totalPages - 2) {
                        pageNumber = totalPages - 4 + index;
                      } else {
                        pageNumber = currentPage - 2 + index;
                      }
                    }

                    final isCurrentPage = pageNumber == currentPage;
                    return GestureDetector(
                      onTap: () {
                        onPageChanged(pageNumber);
                      },
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color:
                              isCurrentPage
                                  ? primaryColorConsulor
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color:
                                isCurrentPage
                                    ? primaryColorConsulor
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
                        currentPage < totalPages
                            ? () {
                              onPageChanged(currentPage + 1);
                            }
                            : null,
                    color:
                        currentPage < totalPages
                            ? primaryColorConsulor
                            : Colors.grey,
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
}
