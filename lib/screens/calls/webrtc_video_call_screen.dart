import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:deepinheart/services/webrtc_service.dart';
import 'package:deepinheart/services/call_state_manager.dart';
import 'package:deepinheart/screens/calls/widgets/coin_balance_widget.dart';
import 'package:deepinheart/screens/calls/widgets/call_rating_dialog.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/webrtc_config.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';

class WebRTCVideoCallScreen extends StatefulWidget {
  final String counselorName;
  final String channelName;
  final int userId;
  final double counselorRate;
  final int? appointmentId;
  final int? counselorId;
  final String? counselorImage;
  final bool isCounselor;
  final bool isTroat;

  const WebRTCVideoCallScreen({
    Key? key,
    required this.counselorName,
    required this.channelName,
    required this.userId,
    this.counselorRate = 50.0,
    this.appointmentId,
    this.counselorId,
    this.counselorImage,
    required this.isCounselor,
    required this.isTroat,
  }) : super(key: key);

  @override
  State<WebRTCVideoCallScreen> createState() => _WebRTCVideoCallScreenState();
}

class _WebRTCVideoCallScreenState extends State<WebRTCVideoCallScreen>
    with WidgetsBindingObserver {
  WebRTCService? _webrtcService;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isLoading = true;
  bool _isConnected = false;
  bool _isMicrophoneEnabled = true;
  bool _isCameraEnabled = true;
  bool _isSpeakerEnabled = false;

  Timer? _callTimer;
  Timer? _coinDeductionTimer;
  Duration _callDuration = Duration.zero;

  double _coinsLeft = 0.0;
  double _initialCoins = 0.0;
  late double _coinsPerMinute;
  late double _coinsPerSecond;

  static const int LOW_COINS_THRESHOLD = 100;
  bool _lowCoinsWarningShown = false;
  bool _lessMinuteWarningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Initialize renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      // Get user coins
      await _loadUserCoins();

      // Initialize WebRTC service
      final roomId = WebRTCConfig.generateRoomId(
        widget.appointmentId?.toString() ?? "0",
      );
      final userId = WebRTCConfig.generateUserId();

      _webrtcService = WebRTCService();

      // Listen to service events
      _webrtcService!.connectionState.listen(_onConnectionStateChanged);
      _webrtcService!.remoteStream.listen(_onRemoteStream);
      _webrtcService!.errorStream.listen(_onError);

      // Initialize WebRTC
      await _webrtcService!.initialize(
        isVideoCall: true,
        roomId: roomId,
        userId: userId,
      );

      // Set local renderer
      if (_webrtcService!.localStream != null) {
        _localRenderer.srcObject = _webrtcService!.localStream;
      }

      // Start call timer
      _startCallTimer();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to initialize WebRTC call: $e');
      _showErrorDialog('Failed to initialize call: $e');
    }
  }

  Future<void> _loadUserCoins() async {
    try {
      final userProvider = Provider.of<UserViewModel>(context, listen: false);
      // Fixed: use userModel instead of user
      _coinsLeft = (userProvider.userModel?.data.coins ?? 0).toDouble();
      _initialCoins = _coinsLeft;
      _coinsPerMinute = widget.counselorRate;
      _coinsPerSecond = _coinsPerMinute / 60.0;
    } catch (e) {
      debugPrint('❌ Failed to load user coins: $e');
    }
  }

  void _onConnectionStateChanged(WebRTCConnectionState state) {
    setState(() {
      switch (state) {
        case WebRTCConnectionState.connected:
          _isConnected = true;
          break;
        case WebRTCConnectionState.connecting:
          _isConnected = false;
          break;
        case WebRTCConnectionState.disconnected:
        case WebRTCConnectionState.failed:
          _isConnected = false;
          _handleCallEnded();
          break;
        default:
          _isConnected = false;
          break;
      }
    });
  }

  void _onRemoteStream(MediaStream stream) {
    setState(() {
      _remoteRenderer.srcObject = stream;
    });
  }

  void _onError(String error) {
    debugPrint('❌ WebRTC error: $error');
    _showErrorDialog(error);
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration = Duration(seconds: timer.tick);
        });

        // Deduct coins every second
        if (!widget.isCounselor && _isConnected) {
          _deductCoins();
        }

        // Check for warnings
        _checkCoinWarnings();
      }
    });
  }

  void _deductCoins() {
    if (_coinsLeft <= 0) {
      _handleInsufficientCoins();
      return;
    }

    _coinsLeft -= _coinsPerSecond;

    // Update user coins in provider
    final userProvider = Provider.of<UserViewModel>(context, listen: false);
    userProvider.updateCoins(_coinsLeft.toInt());
  }

  void _checkCoinWarnings() {
    // Low coins warning
    if (_coinsLeft < LOW_COINS_THRESHOLD && !_lowCoinsWarningShown) {
      _lowCoinsWarningShown = true;
      _showLowCoinsWarning();
    }

    // Less than 1 minute warning
    final minutesLeft = _coinsLeft / _coinsPerMinute;
    if (minutesLeft < 1.0 && !_lessMinuteWarningShown) {
      _lessMinuteWarningShown = true;
      _showLessMinuteWarning();
    }
  }

  void _showLowCoinsWarning() {
    Get.snackbar(
      'Low Balance Warning'.tr,
      'You have less than $LOW_COINS_THRESHOLD coins left'.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showLessMinuteWarning() {
    Get.snackbar(
      'Time Warning'.tr,
      'Less than 1 minute remaining'.tr,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleInsufficientCoins() {
    _showErrorDialog('Insufficient coins. Call ended.');
    _endCall();
  }

  void _handleCallEnded() {
    if (mounted) {
      _showCallRatingDialog();
    }
  }

  void _showCallRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CallRatingDialog(
            counselorId: widget.counselorId ?? 0,
            appointmentId: widget.appointmentId ?? 0,
            counselorName: widget.counselorName,
            counselorImage: widget.counselorImage,
            callDuration: _callDuration,
          ),
    ).then((_) {
      if (mounted) Get.back();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error'.tr),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  _endCall();
                },
                child: Text('OK'.tr),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleMicrophone() async {
    await _webrtcService?.toggleMicrophone();
    if (mounted) {
      setState(() {
        _isMicrophoneEnabled = !_isMicrophoneEnabled;
      });
    }
  }

  Future<void> _toggleCamera() async {
    await _webrtcService?.toggleCamera();
    if (mounted) {
      setState(() {
        _isCameraEnabled = !_isCameraEnabled;
      });
    }
  }

  Future<void> _switchCamera() async {
    await _webrtcService?.switchCamera();
  }

  void _toggleSpeaker() {
    if (mounted) {
      setState(() {
        _isSpeakerEnabled = !_isSpeakerEnabled;
      });
    }
  }

  void _endCall() {
    _callTimer?.cancel();
    _coinDeductionTimer?.cancel();
    _webrtcService?.dispose();
    Get.back();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading ? _buildLoadingUI() : _buildCallUI(),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 20.h),
          CustomText(
            text: 'Connecting...'.tr,
            fontSize: FontConstants.font_16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildCallUI() {
    return Stack(
      children: [
        // Remote video (full screen)
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child:
                _remoteRenderer.srcObject != null
                    ? RTCVideoView(_remoteRenderer)
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 80.w,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          SizedBox(height: 10.h),
                          CustomText(
                            text: 'Waiting for ${widget.counselorName}...'.tr,
                            fontSize: FontConstants.font_16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
          ),
        ),

        // Local video (small overlay)
        Positioned(
          top: 60.h,
          right: 20.w,
          child: Container(
            width: 120.w,
            height: 160.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: primaryColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child:
                  _localRenderer.srcObject != null
                      ? RTCVideoView(_localRenderer, mirror: true)
                      : Container(color: Colors.grey),
            ),
          ),
        ),

        // Top bar with call info
        Positioned(
          top: 40.h,
          left: 20.w,
          right: 20.w,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: widget.counselorName,
                      fontSize: FontConstants.font_18,
                      color: Colors.white,
                      weight: FontWeightConstants.bold,
                    ),
                    CustomText(
                      text: _formatDuration(_callDuration),
                      fontSize: FontConstants.font_14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              CoinBalanceWidget(
                coinsLeft: _coinsLeft,
                estimatedMinutesLeft:
                    _coinsPerMinute > 0
                        ? (_coinsLeft / _coinsPerMinute).ceil()
                        : 0,
                isCounselor: widget.isCounselor,
              ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 40.h,
          left: 20.w,
          right: 20.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
                onPressed: _toggleMicrophone,
                backgroundColor:
                    _isMicrophoneEnabled ? Colors.white30 : Colors.red,
              ),
              _buildControlButton(
                icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                onPressed: _toggleCamera,
                backgroundColor: _isCameraEnabled ? Colors.white30 : Colors.red,
              ),
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                onPressed: _switchCamera,
                backgroundColor: Colors.white30,
              ),
              _buildControlButton(
                icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
                onPressed: _toggleSpeaker,
                backgroundColor:
                    _isSpeakerEnabled ? Colors.white30 : Colors.white30,
              ),
              _buildControlButton(
                icon: Icons.call_end,
                onPressed: _endCall,
                backgroundColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 30.w),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _coinDeductionTimer?.cancel();
    _webrtcService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _saveCurrentCallState();
        break;
      case AppLifecycleState.resumed:
        CallStateManager.clearCallState();
        break;
      case AppLifecycleState.detached:
        _saveCurrentCallState();
        break;
      default:
        break;
    }
  }

  void _saveCurrentCallState() {
    if (!_isConnected) return;

    CallStateManager.saveCallState(
      callType: 'video',
      channelName: widget.channelName,
      counselorName: widget.counselorName,
      userId: widget.userId,
      counselorRate: widget.counselorRate,
      appointmentId: widget.appointmentId,
      counselorId: widget.counselorId,
      counselorImage: widget.counselorImage,
      isCounselor: widget.isCounselor,
      callDurationSeconds: _callDuration.inSeconds,
      coinsLeft: _coinsLeft,
      isTroat: widget.isTroat,
    );
  }
}
