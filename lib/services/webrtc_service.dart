import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:deepinheart/config/webrtc_config.dart';
import 'package:deepinheart/services/signaling_client.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:provider/provider.dart';

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
  Stream<WebRTCConnectionState> get connectionState => _connectionStateController.stream;
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
      _isVideoCall = isVideoCall;
      _roomId = roomId;
      _userId = userId;
      
      debugPrint('🎥 Initializing WebRTC service...');
      debugPrint('   - Room: $roomId');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Video Call: $isVideoCall');

      await _initializeSignalingClient();
      await _createPeerConnection();
      await _getUserMedia();

      _connectionStateController.add(WebRTCConnectionState.connected);
      _currentState = WebRTCConnectionState.connected;
      
      debugPrint('✅ WebRTC service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize WebRTC service: $e');
      _errorController.add('Initialization failed: $e');
      _connectionStateController.add(WebRTCConnectionState.failed);
      _currentState = WebRTCConnectionState.failed;
    }
  }

  Future<void> _initializeSignalingClient() async {
    // Use default signaling URL unless you later add WebRTC fields to `SettingsData`.
    final signalingUrl = WebRTCConfig.defaultSignalingUrl;

    _signalingClient = SignalingClient();
    
    await _signalingClient!.connect(signalingUrl, _userId!);
    
    // Listen for signaling messages
    _signalingClient!.messageStream.listen(_handleSignalingMessage);
    _signalingClient!.connectedStream.listen((_) {
      _signalingClient!.joinRoom(_roomId!);
    });
  }

  Future<void> _createPeerConnection() async {
    final config = WebRTCConfig.getPeerConnectionConfig(null);

    _peerConnection = await createPeerConnection(config);
    
    // Add event listeners
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_remoteUserId != null) {
        _signalingClient!.sendIceCandidate(
          _remoteUserId!,
          candidate.toMap(),
        );
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 Connection state: ${state.name}');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _connectionStateController.add(WebRTCConnectionState.connected);
          _currentState = WebRTCConnectionState.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _connectionStateController.add(WebRTCConnectionState.failed);
          _currentState = WebRTCConnectionState.failed;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _connectionStateController.add(WebRTCConnectionState.connecting);
          _currentState = WebRTCConnectionState.connecting;
          break;
        default:
          break;
      }
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      debugPrint('📹 Remote stream added');
      _remoteStream = stream;
      _remoteStreamController.add(stream);
    };

    _peerConnection!.onRemoveStream = (MediaStream stream) {
      debugPrint('📹 Remote stream removed');
      if (_remoteStream?.id == stream.id) {
        _remoteStream = null;
      }
    };

    debugPrint('✅ Peer connection created');
  }

  Future<void> _getUserMedia() async {
    try {
      final constraints = _isVideoCall 
          ? WebRTCConfig.videoConstraints 
          : WebRTCConfig.audioConstraints;

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      
      // Add local stream to peer connection
      await _peerConnection!.addStream(_localStream!);
      
      debugPrint('✅ Local media stream obtained');
      
    } catch (e) {
      debugPrint('❌ Failed to get user media: $e');
      _errorController.add('Failed to access camera/microphone: $e');
      rethrow;
    }
  }

  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    debugPrint('📨 Handling signaling message: ${message.type.name}');
    
    switch (message.type) {
      case SignalingEventType.userJoined:
        _remoteUserId = message.from;
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
        _currentState = WebRTCConnectionState.disconnected;
        break;
        
      default:
        debugPrint('⚠️ Unhandled message type: ${message.type.name}');
    }
  }

  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null || _remoteUserId == null) return;

    try {
      final RTCSessionDescription offer = 
          await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      await _signalingClient!.sendOffer(_remoteUserId!, offer.toMap());
      debugPrint('📤 Offer created and sent');
      
    } catch (e) {
      debugPrint('❌ Failed to create offer: $e');
      _errorController.add('Failed to create offer: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData) async {
    if (_peerConnection == null) return;

    try {
      final offer = RTCSessionDescription(offerData['sdp'], 'offer');
      await _peerConnection!.setRemoteDescription(offer);
      
      // Create and send answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      if (_remoteUserId != null) {
        await _signalingClient!.sendAnswer(_remoteUserId!, answer.toMap());
      }
      
      debugPrint('📨 Offer handled and answer sent');
      
    } catch (e) {
      debugPrint('❌ Failed to handle offer: $e');
      _errorController.add('Failed to handle offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    if (_peerConnection == null) return;

    try {
      final answer = RTCSessionDescription(answerData['sdp'], 'answer');
      await _peerConnection!.setRemoteDescription(answer);
      
      debugPrint('📨 Answer handled');
      
    } catch (e) {
      debugPrint('❌ Failed to handle answer: $e');
      _errorController.add('Failed to handle answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      
      await _peerConnection!.addCandidate(candidate);
      debugPrint('📨 ICE candidate added');
      
    } catch (e) {
      debugPrint('❌ Failed to add ICE candidate: $e');
      _errorController.add('Failed to add ICE candidate: $e');
    }
  }

  // Media controls
  Future<void> toggleMicrophone() async {
    if (_localStream == null) return;

    final audioTrack = _localStream!.getAudioTracks().first;
    audioTrack.enabled = !audioTrack.enabled;
    debugPrint('🎤 Microphone ${audioTrack.enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> toggleCamera() async {
    if (_localStream == null || !_isVideoCall) return;

    final videoTrack = _localStream!.getVideoTracks().first;
    videoTrack.enabled = !videoTrack.enabled;
    debugPrint('📹 Camera ${videoTrack.enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> switchCamera() async {
    if (_localStream == null || !_isVideoCall) return;

    try {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      debugPrint('📹 Camera switched');
    } catch (e) {
      debugPrint('❌ Failed to switch camera: $e');
      _errorController.add('Failed to switch camera: $e');
    }
  }

  bool get isMicrophoneEnabled {
    if (_localStream == null) return false;
    final audioTrack = _localStream!.getAudioTracks().first;
    return audioTrack.enabled;
  }

  bool get isCameraEnabled {
    if (_localStream == null || !_isVideoCall) return false;
    final videoTrack = _localStream!.getVideoTracks().first;
    return videoTrack.enabled;
  }

  Future<void> dispose() async {
    debugPrint('🗑️ Disposing WebRTC service...');

    _connectionStateController.add(WebRTCConnectionState.disconnected);
    _currentState = WebRTCConnectionState.disconnected;

    // Stop local stream
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        // `stop()` doesn't return a Future in flutter_webrtc
        track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    // Close peer connection
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    // Disconnect signaling client
    if (_signalingClient != null) {
      _signalingClient!.disconnect();
      _signalingClient!.dispose();
      _signalingClient = null;
    }

    // Clear remote stream
    _remoteStream = null;
    _remoteUserId = null;
    _roomId = null;
    _userId = null;

    // Close stream controllers
    await _remoteStreamController.close();
    await _connectionStateController.close();
    await _errorController.close();

    debugPrint('✅ WebRTC service disposed');
  }
}
