class SettingsModel {
  final bool success;
  final String message;
  final SettingsData data;

  SettingsModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: SettingsData.fromJson(json['data'] ?? {}),
    );
  }
}

class SettingsData {
  // Customer Service
  final String customerPhoneService;
  final String customerServiceEmail;

  // App Version
  final String appVersion;
  final String minimumSupportedVersion;

  // Maintenance Mode
  final bool showMaintenanceMode;
  final String maintenanceMessage;
  final String maintenanceStartTime;
  final String maintenanceEndTime;
  final bool completeServiceShutdown;
  final String serviceShutdownMessage;

  // Registration Options
  final bool emailRegistration;
  final bool phoneRegistration;
  final bool kakaoIntegration;
  final bool appleIntegration;

  // Nickname Settings
  final int minNicknameLength;
  final int maxNicknameLength;
  final bool allowSpecialCharactersInNickname;
  final String prohibitedWords;

  // Document Requirements
  final bool idCardCopy;
  final bool licenseCopy;
  final bool resume;
  final bool applicationSelfIntro;
  final bool bankAccountCopy;

  // Profile Settings
  final bool profileName;
  final bool profilePhoto;
  final bool profileSelfIntro;
  final bool specialization;
  final bool experience;
  final bool certificates;

  // Bonus Coins Settings
  final int bNumberOfCoins;
  final int bCoinPrice;

  // Review Settings
  final bool hideNegativeReviews;
  final bool allowCounselorReviewResponses;
  final int reviewEditPeriod;

  // Coin Rate Settings
  final int minCoinRate;
  final int maxCoinRate;

  // Custom Amount Settings
  final int cusAmountOver;
  final int cusNumberOfCoins;
  final int cusPrice;
  final int cusDiscountRate;

  // Refund Policy
  final String refundPolicySection;

  // Coupon Settings
  final bool autoSignupCouponEnabled;
  final String signupCouponAmount;
  final String signupCouponName;
  final bool autoBirthdayCouponEnabled;
  final String birthdayCouponAmount;
  final String birthdayCouponName;
  final bool autoReturnUserCouponEnabled;
  final String returnUserInactiveDays;
  final String returnUserCouponAmount;
  final String returnUserCouponName;
  final String defaultCouponValidityDays;

  // Review Settings (Additional)
  final String reviewFilterWords;
  final bool autoApproveReviews;

  // Push Notification Settings
  final bool allowGlobalPush;
  final bool pushSystemErrorAlerts;
  final bool pushPaymentNotifications;
  final bool pushBookingNotifications;
  final bool pushEventsPromotions;
  final String lowCoinBalanceThreshold;
  final String inactiveUserReminderDays;
  final bool pushBirthdayMessage;
  final String pushTemplateLowCoin;
  final String pushTemplateInactiveUser;
  final String pushTemplateBirthday;
  final String pushTemplateBookingConfirm;
  final String pushTemplateBookingCancel;

  // Call Service Settings
  final String callServiceType;
  final String agoraAppId;
  final String agoraAppCertificate;
  final String mediaServerUrl;
  final String mediaServerApiKey;

  // Policy Links
  final String privacyPolicyLink;
  final String termsOfUseLink;
  final String marketingInfoLink;

  // Tarot URLs
  final String tarotCounselorsUrl;
  final String tarotQuerentsUrl;

  // Backup Settings
  final bool logHistoryEnabled;
  final bool autoBackupEnabled;
  final String backupFrequency;
  final int backupRetentionDays;
  final double vat;

  SettingsData({
    required this.customerPhoneService,
    required this.customerServiceEmail,
    required this.appVersion,
    required this.minimumSupportedVersion,
    required this.showMaintenanceMode,
    required this.maintenanceMessage,
    required this.maintenanceStartTime,
    required this.maintenanceEndTime,
    required this.completeServiceShutdown,
    required this.serviceShutdownMessage,
    required this.emailRegistration,
    required this.phoneRegistration,
    required this.kakaoIntegration,
    required this.appleIntegration,
    required this.minNicknameLength,
    required this.maxNicknameLength,
    required this.allowSpecialCharactersInNickname,
    required this.prohibitedWords,
    required this.idCardCopy,
    required this.licenseCopy,
    required this.resume,
    required this.applicationSelfIntro,
    required this.bankAccountCopy,
    required this.profileName,
    required this.profilePhoto,
    required this.profileSelfIntro,
    required this.specialization,
    required this.experience,
    required this.certificates,
    required this.bNumberOfCoins,
    required this.bCoinPrice,
    required this.hideNegativeReviews,
    required this.allowCounselorReviewResponses,
    required this.reviewEditPeriod,
    required this.minCoinRate,
    required this.maxCoinRate,
    required this.cusAmountOver,
    required this.cusNumberOfCoins,
    required this.cusPrice,
    required this.cusDiscountRate,
    required this.refundPolicySection,
    required this.autoSignupCouponEnabled,
    required this.signupCouponAmount,
    required this.signupCouponName,
    required this.autoBirthdayCouponEnabled,
    required this.birthdayCouponAmount,
    required this.birthdayCouponName,
    required this.autoReturnUserCouponEnabled,
    required this.returnUserInactiveDays,
    required this.returnUserCouponAmount,
    required this.returnUserCouponName,
    required this.defaultCouponValidityDays,
    required this.reviewFilterWords,
    required this.autoApproveReviews,
    required this.allowGlobalPush,
    required this.pushSystemErrorAlerts,
    required this.pushPaymentNotifications,
    required this.pushBookingNotifications,
    required this.pushEventsPromotions,
    required this.lowCoinBalanceThreshold,
    required this.inactiveUserReminderDays,
    required this.pushBirthdayMessage,
    required this.pushTemplateLowCoin,
    required this.pushTemplateInactiveUser,
    required this.pushTemplateBirthday,
    required this.pushTemplateBookingConfirm,
    required this.pushTemplateBookingCancel,
    required this.callServiceType,
    required this.agoraAppId,
    required this.agoraAppCertificate,
    required this.mediaServerUrl,
    required this.mediaServerApiKey,
    required this.privacyPolicyLink,
    required this.termsOfUseLink,
    required this.marketingInfoLink,
    required this.tarotCounselorsUrl,
    required this.tarotQuerentsUrl,
    required this.logHistoryEnabled,
    required this.autoBackupEnabled,
    required this.backupFrequency,
    required this.backupRetentionDays,
    required this.vat,
  });

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      customerPhoneService: json['customer_phone_service'] ?? '',
      customerServiceEmail: json['customer_service_email'] ?? '',
      appVersion: json['app_version'] ?? '',
      minimumSupportedVersion: json['minimum_supported_version'] ?? '',
      showMaintenanceMode: _parseBool(json['show_maintenance_mode']),
      maintenanceMessage: json['maintenance_message'] ?? '',
      maintenanceStartTime: json['maintenance_start_time'] ?? '',
      maintenanceEndTime: json['maintenance_end_time'] ?? '',
      completeServiceShutdown: _parseBool(json['complete_service_shutdown']),
      serviceShutdownMessage: json['service_shutdown_message'] ?? '',
      emailRegistration: _parseBool(json['email_registration']),
      phoneRegistration: _parseBool(json['phone_registration']),
      kakaoIntegration: _parseBool(json['kakao_integration']),
      appleIntegration: _parseBool(json['apple_integration']),
      minNicknameLength: _parseInt(json['min_nickname_length']),
      maxNicknameLength: _parseInt(json['max_nickname_length']),
      allowSpecialCharactersInNickname: _parseBool(
        json['allow_special_characters_in_nickname'],
      ),
      prohibitedWords: json['prohibited_words'] ?? '',
      idCardCopy: _parseBool(json['id_card_copy']),
      licenseCopy: _parseBool(
        json['lisence_copy'],
      ), // Note: API has typo "lisence"
      resume: _parseBool(json['resume']),
      applicationSelfIntro: _parseBool(json['application_self_intro']),
      bankAccountCopy: _parseBool(json['bank_account_copy']),
      profileName: _parseBool(json['profile_name']),
      profilePhoto: _parseBool(json['profile_photo']),
      profileSelfIntro: _parseBool(json['profile_self_intro']),
      specialization: _parseBool(json['specialization']),
      experience: _parseBool(json['experience']),
      certificates: _parseBool(json['certificates']),
      bNumberOfCoins: _parseInt(json['b_number_of_coins']),
      bCoinPrice: _parseInt(json['b_coin_price']),
      hideNegativeReviews: _parseBool(
        json['hide_negitive_reviews'],
      ), // Note: API has typo "negitive"
      allowCounselorReviewResponses: _parseBool(
        json['allow_counselor_review_responses'],
      ),
      reviewEditPeriod: _parseInt(json['review_edit_period']),
      minCoinRate: _parseInt(json['min_coin_rate']),
      maxCoinRate: _parseInt(json['max_coin_rate']),
      cusAmountOver: _parseInt(json['cus_amount_over']),
      cusNumberOfCoins: _parseInt(json['cus_number_of_coins']),
      cusPrice: _parseInt(json['cus_price']),
      cusDiscountRate: _parseInt(json['cus_discount_rate']),
      refundPolicySection: json['refund_policy_section'] ?? '',
      autoSignupCouponEnabled: _parseBool(json['auto_signup_coupon_enabled']),
      signupCouponAmount: json['signup_coupon_amount']?.toString() ?? '',
      signupCouponName: json['signup_coupon_name']?.toString() ?? '',
      autoBirthdayCouponEnabled: _parseBool(
        json['auto_birthday_coupon_enabled'],
      ),
      birthdayCouponAmount: json['birthday_coupon_amount']?.toString() ?? '',
      birthdayCouponName: json['birthday_coupon_name']?.toString() ?? '',
      autoReturnUserCouponEnabled: _parseBool(
        json['auto_return_user_coupon_enabled'],
      ),
      returnUserInactiveDays:
          json['return_user_inactive_days']?.toString() ?? '',
      returnUserCouponAmount:
          json['return_user_coupon_amount']?.toString() ?? '',
      returnUserCouponName: json['return_user_coupon_name']?.toString() ?? '',
      defaultCouponValidityDays:
          json['default_coupon_validity_days']?.toString() ?? '',
      reviewFilterWords: json['review_filter_words']?.toString() ?? '',
      autoApproveReviews: _parseBool(json['auto_approve_reviews']),
      allowGlobalPush: _parseBool(json['allow_global_push']),
      pushSystemErrorAlerts: _parseBool(json['push_system_error_alerts']),
      pushPaymentNotifications: _parseBool(json['push_payment_notifications']),
      pushBookingNotifications: _parseBool(json['push_booking_notifications']),
      pushEventsPromotions: _parseBool(json['push_events_promotions']),
      lowCoinBalanceThreshold:
          json['low_coin_balance_threshold']?.toString() ?? '',
      inactiveUserReminderDays:
          json['inactive_user_reminder_days']?.toString() ?? '',
      pushBirthdayMessage: _parseBool(json['push_birthday_message']),
      pushTemplateLowCoin: json['push_template_low_coin']?.toString() ?? '',
      pushTemplateInactiveUser:
          json['push_template_inactive_user']?.toString() ?? '',
      pushTemplateBirthday: json['push_template_birthday']?.toString() ?? '',
      pushTemplateBookingConfirm:
          json['push_template_booking_confirm']?.toString() ?? '',
      pushTemplateBookingCancel:
          json['push_template_booking_cancel']?.toString() ?? '',
      callServiceType: json['call_service_type']?.toString() ?? '',
      agoraAppId: json['agora_app_id']?.toString() ?? '',
      agoraAppCertificate: json['agora_app_certificate']?.toString() ?? '',
      mediaServerUrl: json['media_server_url']?.toString() ?? '',
      mediaServerApiKey: json['media_server_api_key']?.toString() ?? '',
      privacyPolicyLink: json['privacy_policy_link']?.toString() ?? '',
      termsOfUseLink: json['terms_of_use_link']?.toString() ?? '',
      marketingInfoLink: json['marketing_info_link']?.toString() ?? '',
      tarotCounselorsUrl: json['tarot_counselors_url']?.toString() ?? '',
      tarotQuerentsUrl: json['tarot_querents_url']?.toString() ?? '',
      logHistoryEnabled: _parseBool(json['log_history_enabled']),
      autoBackupEnabled: _parseBool(json['auto_backup_enabled']),
      backupFrequency: json['backup_frequency']?.toString() ?? '',
      backupRetentionDays: _parseInt(json['backup_retention_days']),
      vat: double.parse(json['vat']?.toString() ?? '0'),
    );
  }

  /// Parse string "1"/"0" or bool to bool
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  /// Parse string or int to int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Calculate coin price per single coin
  double get coinPricePerUnit {
    if (bNumberOfCoins == 0) return 0;
    return bCoinPrice / bNumberOfCoins;
  }

  /// Calculate value in currency for given coins
  double calculateCoinValue(int coins) {
    return coinPricePerUnit * coins;
  }
}
