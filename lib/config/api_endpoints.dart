class ApiEndPoints {
  static const SecretKey =
      'Basic MzA2OTo4YTA2M2M3ZS01M2U3LTQ3YmYtOWUxYS00OTY2ZmUyZjhhYWY=';
  static const BASE_URL = "https://deepinheart.savevidtool.com/api/";
  static const USERLOGIN = BASE_URL + "user/login";
  static const SOCIALLOGIN = BASE_URL + "sociallogin";
  static const COUNSELOR_DASHBOARD = BASE_URL + "counselor-dashboard";
  static const COUNSELOR_APPOINTMENT = BASE_URL + "counselor-appointment";
  static const COUNSELOR_APPROVAL = BASE_URL + "counselor-approval";
  static const COUNSELOR_REVENUE =
      BASE_URL + "counselor-revenue-statements"; // Revenue statements
  static const CONSULT_NOW = BASE_URL + "consult-now";
  static const COIN_UPDATE = BASE_URL + "coin-update";
  static const UPDATE_TIME =
      BASE_URL + "update-time"; // For start_time and end_time
  static const GENERATE_AGORA_TOKEN = BASE_URL + "generate-token";
  static const AGORA_WEBHOOK =
      BASE_URL + "agora-webhook"; // Agora webhook events
  static const FAQ_AND_REVIEWS =
      BASE_URL + "faq-and-reviews"; // FAQ and Reviews by category
  static const COUNSELOR_REVIEWS =
      BASE_URL + "review-feedbacks"; // Counselor reviews and feedback
  static const REVIEW_REPLY = BASE_URL + "review-reply"; // Reply to a review
  static const FAVORITE_CLIENTS =
      BASE_URL + "favorite-clients"; // Favorite clients
  static const CONVERSATIONS =
      BASE_URL + "conversations"; // Counselor conversations
  static const CHECK_EMAIL_EXISTS =
      BASE_URL + "check-exit-email"; // Check if email exists
  static const NOTIFICATIONS = BASE_URL + "notifications"; // Notifications
  static const NOTIFICATION_READ =
      BASE_URL + "notifications/read"; // Mark notification as read
  static const NOTIFICATION_READ_ALL =
      BASE_URL + "notifications/read-all"; // Mark all notifications as read
  static const FORGOT_PASSWORD =
      BASE_URL + "forget-password"; // Forgot password
  static const RECENT_APPOINTMENTS =
      BASE_URL + "recent-appointments"; // Recent appointments
  static const MESSAGES_MARK_AS_READ =
      BASE_URL + "messages/mark-as-read"; // Mark messages as read
  static const NOTIFICATION_SETTINGS =
      BASE_URL + "notifications/settings"; // Get notification settings
  static const NOTIFICATION_SETTING =
      BASE_URL + "notifications/setting"; // Update notification settings
  static const UPDATE_IS_AVAILABLE =
      BASE_URL + "update-is-available"; // Update counselor availability
  static const EMERGENCY_ANNOUNCEMENTS =
      BASE_URL + "announcements/emergency"; // Emergency announcements
  static const ANNOUNCEMENTS = BASE_URL + "announcements"; // All announcements
  static const INQUIRIES = BASE_URL + "inquiries"; // Customer service inquiries
  static const PACKAGE_ADD = BASE_URL + "package/add"; // Add package
  static const SEARCH = BASE_URL + "search"; // Search counselors
}
