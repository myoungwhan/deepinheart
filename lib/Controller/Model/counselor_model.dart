// To parse this JSON data, do
//
//     final counselorModel = CounselorModel.fromJson(jsonString);

import 'package:deepinheart/Controller/Model/services_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/config/string_constants.dart';

class CounselorModel {
  bool success;
  String message;
  List<CounselorData> data;

  CounselorModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CounselorModel.fromJson(Map<String, dynamic> json) => CounselorModel(
    success: json["success"] ?? false,
    message: json["message"] ?? "",
    data: List<CounselorData>.from(
      json["data"].map((x) => CounselorData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class CounselorData {
  int id;
  String name;
  String nickName;
  String email;
  int phone;
  String role;
  String profileImage;
  String document;
  String socialType;
  String providerId;
  String gender;
  String zip;
  String address1;
  String address2;
  String introduction;
  List<Specialty> specialties;
  List<String> serviceSpecialties;
  CounsultationMethod consultationMethod;
  int coins;
  double rating;
  int ratingCount;
  bool isAvailable;
  bool isOnline;
  String lastSeen;
  bool in_session;

  CounselorData({
    required this.id,
    required this.name,
    required this.nickName,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.document,
    required this.socialType,
    required this.providerId,
    required this.gender,
    required this.zip,
    required this.address1,
    required this.address2,
    required this.introduction,
    required this.specialties,
    required this.consultationMethod,
    required this.coins,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    required this.isOnline,
    required this.lastSeen,
    this.serviceSpecialties = const [],
    this.in_session = false,
  });

  factory CounselorData.fromJson(Map<String, dynamic> json) => CounselorData(
    id: json["id"] ?? 0,
    name: json["name"] ?? "",
    nickName: json["nick_name"] ?? "",
    email: json["email"] ?? "",
    phone: json["phone"] ?? 0,
    role: json["role"] ?? "",

    //if profile_image is null or empty string then set testuserprofile
    profileImage: json["profile_image"] ?? testuserprofile,

    // profileImage: json["profile_image"] ?? testuserprofile,
    document: json["document"] ?? "",
    socialType: json["social_type"] ?? "",
    providerId: json["provider_id"] ?? "",
    gender: json["gender"] ?? "",
    zip: json["zip"] ?? "",
    address1: json["address1"] ?? "",
    address2: json["address2"] ?? "",
    introduction: json["introduction"] ?? "",
    specialties:
        json["specialties"] != null
            ? List<Specialty>.from(
              json["specialties"].map((x) => Specialty.fromJson(x)),
            )
            : [],
    serviceSpecialties:
        json["service_specialties"] != null
            ? List<String>.from(
              json["service_specialties"].map((x) => x.toString()),
            )
            : [],
    consultationMethod:
        json["counsultation_method"] != null
            ? CounsultationMethod.fromJson(json["counsultation_method"])
            : CounsultationMethod(
              voiceCallAvailable: 0,
              voiceCallCoin: "0",
              videoCallAvailable: 0,
              videoCallCoin: "0",
              chatAvailable: 0,
              chatCoin: "0",
              taxInvoiceAvailable: 0,
            ),
    coins: json["coins"] ?? 0,
    rating: double.tryParse(json["rating"].toString()) ?? 0.0,
    ratingCount: json["rating_count"] ?? 0,
    isAvailable: json["is_available"] ?? true,
    isOnline: json["is_online"] ?? false,
    lastSeen: json["last_seen"] ?? "Never",
    in_session: json["in_session"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "nick_name": nickName,
    "email": email,
    "phone": phone,
    "role": role,
    "profile_image": profileImage,
    "document": document,
    "social_type": socialType,
    "provider_id": providerId,
    "gender": gender,
    "zip": zip,
    "address1": address1,
    "address2": address2,
    "introduction": introduction,
    "specialties": List<dynamic>.from(specialties.map((x) => x.toJson())),
    "service_specialties": List<dynamic>.from(serviceSpecialties.map((x) => x)),
    "rating": rating,
    "rating_count": ratingCount,
    "is_available": isAvailable,
    "is_online": isOnline,
    "last_seen": lastSeen,
    "in_session": in_session,
  };
}

class Specialty {
  int id;
  String name;
  List<Category> categories;
  List<Taxonomy> taxonomies;

  Specialty({
    required this.id,
    required this.name,
    required this.categories,
    required this.taxonomies,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
    id: json["id"] ?? 0,
    name: json["name"] ?? "",
    categories:
        json["categories"] != null
            ? List<Category>.from(
              json["categories"].map((x) => Category.fromJson(x)),
            )
            : [],
    taxonomies:
        json["taxonomies"] != null
            ? List<Taxonomy>.from(
              json["taxonomies"].map((x) => Taxonomy.fromJson(x)),
            )
            : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
    "taxonomies": List<dynamic>.from(taxonomies.map((x) => x.toJson())),
  };
}
