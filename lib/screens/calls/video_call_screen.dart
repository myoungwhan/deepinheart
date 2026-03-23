import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:deepinheart/Controller/Model/settings_model.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/calls/widgets/coin_balance_widget.dart';
import 'package:deepinheart/services/agora_token_generator_service.dart'; // 🧪 Token Generator (remove for production)
import 'package:deepinheart/services/agora_webhook_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:deepinheart/screens/calls/widgets/call_rating_dialog.dart';
import 'package:deepinheart/services/call_state_manager.dart';

// ============================================
// 🧪 TOKEN GENERATION CONFIGURATION
// ============================================
// 🧪 USE_GENERATED_TOKEN:
//    true  = Generate tokens locally (TESTING ONLY - includes App Certificate)
//    false = Fetch tokens from backend API (PRODUCTION)
//
// ⚠️ TO REMOVE CLIENT-SIDE TOKEN GENERATION:
// 1. Set USE_GENERATED_TOKEN = false
// 2. Delete lib/services/agora_token_generator_service.dart
// 3. Remove the import on line 8
const bool USE_GENERATED_TOKEN = false; // ⭐ CHANGE TO false FOR PRODUCTION

// ============================================
// 🧪 TEST MODE CONFIGURATION
// ============================================
// Set to TRUE to use hardcoded Agora Console token for testing
// Set to FALSE to use backend API token for production
const bool USE_TEST_MODE = false; // ⭐ CHANGE THIS TO SWITCH MODES

// Test channel and token (only used when USE_TEST_MODE = true)
const String TEST_CHANNEL_NAME = "test_video_123";
const String TEST_AGORA_TOKEN =
    "007eJxTYDjMqnlKUbszcfWqP+Jrapa6bo7+8DtUrtrR7o5wYM/kyxkKDIaJqUamiQapiWmp5iZJSaaWKUkpJqaGBpYWhgbmlsnGJYu4MhsCGRnSn/QwMzIwMrAAMYjPBCaZwSQLmORjKEktLokvy0xJzY83NDJmYAAA86ElWw==";

// ============================================

class VideoCallScreen extends StatefulWidget {
  final String counslername;
  String channelName;
  final int userId;
  final double counselorRate; // Coins per minute
  final int? appointmentId; // Optional appointment ID for coin updates
  final int? counselorId; // Counselor ID for API calls
  final String? counselorImage; // Counselor image URL
  final bool isCounsler;
  final bool isTroat;
  VideoCallScreen({
    Key? key,
    required this.counslername,
    required this.channelName,
    required this.userId,
    this.counselorRate = 50.0, // Default rate
    this.appointmentId, // Optional parameter
    this.counselorId, // Counselor ID
    this.counselorImage, // Counselor image
    required this.isCounsler,
    required this.isTroat,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with WidgetsBindingObserver {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true; // Track camera direction
  int? _remoteUid;
  bool _isLoading = true;
  Timer? _callTimer;
  Timer? _coinDeductionTimer;
  Timer?
  _coinUpdateApiTimer; // Timer for calling coin-update API every 1 minute
  Timer? _reconnectionGraceTimer; // Timer to wait for user reconnection
  Duration _callDuration = Duration.zero;
  bool _isWaitingForReconnection = false; // Flag to show waiting UI

  // Coins and time tracking
  double _coinsLeft = 0.0; // Get from user balance
  int _initialCoins = 0;
  int _estimatedMinutesLeft = 0;
  bool _isCounselor = false; // Track if current user is a counselor

  // Coin rate configuration (dynamic, from counselor)
  late double coinsPerMinute; // Set from widget.counselorRate
  late double coinsPerSecond; // Calculated from coinsPerMinute
  static const int LOW_COINS_THRESHOLD = 100; // Warning threshold

  bool _lowCoinsWarningShown = false;
  bool _lessMinuteWarningShown = false; // Track if < 1 minute warning shown
  bool _isInitialized = false;

  // Appointment type tracking
  // "consult_now" = real-time coin deduction
  // "appointment" = coins already deducted at booking
  String _appointmentType = "";

  String? _agoraToken =
      "007eJxTYDjMqnlKUbszcfWqP+Jrapa6bo7+8DtUrtrR7o5wYM/kyxkKDIaJqUamiQapiWmp5iZJSaaWKUkpJqaGBpYWhgbmlsnGJYu4MhsCGRnSn/QwMzIwMrAAMYjPBCaZwSQLmORjKEktLokvy0xJzY83NDJmYAAA86ElWw=="; // Store fetched Agora token

  // Debug info for UI
  String _debugStatus = 'Initializing...'.tr;
  bool _videoEnabled = false;
  bool _previewStarted = false;
  bool _remoteVideoReceived = false;
  String _remoteVideoState = 'Waiting'.tr;
  String _userRole = 'publisher'; // Track user role

  // Webhook service for network state handling
  final AgoraWebhookService _webhookService = AgoraWebhookService();
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const int RECONNECTION_GRACE_PERIOD_SECONDS =
      300; // Wait 30 seconds for reconnection

  // Throttle network quality toast to avoid spam
  DateTime? _lastNetworkWarningAt;
  static const int NETWORK_WARNING_COOLDOWN_SECONDS = 30;

  @override
  void initState() {
    if (USE_TEST_MODE) {
      widget.channelName = TEST_CHANNEL_NAME;
      setState(() {});
    }
    super.initState();
    // Add lifecycle observer to handle app background/foreground
    WidgetsBinding.instance.addObserver(this);

    // Initialize coin rates from counselor
    coinsPerMinute = widget.counselorRate;
    coinsPerSecond = coinsPerMinute / 60.0;

    debugPrint('💰 Counselor Rate: $coinsPerMinute coins/minute');
    debugPrint(
      '💰 Per Second Rate: ${coinsPerSecond.toStringAsFixed(3)} coins/second',
    );

    _initializeCoinsAndCall();
  }

  /// Attempt to reconnect to Agora channel
  Future<void> _attemptReconnection() async {
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      debugPrint('❌ Max reconnection attempts reached');
      _isReconnecting = false;
      if (mounted) {
        Get.snackbar(
          'Connection Failed'.tr,
          'Unable to reconnect. Please try again.'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
        );
      }
      return;
    }

    _reconnectAttempts++;
    debugPrint(
      '🔄 Reconnection attempt $_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS',
    );

    // Wait before retrying (exponential backoff)
    final delay = Duration(seconds: _reconnectAttempts * 2);
    await Future.delayed(delay);

    try {
      // Rejoin channel
      if (_engine != null && _agoraToken != null) {
        await _engine!.joinChannel(
          token: _agoraToken!,
          channelId: widget.channelName,
          uid: widget.userId,
          options: const ChannelMediaOptions(
            autoSubscribeVideo: true,
            autoSubscribeAudio: true,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );
        debugPrint('✅ Reconnection successful');
        _isReconnecting = false;
        _reconnectAttempts = 0;

        if (mounted) {
          Get.snackbar(
            'Network Reconnected'.tr,
            'Connection restored'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 2),
            snackPosition: SnackPosition.TOP,
            icon: Icon(Icons.wifi, color: Colors.white),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Reconnection failed: $e');
      _reconnectTimer = Timer(Duration(seconds: 5), () {
        _attemptReconnection();
      });
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // Cancel grace period timer on dispose
    _reconnectionGraceTimer?.cancel();
    _dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('📱 App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground - keep call active
        debugPrint('📱 App resumed - call continues');
        // Clear call state since user is back in the call
        CallStateManager.clearCallState();
        break;
      case AppLifecycleState.paused:
        // App went to background - save call state for potential rejoin
        debugPrint('📱 App paused - saving call state');
        _saveCurrentCallState();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., during screen transition) - keep call active
        debugPrint('📱 App inactive - call continues');
        break;
      case AppLifecycleState.detached:
        // App is being killed - save call state
        debugPrint('📱 App detached - saving call state for rejoin');
        _saveCurrentCallState();
        break;
      case AppLifecycleState.hidden:
        // App is hidden - save call state
        debugPrint('📱 App hidden - saving call state');
        _saveCurrentCallState();
        break;
    }
  }

  /// Save current call state for rejoining after app is killed
  void _saveCurrentCallState() {
    if (!_isJoined || _remoteUid == null) {
      // Don't save if not in active call
      return;
    }

    CallStateManager.saveCallState(
      callType: 'video',
      channelName: widget.channelName,
      counselorName: widget.counslername,
      userId: widget.userId,
      counselorRate: widget.counselorRate,
      appointmentId: widget.appointmentId,
      counselorId: widget.counselorId,
      counselorImage: widget.counselorImage,
      isCounselor: widget.isCounsler,
      callDurationSeconds: _callDuration.inSeconds,
      coinsLeft: _coinsLeft,
      isTroat: widget.isTroat,
    );
  }

  Future<void> _dispose() async {
    try {
      _callTimer?.cancel();
      _coinDeductionTimer?.cancel();
      _coinUpdateApiTimer?.cancel(); // Cancel coin update API timer
      _reconnectTimer?.cancel();
      _reconnectionGraceTimer?.cancel(); // Cancel grace period timer
      if (_engine != null) {
        if (_isJoined) {
          await _engine!.leaveChannel();
        }
        await _engine!.release();
      }
    } catch (e) {
      debugPrint('Error during dispose: $e');
    }
  }

  // Initialize coins from UserViewModel and start call
  Future<void> _initializeCoinsAndCall() async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      // Check if current user is a counselor
      _isCounselor = widget.isCounsler;
      debugPrint('👨‍⚕️ User is counselor: $_isCounselor');
      setState(() {});

      // Fetch appointment type first
      await fetchAppointmentType();
      debugPrint('📋 Appointment type: $_appointmentType');

      // Get user coins from UserViewModel (only for regular users, not counselors)
      if (!_isCounselor && userViewModel.userModel != null) {
        final user = userViewModel.userModel;
        if (user != null && user.data.coins != null) {
          setState(() {
            _coinsLeft = user.data.coins!.toDouble();
            _initialCoins = user.data.coins!;
            _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            _isInitialized = true;
          });

          debugPrint('💰 Initial coins: $_coinsLeft');
          debugPrint('⏱️ Estimated time: $_estimatedMinutesLeft minutes');

          // Check if user has enough coins (only for regular users and consult_now type)
          if (_appointmentType == 'consult_now' &&
              _coinsLeft < coinsPerMinute) {
            _showInsufficientCoinsDialog();
            return;
          }
        } else {
          debugPrint('❌ User model is null or coins not available');
          // Set default for testing if user data not available
          setState(() {
            _coinsLeft = 1000.0;
            _initialCoins = 1000;
            _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            _isInitialized = true;
          });
        }
      } else if (_isCounselor) {
        // For counselors, skip coin deduction and join call directly
        debugPrint('👨‍⚕️ Counselor joining call - no coin deduction');
        setState(() {
          _isInitialized = true;
        });
      }

      // Initialize Agora after coins are loaded
      await _initAgora();
    } catch (e) {
      debugPrint('❌ Error initializing coins: $e');
      // Set default values and continue
      setState(() {
        _coinsLeft = 1000.0;
        _initialCoins = 1000;
        _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
        _isInitialized = true;
      });
      await _initAgora(); // Continue anyway
    }
  }

  // Fetch appointment type from API
  Future<Map<String, dynamic>?> fetchAppointmentType() async {
    if (widget.appointmentId == null) return null;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return null;

      final response = await http.get(
        Uri.parse(
          '${ApiEndPoints.BASE_URL}appointment/${widget.appointmentId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final appointmentData = data['data'];
          _appointmentType = appointmentData['type']?.toString() ?? '';
          debugPrint('📋 Fetched appointment type: $_appointmentType');
          return appointmentData;
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching appointment type: $e');
    }
  }

  // Fetch or Generate Agora token
  Future<void> _fetchAgoraToken() async {
    try {
      debugPrint('🔑 Getting Agora token...');

      // ============================================
      // 🧪 TEST MODE - Use hardcoded token
      // ============================================
      if (USE_TEST_MODE) {
        _agoraToken = TEST_AGORA_TOKEN;
        debugPrint('✅ TEST MODE: Using hardcoded Agora Console token');
        debugPrint('   Test Channel: $TEST_CHANNEL_NAME');
        debugPrint('   Token length: ${_agoraToken!.length}');
        debugPrint('   ⚠️  Both devices will use channel "$TEST_CHANNEL_NAME"');
        return; // Skip backend API call
      }
      // ============================================

      // ============================================
      // 🧪 GENERATED TOKEN MODE - Generate locally
      // ============================================
      if (USE_GENERATED_TOKEN) {
        debugPrint('🔑 GENERATED TOKEN MODE: Creating token locally...');
        debugPrint('   ⚠️  WARNING: App Certificate is in client code!');
        debugPrint('   ⚠️  Use this for TESTING ONLY, NOT for production!');

        // Get Agora credentials from settings
        final settingProvider = Provider.of<SettingProvider>(
          context,
          listen: false,
        );
        var settings = settingProvider.settings;

        if (settings == null) {
          debugPrint('❌ Settings not loaded. Fetching settings...');
          await settingProvider.fetchSettings(context);
          settings = settingProvider.settings;

          if (settings == null) {
            debugPrint('❌ Failed to load settings. Cannot generate token.');
            _agoraToken = null;
            return;
          }
        }

        final agoraAppId = settings.agoraAppId;
        final agoraAppCertificate = settings.agoraAppCertificate;

        if (agoraAppId.isEmpty || agoraAppCertificate.isEmpty) {
          debugPrint('❌ Agora credentials are missing in settings');
          debugPrint('   App ID: ${agoraAppId.isEmpty ? "MISSING" : "OK"}');
          debugPrint(
            '   App Certificate: ${agoraAppCertificate.isEmpty ? "MISSING" : "OK"}',
          );
          //show aleart dialog
          Get.dialog(
            barrierDismissible: false,
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: CustomText(
                            text: 'Agora Credentials Missing'.tr,
                            fontSize: FontConstants.font_16,
                            weight: FontWeightConstants.bold,
                            maxlines: 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    CustomText(
                      text: 'Agora credentials are missing in settings'.tr,
                      fontSize: FontConstants.font_13,
                      weight: FontWeightConstants.regular,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      maxlines: 3,
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: CustomText(
                          text: 'OK'.tr,
                          fontSize: FontConstants.font_14,
                          weight: FontWeightConstants.semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          _agoraToken = null;
          return;
        }

        debugPrint('✅ Using Agora credentials from settings');
        debugPrint(
          '   App ID: ${agoraAppId.substring(0, agoraAppId.length > 8 ? 8 : agoraAppId.length)}...',
        );

        _agoraToken = AgoraTokenGeneratorService.generateRtcToken(
          appId: agoraAppId,
          appCertificate: agoraAppCertificate,
          channelName: widget.channelName,
          uid: widget.userId,
          tokenExpireSeconds: 3600, // 1 hour
        );

        if (_agoraToken == null || _agoraToken!.isEmpty) {
          debugPrint('❌ Failed to generate token');
          _agoraToken = null;
        } else {
          debugPrint('✅ Token generated successfully (client-side)');
        }
        return; // Skip backend API call
      }
      // ============================================

      // ============================================
      // 🌐 PRODUCTION MODE - Fetch from backend API
      // ============================================
      debugPrint('🔑 PRODUCTION MODE: Fetching token from backend API...');

      // BOTH users need to be publishers for video calls
      // Publisher = can send and receive video/audio
      // Subscriber = can only receive (no sending)
      final settingProvider = Provider.of<SettingProvider>(
        context,
        listen: false,
      );
      var settings = settingProvider.settings;

      final agoraAppId = settings!.agoraAppId;
      final agoraAppCertificate = settings.agoraAppCertificate;

      // _agoraToken = AgoraTokenGeneratorService.generateRtcToken(
      //   appId: agoraAppId,
      //   appCertificate: agoraAppCertificate,
      //   channelName: widget.channelName,
      //   uid: 2,
      //   tokenExpireSeconds: 3600, // 1 hour
      // );
      // return;

      final role = 'publisher'; // Always publisher for video calls

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.GENERATE_AGORA_TOKEN),
      );

      request.fields['channel_name'] = widget.channelName;
      request.fields['uid'] = widget.userId.toString();
      request.fields['role'] = role;
      debugPrint('   Requesting token for:');
      debugPrint('   - Channel: ${widget.channelName}');
      debugPrint('   - UID: ${widget.userId}');
      debugPrint('   - Role: $role');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('   Response Status: ${response.statusCode}');
      debugPrint('   Response Body: $responseBody');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        // Try different possible response formats
        if (data is Map) {
          // Check nested data structure first (most common)
          if (data['data'] != null && data['data'] is Map) {
            final dataObj = data['data'] as Map;
            _agoraToken = dataObj['token'] ?? dataObj['agora_token'] ?? '';
          } else {
            // Check top-level
            _agoraToken = data['token'] ?? data['agora_token'] ?? '';
          }
        } else if (data is String) {
          _agoraToken = data;
        }

        debugPrint(
          '🔑 Parsed token from response: ${_agoraToken != null && _agoraToken!.isNotEmpty ? "OK (${_agoraToken!.length} chars)" : "EMPTY"}',
        );

        if (_agoraToken != null && _agoraToken!.isNotEmpty) {
          debugPrint('✅ Agora token fetched successfully');
          debugPrint(
            '   Token (first 20 chars): ${_agoraToken!.substring(0, _agoraToken!.length > 20 ? 20 : _agoraToken!.length)}...',
          );
        } else {
          debugPrint('❌ Token is empty in response');
          debugPrint('   Full response: $responseBody');
          _agoraToken = null;
        }
      } else {
        debugPrint('❌ Failed to fetch token: ${response.statusCode}');
        debugPrint('   Response: $responseBody');
        _agoraToken = null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching/generating Agora token: $e');
      _agoraToken = null;
    }
  }

  Future<void> _initAgora() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch Agora token from backend API
      await _fetchAgoraToken();

      // Request permissions first
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Permission Required'.tr,
          'Camera and microphone permissions are required for video calls'.tr,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(20),
          borderRadius: 10,
          isDismissible: true,
          dismissDirection: DismissDirection.horizontal,
          forwardAnimationCurve: Curves.easeOutBack,
          reverseAnimationCurve: Curves.easeInBack,
          animationDuration: Duration(milliseconds: 500),
          icon: Icon(Icons.security, color: Colors.white),
          shouldIconPulse: true,
          maxWidth: Get.width * 0.9,
          snackStyle: SnackStyle.FLOATING,
        );
        return;
      }

      // Get Agora App ID from settings
      final settingProvider = Provider.of<SettingProvider>(
        context,
        listen: false,
      );
      var settings = settingProvider.settings;

      if (settings == null) {
        debugPrint('❌ Settings not loaded. Fetching settings...');
        await settingProvider.fetchSettings(context);
        settings = settingProvider.settings;
      }

      final agoraAppId = settings?.agoraAppId ?? AgoraConfig.appId;

      if (agoraAppId.isEmpty) {
        debugPrint('❌ Agora App ID is missing');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Get.snackbar(
            'Initialization Error'.tr,
            'Invalid App ID. Please check your Agora configuration.'.tr,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        return;
      }

      debugPrint(
        '✅ Using Agora App ID from settings: ${agoraAppId.substring(0, agoraAppId.length > 8 ? 8 : agoraAppId.length)}...',
      );

      // Create RTC engine instance
      _engine = createAgoraRtcEngine();

      // Initialize with proper error handling
      await _engine!.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Register event handlers BEFORE enabling video
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('onJoinChannelSuccess ${connection.channelId}');
            if (mounted) {
              setState(() {
                _isJoined = true;
                _isLoading = false;
                _debugStatus = '✅ Joined Channel';
              });

              // Send webhook event
              _webhookService.onCallStarted(
                channelName: widget.channelName,
                userId: widget.userId,
                appointmentId: widget.appointmentId,
              );
            }
          },
          onUserJoined: (
            RtcConnection connection,
            int remoteUid,
            int elapsed,
          ) async {
            debugPrint('onUserJoined $remoteUid');
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
                _debugStatus = '👤 User $remoteUid Joined';
                _isWaitingForReconnection = false; // Hide waiting UI
              });

              // Cancel grace period timer if user reconnected
              _cancelReconnectionGraceTimer();

              // Explicitly subscribe to remote video and audio
              _engine?.muteRemoteVideoStream(uid: remoteUid, mute: false);
              _engine?.muteRemoteAudioStream(uid: remoteUid, mute: false);
              debugPrint(
                '✅ Subscribed to remote video and audio for UID: $remoteUid',
              );

              // Send webhook event
              _webhookService.onUserJoined(
                channelName: widget.channelName,
                userId: widget.userId,
                remoteUid: remoteUid,
              );

              // 🔄 SYNC CALL TIME: Fetch real call duration from backend
              // This ensures both users have the same call time after reconnection
              await _syncCallDurationFromBackend();

              // Start/Resume call timer when remote user joins
              _startCallTimer();

              // Handle differently based on role and appointment type
              if (_isCounselor) {
                // COUNSELOR: Send start_time API only for consult_now type
                if (_appointmentType == 'consult_now') {
                  debugPrint(
                    '👨‍⚕️ Counselor: consult_now - sending start_time API',
                  );
                  _sendStartTimeApi();
                } else {
                  debugPrint(
                    '👨‍⚕️ Counselor: appointment type - no start_time API',
                  );
                }
              } else {
                // USER: Only start coin deduction for consult_now type
                if (_appointmentType == 'consult_now') {
                  debugPrint(
                    '💰 USER: consult_now - starting real-time coin deduction',
                  );
                  _startCoinDeduction();
                  _startCoinUpdateApiTimer();
                } else {
                  debugPrint(
                    '📅 USER: appointment type - coins already paid, no deduction',
                  );
                }
              }
            }
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) async {
            debugPrint(
              'onUserOffline $remoteUid - reason: ${reason.toString()}',
            );
            if (mounted) {
              setState(() {
                _remoteUid = null;
              });

              // Send webhook event
              _webhookService.onUserOffline(
                channelName: widget.channelName,
                userId: widget.userId,
                remoteUid: remoteUid,
                reason: reason.toString(),
              );

              // COUNSELOR: Send end_time API only for consult_now type
              if (!_isCounselor && _appointmentType != 'consult_now') {
                debugPrint(
                  '👨‍⚕️ Counselor: consult_now - sending end_time API',
                );
              }

              // ⚠️ CRITICAL: Check if other user explicitly ended the call
              final bool callWasEndedByOtherUser =
                  await _checkIfCallEndedByOtherUser();

              if (callWasEndedByOtherUser) {
                // Other user explicitly ended call - end immediately (no grace period)
                debugPrint('🛑 Call ended by other user - ending immediately');
                _stopCallTimer();
                _stopCoinDeduction();
                _stopCoinUpdateApiTimer();
                _handleSessionEnded();
                return;
              }

              // User just disconnected (app killed) - start grace period
              debugPrint(
                '⏳ Remote user disconnected - starting grace period for reconnection',
              );

              // Show waiting UI
              setState(() {
                _isWaitingForReconnection = true;
              });

              // Pause timers during grace period
              _callTimer?.cancel();
              _coinDeductionTimer?.cancel();
              _coinUpdateApiTimer?.cancel();

              // Start grace period timer
              _startReconnectionGraceTimer();
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('onError $err $msg');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // Send webhook event
              _webhookService.onError(
                channelName: widget.channelName,
                userId: widget.userId,
                errorMessage: msg,
                errorCode: err.toString(),
              );

              Get.snackbar(
                'Connection Error'.tr,
                'Failed to connect: ${_getErrorMessage(err)}'.tr,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: Duration(seconds: 5),
                snackPosition: SnackPosition.TOP,
                margin: EdgeInsets.all(20),
                borderRadius: 10,
                isDismissible: true,
                dismissDirection: DismissDirection.horizontal,
                forwardAnimationCurve: Curves.easeOutBack,
                reverseAnimationCurve: Curves.easeInBack,
                animationDuration: Duration(milliseconds: 500),
                icon: Icon(Icons.error, color: Colors.white),
                shouldIconPulse: true,
                maxWidth: Get.width * 0.9,
                snackStyle: SnackStyle.FLOATING,
              );
            }
          },
          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            debugPrint('Connection state changed: $state, reason: $reason');

            // Send webhook event
            _webhookService.onConnectionStateChanged(
              channelName: widget.channelName,
              userId: widget.userId,
              state: state.toString(),
              reason: reason.toString(),
            );

            // Handle connection state changes
            if (state == ConnectionStateType.connectionStateFailed && mounted) {
              setState(() {
                _isLoading = false;
              });

              // Attempt reconnection
              if (!_isReconnecting && _isJoined) {
                _isReconnecting = true;
                _attemptReconnection();

                if (mounted) {
                  // Get.snackbar(
                  //   'Connection Failed'.tr,
                  //   'Attempting to reconnect...'.tr,
                  //   backgroundColor: Colors.orange,
                  //   colorText: Colors.white,
                  //   duration: Duration(seconds: 3),
                  //   snackPosition: SnackPosition.TOP,
                  //   icon: Icon(Icons.wifi_off, color: Colors.white),
                  // );
                }
              } else {
                if (mounted) {
                  Get.snackbar(
                    'Connection Failed'.tr,
                    'Unable to connect to the call.'.tr,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: Duration(seconds: 5),
                    snackPosition: SnackPosition.TOP,
                    margin: EdgeInsets.all(20),
                    borderRadius: 10,
                    isDismissible: true,
                    dismissDirection: DismissDirection.horizontal,
                    forwardAnimationCurve: Curves.easeOutBack,
                    reverseAnimationCurve: Curves.easeInBack,
                    animationDuration: Duration(milliseconds: 500),
                    icon: Icon(Icons.wifi_off, color: Colors.white),
                    shouldIconPulse: true,
                    maxWidth: Get.width * 0.9,
                    snackStyle: SnackStyle.FLOATING,
                  );
                }
              }
            } else if (state == ConnectionStateType.connectionStateConnected &&
                mounted) {
              // Connection restored
              if (_isReconnecting) {
                _isReconnecting = false;
                _reconnectAttempts = 0;
                _reconnectTimer?.cancel();
              }
            }
          },
          onNetworkQuality: (
            RtcConnection connection,
            int remoteUid,
            QualityType txQuality,
            QualityType rxQuality,
          ) {
            // Calculate network quality metrics for webhook
            // QualityType values: 0=unknown, 1=excellent, 2=good, 3=poor, 4=bad, 5=very bad, 6=down
            final txQualityInt = txQuality.index;
            final rxQualityInt = rxQuality.index;
            final rtt = _estimateRttFromQuality(txQualityInt, rxQualityInt);
            final packetLoss = _estimatePacketLossFromQuality(
              txQualityInt,
              rxQualityInt,
            );

            // Send webhook event for poor quality
            if ((txQualityInt >= 4 || rxQualityInt >= 4) &&
                _canShowNetworkWarning()) {
              _webhookService.onNetworkQuality(
                channelName: widget.channelName,
                userId: widget.userId,
                rtt: rtt,
                packetLoss: packetLoss,
                quality: _getQualityString(txQualityInt, rxQualityInt),
              );

              // Show user notification for poor network quality
              if (mounted) {
                // Get.snackbar(
                //   'Poor Network Quality'.tr,
                //   'Network connection is unstable'.tr,
                //   backgroundColor: Colors.orange,
                //   colorText: Colors.white,
                //   duration: Duration(seconds: 3),
                //   snackPosition: SnackPosition.TOP,
                //   icon: Icon(
                //     Icons.signal_wifi_statusbar_connected_no_internet_4,
                //     color: Colors.white,
                //   ),
                // );
              }
            }
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('⚠️ Token will expire soon');
            _webhookService.onTokenWillExpire(
              channelName: widget.channelName,
              userId: widget.userId,
            );
            // Optionally refresh token here
          },
          onFirstRemoteVideoFrame: (
            RtcConnection connection,
            int remoteUid,
            int width,
            int height,
            int elapsed,
          ) {
            debugPrint('🎥 First remote video frame received!');
            debugPrint('   Remote UID: $remoteUid');
            debugPrint('   Video size: ${width}x${height}');
            if (mounted) {
              setState(() {
                _remoteVideoReceived = true;
                _remoteUid = remoteUid; // Ensure remoteUid is set
                _debugStatus = '🎥 Video Received ${width}x${height}';
              });
            }
          },
          onRemoteVideoStateChanged: (
            RtcConnection connection,
            int remoteUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed,
          ) {
            debugPrint('📹 Remote video state: $state (reason: $reason)');
            if (mounted) {
              setState(() {
                if (state == RemoteVideoState.remoteVideoStateDecoding) {
                  _remoteVideoState = '✅ Decoding';
                  _debugStatus = '✅ Video Decoding';
                  _remoteVideoReceived = true;
                  // Ensure remote UID is set
                  if (_remoteUid == null) {
                    _remoteUid = remoteUid;
                  }
                } else if (state == RemoteVideoState.remoteVideoStateStopped) {
                  _remoteVideoState = '⏸️ Stopped';
                  _debugStatus = '⏸️ Video Stopped';
                } else if (state == RemoteVideoState.remoteVideoStateStarting) {
                  _remoteVideoState = '🔄 Starting';
                  _debugStatus = '🔄 Video Starting';
                  // Ensure remote UID is set
                  if (_remoteUid == null) {
                    _remoteUid = remoteUid;
                  }
                } else {
                  _remoteVideoState = state.toString();
                }
              });
            }
          },
        ),
      );

      // Enable audio first (required for voice)
      await _engine!.enableAudio();
      debugPrint('✅ Audio enabled');

      // Enable video with error handling
      await _engine!.enableVideo();
      debugPrint('✅ Video enabled');

      // Set video encoder configuration for better performance
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      debugPrint('✅ Video encoder configured');

      setState(() {
        _videoEnabled = true;
      });

      // Start preview BEFORE joining channel
      await _engine!.startPreview();
      debugPrint('✅ Preview started');

      setState(() {
        _previewStarted = true;
        _debugStatus = '📹 Preview Started';
      });

      // Join channel with retry logic
      await _joinChannelWithRetry();
    } catch (e) {
      debugPrint('Agora initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Initialization Error'.tr,
          'Failed to initialize video call: ${e.toString()}'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(20),
          borderRadius: 10,
          isDismissible: true,
          dismissDirection: DismissDirection.horizontal,
          forwardAnimationCurve: Curves.easeOutBack,
          reverseAnimationCurve: Curves.easeInBack,
          animationDuration: Duration(milliseconds: 500),
          icon: Icon(Icons.error_outline, color: Colors.white),
          shouldIconPulse: true,
          maxWidth: Get.width * 0.9,
          snackStyle: SnackStyle.FLOATING,
        );
      }
    }
  }

  Future<void> _joinChannelWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

    // Determine which channel to use based on test mode
    final channelToUse = USE_TEST_MODE ? TEST_CHANNEL_NAME : widget.channelName;

    // Log token status before joining
    if (_agoraToken == null || _agoraToken!.isEmpty) {
      debugPrint(
        '⚠️ WARNING: No token available from API, attempting to join without token',
      );
    } else {
      debugPrint('🔑 Joining channel with token');
      debugPrint('   Mode: ${USE_TEST_MODE ? "TEST" : "PRODUCTION"}');
      debugPrint('   Channel: $channelToUse');
      debugPrint('   Token length: ${_agoraToken!.length}');
    }

    while (retryCount < maxRetries) {
      try {
        await _engine!.joinChannel(
          token: _agoraToken ?? '', // Use fetched token from API
          channelId: channelToUse, // ⭐ Use test channel in test mode
          uid: widget.userId,
          options: const ChannelMediaOptions(
            autoSubscribeVideo:
                true, // Automatically subscribe to all video streams
            autoSubscribeAudio:
                true, // Automatically subscribe to all audio streams
            publishCameraTrack: true, // Publish camera-captured video
            publishMicrophoneTrack: true, // Publish microphone-captured audio
            // Use clientRoleBroadcaster to act as a host or clientRoleAudience for audience
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );
        debugPrint('✅ Successfully joined channel');
        break; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        debugPrint('Join channel attempt $retryCount failed: $e');

        if (retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Get.snackbar(
              'Connection Failed'.tr,
              'Unable to join the call after multiple attempts. Please try again.'
                  .tr,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
              snackPosition: SnackPosition.TOP,
              margin: EdgeInsets.all(20),
              borderRadius: 10,
              isDismissible: true,
              dismissDirection: DismissDirection.horizontal,
              forwardAnimationCurve: Curves.easeOutBack,
              reverseAnimationCurve: Curves.easeInBack,
              animationDuration: Duration(milliseconds: 500),
              icon: Icon(Icons.refresh, color: Colors.white),
              shouldIconPulse: true,
              maxWidth: Get.width * 0.9,
              snackStyle: SnackStyle.FLOATING,
            );
          }
        } else {
          // Wait before retry
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
  }

  String _getErrorMessage(ErrorCodeType errorCode) {
    switch (errorCode) {
      case ErrorCodeType.errInvalidAppId:
        return 'Invalid App ID. Please check your Agora configuration.'.tr;
      case ErrorCodeType.errInvalidChannelName:
        return 'Invalid channel name. Please try again.'.tr;
      case ErrorCodeType.errInvalidUserId:
        return 'Invalid user ID. Please try again.'.tr;
      case ErrorCodeType.errTokenExpired:
        return 'Token expired. Please refresh and try again.'.tr;
      case ErrorCodeType.errInvalidToken:
        return 'Invalid token. For testing, ensure tokenless access is enabled in your Agora project.'
            .tr;
      case ErrorCodeType.errConnectionInterrupted:
        return 'Connection interrupted.'.tr;
      case ErrorCodeType.errConnectionLost:
        return 'Connection lost. Please try again.'.tr;
      case ErrorCodeType.errNotInitialized:
        return 'Engine not initialized. Please restart the app.'.tr;
      case ErrorCodeType.errNotReady:
        return 'Engine not ready. Please wait and try again.'.tr;
      case ErrorCodeType.errAlreadyInUse:
        return 'Resource already in use. Please try again later.'.tr;
      case ErrorCodeType.errAborted:
        return 'Operation aborted. Please try again.'.tr;
      case ErrorCodeType.errResourceLimited:
        return 'Resource limited. Please try again later.'.tr;
      case ErrorCodeType.errInvalidArgument:
        return 'Invalid argument. Please check your configuration.'.tr;
      case ErrorCodeType.errNotSupported:
        return 'Operation not supported. Please check your setup.'.tr;
      case ErrorCodeType.errRefused:
        return 'Connection refused. Please try again.'.tr;
      case ErrorCodeType.errBufferTooSmall:
        return 'Buffer too small. Please try again.'.tr;
      case ErrorCodeType.errNotInChannel:
        return 'Not in channel. Please join the channel first.'.tr;
      case ErrorCodeType.errInvalidState:
        return 'Invalid state. Please restart the app.'.tr;
      default:
        return 'Connection error occurred. Please try again.'.tr;
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [Permission.microphone, Permission.camera].request();

    return statuses[Permission.microphone]?.isGranted == true &&
        statuses[Permission.camera]?.isGranted == true;
  }

  void _startCallTimer() {
    // Only start call timer if not already running
    if (_callTimer == null || !_callTimer!.isActive) {
      debugPrint('⏱️ Starting call timer - Remote user joined');

      // Note: _sendStartTimeApi is called in onUserJoined event handler
      // based on appointment type and user role

      _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _callDuration = Duration(seconds: _callDuration.inSeconds + 1);
          });
        }
      });
    }
  }

  void _stopCallTimer() {
    debugPrint('⏱️ Stopping call timer');

    // Send webhook event for call ended
    _webhookService.onCallEnded(
      channelName: widget.channelName,
      userId: widget.userId,
      callDuration: _callDuration,
      appointmentId: widget.appointmentId,
    );

    // Note: _sendEndTimeApi is called in onUserOffline event handler
    // based on appointment type and user role

    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startCoinDeduction() {
    // Skip coin deduction entirely for counselors
    if (_isCounselor) {
      debugPrint('💰 Skipping coin deduction - User is counselor');
      return;
    }

    // Only start coin deduction if not already running and remote user is connected
    if (_coinDeductionTimer == null || !_coinDeductionTimer!.isActive) {
      debugPrint('💰 Starting coin deduction - Remote user joined');

      _coinDeductionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted && _isInitialized && _remoteUid != null) {
          setState(() {
            // Deduct coins per second using counselor's rate
            _coinsLeft -= coinsPerSecond;

            // Ensure coins don't go below 0
            if (_coinsLeft < 0) {
              _coinsLeft = 0;
            }

            // Recalculate estimated time
            if (_coinsLeft > 0) {
              _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            } else {
              _estimatedMinutesLeft = 0;
            }

            debugPrint(
              '💰 Coins: ${_coinsLeft.toStringAsFixed(2)} | ⏱️ Time left: $_estimatedMinutesLeft min',
            );
          });

          // Check for low coins warning
          if (_coinsLeft <= LOW_COINS_THRESHOLD && !_lowCoinsWarningShown) {
            _lowCoinsWarningShown = true;
            _showLowCoinsWarning();
          }

          // ⚠️ CRITICAL: Drop call if estimated time < 1 minute
          if (_estimatedMinutesLeft < 1 &&
              _coinsLeft > 0 &&
              !_lessMinuteWarningShown) {
            _lessMinuteWarningShown = true;
            debugPrint(
              '⚠️ Less than 1 minute remaining - showing final warning',
            );
            _showLessMinuteWarning();
          }

          // Check if out of coins - immediately end call
          if (_coinsLeft <= 0) {
            debugPrint('❌ Coins depleted - ending call immediately');
            timer.cancel();
            // End call immediately without showing out of coins dialog
            _endCall(showRating: true);
          }
        }
      });
    }
  }

  void _stopCoinDeduction() {
    debugPrint('💰 Stopping coin deduction - Remote user left');
    _coinDeductionTimer?.cancel();
    _coinDeductionTimer = null;
  }

  // Start timer to call coin update API every 1 minute
  void _startCoinUpdateApiTimer() {
    // Only start for regular users (not counselors) and if appointment_id is available
    if (_isCounselor || widget.appointmentId == null) {
      debugPrint(
        'Coin update API timer not started: ${_isCounselor ? "user is counselor" : "no appointment ID"}',
      );
      return;
    }

    debugPrint('🔄 Starting coin update API timer - every 1 minute');

    _coinUpdateApiTimer = Timer.periodic(Duration(seconds: 60), (timer) async {
      if (mounted && _isJoined && _remoteUid != null) {
        // await _callCoinUpdateApi();
      }
    });
  }

  // Stop coin update API timer
  void _stopCoinUpdateApiTimer() {
    debugPrint('🔄 Stopping coin update API timer');
    _coinUpdateApiTimer?.cancel();
    _coinUpdateApiTimer = null;
  }

  // Call coin update API in background
  Future<void> _callCoinUpdateApi() async {
    if (widget.appointmentId == null) {
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Coin update API: No token available');
        return;
      }

      debugPrint(
        '🔄 Calling coin update API for appointment: ${widget.appointmentId}',
      );

      final response = await http.post(
        Uri.parse(ApiEndPoints.COIN_UPDATE),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'appointment_id': widget.appointmentId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Coin update API success: ${data.toString()}');

        // Refresh user data to get updated coin balance
        debugPrint('🔄 Refreshing user data to update coin balance...');
        await Provider.of<UserViewModel>(
          context,
          listen: false,
        ).fetchUserData();
        debugPrint('✅ User data refreshed successfully');

        // Update local coins display if needed
        if (mounted && userViewModel.userModel != null) {
          final updatedCoins =
              userViewModel.userModel!.data.coins?.toDouble() ?? _coinsLeft;
          if (updatedCoins != _coinsLeft) {
            setState(() {
              _coinsLeft = updatedCoins;
              _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            });
            debugPrint('💰 Coins updated in UI: $_coinsLeft');
          }
        }
      } else {
        debugPrint(
          '❌ Coin update API failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error calling coin update API: $e');
    }
  }

  // Send start_time to API when call timer starts
  // Only called by counselor for consult_now type
  Future<void> _sendStartTimeApi() async {
    if (!_isCounselor) {
      debugPrint('⏱️ Not a counselor - skipping start_time API');
      return;
    }
    if (_appointmentType != 'consult_now') {
      debugPrint('⏱️ Not consult_now type - skipping start_time API');
      return;
    }
    if (widget.appointmentId == null) {
      debugPrint('⏱️ No appointment ID - skipping start_time API');
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Start time API: No token available');
        return;
      }

      final now = DateTime.now();
      final startTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      debugPrint('═══════════════════════════════════════');
      debugPrint('🕐 Sending start_time API');
      debugPrint('   Appointment ID: ${widget.appointmentId}');
      debugPrint('   Start time: $startTime');
      debugPrint('   Coins: 0 (no deduction at start)');
      debugPrint('═══════════════════════════════════════');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.UPDATE_TIME),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();
      request.fields['start_time'] = startTime;
      request.fields['coins'] = '0'; // No coins deducted at start

      // Debug: Print all request fields
      debugPrint('📤 Request fields:');
      request.fields.forEach((key, value) {
        debugPrint('   $key: "$value"');
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('✅ Start time API success: $responseBody');
      } else {
        debugPrint(
          '❌ Start time API failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending start_time API: $e');
    }
  }

  // ==================== SYNC CALL TIME ====================

  /// Sync call duration from backend when user rejoins
  /// Ensures both users have the same call time (real-time sync)
  Future<void> _syncCallDurationFromBackend() async {
    if (widget.appointmentId == null) {
      debugPrint('⚠️ No appointment ID - cannot sync call duration');
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No token - cannot sync call duration');
        return;
      }

      debugPrint('🔄 Syncing call duration from backend...');

      final response = await http
          .get(
            Uri.parse(
              '${ApiEndPoints.BASE_URL}appointment/${widget.appointmentId}',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Sync timeout');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Handle both array and single object
          dynamic appointmentData;
          if (data['data'] is List) {
            final appointments = data['data'] as List;
            appointmentData = appointments.firstWhere(
              (apt) => apt['id'] == widget.appointmentId,
              orElse: () => null,
            );
          } else {
            appointmentData = data['data'];
          }

          if (appointmentData == null) return;

          final startTime = appointmentData['start_time'];

          if (startTime != null && startTime.toString().isNotEmpty) {
            // Calculate elapsed time from start_time
            try {
              // Parse start_time (format: "HH:mm:ss")
              final parts = startTime.toString().split(':');
              if (parts.length >= 2) {
                final now = DateTime.now();
                final startDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  int.parse(parts[0]), // hours
                  int.parse(parts[1]), // minutes
                  parts.length > 2 ? int.parse(parts[2]) : 0, // seconds
                );

                final elapsedSeconds =
                    now.difference(startDateTime).inSeconds.abs();

                if (mounted) {
                  setState(() {
                    _callDuration = Duration(seconds: elapsedSeconds);
                  });
                }

                debugPrint('✅ Call duration synced: ${elapsedSeconds}s');
                debugPrint('   Start time from API: $startTime');
                debugPrint(
                  '   Current time: ${now.hour}:${now.minute}:${now.second}',
                );
                debugPrint(
                  '   Synced duration: ${_formatDuration(_callDuration)}',
                );
              }
            } catch (e) {
              debugPrint('❌ Error parsing start_time: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing call duration: $e');
    }
  }

  // ==================== CHECK CALL STATUS ====================

  /// Check if the other user has explicitly ended the call
  /// Returns true if appointment status is "completed", false otherwise
  Future<bool> _checkIfCallEndedByOtherUser() async {
    // Skip check if no appointment ID
    if (widget.appointmentId == null) {
      debugPrint('⚠️ No appointment ID - cannot check call status');
      return false;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No token available - cannot check call status');
        return false;
      }

      debugPrint('🔍 Checking if call was ended by other user...');

      final response = await http
          .get(
            Uri.parse(
              '${ApiEndPoints.BASE_URL}appointment/${widget.appointmentId}',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              debugPrint('⏱️ Call status check timeout');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Handle both array and single object responses
          dynamic appointmentData;

          if (data['data'] is List) {
            // API returns array - find appointment by ID
            debugPrint('📋 API returned array of appointments');
            final appointments = data['data'] as List;
            final targetAppointment = appointments.firstWhere(
              (apt) => apt['id'] == widget.appointmentId,
              orElse: () => null,
            );

            if (targetAppointment == null) {
              debugPrint(
                '⚠️ Appointment ID ${widget.appointmentId} not found in array',
              );
              return false;
            }
            appointmentData = targetAppointment;
          } else {
            // API returns single object
            debugPrint('📄 API returned single appointment object');
            appointmentData = data['data'];
          }

          final status = appointmentData['status']?.toString().toLowerCase();
          final endTime = appointmentData['end_time'];
          final counselorStatus =
              appointmentData['counselor_status']?.toString().toLowerCase();

          debugPrint('📊 Appointment check:');
          debugPrint('   Appointment ID: ${appointmentData['id']}');
          debugPrint('   Status: "$status"');
          debugPrint('   End time: "$endTime"');
          debugPrint('   Counselor status: "$counselorStatus"');

          // Check multiple indicators that the call has ended:
          // 1. Status is completed/ended/finished
          // 2. End time is populated (not null or empty)
          // 3. Counselor status indicates call is done
          final bool statusEnded =
              status == 'completed' ||
              status == 'ended' ||
              status == 'finished' ||
              status == 'done' ||
              status == 'complete';

          final bool hasEndTime =
              endTime != null &&
              endTime.toString().isNotEmpty &&
              endTime.toString() != 'null';

          debugPrint('   Status ended: $statusEnded');
          debugPrint('   Has end time: $hasEndTime');

          // For consult_now appointments, if end_time exists, call has ended
          if (_appointmentType == 'consult_now' && hasEndTime) {
            debugPrint('✅ Call ended (consult_now with end_time: $endTime)');
            return true;
          }

          // For regular appointments, check status
          if (statusEnded) {
            debugPrint('✅ Call was ended by other user (status: $status)');
            return true;
          }

          debugPrint('🔄 Call still active - user just disconnected');
          return false;
        }
      } else {
        debugPrint('❌ Failed to check call status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error checking call status: $e');
    }

    // Default: assume user just disconnected (not ended)
    return false;
  }

  // ==================== END TIME API ====================

  // Send end_time to API when call timer stops
  // Only called by counselor for consult_now type
  Future<void> _sendEndTimeApi() async {
    if (_appointmentType != 'consult_now') {
      debugPrint('⏱️ Not consult_now type - skipping end_time API');
      return;
    }
    if (widget.appointmentId == null) {
      debugPrint('⏱️ No appointment ID - skipping end_time API');
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ End time API: No token available');
        return;
      }

      final now = DateTime.now();

      // Format end_time with proper padding (HH:mm format)
      final endTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Validate endTime is not empty
      if (endTime.isEmpty || endTime.length < 5) {
        debugPrint('❌ Invalid end_time format: "$endTime"');
        return;
      }

      // Calculate total coins deducted from the call
      // Method 1: Based on actual coins used
      final coinsDeducted = (_initialCoins - _coinsLeft).toStringAsFixed(2);

      // Method 2: Based on call duration (more accurate)
      final durationInMinutes = _callDuration.inSeconds / 60.0;
      final coinsBasedOnDuration =
          (durationInMinutes * coinsPerMinute).toInt().toString();

      debugPrint('═══════════════════════════════════════');
      debugPrint('🕐 Sending end_time API');
      debugPrint('   Appointment ID: ${widget.appointmentId}');
      debugPrint('   End time: "$endTime" (length: ${endTime.length})');
      debugPrint('   Call duration: ${_formatDuration(_callDuration)}');
      debugPrint('   Coins deducted (from balance): $coinsDeducted');
      debugPrint('   Coins deducted (from duration): $coinsBasedOnDuration');
      debugPrint('═══════════════════════════════════════');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.UPDATE_TIME),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();
      request.fields['end_time'] = endTime;
      // Send coins deducted based on call duration (endTime - startTime) * counselorRate
      request.fields['coins'] = coinsBasedOnDuration;

      // Debug: Print all request fields
      debugPrint('📤 Request fields:');
      request.fields.forEach((key, value) {
        print('*****************************   $key: "$value"');
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('✅ End time API success: $responseBody');
      } else {
        debugPrint(
          '❌ End time API failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending end_time API: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Estimate RTT from Agora quality metrics
  /// Quality: 0=unknown, 1=excellent, 2=good, 3=poor, 4=bad, 5=very bad, 6=down
  int _estimateRttFromQuality(int txQuality, int rxQuality) {
    final avgQuality = (txQuality + rxQuality) / 2;
    if (avgQuality <= 1) return 50; // Excellent
    if (avgQuality <= 2) return 100; // Good
    if (avgQuality <= 3) return 200; // Poor
    if (avgQuality <= 4) return 400; // Bad
    if (avgQuality <= 5) return 600; // Very bad
    return 1000; // Down
  }

  /// Estimate packet loss from Agora quality metrics
  int _estimatePacketLossFromQuality(int txQuality, int rxQuality) {
    final avgQuality = (txQuality + rxQuality) / 2;
    if (avgQuality <= 1) return 0; // Excellent
    if (avgQuality <= 2) return 1; // Good
    if (avgQuality <= 3) return 2; // Poor
    if (avgQuality <= 4) return 5; // Bad
    if (avgQuality <= 5) return 10; // Very bad
    return 20; // Down
  }

  /// Get quality string description
  String _getQualityString(int txQuality, int rxQuality) {
    final avgQuality = (txQuality + rxQuality) / 2;
    if (avgQuality <= 1) return 'excellent';
    if (avgQuality <= 2) return 'good';
    if (avgQuality <= 3) return 'poor';
    if (avgQuality <= 4) return 'bad';
    if (avgQuality <= 5) return 'very_bad';
    return 'down';
  }

  bool _canShowNetworkWarning() {
    final now = DateTime.now();
    if (_lastNetworkWarningAt == null ||
        now.difference(_lastNetworkWarningAt!).inSeconds >
            NETWORK_WARNING_COOLDOWN_SECONDS) {
      _lastNetworkWarningAt = now;
      return true;
    }
    return false;
  }

  Future<void> _toggleMute() async {
    await _engine?.muteLocalAudioStream(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _switchCamera() async {
    try {
      await _engine?.switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
      debugPrint('📷 Camera switched to ${_isFrontCamera ? "front" : "back"}');

      Get.snackbar(
        'Camera Switched'.tr,
        'Now using ${_isFrontCamera ? "front" : "back"} camera'.tr,
        backgroundColor: primaryColor.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(20),
        borderRadius: 10,
        icon: Icon(
          _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
          color: Colors.white,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error switching camera: $e');
    }
  }

  Future<void> _endCall({bool showRating = true}) async {
    debugPrint(
      '🔴 _endCall called - showRating: $showRating, isCounselor: $_isCounselor',
    );

    // Cancel grace period timer if active
    _reconnectionGraceTimer?.cancel();

    // Clear waiting state immediately
    if (_isWaitingForReconnection) {
      if (mounted) {
        setState(() {
          _isWaitingForReconnection = false;
        });
      }
    }

    // Clear saved call state since call is ending normally
    await CallStateManager.clearCallState();

    // For users (not counselors), complete the appointment and show rating
    if (!_isCounselor) {
      _sendEndTimeApi();

      await _completeAppointmentApi();

      // Show rating dialog for users
      if (showRating &&
          widget.appointmentId != null &&
          widget.counselorId != null) {
        debugPrint('📊 Showing rating dialog for user');

        // Dispose resources first
        await _dispose();

        // Navigate back immediately
        if (mounted) {
          debugPrint('⬅️ Navigating back to previous screen');
          Navigator.of(context).pop();
        }

        // Wait for navigation animation to complete
        await Future.delayed(Duration(milliseconds: 300));

        // Show rating dialog on the previous screen
        await Get.dialog(
          CallRatingDialog(
            appointmentId: widget.appointmentId!,
            counselorId: widget.counselorId!,
            counselorName: widget.counslername,
            counselorImage: widget.counselorImage,
            callDuration: _callDuration,
          ),
          barrierDismissible: false,
        );

        debugPrint('✅ Rating dialog completed');
        return;
      }
    }

    debugPrint('⬅️ Ending call and going back');
    await _dispose();
    if (mounted) {
      Get.back();
    }
  }

  // Complete appointment API - called when user ends call
  Future<void> _completeAppointmentApi() async {
    if (widget.appointmentId == null || widget.counselorId == null) {
      debugPrint(
        '⚠️ Missing appointment_id or counselor_id for complete-appointment API',
      );
      return;
    }
    final appointmentData = await fetchAppointmentType();
    if (appointmentData == null) {
      return;
    }
    if (appointmentData['counselor_status']?.toString()?.toLowerCase() ==
        'pending') {
      Navigator.of(context).pop();
      debugPrint('❌ Counselor is pending');
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ Complete appointment API: No token available');
        return;
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('📤 USER: Calling complete-appointment API...');
      debugPrint('   Appointment ID: ${widget.appointmentId}');
      debugPrint('   Counselor ID: ${widget.counselorId}');
      debugPrint('═══════════════════════════════════════');

      final response = await http.post(
        Uri.parse('${ApiEndPoints.BASE_URL}complete-appointment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'appointment_id': widget.appointmentId,
          'counselor_id': widget.counselorId,
        }),
      );

      debugPrint('📤 Complete appointment response: ${response.statusCode}');
      debugPrint('📤 Complete appointment body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Complete appointment API success: ${data.toString()}');
      } else {
        debugPrint(
          '❌ Complete appointment API failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error calling complete-appointment API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views
            _buildVideoViews(),

            // Top info bar
            _buildTopBar(),

            // Debug overlay (top-right corner)
            // _buildDebugOverlay(),

            // Bottom controls
            Positioned(
              bottom: 80,
              child: Container(
                width: Get.width,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [
                    buildCoinsWidget(),
                    Spacer(),
                    widget.isTroat
                        ? buildSettingsButton(context, _isCounselor)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            _buildBottomControls(),

            // Loading overlay
            if (_isLoading || _isWaitingForReconnection) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  // Debug overlay showing video status
  Widget _buildDebugOverlay() {
    return Positioned(
      top: 80.h,
      left: 10.w,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                USE_TEST_MODE ? Colors.orange : Colors.white.withOpacity(0.3),
            width: USE_TEST_MODE ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: USE_TEST_MODE ? "🧪 TEST MODE" : "🔍 Video Debug",
              fontSize: FontConstants.font_12,
              weight: FontWeightConstants.bold,
              color: USE_TEST_MODE ? Colors.orange : Colors.white,
            ),
            SizedBox(height: 8.h),
            _buildDebugRow('Status', _debugStatus),
            _buildDebugRow('Joined', _isJoined ? '✅' : '❌'),
            _buildDebugRow('Video On', _videoEnabled ? '✅' : '❌'),
            _buildDebugRow('Preview', _previewStarted ? '✅' : '❌'),
            _buildDebugRow('Remote UID', _remoteUid?.toString() ?? '⏳'),
            _buildDebugRow('Remote Video', _remoteVideoState),
            _buildDebugRow('Frame Received', _remoteVideoReceived ? '✅' : '❌'),
            _buildDebugRow('Role', _userRole),
            SizedBox(height: 8.h),
            // Channel info
            CustomText(
              text:
                  "Ch: ${USE_TEST_MODE ? TEST_CHANNEL_NAME : widget.channelName}",
              fontSize: FontConstants.font_10,
              color: USE_TEST_MODE ? Colors.orange : Colors.white70,
            ),
            CustomText(
              text: "UID: ${widget.userId}",
              fontSize: FontConstants.font_10,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          CustomText(
            text: "$label: ",
            fontSize: FontConstants.font_10,
            color: Colors.white70,
          ),
          CustomText(
            text: value,
            fontSize: FontConstants.font_10,
            weight: FontWeightConstants.bold,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViews() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Remote video (full screen)
          if (_remoteUid != null && _engine != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!, // Uses the Agora engine instance
                canvas: VideoCanvas(
                  uid: _remoteUid,
                  renderMode: RenderModeType.renderModeFit,
                ), // Binds the remote user's video
                connection: RtcConnection(
                  channelId: widget.channelName,
                  localUid: widget.userId,
                ), // Specifies the channel and local UID
              ),
            )
          else
            // Don't show "Waiting to join" if we're in reconnection mode
            Container(
              color: Colors.grey[900],
              child:
                  _isWaitingForReconnection
                      ? Container() // Empty - overlay will handle the UI
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 80.w,
                              color: Colors.white54,
                            ),
                            UIHelper.verticalSpaceMd,
                            CustomText(
                              text:
                                  "${'Waiting for'.tr} ${widget.counslername} ${'to join...'.tr}",
                              fontSize: FontConstants.font_16,
                              weight: FontWeightConstants.medium,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
            ),

          // Local video (picture-in-picture)
          if (_isVideoEnabled && _engine != null && _previewStarted)
            Positioned(
              top: 100.h,
              right: 20.w,
              child: GestureDetector(
                onTap: () {
                  // Optional: Tap to switch to full screen local video
                },
                child: Container(
                  width: 120.w,
                  height: 160.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: VideoCanvas(
                          uid: 0,
                          renderMode: RenderModeType.renderModeFit,
                          mirrorMode:
                              VideoMirrorModeType.videoMirrorModeEnabled,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    _showEndCallConfirmation();
                  },
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22.w,
                    ),
                  ),
                ),

                // Empty space for symmetry
                SizedBox(width: 40.w),
              ],
            ),
            UIHelper.verticalSpaceSm,
            // Counselor name and timer
            CustomText(
              text: widget.counslername,
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.semiBold,
              color: Colors.white,
            ),
            SizedBox(height: 4.h),
            if (_isJoined)
              CustomText(
                text: _formatDuration(_callDuration),
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.medium,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 30.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Coins/Time remaining widget (left side)
            Spacer(),

            // Center control buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flip Camera button
                _buildControlButton(
                  icon: _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                  isActive: true,
                  onTap: _switchCamera,
                  size: 56.w,
                ),

                SizedBox(width: 20.w),

                // End call button (RED)
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  backgroundColor: Colors.red,
                  onTap: _showEndCallConfirmation,
                  size: 56.w,
                ),

                SizedBox(width: 20.w),

                // Microphone button
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  isActive: !_isMuted,
                  onTap: _toggleMute,
                  size: 56.w,
                ),
              ],
            ),

            Spacer(),

            // Settings button (right side)
          ],
        ),
      ),
    );
  }

  // Coins/Payment display widget
  Widget buildCoinsWidget() {
    return CoinBalanceWidget(
      coinsLeft: _coinsLeft,
      estimatedMinutesLeft: _estimatedMinutesLeft,
      lowCoinsThreshold: LOW_COINS_THRESHOLD,
      isCounselor: _isCounselor, // Hide for counselors
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
    double? size,
  }) {
    final buttonSize = size ?? 60.w;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color:
              backgroundColor != null
                  ? Colors.white
                  : (isActive ? Colors.black : Colors.white),
          size: buttonSize * 0.45,
        ),
      ),
    );
  }

  // Show end call confirmation
  void _showEndCallConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: CustomText(
              text: "End Call?".tr,
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.bold,
              color: Colors.black87,
            ),
            content: CustomText(
              text: "Are you sure you want to end this call?".tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Colors.black54,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: CustomText(
                  text: "Cancel".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: Colors.grey[600]!,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  _endCall(); // End the call
                },
                child: CustomText(
                  text: "End Call".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
    );
  }

  // Show insufficient coins dialog
  void _showInsufficientCoinsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28.w),
                SizedBox(width: 10.w),
                Expanded(
                  child: CustomText(
                    text: "Insufficient Coins".tr,
                    fontSize: FontConstants.font_18,
                    weight: FontWeightConstants.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: CustomText(
              text:
                  "You don't have enough coins for this call. Please recharge."
                      .tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Colors.black54,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: CustomText(
                  text: "Go Back".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: Colors.grey[600]!,
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: CustomText(
                  text: "Recharge Coins".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
    );
  }

  // Show popup when the other user ends the session
  // Handle session ended smoothly - navigate back first, then show rating
  Future<void> _handleSessionEnded() async {
    // Cancel grace period timer if active
    _reconnectionGraceTimer?.cancel();

    // Clear waiting state
    if (mounted && _isWaitingForReconnection) {
      setState(() {
        _isWaitingForReconnection = false;
      });
    }

    // For users, navigate back smoothly and show rating dialog on previous screen
    if (!_isCounselor &&
        widget.appointmentId != null &&
        widget.counselorId != null) {
      // Store data before disposing
      final appointmentId = widget.appointmentId!;
      final counselorId = widget.counselorId!;
      final counselorName = widget.counslername;
      final counselorImage = widget.counselorImage;
      final callDuration = _callDuration;

      // Complete appointment API in background (don't await)
      _completeAppointmentApi();

      // Dispose resources
      await _dispose();

      // Navigate back immediately (smooth transition)
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Wait for navigation animation to complete, then show rating dialog on previous screen
      await Future.delayed(Duration(milliseconds: 600));

      // Show rating dialog on the previous screen using Get.dialog
      // This will automatically use the correct context after navigation
      await Get.dialog(
        CallRatingDialog(
          appointmentId: appointmentId,
          counselorId: counselorId,
          counselorName: counselorName,
          counselorImage: counselorImage,
          callDuration: callDuration,
        ),
        barrierDismissible: false,
      );

      return;
    }

    // For counselors, just navigate back
    await _dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Show low coins warning
  void _showLowCoinsWarning() {
    Get.snackbar(
      '⚠️ Low Coins Warning'.tr,
      'You have less than $LOW_COINS_THRESHOLD coins remaining.'.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 5),
      margin: EdgeInsets.all(20),
      borderRadius: 10,
      icon: Icon(Icons.warning_amber, color: Colors.white),
      shouldIconPulse: true,
    );
  }

  // Show warning when less than 1 minute remaining
  void _showLessMinuteWarning() {
    Get.snackbar(
      '⚠️ Call Ending Soon'.tr,
      'Less than 1 minute remaining. Please recharge to continue.'.tr,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 10),
      margin: EdgeInsets.all(20),
      borderRadius: 10,
      icon: Icon(Icons.timer_off, color: Colors.white),
      shouldIconPulse: true,
      isDismissible: false,
    );
  }

  /// Start grace period timer - wait for user to reconnect before ending call
  void _startReconnectionGraceTimer() {
    debugPrint(
      '⏳ Starting reconnection grace period ($RECONNECTION_GRACE_PERIOD_SECONDS seconds)',
    );

    _reconnectionGraceTimer?.cancel(); // Cancel any existing timer

    _reconnectionGraceTimer = Timer(
      Duration(seconds: RECONNECTION_GRACE_PERIOD_SECONDS),
      () {
        if (mounted && _remoteUid == null && _isWaitingForReconnection) {
          // Grace period expired and user still hasn't reconnected
          debugPrint('❌ Reconnection grace period expired - ending call');
          setState(() {
            _isWaitingForReconnection = false;
          });

          // Stop timers and end session
          _stopCallTimer();
          _stopCoinDeduction();
          _stopCoinUpdateApiTimer();
          _handleSessionEnded();
        } else if (_remoteUid != null) {
          // User already reconnected, just clear the waiting state
          debugPrint('✅ User already reconnected during grace period');
          if (mounted) {
            setState(() {
              _isWaitingForReconnection = false;
            });
          }
        }
      },
    );
  }

  /// Cancel grace period timer when user reconnects
  void _cancelReconnectionGraceTimer() {
    if (_reconnectionGraceTimer != null && _reconnectionGraceTimer!.isActive) {
      debugPrint('✅ User reconnected - canceling grace period timer');
      _reconnectionGraceTimer?.cancel();
      _reconnectionGraceTimer = null;

      // Ensure waiting state is cleared
      if (mounted && _isWaitingForReconnection) {
        setState(() {
          _isWaitingForReconnection = false;
        });
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            UIHelper.verticalSpaceMd,
            CustomText(
              text:
                  _isWaitingForReconnection
                      ? "Waiting for reconnection...".tr
                      : "Connecting to call...".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.white,
            ),
            if (_isWaitingForReconnection) ...[
              UIHelper.verticalSpaceSm,
              CustomText(
                text: "The other user will rejoin shortly".tr,
                fontSize: FontConstants.font_14,
                weight: FontWeightConstants.regular,
                color: Colors.white70,
              ),
              UIHelper.verticalSpaceL,
              // Add End Call button during waiting period
              ElevatedButton(
                onPressed: () {
                  // Cancel grace period and end call immediately
                  _reconnectionGraceTimer?.cancel();
                  setState(() {
                    _isWaitingForReconnection = false;
                  });
                  _endCall(showRating: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: CustomText(
                  text: "End Call".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Settings button (opens tarot reading webpage)
Widget buildSettingsButton(BuildContext context, bool _isCounselor) {
  return GestureDetector(
    onTap: () {
      _openTarotWebBrowser(context, _isCounselor);
    },
    child: Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Icon(Icons.star, color: Colors.white, size: 24.w),
    ),
  );
}

// Open tarot reading webpage
void _openTarotWebBrowser(BuildContext context, bool _isCounselor) {
  // Initialize WebView controller
  late final WebViewController controller;

  SettingsData settings = context.read<SettingProvider>().settingsModel!.data;
  final String tarotUrl1 =
      _isCounselor ? settings.tarotCounselorsUrl : settings.tarotQuerentsUrl;

  final String tarotUrl =
      tarotUrl1.isNotEmpty
          ? tarotUrl1
          : _isCounselor
          ? 'http://47.236.118.189:443'
          : 'http://47.236.118.189:443/querents';

  debugPrint(
    '🔮 Opening tarot for ${_isCounselor ? "counselor" : "user"}: $tarotUrl',
  );

  controller =
      WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(tarotUrl));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag:
        false, // Disable drag to prevent conflict with WebView scrolling
    builder:
        (context) => GestureDetector(
          onTap: () {}, // Prevent tap from closing
          child: Container(
            height: Get.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Modern header with close button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tarot icon and title
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: primaryColor,
                            size: 24.w,
                          ),
                          SizedBox(width: 10.w),
                          CustomText(
                            text: "Tarot Reading".tr,
                            fontSize: FontConstants.font_16,
                            weight: FontWeightConstants.semiBold,
                            color: Colors.black87,
                          ),
                        ],
                      ),

                      // Close button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.black87,
                            size: 20.w,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // WebView with proper scrolling
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: WebViewWidget(controller: controller),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}
