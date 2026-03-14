class DashboardData {
  final SessionsData sessions;
  final RevenueData revenue;
  final ScheduledSessionsData scheduledSessions;
  final RatingData rating;
  

  DashboardData({
    required this.sessions,
    required this.revenue,
    required this.scheduledSessions,
    required this.rating,
  });

  factory DashboardData.sample() {
    return DashboardData(
      sessions: SessionsData(todayCount: 0, totalTime: '0h 0m', isOnline: true),
      revenue: RevenueData(
        dayRevenue: 0,
        weekRevenue: 0,
        monthRevenue: 0,
        changePercentage: 0.0,
      ),
      scheduledSessions: ScheduledSessionsData(
        currentSessions: 0,
        totalSessions: 0,
        nextSessionTime: '0:0 PM',
      ),
      rating: RatingData(averageRating: 0.0, totalReviews: 0),
    );
  }
}

class SessionsData {
  final int todayCount;
  final String totalTime;
  final bool isOnline;

  SessionsData({
    required this.todayCount,
    required this.totalTime,
    required this.isOnline,
  });
}

class RevenueData {
  final double dayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double changePercentage;

  RevenueData({
    required this.dayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.changePercentage,
  });

  String getFormattedRevenue(TimePeriod period) {
    double amount;
    switch (period) {
      case TimePeriod.day:
        amount = dayRevenue;
        break;
      case TimePeriod.week:
        amount = weekRevenue;
        break;
      case TimePeriod.month:
        amount = monthRevenue;
        break;
    }
    return '\$${amount.toStringAsFixed(0)}';
  }
}

class ScheduledSessionsData {
  final int currentSessions;
  final int totalSessions;
  final String nextSessionTime;

  ScheduledSessionsData({
    required this.currentSessions,
    required this.totalSessions,
    required this.nextSessionTime,
  });
}

class RatingData {
  final double averageRating;
  final int totalReviews;

  RatingData({required this.averageRating, required this.totalReviews});
}

enum TimePeriod { day, week, month }
