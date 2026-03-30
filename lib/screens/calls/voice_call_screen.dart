import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:deepinheart/config/agora_config.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/screens/calls/video_call_screen.dart';
import 'package:deepinheart/screens/calls/widgets/coin_balance_widget.dart';
import 'package:deepinheart/services/agora_token_generator_service.dart'; // 🧪 Token Generator (remove for production)
import 'package:deepinheart/services/agora_webhook_service.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/screens/calls/widgets/call_rating_dialog.dart';
import 'package:deepinheart/services/call_state_manager.dart';

// ============================================
// 🧪 TOKEN GENERATION CONFIGURATION
// ============================================
// Set to TRUE to generate tokens locally (TESTING ONLY)
// Set to FALSE to fetch tokens from backend API (PRODUCTION)
const bool USE_GENERATED_TOKEN = false; // ⭐ CHANGE TO false FOR PRODUCTION
// ============================================

class VoiceCallScreen extends StatefulWidget {
  final String counslername;
  final String channelName;
  final int userId;
  final double counselorRate; // Coins per minute
  final int? appointmentId; // Optional appointment ID for coin updates
  final int? counselorId; // Counselor ID for API calls
  final String? counselorImage; // Counselor image URL
  final bool isCounselor; // Track if current user is a counselor
  final bool isTroat;

  VoiceCallScreen({
    Key? key,
    required this.counslername,
    required this.channelName,
    required this.userId,
    this.counselorRate = 50.0, // Default rate
    this.appointmentId, // Optional parameter
    this.counselorId, // Counselor ID
    this.counselorImage, // Counselor image
    required this.isCounselor,
    required this.isTroat,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerEnabled = true;
  bool _isLoading = true;
  int? _remoteUid;
  Timer? _callTimer;
  Timer? _coinDeductionTimer;
  Timer?
  _coinUpdateApiTimer; // Timer for calling coin-update API every 1 minute
  Timer? _reconnectionGraceTimer; // Timer to wait for user reconnection
  Duration _callDuration = Duration.zero;
  bool _isWaitingForReconnection = false; // Flag to show waiting UI
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Coins and time tracking
  double _coinsLeft = 0.0;
  int _initialCoins = 0;
  int _estimatedMinutesLeft = 0;
  bool _isCounselor = false; // Track if current user is a counselor

  // Coin rate configuration (dynamic, from counselor)
  late double coinsPerMinute;
  late double coinsPerSecond;
  static const int LOW_COINS_THRESHOLD = 100;

  bool _lowCoinsWarningShown = false;
  bool _lessMinuteWarningShown = false; // Track if < 1 minute warning shown
  bool _isInitialized = false;

  // Appointment type tracking
  // "consult_now" = real-time coin deduction
  // "appointment" = coins already deducted at booking
  String _appointmentType = "";

  String? _agoraToken; // Store fetched Agora token

  // Webhook service for network state handling
  final AgoraWebhookService _webhookService = AgoraWebhookService();
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const int RECONNECTION_GRACE_PERIOD_SECONDS =
      300; // Wait 120 seconds for reconnection

  // Throttle network quality toast to avoid spam
  DateTime? _lastNetworkWarningAt;
  static const int NETWORK_WARNING_COOLDOWN_SECONDS = 30;

  @override
  void initState() {
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

    _initAnimations();
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
            autoSubscribeVideo: false,
            autoSubscribeAudio: true,
            publishCameraTrack: false,
            publishMicrophoneTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
          ),
        );
        debugPrint('✅ Reconnection successful');
        _isReconnecting = false;
        _reconnectAttempts = 0;

        if (mounted) {
          // Get.snackbar(
          //   'Network Reconnected'.tr,
          //   'Connection restored'.tr,
          //   backgroundColor: Colors.green,
          //   colorText: Colors.white,
          //   duration: Duration(seconds: 2),
          //   snackPosition: SnackPosition.TOP,
          //   icon: Icon(Icons.wifi, color: Colors.white),
          // );
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
      callType: 'voice',
      channelName: widget.channelName,
      counselorName: widget.counslername,
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

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _dispose() async {
    try {
      _callTimer?.cancel();
      _coinDeductionTimer?.cancel();
      _coinUpdateApiTimer?.cancel(); // Cancel coin update API timer
      _reconnectTimer?.cancel();
      _pulseController.dispose();
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

      // Use the isCounselor parameter from widget
      _isCounselor = widget.isCounselor;
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
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching appointment type: $e');
      return null;
    }
  }

  // Fetch or Generate Agora token
  Future<void> _fetchAgoraToken() async {
    try {
      debugPrint('🔑 Getting Agora token...');

      // ============================================
      // 🧪 GENERATED TOKEN MODE - Generate locally
      // ============================================
      if (USE_GENERATED_TOKEN) {
        debugPrint(
          '🔑 GENERATED TOKEN MODE: Creating token locally (Audio only)...',
        );
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
          debugPrint(
            '✅ Token generated successfully (client-side - audio call)',
          );
        }
        return; // Skip backend API call
      }
      // ============================================

      // ============================================
      // 🌐 PRODUCTION MODE - Fetch from backend API
      // ============================================
      debugPrint('🔑 PRODUCTION MODE: Fetching token from backend...');

      // BOTH users need to be publishers for voice calls
      // Publisher = can send and receive audio
      // Subscriber = can only receive (no sending)
      final role = 'publisher'; // Always publisher for voice calls

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
          'Microphone permission is required for voice calls'.tr,
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
          icon: Icon(Icons.mic_off, color: Colors.white),
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
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Register event handlers BEFORE joining channel
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('onJoinChannelSuccess ${connection.channelId}');
            if (mounted) {
              setState(() {
                _isJoined = true;
                _isLoading = false;
              });

              // Send webhook event
              _webhookService.onCallStarted(
                channelName: widget.channelName,
                userId: widget.userId,
                appointmentId: widget.appointmentId,
              );
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('onUserJoined $remoteUid');
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });

              // Send webhook event
              _webhookService.onUserJoined(
                channelName: widget.channelName,
                userId: widget.userId,
                remoteUid: remoteUid,
              );

              // Start call timer when remote user joins
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
          ) {
            debugPrint('onUserOffline $remoteUid');
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
              if (_isCounselor && _appointmentType == 'consult_now') {
                debugPrint(
                  '👨‍⚕️ Counselor: consult_now - sending end_time API',
                );
              }

              // Stop call timer and coin deduction when remote user leaves
              _stopCallTimer();
              _stopCoinDeduction();
              _stopCoinUpdateApiTimer();

              // Handle session ended - navigate back smoothly for users, then show rating
              _handleSessionEnded();
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
                    'Unable to connect to the call'.tr,
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
                // Keep UI quiet unless cooldown expired; prefer logging only
                debugPrint('⚠️ Poor network quality detected (voice call)');
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
        ),
      );

      // Disable video for voice call
      await _engine!.disableVideo();

      // Set audio profile for better voice quality
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

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
          'Failed to initialize voice call: ${e.toString()}'.tr,
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

    // Log token status before joining
    if (_agoraToken == null || _agoraToken!.isEmpty) {
      debugPrint(
        '⚠️ WARNING: No token available from API, attempting to join without token',
      );
    } else {
      debugPrint('🔑 Joining channel with token from backend API');
      debugPrint('   Token length: ${_agoraToken!.length}');
    }

    while (retryCount < maxRetries) {
      try {
        await _engine!.joinChannel(
          token: _agoraToken ?? '', // Use fetched token from API
          channelId: widget.channelName,
          uid: widget.userId,
          options: const ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileCommunication,
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishMicrophoneTrack: true,
            publishCameraTrack: false,
            autoSubscribeAudio: true,
            autoSubscribeVideo: false,
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
        return 'Connection interrupted. Please check your internet connection.'
            .tr;
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
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
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

    _coinUpdateApiTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      if (mounted && _isJoined && _remoteUid != null) {
        //  await _callCoinUpdateApi();
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

      debugPrint(
        '🕐 Sending start_time API for appointment: ${widget.appointmentId}',
      );
      debugPrint('   Start time: $startTime');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.UPDATE_TIME),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();
      request.fields['start_time'] = startTime;

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

  // Send end_time to API when call timer stops
  // Only called by counselor for consult_now type
  Future<void> _sendEndTimeApi() async {
    // if (!_isCounselor) {
    //   debugPrint('⏱️ Not a counselor - skipping end_time API');
    //   return;
    // }
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
        debugPrint('   $key: "$value"');
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

  Future<void> _toggleSpeaker() async {
    await _engine?.setEnableSpeakerphone(!_isSpeakerEnabled);
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
  }

  Future<void> _endCall({bool showRating = true}) async {
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
        await _dispose();

        // Show rating dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => CallRatingDialog(
                appointmentId: widget.appointmentId!,
                counselorId: widget.counselorId!,
                counselorName: widget.counslername,
                counselorImage: widget.counselorImage,
                callDuration: _callDuration,
              ),
        );

        // Navigate back to previous screen after rating dialog closes
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    await _dispose();
    Get.back();
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
    if (appointmentData['counselor_status'].toString().toLowerCase() ==
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
            // Background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.6),
                    Colors.black,
                  ],
                ),
              ),
            ),

            // Main content
            _buildMainContent(),

            if (_isInitialized)
              Positioned(
                bottom: 120.h,
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
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

            // Bottom controls
            _buildBottomControls(),

            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget buildCoinsWidget() {
    return CoinBalanceWidget(
      coinsLeft: _coinsLeft,
      estimatedMinutesLeft: _estimatedMinutesLeft,
      lowCoinsThreshold: LOW_COINS_THRESHOLD,
      isCounselor: _isCounselor, // Hide for counselors
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Coins widget at top

          // Counselor avatar
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 100.w,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Icon(Icons.person, size: 100.w, color: Colors.white),
                  ),
                ),
              );
            },
          ),

          UIHelper.verticalSpaceMd,

          // Counselor name
          CustomText(
            text: widget.counslername,
            fontSize: FontConstants.font_28,
            weight: FontWeightConstants.bold,
            color: Colors.white,
          ),

          UIHelper.verticalSpaceMd,

          // Call status
          if (_isJoined && _remoteUid != null)
            CustomText(
              text: "Connected".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.white70,
            )
          else if (_isJoined)
            CustomText(
              text:
                  "${'Waiting for'.tr} ${widget.counslername} ${'to join...'.tr}",
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.white70,
            )
          else
            CustomText(
              text: "Connecting...".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.white70,
            ),

          UIHelper.verticalSpaceMd,

          // Call duration
          if (_isJoined)
            CustomText(
              text: _formatDuration(_callDuration),
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.bold,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              isActive: !_isMuted,
              onTap: _toggleMute,
            ),

            // Speaker button
            _buildControlButton(
              icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
              isActive: _isSpeakerEnabled,
              onTap: _toggleSpeaker,
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              isActive: false,
              backgroundColor: Colors.red,
              onTap: _showEndCallConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70.w,
        height: 70.w,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (isActive ? Colors.white : Colors.white.withOpacity(0.3)),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color:
              backgroundColor != null
                  ? Colors.white
                  : (isActive ? Colors.black : Colors.white),
          size: 32.w,
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            UIHelper.verticalSpaceMd,
            CustomText(
              text: "Connecting to call...".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.white,
            ),
          ],
        ),
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
            ],
          ),
    );
  }

  // Handle session ended smoothly - navigate back first, then show rating
  Future<void> _handleSessionEnded() async {
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
}
