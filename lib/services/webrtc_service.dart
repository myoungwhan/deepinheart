import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:deepinheart/config/webrtc_config.dart';
import 'package:deepinheart/services/signaling_client.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/main.dart'; // Assuming navigatorKey is here

enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  SignalingClient? _signalingClient;
  String? _roomId;
  String? _userId;
  String? _remoteUserId;

  final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();
  final StreamController<WebRTCConnectionState> _connectionStateController =
      StreamController<WebRTCConnectionState>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Event streams
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<WebRTCConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // State getters
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStreamSync => _remoteStream;
  WebRTCConnectionState get currentState => _currentState;
  WebRTCConnectionState _currentState = WebRTCConnectionState.disconnected;

  // Call type
  bool _isVideoCall = true;
  bool get isVideoCall => _isVideoCall;

  Future<void> initialize({
    required bool isVideoCall,
    required String roomId,
    required String userId,
  }) async {
    try {
      // CRITICAL: Validate all required parameters
      if (roomId == null || roomId.isEmpty) {
        debugPrint('❌ Room ID is null or empty!');
        _errorController.add('Room ID is required');
        _connectionStateController.add(WebRTCConnectionState.failed);
        return;
      }
      
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ User ID is null or empty!');
        _errorController.add('User ID is required');
        _connectionStateController.add(WebRTCConnectionState.failed);
        return;
      }
      
      _isVideoCall = isVideoCall;
      _roomId = roomId;
      _userId = userId;

      debugPrint('🎥 Initializing WebRTC service...');
      debugPrint('📞 Call Parameters:');
      debugPrint('   - Is Video Call: $isVideoCall');
      debugPrint('   - Room ID: $roomId');
      debugPrint('   - User ID: $userId');
      
      _connectionStateController.add(WebRTCConnectionState.connecting);

      await _initializeSignalingClient();
      await _createPeerConnection();
      await _getUserMedia();

      debugPrint('✅ WebRTC service local setup complete');
    } catch (e) {
      debugPrint('❌ Failed to initialize WebRTC service: $e');
      _errorController.add('Initialization failed: $e');
      _connectionStateController.add(WebRTCConnectionState.failed);
    }
  }

  Future<void> _initializeSignalingClient() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('❌ Navigator context not available');
      throw Exception('Navigator context not available');
    }

    final settings = Provider.of<SettingProvider>(context, listen: false).settings;
    
    // FIX: Correctly check settings and use the URL from Admin Panel
    String signalingUrl = (settings?.webrtcSignalingUrl != null && settings!.webrtcSignalingUrl.isNotEmpty)
        ? settings.webrtcSignalingUrl
        : WebRTCConfig.defaultSignalingUrl;
    
    // CRITICAL: Validate signaling URL
    if (signalingUrl.isEmpty) {
      debugPrint('❌ Signaling server URL is empty!');
      throw Exception('Signaling server URL is empty');
    }
    
    debugPrint('🔗 Signaling Server URL: $signalingUrl');
    debugPrint('🏠 Room ID: $_roomId');
    debugPrint('👤 User ID: $_userId');
    
    _signalingClient = SignalingClient();
    
    _signalingClient!.messageStream.listen(_handleSignalingMessage);
    _signalingClient!.errorStream.listen((err) => _errorController.add(err));

    _signalingClient!.connectedStream.listen((_) {
      debugPrint('✅ Signaling client connected, joining room...');
      if (_roomId != null) {
        _signalingClient!.joinRoom(_roomId!);
      } else {
        debugPrint('❌ Room ID is null when trying to join!');
        _errorController.add('Room ID is null');
      }
    });

    await _signalingClient!.connect(signalingUrl, _userId!);
  }

  Future<void> _createPeerConnection() async {
    final context = navigatorKey.currentContext;
    final turnServers =
        context != null
            ? Provider.of<SettingProvider>(
              context,
              listen: false,
            ).settings?.webrtcTurnServers
            : null;

    final config = WebRTCConfig.getPeerConnectionConfig(turnServers);

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_remoteUserId != null) {
        _signalingClient!.sendIceCandidate(_remoteUserId!, candidate.toMap());
      } else {
        debugPrint(
          '⌛ ICE candidate generated but remoteUserId is null. Storing...',
        );
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 Peer Connection state: ${state.name}');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _currentState = WebRTCConnectionState.connected;
          _connectionStateController.add(WebRTCConnectionState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _currentState = WebRTCConnectionState.failed;
          _connectionStateController.add(WebRTCConnectionState.failed);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        debugPrint('📹 Remote stream received via onTrack');
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };

    // Legacy support
    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('📹 Remote stream added (legacy)');
      _remoteStream = stream;
      _remoteStreamController.add(stream);
    };

    debugPrint('✅ Peer connection created');
  }

  Future<void> _getUserMedia() async {
    final constraints =
        _isVideoCall
            ? WebRTCConfig.videoConstraints
            : WebRTCConfig.audioConstraints;

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    // Use Transceivers for better control in modern WebRTC
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    debugPrint('✅ Local media stream obtained');
  }

  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    debugPrint(
      '📨 Handling signaling message: ${message.type.name} from ${message.from}',
    );

    // CRITICAL FIX: Ensure remoteUserId is updated from ANY incoming message
    if (message.from != null && message.from != _userId) {
      _remoteUserId = message.from;
    }

    switch (message.type) {
      case SignalingEventType.userJoined:
        // When someone else joins, we are the 'caller', so we create the offer
        await _createAndSendOffer();
        break;

      case SignalingEventType.offer:
        await _handleOffer(message.data);
        break;

      case SignalingEventType.answer:
        await _handleAnswer(message.data);
        break;

      case SignalingEventType.iceCandidate:
        await _handleIceCandidate(message.data);
        break;

      case SignalingEventType.userLeft:
        _remoteUserId = null;
        _connectionStateController.add(WebRTCConnectionState.disconnected);
        break;

      default:
        break;
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _remoteUserId == null) return;
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await _signalingClient!.sendOffer(_remoteUserId!, offer.toMap());
      debugPrint('📤 Offer sent to $_remoteUserId');
    } catch (e) {
      debugPrint('❌ Offer Error: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], 'offer'),
      );
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      if (_remoteUserId != null) {
        await _signalingClient!.sendAnswer(_remoteUserId!, answer.toMap());
        debugPrint('📤 Answer sent to $_remoteUserId');
      }
    } catch (e) {
      debugPrint('❌ Handle Offer Error: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answerData['sdp'], 'answer'),
      );
    } catch (e) {
      debugPrint('❌ Handle Answer Error: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) return;
    try {
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      debugPrint('❌ Add Candidate Error: $e');
    }
  }

  // ... (Media control methods remain same as before)
  Future<void> toggleMicrophone() async {
    if (_localStream == null) return;
    final audioTrack = _localStream!.getAudioTracks().first;
    audioTrack.enabled = !audioTrack.enabled;
  }

  Future<void> toggleCamera() async {
    if (_localStream == null || !_isVideoCall) return;
    final videoTrack = _localStream!.getVideoTracks().first;
    videoTrack.enabled = !videoTrack.enabled;
  }

  Future<void> switchCamera() async {
    if (_localStream == null || !_isVideoCall) return;
    final videoTrack = _localStream!.getVideoTracks().first;
    await Helper.switchCamera(videoTrack);
  }

  bool get isMicrophoneEnabled =>
      _localStream?.getAudioTracks().first.enabled ?? false;
  bool get isCameraEnabled =>
      _localStream?.getVideoTracks().first.enabled ?? false;

  Future<void> dispose() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();
    _signalingClient?.dispose();
    _remoteStreamController.close();
    _connectionStateController.close();
    _errorController.close();
  }
}
