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

  // Media constraints
  static const Map<String, dynamic> videoConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '640', 
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };

  static const Map<String, dynamic> audioConstraints = {
    'audio': true,
    'video': false,
  };

  // Peer connection configuration
  static Map<String, dynamic> getPeerConnectionConfig(String? turnConfig) {
    return {
      'iceServers': [...iceServers, ...getTurnServers(turnConfig)],
      'iceCandidatePoolSize': 10,
    };
  }

  // Production Signaling Server URL
  static const String defaultSignalingUrl = 'http://158.247.241.227:3000';
  
  // Fallback URLs in case primary fails
  static const List<String> fallbackSignalingUrls = [
    'ws://localhost:3000',        // Local development
    'http://127.0.0.1:3000',      // Localhost alternative
    'wss://158.247.241.227:3000',      // WebSocket secure fallback
  ];
  
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration reconnectionDelay = Duration(seconds: 3);
  static const int maxReconnectionAttempts = 5;

  static String generateRoomId(String appointmentId) {
    return 'room_$appointmentId';
  }

  static String generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
