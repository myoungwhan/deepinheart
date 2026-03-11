import 'package:flutter/material.dart';

class BannerModel {
  final String bannerName;
  final String bannerType;
  final String imageUrl; // For image banners
  final String externalLink; // Link for clickable banners
  final DateTime exposureBegin;
  final DateTime exposureEnd;
  final String couponDescription; // Optional: Coupon description
  final String buttonText; // Text for the button
  final Color buttonColor; // Button color for consistency
  //button click action
  VoidCallback? buttonClickAction;
  bool isShowCoinIcon = true;

  // Constructor with default values
  BannerModel({
    required this.bannerName,
    required this.bannerType,
    this.imageUrl = '', // Default: no URL (use local placeholder in UI)
    this.externalLink = '', // Default to an empty string if no link provided
    DateTime? exposureBegin,
    DateTime? exposureEnd,
    this.couponDescription = '', // Default to empty string if not provided
    this.buttonText = 'Click Here', // Default button text
    this.buttonColor = Colors.blue, // Default button color
    this.buttonClickAction,
    this.isShowCoinIcon = true,
  }) : exposureBegin = exposureBegin ?? DateTime.now(),
       exposureEnd = exposureEnd ?? DateTime.now().add(Duration(days: 30));
}
