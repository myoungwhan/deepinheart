/// Model for Favorite Clients API response
class FavoriteClientsResponse {
  final bool success;
  final String message;
  final List<FavoriteClientData> data;

  FavoriteClientsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FavoriteClientsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteClientsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => FavoriteClientData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class FavoriteClientData {
  final FavoriteClient client;

  FavoriteClientData({required this.client});

  factory FavoriteClientData.fromJson(Map<String, dynamic> json) {
    return FavoriteClientData(
      client: FavoriteClient.fromJson(json['client'] ?? {}),
    );
  }
}

class FavoriteClient {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final double rating;
  final int sessionCount;

  FavoriteClient({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.rating,
    required this.sessionCount,
  });

  factory FavoriteClient.fromJson(Map<String, dynamic> json) {
    return FavoriteClient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'],
      rating: _parseDouble(json['rating']),
      sessionCount: _parseInt(json['session_count']),
    );
  }

  /// Parse dynamic to double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse dynamic to int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Get initial letter for avatar
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Check if has profile image
  bool get hasProfileImage =>
      profileImage != null && profileImage!.isNotEmpty;
}

