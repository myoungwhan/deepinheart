import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages active call state persistence for rejoining interrupted calls
class CallStateManager {
  static const String _keyActiveCall = 'active_call_state';

  /// Save active call state
  static Future<void> saveCallState({
    required String callType, // 'video' or 'voice'
    required String channelName,
    required String counselorName,
    required int userId,
    required double counselorRate,
    required int? appointmentId,
    required int? counselorId,
    required String? counselorImage,
    required bool isCounselor,
    required int callDurationSeconds,
    required double coinsLeft,
    required bool isTroat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final callState = {
        'callType': callType,
        'channelName': channelName,
        'counselorName': counselorName,
        'userId': userId,
        'counselorRate': counselorRate,
        'appointmentId': appointmentId,
        'counselorId': counselorId,
        'counselorImage': counselorImage,
        'isCounselor': isCounselor,
        'callDurationSeconds': callDurationSeconds,
        'coinsLeft': coinsLeft,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isTroat': isTroat,
      };

      await prefs.setString(_keyActiveCall, jsonEncode(callState));
      print('✅ Call state saved: $callState');
    } catch (e) {
      print('❌ Error saving call state: $e');
    }
  }

  /// Get saved call state
  static Future<Map<String, dynamic>?> getCallState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final callStateJson = prefs.getString(_keyActiveCall);

      if (callStateJson == null) {
        return null;
      }

      final callState = jsonDecode(callStateJson) as Map<String, dynamic>;

      // Check if call state is still valid (within last 30 minutes)
      final timestamp = callState['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = now - timestamp;
      final minutesElapsed = diff / (1000 * 60);

      if (minutesElapsed > 30) {
        // Call state too old, clear it
        await clearCallState();
        print(
          '⚠️ Call state expired (${minutesElapsed.toStringAsFixed(0)} minutes old)',
        );
        return null;
      }

      print('✅ Call state retrieved: $callState');
      return callState;
    } catch (e) {
      print('❌ Error getting call state: $e');
      return null;
    }
  }

  /// Clear saved call state
  static Future<void> clearCallState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveCall);
      print('✅ Call state cleared');
    } catch (e) {
      print('❌ Error clearing call state: $e');
    }
  }

  /// Check if there's an active call
  static Future<bool> hasActiveCall() async {
    final callState = await getCallState();
    return callState != null;
  }
}
