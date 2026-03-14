class CouponBannerModel {
  final bool success;
  final String message;
  final CouponBannerData data;

  CouponBannerModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CouponBannerModel.fromJson(Map<String, dynamic> json) {
    return CouponBannerModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CouponBannerData.fromJson(json['data'] ?? {}),
    );
  }
}

class CouponBannerData {
  final List<Advertisement> advertisements;
  final List<CouponBanner> couponBanners;

  CouponBannerData({
    required this.advertisements,
    required this.couponBanners,
  });

  factory CouponBannerData.fromJson(Map<String, dynamic> json) {
    return CouponBannerData(
      advertisements: (json['advertisements'] as List<dynamic>?)
              ?.map((x) => Advertisement.fromJson(x))
              .toList() ??
          [],
      couponBanners: (json['coupon_banners'] as List<dynamic>?)
              ?.map((x) => CouponBanner.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class Advertisement {
  final int id;
  final String bannerImage;
  final String startDate;
  final String endDate;
  final String? externalLink;
  final String? description;
  final String exposureLocation;
  final String bannerType;

  Advertisement({
    required this.id,
    required this.bannerImage,
    required this.startDate,
    required this.endDate,
    this.externalLink,
    this.description,
    required this.exposureLocation,
    required this.bannerType,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      bannerImage: json['banner_image'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      externalLink: json['external_link'],
      description: json['description'],
      exposureLocation: json['exposure_location'] ?? '',
      bannerType: json['banner_type'] ?? '',
    );
  }
}

class CouponBanner {
  final int id;
  final String couponName;
  final String description;
  final int couponCode;
  final String bannerImage;
  final String startDate;
  final String endDate;
  final String discountAmount;
  final int quantityIssued;
  final String couponType;
  final String couponScope;

  CouponBanner({
    required this.id,
    required this.couponName,
    required this.description,
    required this.couponCode,
    required this.bannerImage,
    required this.startDate,
    required this.endDate,
    required this.discountAmount,
    required this.quantityIssued,
    required this.couponType,
    required this.couponScope,
  });

  factory CouponBanner.fromJson(Map<String, dynamic> json) {
    return CouponBanner(
      id: json['id'] ?? 0,
      couponName: json['coupon_name'] ?? '',
      description: json['description'] ?? '',
      couponCode: json['coupon_code'] ?? 0,
      bannerImage: json['banner_image'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      discountAmount: json['discount_amount'] ?? '0.00',
      quantityIssued: json['quantity_issued'] ?? 0,
      couponType: json['coupon_type'] ?? '',
      couponScope: json['coupon_scope'] ?? '',
    );
  }

  // Helper method to check if coupon is expired
  bool get isExpired {
    try {
      final endDateParsed = DateTime.parse(endDate);
      return DateTime.now().isAfter(endDateParsed);
    } catch (e) {
      return false;
    }
  }

  // Helper method to format expiration date
  String get formattedExpirationDate {
    try {
      final endDateParsed = DateTime.parse(endDate);
      return 'Up to ${endDateParsed.year}.${endDateParsed.month.toString().padLeft(2, '0')}.${endDateParsed.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return endDate;
    }
  }
}

