import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/voice_call_screen.dart';
import 'package:deepinheart/screens/calls/webrtc_video_call_screen.dart';
import 'package:deepinheart/screens/calls/webrtc_voice_call_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum CallEngine {
  agora,
  webrtc,
}

class CallEngineSelector {
  static CallEngine getCurrentEngine() {
    try {
      final settings = Provider.of<SettingProvider>(
        Get.context!,
        listen: false,
      ).settings;
      
      final callServiceType = settings?.callServiceType?.toLowerCase() ?? 'agora';
      
      switch (callServiceType) {
        case 'webrtc':
          return CallEngine.webrtc;
        case 'agora':
        default:
          return CallEngine.agora;
      }
    } catch (e) {
      debugPrint('❌ Failed to get call engine, defaulting to Agora: $e');
      return CallEngine.agora;
    }
  }

  static Future<void> navigateToVideoCall({
    required String counselorName,
    required String channelName,
    required int userId,
    double counselorRate = 50.0,
    int? appointmentId,
    int? counselorId,
    String? counselorImage,
    bool isCounselor = false,
    bool isTroat = false,
  }) async {
    // CRITICAL: Validate all required parameters
    if (channelName == null || channelName.isEmpty) {
      debugPrint('❌ Channel name is null or empty!');
      Get.snackbar('Error', 'Channel name is missing');
      return;
    }
    
    debugPrint('🔍 validateParams - counselorName: $counselorName, channelName: $channelName, userId: $userId');
    
    final engine = getCurrentEngine();
    
    debugPrint('🚀 Navigating to video call with engine: ${engine.name}');
    debugPrint('📞 Call Details:');
    debugPrint('   - Channel Name: $channelName');
    debugPrint('   - User ID: $userId');
    debugPrint('   - Counselor: $counselorName');
    debugPrint('   - Appointment ID: $appointmentId');
    
    switch (engine) {
      case CallEngine.webrtc:
        // Enable WebRTC debugging
        if (kDebugMode) {
          debugPrint('🐛 WebRTC Debug Mode Enabled');
          WebRTC.debug = true;
        }
        
        await Get.to(
          () => WebRTCVideoCallScreen(
            counselorName: counselorName,
            channelName: channelName,
            userId: userId,
            counselorRate: counselorRate,
            appointmentId: appointmentId,
            counselorId: counselorId,
            counselorImage: counselorImage,
            isCounselor: isCounselor,
            isTroat: isTroat,
          ),
        );
        break;
        
      case CallEngine.agora:
      default:
        await Get.to(
          () => VideoCallScreen(
            counslername: counselorName,
            channelName: channelName,
            userId: userId,
            counselorRate: counselorRate,
            appointmentId: appointmentId,
            counselorId: counselorId,
            counselorImage: counselorImage,
            isCounsler: isCounselor,
            isTroat: isTroat,
          ),
        );
        break;
    }
  }

  static Future<void> navigateToVoiceCall({
    required String counselorName,
    required String channelName,
    required int userId,
    double counselorRate = 50.0,
    int? appointmentId,
    int? counselorId,
    String? counselorImage,
    bool isCounselor = false,
    bool isTroat = false,
  }) async {
    // CRITICAL: Validate all required parameters
    if (channelName == null || channelName.isEmpty) {
      debugPrint('❌ Channel name is null or empty!');
      Get.snackbar('Error', 'Channel name is missing');
      return;
    }
    
    debugPrint('🔍 validateParams - counselorName: $counselorName, channelName: $channelName, userId: $userId');
    
    final engine = getCurrentEngine();
    
    debugPrint('🚀 Navigating to voice call with engine: ${engine.name}');
    debugPrint('📞 Call Details:');
    debugPrint('   - Channel Name: $channelName');
    debugPrint('   - User ID: $userId');
    debugPrint('   - Counselor: $counselorName');
    debugPrint('   - Appointment ID: $appointmentId');
    
    switch (engine) {
      case CallEngine.webrtc:
        // Enable WebRTC debugging
        if (kDebugMode) {
          debugPrint('🐛 WebRTC Debug Mode Enabled');
          WebRTC.debug = true;
        }
        
        await Get.to(
          () => WebRTCVoiceCallScreen(
            counselorName: counselorName,
            channelName: channelName,
            userId: userId,
            counselorRate: counselorRate,
            appointmentId: appointmentId,
            counselorId: counselorId,
            counselorImage: counselorImage,
            isCounselor: isCounselor,
            isTroat: isTroat,
          ),
        );
        break;
        
      case CallEngine.agora:
      default:
        await Get.to(
          () => VoiceCallScreen(
            isCounselor: isCounselor,
            counslername: counselorName,
            channelName: channelName,
            userId: userId,
            counselorRate: counselorRate,
            appointmentId: appointmentId,
            counselorId: counselorId,
            counselorImage: counselorImage,
            isTroat: isTroat,
          ),
        );
        break;
    }
  }

  static String getEngineDisplayName() {
    final engine = getCurrentEngine();
    switch (engine) {
      case CallEngine.webrtc:
        return 'WebRTC';
      case CallEngine.agora:
      default:
        return 'Agora';
    }
  }

  static bool isWebRTCEngine() {
    return getCurrentEngine() == CallEngine.webrtc;
  }

  static bool isAgoraEngine() {
    return getCurrentEngine() == CallEngine.agora;
  }
}
