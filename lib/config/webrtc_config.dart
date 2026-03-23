class WebRTCConfig {
  // STUN servers for NAT traversal
  static const List<Map<String, dynamic>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  // TURN servers (optional - configure in backend settings)
  static List<Map<String, dynamic>> getTurnServers(String? turnConfig) {
    if (turnConfig == null || turnConfig.isEmpty) {
      return [];
    }

    try {
      // Parse TURN server configuration from backend
      // Expected format: "turn:username:password@server:port"
      final parts = turnConfig.split('@');
      if (parts.length != 2) return [];

      final authPart = parts[0];
      final serverPart = parts[1];
      
      final authParts = authPart.split(':');
      if (authParts.length != 3) return [];

      final protocol = authParts[0];
      final username = authParts[1];
      final password = authParts[2];

      return [
        {
          'urls': '$protocol:$serverPart',
          'username': username,
          'credential': password,
        }
      ];
    } catch (e) {
      return [];
    }
  }

  // Media constraints for video calls
  static const Map<String, dynamic> videoConstraints = {
    'mandatory': {
      'minWidth': '320',
      'minHeight': '240',
      'maxWidth': '1280',
      'maxHeight': '720',
    },
    'optional': [
      {'minFrameRate': 15},
      {'maxFrameRate': 30},
    ],
  };

  // Media constraints for voice calls
  static const Map<String, dynamic> audioConstraints = {
    'mandatory': {},
    'optional': [
      {'echoCancellation': true},
      {'noiseSuppression': true},
      {'autoGainControl': true},
    ],
  };

  // Peer connection configuration
  static Map<String, dynamic> getPeerConnectionConfig(String? turnConfig) {
    return {
      'iceServers': [...iceServers, ...getTurnServers(turnConfig)],
      'iceCandidatePoolSize': 10,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
  }

  // Default signaling server URL (can be overridden by backend settings)
  static const String defaultSignalingUrl = 'ws://localhost:8080';
  
  // Connection timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration reconnectionDelay = Duration(seconds: 3);
  static const int maxReconnectionAttempts = 5;

  // Room and user management
  static String generateRoomId(String appointmentId) {
    return 'webrtc_room_$appointmentId';
  }

  static String generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Media quality presets
  static Map<String, dynamic> getQualityPreset(String quality) {
    switch (quality.toLowerCase()) {
      case 'low':
        return {
          'width': {'min': 320, 'ideal': 320},
          'height': {'min': 240, 'ideal': 240},
          'frameRate': {'min': 15, 'ideal': 15},
        };
      case 'medium':
        return {
          'width': {'min': 640, 'ideal': 640},
          'height': {'min': 480, 'ideal': 480},
          'frameRate': {'min': 24, 'ideal': 24},
        };
      case 'high':
        return {
          'width': {'min': 1280, 'ideal': 1280},
          'height': {'min': 720, 'ideal': 720},
          'frameRate': {'min': 30, 'ideal': 30},
        };
      default:
        return getQualityPreset('medium');
    }
  }
}
