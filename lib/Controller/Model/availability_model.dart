import 'dart:convert';

AvailabilityResponse availabilityResponseFromJson(String str) =>
    AvailabilityResponse.fromJson(json.decode(str));

String availabilityResponseToJson(AvailabilityResponse data) =>
    json.encode(data.toJson());

class AvailabilityResponse {
  bool success;
  String message;
  AvailabilityData? data;

  AvailabilityResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AvailabilityResponse.fromJson(
    Map<String, dynamic> json,
  ) => AvailabilityResponse(
    success: json["success"],
    message: json["message"],
    data: json["data"] != null ? AvailabilityData.fromJson(json["data"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": data?.toJson(),
  };
}

class AvailabilityData {
  List<DayAvailability> availability;

  AvailabilityData({required this.availability});

  factory AvailabilityData.fromJson(Map<String, dynamic> json) =>
      AvailabilityData(
        availability: List<DayAvailability>.from(
          json["availability"].map((x) => DayAvailability.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "availability": List<dynamic>.from(availability.map((x) => x.toJson())),
  };
}

class DayAvailability {
  String day;
  List<SlotAvailabilityItem> slots;

  DayAvailability({required this.day, required this.slots});

  factory DayAvailability.fromJson(Map<String, dynamic> json) =>
      DayAvailability(
        day: json["day"],
        slots: List<SlotAvailabilityItem>.from(
          json["slots"].map((x) => SlotAvailabilityItem.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "day": day,
    "slots": List<dynamic>.from(slots.map((x) => x.toJson())),
  };
}

class SlotAvailabilityItem {
  SlotInfo slot;
  bool isAvailable;

  SlotAvailabilityItem({required this.slot, required this.isAvailable});

  factory SlotAvailabilityItem.fromJson(Map<String, dynamic> json) =>
      SlotAvailabilityItem(
        slot: SlotInfo.fromJson(json["slot"]),
        isAvailable: json["is_available"],
      );

  Map<String, dynamic> toJson() => {
    "slot": slot.toJson(),
    "is_available": isAvailable,
  };
}

class SlotInfo {
  int id;
  String displayTime;
  int isActive;

  SlotInfo({
    required this.id,
    required this.displayTime,
    required this.isActive,
  });

  factory SlotInfo.fromJson(Map<String, dynamic> json) => SlotInfo(
    id: json["id"],
    displayTime: json["display_time"],
    isActive: json["is_active"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "display_time": displayTime,
    "is_active": isActive,
  };
}
