import 'dart:convert';
import 'package:deepinheart/Controller/Model/settings_model.dart';
import 'package:deepinheart/Controller/Model/emergency_announcement_model.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/widgets/maintenance_dialog.dart';
import 'package:deepinheart/widgets/emergency_notice_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SettingProvider extends ChangeNotifier {
  SettingsModel? _settingsModel;
  bool _isLoading = false;
  String? _error;
  EmergencyAnnouncementModel? _emergencyAnnouncements;
  EmergencyAnnouncementModel? _announcements;
  bool _isLoadingAnnouncements = false;

  // Getters
  SettingsModel? get settingsModel => _settingsModel;
  SettingsData? get settings => _settingsModel?.data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSettings => _settingsModel != null;
  EmergencyAnnouncementModel? get emergencyAnnouncements =>
      _emergencyAnnouncements;
  EmergencyAnnouncementModel? get announcements => _announcements;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;
  List<EmergencyAnnouncement> get activeEmergencyAnnouncements {
    if (_emergencyAnnouncements == null ||
        _emergencyAnnouncements!.data.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    return _emergencyAnnouncements!.data.where((announcement) {
      try {
        final start = DateTime.parse(announcement.startDate);
        final end = DateTime.parse(announcement.endDate);
        return now.isAfter(start.subtract(Duration(seconds: 1))) &&
            now.isBefore(end.add(Duration(days: 1))) &&
            announcement.isActive &&
            announcement.status.toLowerCase() == 'active';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Constructor - fetch settings immediately
  SettingProvider(BuildContext context) {
    // fetchSettings(context);
  }

  /// Fetch app settings from API
  Future<void> fetchSettings(BuildContext context) async {
    _isLoading = true;
    _error = null;
    //notifyListeners();

    try {
      debugPrint('📱 Fetching app settings...');

      final response = await http.get(
        Uri.parse('${ApiEndPoints.BASE_URL}settings'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _settingsModel = SettingsModel.fromJson(data);
          debugPrint('✅ Settings fetched successfully');
          debugPrint('   - Coin Price: ${settings?.bCoinPrice}');
          debugPrint('   - Number of Coins: ${settings?.bNumberOfCoins}');
          debugPrint('   - Price per Coin: ${settings?.coinPricePerUnit}');
          debugPrint('   - Service Shutdown: ${isServiceShutdown}');
          if (navigatorKey.currentContext != null) {
            debugPrint('*Checking Maintenance Mode');
            await Future.delayed(Duration(seconds: 3));
            MaintenanceDialog.checkAndShow(context);

            // Check and show emergency announcements
            debugPrint('*Checking Emergency Announcements');
            // await fetchEmergencyAnnouncements(context);
          }
        } else {
          _error = data['message'] ?? 'Failed to fetch settings';
          debugPrint('❌ Settings API error: $_error');
        }
        notifyListeners();
      } else {
        _error = 'Failed to fetch settings: ${response.statusCode}';
        debugPrint(
          '❌ Settings API failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _error = 'Error fetching settings: $e';
      debugPrint('❌ Error fetching settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh settings
  Future<void> refreshSettings(context) async {
    await fetchSettings(context);
  }

  /// Fetch emergency announcements from API
  Future<void> fetchEmergencyAnnouncements(BuildContext context) async {
    try {
      debugPrint('📢 Fetching emergency announcements...');

      final response = await http.get(
        Uri.parse(ApiEndPoints.EMERGENCY_ANNOUNCEMENTS),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${Provider.of<UserViewModel>(context, listen: false).userModel!.data.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _emergencyAnnouncements = EmergencyAnnouncementModel.fromJson(data);
          debugPrint('✅ Emergency announcements fetched successfully');
          debugPrint(
            '   - Total announcements: ${_emergencyAnnouncements!.data.length}',
          );

          // Check and show high priority emergency notices (on app launch)
          final activeAnnouncements = activeEmergencyAnnouncements;
          if (activeAnnouncements.isNotEmpty) {
            debugPrint(
              '   - Active announcements: ${activeAnnouncements.length}',
            );
            // Show high priority dialog after a short delay to avoid conflicts with maintenance dialog
            await Future.delayed(Duration(seconds: 1));
            if (navigatorKey.currentContext != null) {
              // Show high priority announcements immediately on app launch
              EmergencyNoticeDialog.checkAndShowHighPriority(
                context,
                activeAnnouncements,
              );
              // Also show low priority as notifications
              EmergencyNoticeDialog.checkAndShowLowPriority(
                context,
                activeAnnouncements,
              );
            }
          } else {
            debugPrint('   - No active announcements');
          }
        } else {
          debugPrint('❌ Emergency announcements API error: ${data['message']}');
        }
      } else {
        debugPrint(
          '❌ Emergency announcements API failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching emergency announcements: $e');
    }
  }

  /// Fetch all announcements from API (GET /api/announcements with Bearer token).
  /// Response: { "success": true, "message": "...", "data": [ { id, title, category, content, type, start_date, end_date, ... } ] }
  Future<void> fetchAnnouncements(BuildContext context) async {
    _isLoadingAnnouncements = true;
    notifyListeners();

    try {
      debugPrint('📢 Fetching announcements...');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      final token = Provider.of<UserViewModel>(context, listen: false).userModel?.data.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(ApiEndPoints.ANNOUNCEMENTS),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _announcements = EmergencyAnnouncementModel.fromJson(data);
          debugPrint('✅ Announcements fetched successfully');
          debugPrint(
            '   - Total announcements: ${_announcements!.data.length}',
          );
        } else {
          debugPrint('❌ Announcements API error: ${data['message']}');
        }
      } else {
        debugPrint(
          '❌ Announcements API failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching announcements: $e');
    } finally {
      _isLoadingAnnouncements = false;
      notifyListeners();
    }
  }

  /// Calculate coin value in currency
  /// Formula: (b_coin_price / b_number_of_coins) * coins
  double calculateCoinValue(int coins) {
    if (settings == null) return 0;
    return settings!.calculateCoinValue(coins);
  }

  /// Get formatted coin value string
  String getFormattedCoinValue(int coins, {String currencySymbol = '\$'}) {
    final value = calculateCoinValue(coins);
    print(value.toString() + "*********");
    return '$currencySymbol${value.toStringAsFixed(2)}';
  }

  /// Get coin price per unit
  double get coinPricePerUnit => settings?.coinPricePerUnit ?? 0;

  /// Check if app is in maintenance mode
  bool get isInMaintenanceMode => settings?.showMaintenanceMode ?? false;

  /// Check if service is completely shut down
  bool get isServiceShutdown => settings?.completeServiceShutdown ?? false;

  /// Get minimum supported version
  String get minimumSupportedVersion => settings?.minimumSupportedVersion ?? '';

  /// Get customer service phone
  String get customerServicePhone => settings?.customerPhoneService ?? '';

  /// Get customer service email
  String get customerServiceEmail => settings?.customerServiceEmail ?? '';

  // Maintenance/Shutdown Settings Getters
  String get maintenanceMessage => settings?.maintenanceMessage ?? '';
  String get maintenanceStartTime => settings?.maintenanceStartTime ?? '';
  String get maintenanceEndTime => settings?.maintenanceEndTime ?? '';
  String get serviceShutdownMessage => settings?.serviceShutdownMessage ?? '';

  // Registration/Login Settings Getters
  bool get isEmailRegistrationEnabled => settings?.emailRegistration ?? true;
  bool get isPhoneRegistrationEnabled => settings?.phoneRegistration ?? true;
  bool get isKakaoIntegrationEnabled => settings?.kakaoIntegration ?? true;
  bool get isAppleIntegrationEnabled => settings?.appleIntegration ?? true;

  // Nickname Validation Settings
  int get minNicknameLength => settings?.minNicknameLength ?? 0;
  int get maxNicknameLength => settings?.maxNicknameLength ?? 0;
  bool get allowSpecialCharactersInNickname =>
      settings?.allowSpecialCharactersInNickname ?? true;
  String get prohibitedWords => settings?.prohibitedWords ?? '';

  // Profile Settings Getters
  bool get isProfileNameEnabled => settings?.profileName ?? true;
  bool get isProfilePhotoEnabled => settings?.profilePhoto ?? true;
  bool get isProfileSelfIntroEnabled => settings?.profileSelfIntro ?? true;

  // Service Settings Getters
  bool get isSpecializationEnabled => settings?.specialization ?? true;
  bool get isExperienceEnabled => settings?.experience ?? true;
  bool get isCertificatesEnabled => settings?.certificates ?? true;

  // Document Requirements Getters
  bool get isIdCardCopyRequired => settings?.idCardCopy ?? false;
  bool get isLicenseCopyRequired => settings?.licenseCopy ?? false;
  bool get isResumeRequired => settings?.resume ?? false;
  bool get isApplicationSelfIntroRequired =>
      settings?.applicationSelfIntro ?? false;
  bool get isBankAccountCopyRequired => settings?.bankAccountCopy ?? false;

  /// Validate nickname according to settings
  String? validateNickname(String nickname) {
    if (nickname.isEmpty) {
      return "Please enter a nickname".tr;
    }

    // Check minimum length
    if (minNicknameLength > 0 && nickname.length < minNicknameLength) {
      return "Nickname must be at least $minNicknameLength characters".tr;
    }

    // Check maximum length
    if (maxNicknameLength > 0 && nickname.length > maxNicknameLength) {
      return "Nickname must not exceed $maxNicknameLength characters".tr;
    }

    // Check for prohibited words
    if (prohibitedWords.isNotEmpty) {
      List<String> prohibited =
          prohibitedWords
              .split(',')
              .map((w) => w.trim().toLowerCase())
              .toList();
      String lowerNickname = nickname.toLowerCase();
      for (String word in prohibited) {
        if (word.isNotEmpty && lowerNickname.contains(word)) {
          return "Nickname contains prohibited word".tr;
        }
      }
    }

    // Check special characters
    if (!allowSpecialCharactersInNickname) {
      final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
      if (specialCharRegex.hasMatch(nickname)) {
        return "Nickname cannot contain special characters".tr;
      }
    }

    return null; // Valid
  }
}
