import 'dart:convert';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Agora webhook event types (matching backend format)
enum AgoraWebhookEventType {
  join, // User joined channel
  leave, // User left channel
  connectionState, // Connection state changed
  networkQuality, // Network quality event
  callStarted, // Call started
  callEnded, // Call ended
  tokenExpire, // Token will expire
  error, // Error occurred
}

/// Agora webhook service for sending events to backend
class AgoraWebhookService {
  static final AgoraWebhookService _instance = AgoraWebhookService._internal();
  factory AgoraWebhookService() => _instance;
  AgoraWebhookService._internal();

  /// Send webhook event to backend
  Future<bool> sendWebhookEvent({
    required AgoraWebhookEventType eventType,
    required String channelName,
    required int userId,
    int? remoteUid,
    Map<String, dynamic>? additionalData,
    String? errorMessage,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Webhook: No auth token available');
        return false;
      }

      // Build event data matching backend format
      final eventData = <String, dynamic>{
        'event_type': eventType.name,
        'channel_name': channelName,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'error_message':
            errorMessage ?? 'None', // Always include, "None" if no error
      };

      // Add remote_uid if provided
      if (remoteUid != null) {
        eventData['remote_uid'] = remoteUid;
      }

      // Add any additional data
      if (additionalData != null) {
        eventData.addAll(additionalData);
      }

      final webhookUrl = '${ApiEndPoints.BASE_URL}agora-webhook';
      final requestBody = jsonEncode(eventData);

      // Debug: Log the webhook payload
      debugPrint('🔔 Sending webhook event:');
      debugPrint('   URL: $webhookUrl');
      debugPrint('   Event Type: ${eventType.name}');
      debugPrint('   Payload: $requestBody');

      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Webhook request timeout');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Webhook sent: ${eventType.name}');
        debugPrint('   Response: ${response.body}');
        return true;
      } else {
        debugPrint(
          '❌ Webhook failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Webhook error: $e');
      return false;
    }
  }

  /// Send user joined event
  Future<void> onUserJoined({
    required String channelName,
    required int userId,
    required int remoteUid,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.join,
      channelName: channelName,
      userId: userId,
      remoteUid: remoteUid,
    );
  }

  /// Send user offline event
  Future<void> onUserOffline({
    required String channelName,
    required int userId,
    required int remoteUid,
    String? reason,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.leave,
      channelName: channelName,
      userId: userId,
      remoteUid: remoteUid,
      additionalData: reason != null ? {'reason': reason} : null,
    );
  }

  /// Send connection state changed event
  Future<void> onConnectionStateChanged({
    required String channelName,
    required int userId,
    required String state,
    required String reason,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.connectionState,
      channelName: channelName,
      userId: userId,
      additionalData: {'connection_state': state, 'reason': reason},
    );
  }

  /// Send network quality event
  Future<void> onNetworkQuality({
    required String channelName,
    required int userId,
    required int rtt,
    required int packetLoss,
    required String quality,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.networkQuality,
      channelName: channelName,
      userId: userId,
      additionalData: {
        'rtt': rtt,
        'packet_loss': packetLoss,
        'quality': quality,
      },
    );
  }

  /// Send call started event
  Future<void> onCallStarted({
    required String channelName,
    required int userId,
    int? appointmentId,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.callStarted,
      channelName: channelName,
      userId: userId,
      additionalData:
          appointmentId != null ? {'appointment_id': appointmentId} : null,
    );
  }

  /// Send call ended event
  Future<void> onCallEnded({
    required String channelName,
    required int userId,
    required Duration callDuration,
    int? appointmentId,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.callEnded,
      channelName: channelName,
      userId: userId,
      additionalData: {
        'call_duration_seconds': callDuration.inSeconds,
        if (appointmentId != null) 'appointment_id': appointmentId,
      },
    );
  }

  /// Send token will expire event
  Future<void> onTokenWillExpire({
    required String channelName,
    required int userId,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.tokenExpire,
      channelName: channelName,
      userId: userId,
    );
  }

  /// Send error event
  Future<void> onError({
    required String channelName,
    required int userId,
    required String errorMessage,
    String? errorCode,
  }) async {
    await sendWebhookEvent(
      eventType: AgoraWebhookEventType.error,
      channelName: channelName,
      userId: userId,
      errorMessage: errorMessage,
      additionalData: errorCode != null ? {'error_code': errorCode} : null,
    );
  }

  /// Get authentication token from SharedPreferences
  /// Token is stored with key "token" (as per UserViewModel)
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Token is stored with key "token" in SharedPreferences
      return prefs.getString('token');
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }
}
