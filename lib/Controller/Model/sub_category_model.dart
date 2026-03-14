import 'package:flutter/material.dart';

class SubCategoryModel {
  final String title; // Sub-category ka title, jaise 'Love', 'Today'
  final String color; // Sub-category ka color (Hex format)

  SubCategoryModel({required this.title, required this.color});

  // Method to return color from string (hex code)
  Color getColor() {
    return Color(int.parse(color.replaceAll('#', '0xff')));
  }
}
