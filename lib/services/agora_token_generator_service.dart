import 'package:flutter/foundation.dart';
import 'package:agora_token_generator/agora_token_generator.dart';

/// ⚠️ WARNING: This service is for TESTING ONLY!
/// NEVER use this in production as it exposes your App Certificate.
/// In production, generate tokens on your backend server.
///
/// 🧪 TO REMOVE THIS:
/// 1. Delete this file
/// 2. Remove the import from video_call_screen.dart
/// 3. Change USE_GENERATED_TOKEN to false in video_call_screen.dart
class AgoraTokenGeneratorService {
  /// Generate RTC token with ALL video call privileges
  ///
  /// ✅ Includes all privileges needed for remote video preview:
  /// - Join channel
  /// - Publish video/audio
  /// - Subscribe to remote streams
  ///
  /// Parameters:
  /// - [appId]: Agora App ID (from settings)
  /// - [appCertificate]: Agora App Certificate (from settings)
  /// - [channelName]: Channel name (must match exactly!)
  /// - [uid]: User ID (0 for wildcard)
  /// - [tokenExpireSeconds]: Token validity (default: 1 hour)
  static String generateRtcToken({
    required String appId,
    required String appCertificate,
    required String channelName,
    required int uid,
    int tokenExpireSeconds = 3600,
  }) {
    try {
      if (channelName.isEmpty) {
        debugPrint('❌ Token Error: Channel name is empty');
        return '';
      }

      if (appId.isEmpty || appCertificate.isEmpty) {
        debugPrint('❌ Token Error: Agora credentials are empty');
        debugPrint('   App ID: ${appId.isEmpty ? "MISSING" : "OK"}');
        debugPrint(
          '   App Certificate: ${appCertificate.isEmpty ? "MISSING" : "OK"}',
        );
        return '';
      }

      // Generate token with all privileges
      final token = RtcTokenBuilder.buildTokenWithUid(
        appId: appId,
        appCertificate: appCertificate,
        channelName: channelName,
        uid: uid,
        tokenExpireSeconds: tokenExpireSeconds,
      );

      debugPrint('🔑 ═══════════════════════════════════════');
      debugPrint('🔑 Token Generated (Client-Side)');
      debugPrint('🔑 ═══════════════════════════════════════');
      debugPrint('   📺 Channel: $channelName');
      debugPrint('   👤 UID: $uid ${uid == 0 ? "(Wildcard)" : ""}');
      debugPrint('   ⏰ Expires: ${(tokenExpireSeconds / 60).round()} minutes');
      debugPrint('   📏 Length: ${token.length} chars');
      debugPrint('   ✅ Privileges: ALL (Join + Publish + Subscribe)');
      debugPrint('🔑 ═══════════════════════════════════════');

      return token;
    } catch (e) {
      debugPrint('❌ Token Generation Failed: $e');
      return '';
    }
  }
}
