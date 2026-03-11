// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  bool success;
  String message;
  Data data;

  UserModel({required this.success, required this.message, required this.data});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    success: json["success"],
    message: json["message"],
    data: Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
  };
}

class Data {
  int id;
  String name;
  String nickName;
  String email;
  String phone;
  String role;
  String profileImage;
  String socialType;
  List<Specialty> specialties;
  String token;
  String? gender;
  String? address1;
  String? address2;
  String? zip;
  String? introduction;
  //add "coins" rating
  int? coins;
  double? rating;
  bool? isAvailable;
  bool? in_session;
  bool? isOnline;
  String? lastSeen;

  Data({
    required this.id,
    required this.name,
    required this.nickName,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.socialType,
    required this.specialties,
    required this.token,
    this.gender,
    this.address1,
    this.address2,
    this.zip,
    this.introduction,
    this.coins,
    this.rating,
    this.isAvailable,
    this.isOnline,
    this.lastSeen,
    this.in_session,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"],
    name: json["name"],
    nickName: json["nick_name"],
    email: json["email"],
    phone: json["phone"].toString(),
    role: json["role"],
    profileImage: json["profile_image"],
    socialType: json["social_type"],
    specialties: List<Specialty>.from(
      json["specialties"].map((x) => Specialty.fromJson(x)),
    ),
    token: json["token"] ?? "",
    gender: json["gender"],
    address1: json["address1"],
    address2: json["address2"],
    zip: json["zip"],
    introduction: json["introduction"],
    coins: json["coins"] ?? 0,
    rating: double.tryParse(json["rating"].toString()) ?? 0.0,
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
    "social_type": socialType,
    "specialties": List<dynamic>.from(specialties.map((x) => x.toJson())),
    "token": token,
    "gender": gender,
    "address1": address1,
    "address2": address2,
    "zip": zip,
    "introduction": introduction,
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

  Specialty({required this.id, required this.name, required this.categories});

  factory Specialty.fromJson(Map<String, dynamic> json) => Specialty(
    id: json["id"],
    name: json["name"],
    categories: List<Category>.from(
      json["categories"].map((x) => Category.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
  };
}

class Category {
  int id;
  String name;
  String image;
  String description;
  String position;
  String screenNumber;
  int status;
  List<SubCategory> subCategories;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.position,
    required this.screenNumber,
    required this.status,
    required this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"],
    name: json["name"],
    image: json["image"],
    description: json["description"],
    position: json["position"],
    screenNumber: json["screen_number"],
    status: json["status"],
    subCategories:
        json.containsKey('sub_categories')
            ? List<SubCategory>.from(
              json["sub_categories"].map((x) => SubCategory.fromJson(x)),
            )
            : [],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "description": description,
    "position": position,
    "screen_number": screenNumber,
    "status": status,
    "sub_categories": List<dynamic>.from(subCategories.map((x) => x.toJson())),
  };
}

class SubCategory {
  int id;
  String name;
  dynamic iconUrl;
  String color;

  SubCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.color,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) => SubCategory(
    id: json["id"],
    name: json["name"],
    iconUrl: json["icon_url"],
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "icon_url": iconUrl,
    "color": color,
  };
}
