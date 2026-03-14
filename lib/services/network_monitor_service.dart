import 'dart:async';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/foundation.dart';

/// Network connection status
enum NetworkStatus { connected, disconnected, poor, reconnecting }

/// Network monitoring service for Agora calls
class NetworkMonitorService {
  static final NetworkMonitorService _instance =
      NetworkMonitorService._internal();
  factory NetworkMonitorService() => _instance;
  NetworkMonitorService._internal();

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  NetworkStatus _currentStatus = NetworkStatus.connected;
  final _statusController = StreamController<NetworkStatus>.broadcast();

  // Network quality tracking
  int _lastRtt = 0; // Round-trip time in ms
  int _lastPacketLoss = 0; // Packet loss percentage
  bool _isNetworkStable = true;

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Last RTT (Round-trip time)
  int get lastRtt => _lastRtt;

  /// Last packet loss percentage
  int get lastPacketLoss => _lastPacketLoss;

  /// Is network stable
  bool get isNetworkStable => _isNetworkStable;

  /// Initialize network monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final initialStatus = await ConnectivityWrapper.instance.isConnected;
      _currentStatus =
          initialStatus ? NetworkStatus.connected : NetworkStatus.disconnected;
      _statusController.add(_currentStatus);

      // Listen to connectivity changes
      _connectivitySubscription = ConnectivityWrapper.instance.onStatusChange
          .listen((ConnectivityStatus status) {
            _handleConnectivityChange(status);
          });

      debugPrint('🌐 Network Monitor initialized: $_currentStatus');
    } catch (e) {
      debugPrint('❌ Network Monitor initialization error: $e');
    }
  }

  /// Handle connectivity status changes
  void _handleConnectivityChange(ConnectivityStatus status) {
    NetworkStatus newStatus;

    if (status == ConnectivityStatus.CONNECTED) {
      newStatus = NetworkStatus.connected;
      _isNetworkStable = true;
    } else {
      newStatus = NetworkStatus.disconnected;
      _isNetworkStable = false;
    }

    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
      debugPrint('🌐 Network status changed: $_currentStatus');
    }
  }

  /// Update network quality metrics from Agora
  void updateNetworkQuality({required int rtt, required int packetLoss}) {
    _lastRtt = rtt;
    _lastPacketLoss = packetLoss;

    // Determine if network is stable based on quality metrics
    // Poor network: RTT > 500ms or packet loss > 5%
    _isNetworkStable = rtt < 500 && packetLoss < 5;

    if (!_isNetworkStable) {
      _currentStatus = NetworkStatus.poor;
      _statusController.add(_currentStatus);
      debugPrint('⚠️ Poor network quality: RTT=${rtt}ms, Loss=${packetLoss}%');
    } else if (_currentStatus == NetworkStatus.poor) {
      _currentStatus = NetworkStatus.connected;
      _statusController.add(_currentStatus);
      debugPrint(
        '✅ Network quality improved: RTT=${rtt}ms, Loss=${packetLoss}%',
      );
    }
  }

  /// Set reconnecting status
  void setReconnecting(bool isReconnecting) {
    if (isReconnecting) {
      _currentStatus = NetworkStatus.reconnecting;
      _statusController.add(_currentStatus);
      debugPrint('🔄 Network reconnecting...');
    } else if (_currentStatus == NetworkStatus.reconnecting) {
      _currentStatus = NetworkStatus.connected;
      _statusController.add(_currentStatus);
      debugPrint('✅ Network reconnected');
    }
  }

  /// Check if network is available
  Future<bool> isNetworkAvailable() async {
    try {
      return await ConnectivityWrapper.instance.isConnected;
    } catch (e) {
      debugPrint('❌ Error checking network: $e');
      return false;
    }
  }

  /// Get network quality description
  String getNetworkQualityDescription() {
    if (!_isNetworkStable) {
      return 'Poor network quality';
    }
    if (_lastRtt > 300) {
      return 'Network is slow';
    }
    if (_lastPacketLoss > 2) {
      return 'Network has packet loss';
    }
    return 'Network is stable';
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    debugPrint('🌐 Network Monitor disposed');
  }
}
