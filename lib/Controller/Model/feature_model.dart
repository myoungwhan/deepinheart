import 'package:flutter/material.dart';

class FeatureModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  FeatureModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel(
    title: json["title"]?.toString() ?? '',
    description: json["text"]?.toString() ?? json["description"]?.toString() ?? '',
    icon: Icons.article_outlined,
    color: Colors.grey,
  );
}
