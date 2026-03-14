import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:deepinheart/config/webrtc_config.dart';

enum SignalingEventType {
  join,
  leave,
  offer,
  answer,
  iceCandidate,
  userJoined,
  userLeft,
  error,
}

class SignalingMessage {
  final SignalingEventType type;
  final Map<String, dynamic> data;
  final String? from;
  final String? to;
  final String room;

  SignalingMessage({
    required this.type,
    required this.data,
    required this.room,
    this.from,
    this.to,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'room': room,
      'from': from,
      'to': to,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: SignalingEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SignalingEventType.error,
      ),
      data: json['data'] ?? {},
      room: json['room'] ?? '',
      from: json['from'],
      to: json['to'],
    );
  }
}

class SignalingClient {
  IO.Socket? _socket;
  String? _currentRoom;
  String? _userId;
  final StreamController<SignalingMessage> _messageController = 
      StreamController<SignalingMessage>.broadcast();
  
  // Event streams
  Stream<SignalingMessage> get messageStream => _messageController.stream;
  Stream<void> get connectedStream => _connectedController.stream;
  Stream<void> get disconnectedStream => _disconnectedController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  final StreamController<void> _connectedController = 
      StreamController<void>.broadcast();
  final StreamController<void> _disconnectedController = 
      StreamController<void>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();

  bool get isConnected => _socket?.connected ?? false;
  String? get currentRoom => _currentRoom;
  String? get userId => _userId;

  Future<void> connect(String signalingUrl, String userId) async {
    try {
      _userId = userId;
      
      debugPrint('🔌 Connecting to signaling server: $signalingUrl');
      
      _socket = IO.io(
        signalingUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setReconnectionAttempts(WebRTCConfig.maxReconnectionAttempts)
            .setReconnectionDelay(WebRTCConfig.reconnectionDelay.inMilliseconds)
            .setTimeout(WebRTCConfig.connectionTimeout.inMilliseconds)
            .build(),
      );

      _setupEventListeners();
      
      await _socket?.connect();
      
      debugPrint('✅ Connected to signaling server');
      _connectedController.add(null);
      
    } catch (e) {
      debugPrint('❌ Failed to connect to signaling server: $e');
      _errorController.add('Connection failed: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('✅ Socket connected');
      _connectedController.add(null);
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Socket disconnected');
      _disconnectedController.add(null);
    });

    _socket!.onConnectError((error) {
      debugPrint('❌ Socket connection error: $error');
      _errorController.add('Connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
      _errorController.add('Socket error: $error');
    });

    _socket!.on('message', (data) {
      try {
        final message = SignalingMessage.fromJson(data);
        debugPrint('📨 Received signaling message: ${message.type.name}');
        _messageController.add(message);
      } catch (e) {
        debugPrint('❌ Failed to parse signaling message: $e');
      }
    });

    _socket!.on('room-joined', (data) {
      debugPrint('🏠 Joined room: ${data['room']}');
    });

    _socket!.on('room-left', (data) {
      debugPrint('🚪 Left room: ${data['room']}');
    });

    _socket!.on('user-joined', (data) {
      debugPrint('👤 User joined room: ${data['userId']}');
      final message = SignalingMessage(
        type: SignalingEventType.userJoined,
        data: data,
        room: _currentRoom ?? '',
        from: data['userId'],
      );
      _messageController.add(message);
    });

    _socket!.on('user-left', (data) {
      debugPrint('👋 User left room: ${data['userId']}');
      final message = SignalingMessage(
        type: SignalingEventType.userLeft,
        data: data,
        room: _currentRoom ?? '',
        from: data['userId'],
      );
      _messageController.add(message);
    });
  }

  Future<void> joinRoom(String roomId) async {
    if (!isConnected) {
      throw Exception('Not connected to signaling server');
    }

    _currentRoom = roomId;
    
    final message = SignalingMessage(
      type: SignalingEventType.join,
      data: {
        'userId': _userId,
        'room': roomId,
      },
      room: roomId,
      from: _userId,
    );

    _socket?.emit('join-room', message.toJson());
    debugPrint('🏠 Joining room: $roomId');
  }

  Future<void> leaveRoom() async {
    if (!isConnected || _currentRoom == null) return;

    final message = SignalingMessage(
      type: SignalingEventType.leave,
      data: {
        'userId': _userId,
        'room': _currentRoom,
      },
      room: _currentRoom!,
      from: _userId,
    );

    _socket?.emit('leave-room', message.toJson());
    debugPrint('🚪 Leaving room: $_currentRoom');
    
    _currentRoom = null;
  }

  Future<void> sendOffer(String targetUserId, Map<String, dynamic> offer) async {
    if (!isConnected || _currentRoom == null) {
      throw Exception('Not connected to room');
    }

    final message = SignalingMessage(
      type: SignalingEventType.offer,
      data: offer,
      room: _currentRoom!,
      from: _userId,
      to: targetUserId,
    );

    _socket?.emit('send-message', message.toJson());
    debugPrint('📤 Sending offer to: $targetUserId');
  }

  Future<void> sendAnswer(String targetUserId, Map<String, dynamic> answer) async {
    if (!isConnected || _currentRoom == null) {
      throw Exception('Not connected to room');
    }

    final message = SignalingMessage(
      type: SignalingEventType.answer,
      data: answer,
      room: _currentRoom!,
      from: _userId,
      to: targetUserId,
    );

    _socket?.emit('send-message', message.toJson());
    debugPrint('📤 Sending answer to: $targetUserId');
  }

  Future<void> sendIceCandidate(String targetUserId, Map<String, dynamic> candidate) async {
    if (!isConnected || _currentRoom == null) {
      throw Exception('Not connected to room');
    }

    final message = SignalingMessage(
      type: SignalingEventType.iceCandidate,
      data: candidate,
      room: _currentRoom!,
      from: _userId,
      to: targetUserId,
    );

    _socket?.emit('send-message', message.toJson());
    debugPrint('📤 Sending ICE candidate to: $targetUserId');
  }

  void disconnect() {
    if (_currentRoom != null) {
      leaveRoom();
    }

    _socket?.disconnect();
    _socket = null;
    _currentRoom = null;
    _userId = null;
    
    debugPrint('🔌 Disconnected from signaling server');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectedController.close();
    _disconnectedController.close();
    _errorController.close();
  }
}
