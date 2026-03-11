import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:flutter/material.dart';
import 'sub_category_model.dart';
import 'feature_model.dart';

class ServiceCategoryModel {
  final String title;
  final String img;
  final String description;
  final List<SubCategoryModel> subCategories;
  final List<FeatureModel> features; // ← new
  List<FreqQuestionModel> questions; // ← new

  ServiceCategoryModel({
    required this.title,
    required this.img,
    required this.description,
    required this.subCategories,
    required this.features, // ← new
    required this.questions,
  });
}
