// To parse this JSON data, do
//
//     final timeSlotModel = timeSlotModelFromJson(jsonString);

import 'dart:convert';

TimeSlotModel timeSlotModelFromJson(String str) =>
    TimeSlotModel.fromJson(json.decode(str));

String timeSlotModelToJson(TimeSlotModel data) => json.encode(data.toJson());

class TimeSlotModel {
  bool success;
  String message;
  List<TimeSlotData> data;

  TimeSlotModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) => TimeSlotModel(
    success: json["success"],
    message: json["message"],
    data: List<TimeSlotData>.from(
      json["data"].map((x) => TimeSlotData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class TimeSlotData {
  String period;
  List<Slot> slots;

  TimeSlotData({required this.period, required this.slots});

  factory TimeSlotData.fromJson(Map<String, dynamic> json) => TimeSlotData(
    period: json["period"],
    slots: List<Slot>.from(json["slots"].map((x) => Slot.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "period": period,
    "slots": List<dynamic>.from(slots.map((x) => x.toJson())),
  };
}

class Slot {
  int id;
  String displayTime;
  int isActive;

  Slot({required this.id, required this.displayTime, required this.isActive});

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
    id: json["id"] ?? 0,
    displayTime: json["display_time"] ?? "",
    isActive: json["is_active"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "display_time": displayTime,
    "is_active": isActive,
  };
}

class SlotAvailability {
  Slot slot;
  bool isAvailable;

  SlotAvailability({required this.slot, required this.isAvailable});

  factory SlotAvailability.fromJson(Map<String, dynamic> json) =>
      SlotAvailability(
        slot: Slot.fromJson(json["slot"] ?? {}),
        isAvailable: json["is_available"] ?? false,
      );

  Map<String, dynamic> toJson() => {
    "slot": slot.toJson(),
    "is_available": isAvailable,
  };
}
