// To parse this JSON data, do
//
//     final hashtagModel = hashtagModelFromJson(jsonString);

import 'dart:convert';

HashtagModel hashtagModelFromJson(String str) =>
    HashtagModel.fromJson(json.decode(str));

String hashtagModelToJson(HashtagModel data) => json.encode(data.toJson());

class HashtagModel {
  bool success;
  String message;
  List<HashTagData> data;

  HashtagModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HashtagModel.fromJson(Map<String, dynamic> json) => HashtagModel(
    success: json["success"],
    message: json["message"],
    data: List<HashTagData>.from(
      json["data"].map((x) => HashTagData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class HashTagData {
  int id;
  String name;
  String explanation;
  int isUse;
  int priority;

  HashTagData({
    required this.id,
    required this.name,
    required this.explanation,
    required this.isUse,
    required this.priority,
  });

  factory HashTagData.fromJson(Map<String, dynamic> json) => HashTagData(
    id: json["id"],
    name: json["name"],
    explanation: json["explanation"],
    isUse: json["is_use"],
    priority: json["priority"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "explanation": explanation,
    "is_use": isUse,
    "priority": priority,
  };
}
