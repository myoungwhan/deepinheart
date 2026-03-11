import 'package:deepinheart/Controller/Model/coupon_banner_model.dart';

class RegisteredCouponModel {
  final bool success;
  final String message;
  final RegisteredCouponData data;

  RegisteredCouponModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RegisteredCouponModel.fromJson(Map<String, dynamic> json) {
    return RegisteredCouponModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: RegisteredCouponData.fromJson(json['data'] ?? {}),
    );
  }
}

class RegisteredCouponData {
  final List<RegisteredCoupon> registeredCoupons;
  final List<RegisteredCoupon> usedAndExpiredCoupons;

  RegisteredCouponData({
    required this.registeredCoupons,
    required this.usedAndExpiredCoupons,
  });

  factory RegisteredCouponData.fromJson(Map<String, dynamic> json) {
    return RegisteredCouponData(
      registeredCoupons: (json['registered_coupons'] as List<dynamic>?)
              ?.map((x) => RegisteredCoupon.fromJson(x))
              .toList() ??
          [],
      usedAndExpiredCoupons:
          (json['used_and_expired_coupons'] as List<dynamic>?)
                  ?.map((x) => RegisteredCoupon.fromJson(x))
                  .toList() ??
              [],
    );
  }
}

class RegisteredCoupon {
  final int id;
  final CouponBanner couponBanner;
  final int isUsed; // 1 = used, 0 = not used
  final String registeredAt;

  RegisteredCoupon({
    required this.id,
    required this.couponBanner,
    required this.isUsed,
    required this.registeredAt,
  });

  factory RegisteredCoupon.fromJson(Map<String, dynamic> json) {
    return RegisteredCoupon(
      id: json['id'] ?? 0,
      couponBanner: CouponBanner.fromJson(
          json['coupon_banner'] ?? {}),
      isUsed: json['is_used'] ?? 0,
      registeredAt: json['registered_at'] ?? '',
    );
  }

  // Check if coupon is used
  bool get used => isUsed == 1;

  // Check if coupon is expired based on coupon banner end date
  bool get isExpired => couponBanner.isExpired;

  // Helper method to format expiration date
  String get formattedExpirationDate => couponBanner.formattedExpirationDate;
}

