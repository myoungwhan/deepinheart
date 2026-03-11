class CounselorDashboardModel {
  final bool success;
  final String message;
  final CounselorDashboardData data;

  CounselorDashboardModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CounselorDashboardModel.fromJson(Map<String, dynamic> json) {
    return CounselorDashboardModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: CounselorDashboardData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data.toJson()};
  }
}

class CounselorDashboardData {
  final int todaySession;
  final String todaySessionTime;
  final int weeklySession;
  final RevenueData revenue;
  final num rating;
  final num rating_count;

  CounselorDashboardData({
    required this.todaySession,
    required this.todaySessionTime,
    required this.weeklySession,
    required this.revenue,
    required this.rating,
    required this.rating_count,
  });

  factory CounselorDashboardData.fromJson(Map<String, dynamic> json) {
    return CounselorDashboardData(
      todaySession: json['today_session'] ?? 0,
      todaySessionTime: json['today_session_time'] ?? '0 hrs 0 mins',
      weeklySession: json['weekly_session'] ?? 0,
      revenue: RevenueData.fromJson(json['revenue'] ?? {}),
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      rating_count: json['rating_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_session': todaySession,
      'today_session_time': todaySessionTime,
      'weekly_session': weeklySession,
      'revenue': revenue.toJson(),
      'rating': rating,
    };
  }
}

class RevenueData {
  final num daily;
  final num weekly;
  final num monthly;
  final num dailyVsYesterday;
  final num weeklyVsLastWeek;
  final num monthlyVsLastMonth;

  RevenueData({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.dailyVsYesterday,
    required this.weeklyVsLastWeek,
    required this.monthlyVsLastMonth,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      daily: _parseToNum(json['daily']),
      weekly: _parseToNum(json['weekly']),
      monthly: _parseToNum(json['monthly']),
      dailyVsYesterday: _parseToNum(json['daily_vs_yesterday']),
      weeklyVsLastWeek: _parseToNum(json['weekly_vs_last_week']),
      monthlyVsLastMonth: _parseToNum(json['monthly_vs_last_month']),
    );
  }

  /// Helper method to parse string or number to num
  /// Handles both string and numeric values from API
  static num _parseToNum(dynamic value) {
    if (value == null) return 0;

    // If already a number, return it
    if (value is num) return value;

    // If it's a string, try to parse it
    if (value is String) {
      // Remove any whitespace
      final trimmed = value.trim();
      if (trimmed.isEmpty) return 0;

      // Try to parse as double first (handles decimals)
      final parsed = num.tryParse(trimmed);
      if (parsed != null) return parsed;

      // If parsing fails, return 0
      return 0;
    }

    // For any other type, try to convert to num
    try {
      return num.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily,
      'daily_vs_yesterday': dailyVsYesterday,
      'weekly': weekly,
      'weekly_vs_last_week': weeklyVsLastWeek,
      'monthly': monthly,
      'monthly_vs_last_month': monthlyVsLastMonth,
    };
  }

  /// Get revenue value based on time period
  num getRevenueByPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'day':
      case 'daily':
        return daily;
      case 'week':
      case 'weekly':
        return weekly;
      case 'month':
      case 'monthly':
        return monthly;
      default:
        return daily;
    }
  }
}
