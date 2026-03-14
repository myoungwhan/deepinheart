// To parse this JSON data, do
//
//     final accountServiceModel = accountServiceModelFromJson(jsonString);

import 'dart:convert';

import 'package:deepinheart/Controller/Model/hashtag_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Model/time_slots_model.dart';
import 'package:deepinheart/services/translation_service.dart';

AccountServiceModel accountServiceModelFromJson(String str) =>
    AccountServiceModel.fromJson(json.decode(str));

String accountServiceModelToJson(AccountServiceModel data) =>
    json.encode(data.toJson());

class AccountServiceModel {
  bool success;
  String message;
  ServiceModel data;

  AccountServiceModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AccountServiceModel.fromJson(Map<String, dynamic> json) =>
      AccountServiceModel(
        success: json["success"],
        message: json["message"],
        data: ServiceModel.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data.toJson(),
  };
}

class ServiceModel {
  int id;
  List<Category> categories;
  List<TaxonomyService> taxonomies;
  List<HashTagData> hashTags;
  List<Speciality> specialities;
  ProfileInformation profileInformation;
  int timeInput;
  CounsultationMethod counsultationMethod;
  List<Avialability> avialability;
  Reservation reservation;
  Holidays holidays;
  List<Package> packages;

  ServiceModel({
    required this.id,
    required this.categories,
    required this.taxonomies,
    required this.hashTags,
    required this.specialities,
    required this.profileInformation,
    required this.timeInput,
    required this.counsultationMethod,
    required this.avialability,
    required this.reservation,
    required this.holidays,
    required this.packages,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json["id"],
    categories: List<Category>.from(
      json["categories"].map((x) => Category.fromJson(x)),
    ),
    taxonomies: List<TaxonomyService>.from(
      json["taxonomies"].map((x) => TaxonomyService.fromJson(x)),
    ),
    hashTags: List<HashTagData>.from(
      json["hashTags"].map((x) => HashTagData.fromJson(x)),
    ),
    specialities: List<Speciality>.from(
      json["specialities"].map((x) => Speciality.fromJson(x)),
    ),
    profileInformation: ProfileInformation.fromJson(
      json["profile_information"],
    ),
    timeInput: json["time_input"],
    counsultationMethod: CounsultationMethod.fromJson(
      json["counsultation_method"],
    ),
    avialability: List<Avialability>.from(
      json["avialability"].map((x) => Avialability.fromJson(x)),
    ),
    reservation: Reservation.fromJson(json["reservation"]),
    holidays: Holidays.fromJson(json["holidays"]),
    packages: List<Package>.from(
      json["packages"].map((x) => Package.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "categories": List<dynamic>.from(categories.map((x) => x.toJson())),
    "taxonomies": List<dynamic>.from(taxonomies.map((x) => x.toJson())),
    "hashTags": List<dynamic>.from(hashTags.map((x) => x.toJson())),
    "specialities": List<dynamic>.from(specialities.map((x) => x.toJson())),
    "profile_information": profileInformation.toJson(),
    "time_input": timeInput,
    "counsultation_method": counsultationMethod.toJson(),
    "avialability": List<dynamic>.from(avialability.map((x) => x.toJson())),
    "reservation": reservation.toJson(),
    "holidays": holidays.toJson(),
    "packages": List<dynamic>.from(packages.map((x) => x.toJson())),
  };
}

class Avialability {
  String day;
  List<SlotAvailability> slots;

  Avialability({required this.day, required this.slots});

  factory Avialability.fromJson(Map<String, dynamic> json) => Avialability(
    day: json["day"] ?? "",
    slots: List<SlotAvailability>.from(
      json["slots"].map((x) => SlotAvailability.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "day": day,
    "slots": List<dynamic>.from(slots.map((x) => x.toJson())),
  };
}

class Holidays {
  List<String> holidayRegular;
  List<String> holidayTemporary;

  Holidays({required this.holidayRegular, required this.holidayTemporary});

  factory Holidays.fromJson(Map<String, dynamic> json) => Holidays(
    holidayRegular: List<String>.from(json["holiday_regular"] ?? []),
    holidayTemporary: List<String>.from(json["holiday_temporary"] ?? []),
  );

  Map<String, dynamic> toJson() => {
    "holiday_regular": List<dynamic>.from(holidayRegular),
    "holiday_temporary": List<dynamic>.from(holidayTemporary),
  };
}

class CounsultationMethod {
  int voiceCallAvailable;
  String voiceCallCoin;
  int videoCallAvailable;
  String videoCallCoin;
  int chatAvailable;
  String chatCoin;
  int taxInvoiceAvailable;

  CounsultationMethod({
    required this.voiceCallAvailable,
    required this.voiceCallCoin,
    required this.videoCallAvailable,
    required this.videoCallCoin,
    required this.chatAvailable,
    required this.chatCoin,
    required this.taxInvoiceAvailable,
  });

  factory CounsultationMethod.fromJson(
    Map<String, dynamic> json,
  ) => CounsultationMethod(
    voiceCallAvailable: json["voice_call_available"] ?? 0,
    voiceCallCoin:
        ((double.tryParse(json["voice_call_coin"]?.toString() ?? "0") ?? 0.0)
                .round())
            .toString(),
    videoCallAvailable: json["video_call_available"] ?? 0,
    videoCallCoin:
        ((double.tryParse(json["video_call_coin"]?.toString() ?? "0") ?? 0.0)
                .round())
            .toString(),
    chatAvailable: json["chat_available"] ?? 0,
    chatCoin:
        ((double.tryParse(json["chat_coin"]?.toString() ?? "0") ?? 0.0).round())
            .toString(),
    taxInvoiceAvailable: json["tax_invoice_available"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "voice_call_available": voiceCallAvailable,
    "voice_call_coin": voiceCallCoin,
    "video_call_available": videoCallAvailable,
    "video_call_coin": videoCallCoin,
    "chat_available": chatAvailable,
    "chat_coin": chatCoin,
    "tax_invoice_available": taxInvoiceAvailable,
  };
}

class Package {
  int id;
  String name;
  String discountRate;
  int duration;
  int session;
  int coins;

  Package({
    required this.id,
    required this.name,
    required this.discountRate,
    required this.duration,
    required this.session,
    required this.coins,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
    id: json["id"],
    name: json["name"],
    discountRate: json["discount_rate"],
    duration: json["duration"],
    session: json["session"],
    coins: json["coins"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "discount_rate": discountRate,
    "duration": duration,
    "session": session,
    "coins": coins,
  };
}

class ProfileInformation {
  String experience;
  dynamic certificate;
  dynamic education;
  dynamic training;
  int timeInput;

  ProfileInformation({
    required this.experience,
    required this.certificate,
    required this.education,
    required this.training,
    required this.timeInput,
  });

  factory ProfileInformation.fromJson(Map<String, dynamic> json) =>
      ProfileInformation(
        experience: json["experience"],
        certificate: json["certificate"],
        education: json["education"],
        training: json["training"],
        timeInput: json["time_input"],
      );

  Map<String, dynamic> toJson() => {
    "experience": experience,
    "certificate": certificate,
    "education": education,
    "training": training,
    "time_input": timeInput,
  };
}

class Reservation {
  int minBookingTime;
  int maxBookingPeriod;
  String bookingConfirmation;

  Reservation({
    required this.minBookingTime,
    required this.maxBookingPeriod,
    required this.bookingConfirmation,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    minBookingTime: json["min_booking_time"],
    maxBookingPeriod: json["max_booking_period"],
    bookingConfirmation: json["booking_confirmation"],
  );

  Map<String, dynamic> toJson() => {
    "min_booking_time": minBookingTime,
    "max_booking_period": maxBookingPeriod,
    "booking_confirmation": bookingConfirmation,
  };
}

class Speciality {
  int id;
  String name;

  Speciality({required this.id, required this.name});

  factory Speciality.fromJson(Map<String, dynamic> json) =>
      Speciality(id: json["id"], name: json["name"]);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class TaxonomyService {
  int id;
  String name;
  List<Item> items;

  TaxonomyService({required this.id, required this.name, required this.items});

  factory TaxonomyService.fromJson(Map<String, dynamic> json) =>
      TaxonomyService(
        id: json["id"],
        name: json["name"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "items": List<dynamic>.from(items.map((x) => x.toJson())),
  };
}

class Item {
  int id;
  String name;
  String iconUrl;
  String color;
  String? nameTranslated;

  Item({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.color,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json["id"],
    name: json["name"],
    iconUrl: json["icon_url"] ?? "",
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "icon_url": iconUrl,
    "color": color,
  };

  //
  Future<String> getTranslatedName() async {
    return await translationService.translate(name);
  }
}
