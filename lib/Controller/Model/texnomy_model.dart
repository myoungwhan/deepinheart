// To parse this JSON data, do
//
//     final texonomyModel = texonomyModelFromJson(jsonString);

import 'dart:convert';

import 'package:deepinheart/Controller/Model/feature_model.dart';
import 'package:deepinheart/Controller/Model/freq_question_model.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:flutter/material.dart';

TexonomyModel texonomyModelFromJson(String str) =>
    TexonomyModel.fromJson(json.decode(str));

String texonomyModelToJson(TexonomyModel data) => json.encode(data.toJson());

class TexonomyModel {
  bool success;
  String message;
  TexnomyData texnomyData;

  TexonomyModel({
    required this.success,
    required this.message,
    required this.texnomyData,
  });

  factory TexonomyModel.fromJson(Map<String, dynamic> json) => TexonomyModel(
    success: json["success"],
    message: json["message"],
    texnomyData: TexnomyData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": texnomyData.toJson(),
  };
}

class TexnomyData {
  Counseling fortune;
  Counseling counseling;

  TexnomyData({required this.fortune, required this.counseling});

  factory TexnomyData.fromJson(Map<String, dynamic> json) => TexnomyData(
    fortune: Counseling.fromJson(json["fortune"]),
    counseling: Counseling.fromJson(json["counseling"]),
  );

  Map<String, dynamic> toJson() => {
    "fortune": fortune.toJson(),
    "counseling": counseling.toJson(),
  };
}

class Counseling {
  int id;
  String name;
  List<Category> categories;
  List<Taxonomy> taxonomies;

  Counseling({
    required this.id,
    required this.name,
    required this.categories,
    required this.taxonomies,
  });

  factory Counseling.fromJson(Map<String, dynamic> json) => Counseling(
    id: json["id"],
    name: json["name"],
    categories: List<Category>.from(
      json["categories"].map((x) => Category.fromJson(x)),
    ),
    taxonomies: List<Taxonomy>.from(
      json["taxonomies"].map((x) => Taxonomy.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
    "taxonomies": List<dynamic>.from(taxonomies.map((x) => x.toJson())),
  };
}

class Category {
  int id;
  String name;
  String? nameTranslated;
  String image;
  String background_image;
  String description;
  String position;
  String screenNumber;
  int status;
  List<SubCategory> subCategories;
  List<FeatureModel> features;
  List<FreqQuestionModel> questions;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.position,
    required this.screenNumber,
    required this.status,
    required this.subCategories,
    required this.features,
    required this.questions,
    this.nameTranslated,
    this.background_image = "",
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    image: json["image"],
    description: json["description"],
    position: json["position"],
    screenNumber: json["screen_number"],
    status: json["status"],
    features:
        json.containsKey('features')
            ? List<FeatureModel>.from(
              (json["features"] as List).map((x) => FeatureModel.fromJson(x)),
            )
            : [],
    questions:
        json.containsKey('faq')
            ? List<FreqQuestionModel>.from(
              (json["faq"] as List).map((x) => FreqQuestionModel.fromJson(x)),
            )
            : [],
    subCategories:
        json.containsKey('sub_categories')
            ? List<SubCategory>.from(
              json["sub_categories"].map((x) => SubCategory.fromJson(x)),
            )
            : [],
    background_image: json["background_image"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "description": description,
    "position": position,
    "screen_number": screenNumber,
    "status": status,
    "background_image": background_image,
    "sub_categories": List<dynamic>.from(subCategories.map((x) => x.toJson())),
  };
  Future<String> getTranslatedName() async {
    return await translationService.translate(name);
  }
}

class SubCategory {
  int id;
  String name;
  String? iconUrl;
  String color;

  SubCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.color,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) => SubCategory(
    id: json["id"] ?? 0,
    name: json["name"] ?? json["title"] ?? '',
    iconUrl: json["icon_url"],
    color: json["color"] ?? '#000000',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "icon_url": iconUrl,
    "color": color,
  };
  Color getColor() {
    return Color(int.parse(color.replaceAll('#', '0xff')));
  }
}

class Taxonomy {
  int id;
  String name;
  String position;
  String screenNumber;
  int status;
  List<SubCategory> taxonomieItems;

  Taxonomy({
    required this.id,
    required this.name,
    required this.position,
    required this.screenNumber,
    required this.status,
    required this.taxonomieItems,
  });

  factory Taxonomy.fromJson(Map<String, dynamic> json) => Taxonomy(
    id: json["id"],
    name: json["name"],
    position: json["position"] ?? "1",
    screenNumber: json["screen_number"] ?? "1",
    status: json["status"] ?? 1,
    taxonomieItems:
        json.containsKey('taxonomie_items')
            ? List<SubCategory>.from(
              json["taxonomie_items"].map((x) => SubCategory.fromJson(x)),
            )
            : json.containsKey('taxonomies')
            ? List<SubCategory>.from(
              json["taxonomies"].map((x) => SubCategory.fromJson(x)),
            )
            : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "position": position,
    "screen_number": screenNumber,
    "status": status,
    "taxonomie_items": List<dynamic>.from(
      taxonomieItems.map((x) => x.toJson()),
    ),
  };
}
