import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/settings_model.dart';
import 'package:deepinheart/Controller/Viewmodel/setting_provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens_consoler/chat/providers/chat_provider.dart';
import 'package:deepinheart/views/colors.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/screens/calls/widgets/call_rating_dialog.dart';
import 'package:deepinheart/screens/calls/widgets/coin_balance_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String counselorName;
  final String channelName;
  final int userId;
  final double counselorRate;
  final int? appointmentId;
  final int? counselorId;
  final bool isCounselor;
  final bool isViewOnly; // View chat history only, no coin deduction
  final bool isTroat;

  const ChatScreen({
    Key? key,
    required this.counselorName,
    required this.channelName,
    required this.userId,
    this.counselorRate = 50.0,
    this.appointmentId,
    this.counselorId,
    required this.isCounselor,
    this.isViewOnly = false, // Default to active chat
    required this.isTroat,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  // Timers
  Timer? _chatTimer;
  Timer? _coinDeductionTimer;
  Timer? _coinUpdateApiTimer;
  Timer? _messageFetchTimer;
  Timer? _appointmentStatusTimer; // Timer to check if counselor has joined
  Duration _chatDuration = Duration.zero;

  // Coins and time tracking
  double _coinsLeft = 0.0;
  int _initialCoins = 0;
  int _estimatedMinutesLeft = 0;
  bool _isCounselor = false;

  // Coin rate configuration
  late double coinsPerMinute;
  late double coinsPerSecond;
  static const int LOW_COINS_THRESHOLD = 100;

  bool _lowCoinsWarningShown = false;
  bool _lessMinuteWarningShown = false;
  bool _isInitialized = false;
  bool _chatStarted = false;

  // Counselor presence tracking (for user side)
  bool _counselorHasJoined = false;
  String _counselorStatus = "Waiting...".tr;
  bool _appointmentFinished = false; // Track if status = "confirmed"

  // Session ended tracking (for counselor side)
  Timer? _sessionEndedPollingTimer;
  bool _sessionEndedByUser = false;
  DateTime? _sessionStartTime; // Track when current session started

  // Appointment type tracking
  // "consult_now" = real-time coin deduction
  // "appointment" = coins already deducted at booking
  String _appointmentType = "";

  @override
  void initState() {
    super.initState();
    coinsPerMinute = widget.counselorRate;
    coinsPerSecond = coinsPerMinute / 60.0;
    _isCounselor = widget.isCounselor;

    debugPrint('💬 Chat Screen Initialized');
    debugPrint('💰 Counselor Rate: $coinsPerMinute coins/minute');
    debugPrint('👨‍⚕️ Is Counselor: $_isCounselor');
    // call mark as read api
    _markAsReadApi();

    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatTimer?.cancel();
    _coinDeductionTimer?.cancel();
    _coinUpdateApiTimer?.cancel();
    _messageFetchTimer?.cancel();
    _appointmentStatusTimer?.cancel();
    _sessionEndedPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // VIEW ONLY MODE - Just fetch chat history, no timers or coin deduction
      if (widget.isViewOnly) {
        debugPrint('📖 VIEW ONLY MODE - Loading chat history');
        setState(() {
          _isInitialized = true;
          _counselorHasJoined = true;
          _counselorStatus = "Chat History".tr;
        });

        // Fetch messages only
        await _fetchMessages();

        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);

      // Initialize coins for regular users
      if (!_isCounselor && userViewModel.userModel != null) {
        final user = userViewModel.userModel;
        if (user != null && user.data.coins != null) {
          setState(() {
            _coinsLeft = user.data.coins!.toDouble();
            _initialCoins = user.data.coins!;
            _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            _isInitialized = true;
          });

          if (_coinsLeft < coinsPerMinute) {
            _showInsufficientCoinsDialog();
            return;
          }
        } else {
          setState(() {
            _coinsLeft = 1000.0;
            _initialCoins = 1000;
            _estimatedMinutesLeft = (_coinsLeft / coinsPerMinute).floor();
            _isInitialized = true;
          });
        }

        // For USER: Start polling appointment status to check if counselor has joined
        _startAppointmentStatusPolling();
      } else if (_isCounselor) {
        // For COUNSELOR: Fetch appointment type first, then start chat session
        setState(() {
          _isInitialized = true;
          _counselorHasJoined = true;
          _counselorStatus = "Online".tr;
        });

        // Fetch appointment details to get the type
        await _fetchAppointmentType();

        // Start chat session (this will call _sendStartTimeApi if consult_now)
        _startChatSession();

        // COUNSELOR: Start polling to detect when user ends the session
        _startSessionEndedPolling();
      }

      // Fetch messages
      await _fetchMessages();

      // Start message fetching timer
      _messageFetchTimer = Timer.periodic(Duration(seconds: 2), (timer) {
        _fetchMessages();
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error initializing chat: $e');
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    }
  }

  void _startChatSession() {
    if (_chatStarted) {
      debugPrint('⚠️ Chat session already started, ignoring duplicate call');
      return;
    }
    _chatStarted = true;
    _sessionStartTime = DateTime.now(); // Record session start time

    debugPrint('═══════════════════════════════════════');
    debugPrint('💬💬💬 STARTING CHAT SESSION 💬💬💬');
    debugPrint('   Appointment ID: ${widget.appointmentId}');
    debugPrint('   Counselor Name: ${widget.counselorName}');
    debugPrint('   Is Counselor: $_isCounselor');
    debugPrint('   Appointment Type: $_appointmentType');
    debugPrint('   Counselor Rate: $coinsPerMinute coins/minute');
    debugPrint('   Counselor Has Joined: $_counselorHasJoined');
    debugPrint('   Session Start Time: $_sessionStartTime');
    debugPrint('═══════════════════════════════════════');

    // Start chat timer
    _startChatTimer();
    debugPrint('✅ Chat timer started');

    if (_isCounselor) {
      // COUNSELOR: Send start_time API only for consult_now type
      if (_appointmentType == 'consult_now') {
        debugPrint(
          '👨‍⚕️ COUNSELOR: consult_now type - sending start_time API',
        );
        _sendStartTimeApi();
      } else {
        debugPrint(
          '👨‍⚕️ COUNSELOR: appointment type - no start_time API needed',
        );
      }
    } else {
      // USER: Only start coin deduction for consult_now type
      // For appointment type, coins are already deducted at booking
      if (_appointmentType == 'consult_now') {
        debugPrint(
          '💰 USER: consult_now type - starting real-time coin deduction',
        );
        _startCoinDeduction();
        _startCoinUpdateApiTimer();
        debugPrint('✅ Coin deduction and update API timers started');
      } else {
        debugPrint(
          '📅 USER: appointment type - coins already paid at booking, no real-time deduction',
        );
      }
    }

    debugPrint('═══════════════════════════════════════');
    debugPrint('✅✅✅ CHAT SESSION FULLY STARTED ✅✅✅');
    debugPrint('═══════════════════════════════════════');
  }

  // ==================== FETCH APPOINTMENT TYPE (FOR COUNSELOR) ====================

  /// Fetch appointment type (called by counselor on init)
  Future<void> _fetchAppointmentType() async {
    if (widget.appointmentId == null) return;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return;

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
          debugPrint(
            '📋 Counselor: Fetched appointment type: $_appointmentType',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching appointment type: $e');
    }
  }

  // ==================== MARK MESSAGES AS READ ====================

  /// Mark all messages in this chat as read
  Future<void> _markAsReadApi() async {
    if (widget.appointmentId == null) {
      debugPrint('⚠️ Cannot mark as read: appointmentId is null');
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Cannot mark as read: No authentication token');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndPoints.MESSAGES_MARK_AS_READ),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        if (data['success'] == true) {
          debugPrint(
            '✅ Messages marked as read for appointment ${widget.appointmentId}',
          );

          // Refresh conversations list to update unread status in conversation screen
          try {
            final chatProvider = Provider.of<ChatProvider>(
              context,
              listen: false,
            );
            await chatProvider.refreshConversations(context);
            debugPrint('✅ Conversations refreshed after marking as read');
          } catch (e) {
            // ChatProvider might not be available in all contexts, ignore error
            debugPrint('⚠️ Could not refresh conversations: $e');
          }
        } else {
          debugPrint('⚠️ Failed to mark as read: ${data['message']}');
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint(
          '❌ Error marking as read: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _markAsReadApi: $e');
    }
  }

  // ==================== APPOINTMENT STATUS POLLING (USER SIDE) ====================

  /// Start polling appointment status every 1 second to check if counselor has joined
  void _startAppointmentStatusPolling() {
    if (_isCounselor) return; // Only for users
    if (widget.appointmentId == null) return;

    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 USER: Starting appointment status polling');
    debugPrint('   Checking EVERY 1 SECOND for counselor join (AGGRESSIVE)');
    debugPrint('   Appointment ID: ${widget.appointmentId}');
    debugPrint('═══════════════════════════════════════');

    // Check immediately first (instant check)
    _checkAppointmentStatus();

    // Then poll EVERY 1 SECOND for real-time detection (more aggressive than video call)
    _appointmentStatusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted &&
          !_counselorHasJoined &&
          !_chatStarted &&
          !_appointmentFinished) {
        debugPrint(
          '🔄 USER: Polling appointment status... (attempt ${timer.tick})',
        );
        _checkAppointmentStatus();
      } else if (_counselorHasJoined || _chatStarted || _appointmentFinished) {
        // Stop polling once counselor joins, chat started, or appointment finished
        debugPrint(
          '✅ USER: Stopping polling (joined: $_counselorHasJoined, started: $_chatStarted, finished: $_appointmentFinished)',
        );
        _stopAppointmentStatusPolling();
      }
    });
  }

  /// Stop appointment status polling
  void _stopAppointmentStatusPolling() {
    debugPrint('🔄 Stopping appointment status polling');
    _appointmentStatusTimer?.cancel();
    _appointmentStatusTimer = null;
  }

  /// Start polling to detect when user ends the session (for COUNSELOR side)
  void _startSessionEndedPolling() {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🔄 _startSessionEndedPolling called');
    debugPrint('   _isCounselor: $_isCounselor');
    debugPrint('   appointmentId: ${widget.appointmentId}');
    debugPrint('═══════════════════════════════════════');

    if (!_isCounselor) {
      debugPrint('🔄 Not counselor - skipping session ended polling');
      return;
    }

    debugPrint('✅ COUNSELOR: Starting session ended polling (every 2 seconds)');

    // Show snackbar to confirm polling started
    // Get.snackbar(
    //   '🔄 Session Monitoring Active',
    //   'Monitoring for user session end...',
    //   backgroundColor: Colors.blue,
    //   colorText: Colors.white,
    //   snackPosition: SnackPosition.TOP,
    //   duration: Duration(seconds: 3),
    // );

    // Check immediately first
    _checkIfUserEndedSession();

    // Poll every 2 seconds
    _sessionEndedPollingTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkIfUserEndedSession();
      }
    });
  }

  /// Stop session ended polling
  void _stopSessionEndedPolling() {
    debugPrint('🔄 Stopping session ended polling');
    _sessionEndedPollingTimer?.cancel();
    _sessionEndedPollingTimer = null;
  }

  /// Check if the user has ended the session (for COUNSELOR side)
  Future<void> _checkIfUserEndedSession() async {
    // Skip in view-only mode (viewing chat history)
    if (widget.appointmentId == null ||
        !_isCounselor ||
        _sessionEndedByUser ||
        widget.isViewOnly) {
      return;
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        debugPrint('❌ COUNSELOR: No token available for session ended check');
        return;
      }

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
          final status = appointmentData['status']?.toString().toLowerCase();

          debugPrint('🔄 COUNSELOR: Polling status = "$status"');

          // Check if appointment is completed - means user ended the session
          final bool isEnded =
              status == 'completed' ||
              status == 'ended' ||
              status == 'finished' ||
              status == 'done' ||
              status == 'complete' ||
              status == 'confirmed'; // User finished the appointment

          if (isEnded) {
            debugPrint(
              '✅ COUNSELOR: User has ended the session! (status: $status)',
            );

            setState(() {
              _sessionEndedByUser = true;
            });

            // Stop polling
            _stopSessionEndedPolling();

            // Handle session ended smoothly - navigate back first, then show rating
            _handleSessionEnded();
          }
        }
      } else {
        debugPrint('❌ COUNSELOR: Session check failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error checking if user ended session: $e');
    }
  }

  /// Check appointment status API to see if counselor has joined
  Future<void> _checkAppointmentStatus() async {
    if (widget.appointmentId == null) return;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return;

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
            Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Appointment status check timeout');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Handle both array and single object responses (like video call screen)
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
              return;
            }
            appointmentData = targetAppointment;
          } else {
            // API returns single object
            debugPrint('📄 API returned single appointment object');
            appointmentData = data['data'];
          }

          final counselorStatus = appointmentData['counselor_status'];
          final appointmentStatus = appointmentData['status'];
          final appointmentType = appointmentData['type']?.toString() ?? '';

          // Save appointment type for use in other methods
          _appointmentType = appointmentType;

          debugPrint('📋 Appointment Status Check:');
          debugPrint('   ID: ${appointmentData['id']}');
          debugPrint('   Type: $appointmentType');
          debugPrint('   Counselor status: $counselorStatus');
          debugPrint('   Appointment status: $appointmentStatus');
          debugPrint('   Has joined: $_counselorHasJoined');
          debugPrint('   Chat started: $_chatStarted');
          debugPrint('   Appointment finished: $_appointmentFinished');

          // 🔥 CHECK 1: Is appointment finished? (status = "confirmed")
          if (appointmentStatus != null &&
              appointmentStatus.toString().toLowerCase() == 'confirmed' &&
              !_appointmentFinished) {
            debugPrint('✅ Appointment is CONFIRMED (finished)');
            if (mounted) {
              setState(() {
                _appointmentFinished = true;
              });
            }
            _stopAppointmentStatusPolling();
            return; // Exit early - no need to check counselor status
          }

          // 🔥 CHECK 2: Has counselor accepted and joined?
          // counselor_status = "accept" means counselor has ACCEPTED AND JOINED
          final bool counselorHasJoined =
              counselorStatus != null &&
              counselorStatus.toString().toLowerCase() == 'accept';

          if (counselorHasJoined && !_counselorHasJoined) {
            debugPrint('═══════════════════════════════════════');
            debugPrint('✅✅✅ COUNSELOR HAS JOINED! ✅✅✅');
            debugPrint('   Counselor status: $counselorStatus');
            debugPrint('   Appointment type: $appointmentType');
            debugPrint('   NOW ACTIVATING CHAT & CALLING _startChatTimer...');
            debugPrint('═══════════════════════════════════════');

            if (mounted) {
              setState(() {
                _counselorHasJoined = true;
                _counselorStatus = "Online".tr;
              });
            }

            // Stop polling since counselor has joined
            _stopAppointmentStatusPolling();

            // Start chat session IMMEDIATELY (coin deduction, timers)
            _startChatSession();

            // Refresh UI to enable message input
            if (mounted) {
              setState(() {});
            }
          } else if (!counselorHasJoined) {
            // Counselor has NOT joined yet (status is "pending" or something else)
            if (mounted) {
              setState(() {
                _counselorStatus = "Waiting for counselor to accept...".tr;
              });
            }
            debugPrint('⏳ Waiting for counselor to accept and join...');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking appointment status: $e');
    }
  }

  // ==================== API CALLS ====================

  Future<void> _fetchMessages() async {
    if (widget.appointmentId == null) return;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${ApiEndPoints.BASE_URL}messages/${widget.appointmentId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> messagesData = data['data'];
          final currentUserId = userViewModel.userModel?.data.id;

          // COUNSELOR: Check if user has sent session ended message
          // Skip this check in view-only mode (viewing chat history)
          // IMPORTANT: Only check messages sent AFTER current session started
          if (_isCounselor &&
              !_sessionEndedByUser &&
              !widget.isViewOnly &&
              _chatStarted &&
              _sessionStartTime != null) {
            for (var msg in messagesData) {
              final messageText = msg['message']?.toString() ?? '';
              final senderId = msg['sender_id'];
              final messageTimestamp = DateTime.tryParse(
                msg['created_at'] ?? '',
              );

              // Check if this is a session ended message from the user (not counselor)
              // AND it was sent AFTER the current session started
              if (messageText == '[SESSION_ENDED_BY_USER]' &&
                  senderId != currentUserId &&
                  messageTimestamp != null &&
                  messageTimestamp.isAfter(_sessionStartTime!)) {
                debugPrint('═══════════════════════════════════════');
                debugPrint('✅ COUNSELOR: Detected user ended session message!');
                debugPrint('   Message timestamp: $messageTimestamp');
                debugPrint('   Session start time: $_sessionStartTime');
                debugPrint('═══════════════════════════════════════');

                setState(() {
                  _sessionEndedByUser = true;
                });

                // Stop all polling
                _stopSessionEndedPolling();
                _messageFetchTimer?.cancel();

                // Handle session ended smoothly - navigate back first, then show rating
                _handleSessionEnded();
                return; // Don't update messages list
              }
            }
          }

          setState(() {
            _messages =
                messagesData
                    .where((msg) {
                      // Filter out system messages
                      final messageText = msg['message']?.toString() ?? '';
                      return messageText != '[SESSION_ENDED_BY_USER]';
                    })
                    .map((msg) {
                      final senderId = msg['sender_id'];
                      final messageIsFromCounselor =
                          _isCounselor
                              ? senderId == currentUserId
                              : senderId != currentUserId;

                      return ChatMessage(
                        id: msg['id'],
                        text: msg['message'] ?? '',
                        isFromCounselor: messageIsFromCounselor,
                        timestamp:
                            DateTime.tryParse(msg['created_at'] ?? '') ??
                            DateTime.now(),
                        senderName: msg['sender']?['name'] ?? '',
                        senderImage: msg['sender']?['image'] ?? '',
                        isRead: msg['read_at'] != null,
                        fileUrl: msg['file'],
                      );
                    })
                    .toList();
          });

          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching messages: $e');
    }
  }

  Future<void> _sendMessageApi(String message, {File? attachment}) async {
    if (widget.appointmentId == null) return;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}messages'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();
      request.fields['message'] = message;

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', attachment.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchMessages();
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint(
          '❌ Send message failed: ${response.statusCode} - $responseBody',
        );

        // Handle specific error messages
        try {
          final errorData = jsonDecode(responseBody);
          final errorMessage =
              errorData['message'] ?? 'Failed to send message'.tr;

          // Show user-friendly error
          if (mounted) {
            Get.snackbar(
              'Error'.tr,
              errorMessage,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: Duration(seconds: 4),
            );
          }
        } catch (_) {
          // If parsing fails, show generic error
          if (mounted) {
            Get.snackbar(
              'Error'.tr,
              'Failed to send message'.tr,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    }
  }

  Future<void> _sendStartTimeApi() async {
    // Only counselor can call this API and only for consult_now type
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
      debugPrint('   URL: ${ApiEndPoints.UPDATE_TIME}');
      debugPrint('   Token: Bearer $token');
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

      // Debug: Print all request fields and headers
      debugPrint('📤 Request Headers:');
      request.headers.forEach((key, value) {
        debugPrint('   $key: $value');
      });
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

  Future<void> _sendEndTimeApi() async {
    // Only counselor can call this API and only for consult_now type
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
      final endTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      // Validate endTime is not empty
      if (endTime.isEmpty || endTime.length < 5) {
        debugPrint('❌ Invalid end_time format: "$endTime"');
        return;
      }

      // Calculate total coins deducted from the chat
      // Method 1: Based on actual coins used
      final coinsDeducted = (_initialCoins - _coinsLeft).toStringAsFixed(2);

      // Method 2: Based on chat duration (more accurate)
      final durationInMinutes = _chatDuration.inSeconds / 60.0;
      final coinsBasedOnDuration =
          (durationInMinutes * coinsPerMinute).toInt().toString();

      debugPrint('═══════════════════════════════════════');
      debugPrint('🕐 Sending end_time API');
      debugPrint('   Appointment ID: ${widget.appointmentId}');
      debugPrint('   End time: "$endTime" (length: ${endTime.length})');
      debugPrint('   Chat duration: ${_formatDuration(_chatDuration)}');
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
      // Send coins deducted based on chat duration (endTime - startTime) * counselorRate
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

  // ==================== TIMER METHODS ====================

  void _startChatTimer() {
    // Only start chat timer if not already running
    if (_chatTimer != null && _chatTimer!.isActive) return;

    debugPrint('⏱️ Starting chat timer');

    _chatTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _chatDuration = Duration(seconds: _chatDuration.inSeconds + 1);
        });
      }
    });
  }

  void _stopChatTimer() {
    debugPrint('⏱️ Stopping chat timer');
    debugPrint('   Total chat duration: ${_formatDuration(_chatDuration)}');

    _chatTimer?.cancel();
    _chatTimer = null;
  }

  void _startCoinDeduction() {
    // Skip coin deduction entirely for counselors
    if (_isCounselor) {
      debugPrint('💰 Skipping coin deduction - User is counselor');
      return;
    }

    // Only start coin deduction if not already running
    if (_coinDeductionTimer != null && _coinDeductionTimer!.isActive) return;

    debugPrint('💰 Starting coin deduction');
    debugPrint(
      '💰 Per Second Rate: ${coinsPerSecond.toStringAsFixed(3)} coins/second',
    );

    _coinDeductionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && _isInitialized) {
        setState(() {
          // Deduct coins per second using counselor's rate
          _coinsLeft -= coinsPerSecond;

          // Ensure coins don't go below 0
          if (_coinsLeft < 0) _coinsLeft = 0;

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

        // ⚠️ CRITICAL: End chat if estimated time < 1 minute
        if (_estimatedMinutesLeft < 1 &&
            _coinsLeft > 0 &&
            !_lessMinuteWarningShown) {
          _lessMinuteWarningShown = true;
          debugPrint('⚠️ Less than 1 minute remaining - showing final warning');
          _showLessMinuteWarning();
        }

        // Check if out of coins - immediately end chat
        if (_coinsLeft <= 0) {
          debugPrint('❌ Coins depleted - ending chat immediately');
          timer.cancel();
          _handleOutOfCoins();
        }
      }
    });
  }

  void _stopCoinDeduction() {
    debugPrint('💰 Stopping coin deduction');
    _coinDeductionTimer?.cancel();
    _coinDeductionTimer = null;
  }

  // Start timer to call coin update API every 1 minute
  void _startCoinUpdateApiTimer() {
    // Only start for regular users (not counselors) and if appointment_id is available
    if (_isCounselor || widget.appointmentId == null) {
      debugPrint(
        '💰 Coin update API timer not started: ${_isCounselor ? "user is counselor" : "no appointment ID"}',
      );
      return;
    }

    debugPrint('🔄 Starting coin update API timer - every 1 minute');

    _coinUpdateApiTimer = Timer.periodic(Duration(seconds: 60), (timer) async {
      if (mounted) {
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

  // ==================== MESSAGE HANDLING ====================

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(
          text: messageText,
          isFromCounselor: _isCounselor,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
    });
    _scrollToBottom();

    await _sendMessageApi(messageText);

    setState(() {
      _isSending = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== ATTACHMENT HANDLING ====================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                CustomText(
                  text: "Attachments",
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.semiBold,
                  color: Colors.black87,
                ),
                SizedBox(height: 24.h),

                // Options Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: "Camera",
                      color: primaryColor,
                      onTap: () {
                        Get.back();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.photo_library,
                      label: "Gallery",
                      color: primaryColor,
                      onTap: () {
                        Get.back();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.attach_file,
                      label: "File",
                      color: Color(0xFF9C27B0),
                      onTap: () {
                        Get.back();
                        _pickFile();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Cancel button
                Divider(color: Colors.grey[200]),
                TextButton(
                  onPressed: () => Get.back(),
                  child: CustomText(
                    text: "Cancel",
                    fontSize: FontConstants.font_16,
                    weight: FontWeightConstants.medium,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 26.w),
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: label,
            fontSize: FontConstants.font_13,
            weight: FontWeightConstants.regular,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isSending = true;
        });

        await _sendMessageApi('', attachment: File(image.path));

        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withReadStream: false,
      );

      final path = result?.files.single.path;
      if (path != null) {
        setState(() {
          _isSending = true;
        });

        await _sendMessageApi('', attachment: File(path));

        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
    }
  }

  // ==================== END CHAT ====================

  Future<void> _endChat() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('💬 Ending Chat Session');
    debugPrint('   Appointment ID: ${widget.appointmentId}');
    debugPrint('   Chat duration: ${_formatDuration(_chatDuration)}');
    debugPrint(
      '   Coins used: ${(_initialCoins - _coinsLeft).toStringAsFixed(2)}',
    );
    debugPrint('═══════════════════════════════════════');

    // COUNSELOR: Send end_time API when counselor leaves
    if (!_isCounselor) {
      await _sendEndTimeApi();
    }

    // Stop all timers
    _stopChatTimer();
    _stopCoinDeduction();
    _stopCoinUpdateApiTimer();
    _stopAppointmentStatusPolling();
    _stopSessionEndedPolling();
    _messageFetchTimer?.cancel();

    // Call complete-appointment API only for users (not counselors)
    if (!_isCounselor) {
      // Send a system message to notify counselor that user has ended
      await _sendSessionEndedMessage();
      await _completeAppointmentApi();

      // Show rating dialog for users (only for consult_now type)
      if (_appointmentType == 'consult_now' &&
          widget.appointmentId != null &&
          widget.counselorId != null) {
        debugPrint('✅ Chat session ended - showing rating dialog');

        // Show rating dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => CallRatingDialog(
                appointmentId: widget.appointmentId!,
                counselorId: widget.counselorId!,
                counselorName: widget.counselorName,
                callDuration: _chatDuration,
              ),
        );

        // Navigate back to previous screen after rating dialog closes
        debugPrint('✅ Chat session ended successfully');
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    debugPrint('✅ Chat session ended successfully');

    Get.back();
  }

  // Send a system message when user ends the chat
  Future<void> _sendSessionEndedMessage() async {
    if (widget.appointmentId == null) return;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return;

      debugPrint('📤 USER: Sending session ended message...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndPoints.BASE_URL}messages'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['appointment_id'] = widget.appointmentId.toString();
      request.fields['message'] = '[SESSION_ENDED_BY_USER]';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Session ended message sent successfully');
      } else {
        debugPrint('❌ Failed to send session ended message: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending session ended message: $e');
    }
  }

  // Complete appointment API - called when user ends chat
  Future<void> _completeAppointmentApi() async {
    if (widget.appointmentId == null || widget.counselorId == null) {
      debugPrint(
        '⚠️ Missing appointment_id or counselor_id for complete-appointment API',
      );
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

  /// Check if appointment's counselor_status is pending
  Future<bool> _isCounselorStatusPending() async {
    if (widget.appointmentId == null) return false;

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) return false;

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
              debugPrint('⏱️ Counselor status check timeout');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          dynamic appointmentData;

          if (data['data'] is List) {
            final appointments = data['data'] as List;
            final targetAppointment = appointments.firstWhere(
              (apt) => apt['id'] == widget.appointmentId,
              orElse: () => null,
            );
            if (targetAppointment == null) return false;
            appointmentData = targetAppointment;
          } else {
            appointmentData = data['data'];
          }

          final counselorStatus = appointmentData['counselor_status'];
          final isPending =
              counselorStatus != null &&
              counselorStatus.toString().toLowerCase() == 'pending';

          debugPrint(
            '🔍 Checking counselor status: $counselorStatus (isPending: $isPending)',
          );
          return isPending;
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking counselor status: $e');
    }
    return false;
  }

  void _showEndChatConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: CustomText(
              text: "End Chat?".tr,
              fontSize: FontConstants.font_18,
              weight: FontWeightConstants.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black87,
            ),
            content: CustomText(
              text: "Are you sure you want to end this chat session?".tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Get.isDarkMode ? Colors.white : Colors.black54,
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
                  Get.back();
                  _endChat();
                },
                child: CustomText(
                  text: "End Chat".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
    );
  }

  // ==================== WARNING DIALOGS ====================

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
                  "You don't have enough coins for this chat. Please recharge."
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

  // Handle session ended smoothly - navigate back first, then show rating
  Future<void> _handleSessionEnded() async {
    // For users, navigate back smoothly and show rating dialog on previous screen
    if (!_isCounselor &&
        _appointmentType == 'consult_now' &&
        widget.appointmentId != null &&
        widget.counselorId != null) {
      // Store data before disposing
      final appointmentId = widget.appointmentId!;
      final counselorId = widget.counselorId!;
      final counselorName = widget.counselorName;
      final chatDuration = _chatDuration;

      // Complete appointment API in background (don't await)
      _completeAppointmentApi();

      // Stop all timers
      _stopChatTimer();
      _stopCoinDeduction();
      _stopCoinUpdateApiTimer();
      _stopAppointmentStatusPolling();
      _stopSessionEndedPolling();
      _messageFetchTimer?.cancel();

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
          callDuration: chatDuration,
        ),
        barrierDismissible: false,
      );

      return;
    }

    // For counselors, just end chat silently and navigate back
    await _endChatSilently();
  }

  // End chat silently (used when other user ends the session)
  Future<void> _endChatSilently() async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('💬 Ending Chat Session (triggered by other user)');
    debugPrint('   Appointment ID: ${widget.appointmentId}');
    debugPrint('   Chat duration: ${_formatDuration(_chatDuration)}');
    debugPrint('   Is Counselor: $_isCounselor');
    debugPrint('   Appointment Type: $_appointmentType');
    debugPrint('═══════════════════════════════════════');

    // COUNSELOR: Send end_time API when user ends the chat
    if (_isCounselor && _appointmentType == 'consult_now') {
      debugPrint('👨‍⚕️ COUNSELOR: Sending end_time API (user ended chat)...');
      //   await _sendEndTimeApi();
    }

    // Stop all timers
    _stopChatTimer();
    _stopCoinDeduction();
    _stopCoinUpdateApiTimer();
    _stopAppointmentStatusPolling();
    _stopSessionEndedPolling();
    _messageFetchTimer?.cancel();

    debugPrint('✅ Chat session ended (triggered by other user)');

    Get.back();
  }

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

  void _showLessMinuteWarning() {
    Get.snackbar(
      '⚠️ Chat Ending Soon'.tr,
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

  void _handleOutOfCoins() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(Icons.money_off, color: Colors.red, size: 28.w),
                SizedBox(width: 10.w),
                CustomText(
                  text: "Out of Coins".tr,
                  fontSize: FontConstants.font_18,
                  weight: FontWeightConstants.bold,
                  color: Colors.red,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: "Your coins have run out. The chat will end now.".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.regular,
                  color: Colors.black54,
                  align: TextAlign.center,
                ),
                UIHelper.verticalSpaceSm,
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: "Chat Duration:".tr,
                        fontSize: FontConstants.font_13,
                        weight: FontWeightConstants.medium,
                        color: Colors.black54,
                      ),
                      CustomText(
                        text: _formatDuration(_chatDuration),
                        fontSize: FontConstants.font_13,
                        weight: FontWeightConstants.bold,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: "Coins Used:".tr,
                        fontSize: FontConstants.font_13,
                        weight: FontWeightConstants.medium,
                        color: Colors.black54,
                      ),
                      CustomText(
                        text: "$_initialCoins",
                        fontSize: FontConstants.font_13,
                        weight: FontWeightConstants.bold,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  _endChat();
                },
                child: CustomText(
                  text: "OK".tr,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
    );
  }

  // ==================== HELPER METHODS ====================

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatMessageTime(DateTime timestamp) {
    return DateFormat('h:mm a').format(timestamp);
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Today";
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return "Yesterday";
    } else {
      return DateFormat('M/d/yyyy').format(date);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Show full screen image viewer
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Full screen image
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: Get.width,
                    height: Get.height,
                    color: Colors.black.withOpacity(0.9),
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.white54,
                                    size: 64.w,
                                  ),
                                  SizedBox(height: 16.h),
                                  CustomText(
                                    text: "Failed to load image",
                                    fontSize: FontConstants.font_16,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 50.h,
                  right: 20.w,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24.w),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Build file attachment widget for non-image files
  Widget _buildFileAttachment(String fileUrl, bool isMyMessage) {
    final fileName = fileUrl.split('/').last;
    final extension = fileName.split('.').last.toUpperCase();

    return GestureDetector(
      onTap: () => _openFile(fileUrl),
      child: Container(
        width: Get.width * 0.65,
        padding: EdgeInsets.all(12.w),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color:
                    isMyMessage
                        ? Colors.white.withOpacity(0.2)
                        : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getFileIcon(extension),
                color: isMyMessage ? Colors.white : primaryColor,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text:
                        fileName.length > 20
                            ? '${fileName.substring(0, 17)}...'
                            : fileName,
                    fontSize: FontConstants.font_13,
                    weight: FontWeightConstants.medium,
                    color: isMyMessage ? Colors.white : Colors.black87,
                  ),
                  SizedBox(height: 2.h),
                  CustomText(
                    text: '$extension File',
                    fontSize: FontConstants.font_11,
                    weight: FontWeightConstants.regular,
                    color: isMyMessage ? Colors.white70 : Colors.grey[500],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: isMyMessage ? Colors.white70 : Colors.grey[400],
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  // Get appropriate icon for file type
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Open file in external browser/viewer
  Future<void> _openFile(String fileUrl) async {
    try {
      debugPrint('📂 Opening file: $fileUrl');
      final uri = Uri.parse(fileUrl);
      await UIHelper.launchInBrowser1(uri);
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      if (mounted) {
        Get.snackbar(
          'Error'.tr,
          'Could not open file'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3),
        );
      }
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // In view-only mode, allow back navigation
        if (widget.isViewOnly) {
          return true;
        }

        // Check if counselor_status is pending - if so, allow silent navigation
        final isPending = await _isCounselorStatusPending();
        if (isPending) {
          debugPrint(
            '✅ Counselor status is pending - allowing silent navigation',
          );
          return true; // Allow back navigation
        }

        // For active chat, show confirmation dialog
        _showEndChatConfirmation();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: _buildAppBar(),
        body:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                )
                : Stack(
                  children: [
                    // Main content column
                    Column(
                      children: [
                        // View only banner
                        if (widget.isViewOnly) _buildViewOnlyBanner(),

                        // Chat messages
                        Expanded(child: _buildMessagesList()),

                        // Message input (hidden in view-only mode)
                        if (!widget.isViewOnly) _buildMessageInput(),
                      ],
                    ),

                    // Floating coins widget and settings button (like video call screen)
                    if (!_isCounselor && !widget.isViewOnly)
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            children: [
                              _buildCoinsWidget(),
                              Spacer(),
                              widget.isTroat
                                  ? _buildSettingsButton()
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  // Floating coins widget (same as video call screen)
  Widget _buildCoinsWidget() {
    return CoinBalanceWidget(
      coinsLeft: _coinsLeft,
      estimatedMinutesLeft: _estimatedMinutesLeft,
      lowCoinsThreshold: LOW_COINS_THRESHOLD,
      isCounselor: _isCounselor,
    );
  }

  // Settings button (opens tarot reading webpage)
  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        _openTarotWebBrowser();
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
  void _openTarotWebBrowser() {
    late final WebViewController controller;

    // Use different URL based on user role

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
      enableDrag: false,
      builder:
          (context) => GestureDetector(
            onTap: () {},
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

  Widget _buildViewOnlyBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.blue.shade700, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomText(
              text: 'Viewing chat history - This conversation has ended'.tr,
              fontSize: FontConstants.font_13,
              weight: FontWeightConstants.medium,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.grey.withOpacity(0.3),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black87, size: 24.w),
        onPressed: () async {
          // In view-only mode, just go back without confirmation
          if (widget.isViewOnly) {
            Get.back();
            return;
          }

          // Check if counselor_status is pending - if so, silently navigate back
          final isPending = await _isCounselorStatusPending();
          if (isPending) {
            debugPrint(
              '✅ Counselor status is pending - navigating back silently',
            );
            Get.back();
            return;
          }

          // Otherwise, show confirmation dialog
          _showEndChatConfirmation();
        },
      ),
      centerTitle: true,
      title: Column(
        children: [
          CustomText(
            text: widget.counselorName,
            fontSize: FontConstants.font_18,
            weight: FontWeightConstants.semiBold,
            color: Colors.black87,
          ),
          SizedBox(height: 4.h),
          if (widget.isViewOnly)
            CustomText(
              text: "Chat History".tr,
              fontSize: FontConstants.font_13,
              weight: FontWeightConstants.regular,
              color: Colors.blue.shade700,
            )
          else if (_chatTimer != null && _chatTimer!.isActive)
            CustomText(
              text: _formatDuration(_chatDuration),
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.medium,
              color: Color(0xFF4CAF50),
            )
          else
            CustomText(
              text: _counselorStatus,
              fontSize: FontConstants.font_13,
              weight: FontWeightConstants.regular,
              color: _counselorHasJoined ? Color(0xFF4CAF50) : Colors.orange,
            ),
        ],
      ),
      actions: [
        // Show "End Chat" button for user side when not in view-only mode
        if (!widget.isViewOnly && !_isCounselor)
          IconButton(
            icon: Icon(Icons.close, color: Colors.black87, size: 24.w),
            tooltip: "End Chat".tr,
            onPressed: () async {
              // Check if counselor_status is pending - if so, silently navigate back
              final isPending = await _isCounselorStatusPending();
              if (isPending) {
                debugPrint(
                  '✅ Counselor status is pending - navigating back silently',
                );
                Get.back();
                return;
              }

              // Otherwise, show confirmation dialog
              _showEndChatConfirmation();
            },
          ),
        // IconButton(
        //   icon: Icon(Icons.person_outline, color: Colors.black87, size: 24.w),
        //   onPressed: () {
        //     // Show profile
        //   },
        // ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.w,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: "No messages yet".tr,
              fontSize: FontConstants.font_16,
              weight: FontWeightConstants.medium,
              color: Colors.grey[500],
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: "Start the conversation!".tr,
              fontSize: FontConstants.font_14,
              weight: FontWeightConstants.regular,
              color: Colors.grey[400],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDateSeparator =
            index == 0 ||
            !_isSameDay(_messages[index - 1].timestamp, message.timestamp);

        return Column(
          children: [
            if (showDateSeparator) _buildDateSeparator(message.timestamp),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: CustomText(
            text: _formatDateSeparator(date),
            fontSize: FontConstants.font_12,
            weight: FontWeightConstants.medium,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMyMessage =
        _isCounselor ? message.isFromCounselor : !message.isFromCounselor;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            // Other person's avatar with initials
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Color(0xFFE8E8E8),
              child: CustomText(
                text: _getInitials(message.senderName ?? widget.counselorName),
                fontSize: FontConstants.font_12,
                weight: FontWeightConstants.semiBold,
                color: Color(0xFF7C4DFF),
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.7),
                  decoration: BoxDecoration(
                    color: isMyMessage ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.r),
                      topRight: Radius.circular(18.r),
                      bottomLeft: Radius.circular(isMyMessage ? 18.r : 4.r),
                      bottomRight: Radius.circular(isMyMessage ? 4.r : 18.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show image/file attachment if exists
                      if (message.hasFile) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.r),
                            topRight: Radius.circular(18.r),
                            bottomLeft: Radius.circular(
                              message.text.isNotEmpty
                                  ? 0
                                  : (isMyMessage ? 18.r : 4.r),
                            ),
                            bottomRight: Radius.circular(
                              message.text.isNotEmpty
                                  ? 0
                                  : (isMyMessage ? 4.r : 18.r),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (message.isImage) {
                                _showFullScreenImage(message.fileUrl!);
                              } else {
                                _openFile(message.fileUrl!);
                              }
                            },
                            child:
                                message.isImage
                                    ? CachedNetworkImage(
                                      imageUrl: message.fileUrl!,
                                      width: Get.width * 0.65,
                                      height: 200.h,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: Get.width * 0.65,
                                            height: 200.h,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(primaryColor),
                                              ),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: Get.width * 0.65,
                                            height: 200.h,
                                            color: Colors.grey[200],
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[400],
                                                  size: 40.w,
                                                ),
                                                SizedBox(height: 8.h),
                                                CustomText(
                                                  text: "Failed to load image",
                                                  fontSize:
                                                      FontConstants.font_12,
                                                  color: Colors.grey[500],
                                                ),
                                              ],
                                            ),
                                          ),
                                    )
                                    : _buildFileAttachment(
                                      message.fileUrl!,
                                      isMyMessage,
                                    ),
                          ),
                        ),
                      ],
                      // Show text message if exists
                      if (message.text.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: CustomText(
                            text: message.text,
                            fontSize: FontConstants.font_14,
                            weight: FontWeightConstants.regular,
                            color: isMyMessage ? Colors.white : Colors.black87,
                          ),
                        ),
                      // If only file with no text, add some padding
                      if (message.hasFile && message.text.isEmpty)
                        SizedBox(height: 0),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                // Time and Read status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: _formatMessageTime(message.timestamp),
                      fontSize: FontConstants.font_11,
                      weight: FontWeightConstants.regular,
                      color: Colors.grey[500],
                    ),
                    if (isMyMessage && message.isRead) ...[
                      SizedBox(width: 4.w),
                      CustomText(
                        text: "Read",
                        fontSize: FontConstants.font_11,
                        weight: FontWeightConstants.regular,
                        color: Colors.grey[500],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    // 🔥 CONDITION 1: If appointment is finished (status = "confirmed"), hide input
    if (_appointmentFinished) {
      debugPrint('❌ Message input HIDDEN: Appointment is finished (confirmed)');
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Center(
          child: CustomText(
            text: "This conversation has ended".tr,
            fontSize: FontConstants.font_14,
            weight: FontWeightConstants.medium,
            color: Colors.grey[600]!,
          ),
        ),
      );
    }

    // 🔥 CONDITION 2: Enable input when BOTH conditions are true:
    // 1. Counselor has joined (_counselorHasJoined)
    // 2. Chat session has started (_chatStarted)
    final bool canSendMessages = _counselorHasJoined && _chatStarted;

    // Debug every rebuild
    if (!canSendMessages) {
      debugPrint('❌ Message input DISABLED:');
      debugPrint('   _counselorHasJoined: $_counselorHasJoined');
      debugPrint('   _chatStarted: $_chatStarted');
    } else {
      debugPrint('✅ Message input ENABLED');
    }

    return !canSendMessages
        ? Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomText(
                  text: _counselorStatus,
                  fontSize: FontConstants.font_14,
                  weight: FontWeightConstants.medium,
                  color: primaryColor,
                  align: TextAlign.center,
                ),
              ),
            ],
          ),
        )
        : Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment button
                GestureDetector(
                  onTap: _showAttachmentOptions,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.attach_file,
                      color: Colors.grey[600],
                      size: 22.w,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(7.w),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: FontConstants.font_14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.w),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Send button
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey[400] : primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        _isSending
                            ? Padding(
                              padding: EdgeInsets.all(12.w),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Icons.send, color: Colors.white, size: 22.w),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class ChatMessage {
  final int? id;
  final String text;
  final bool isFromCounselor;
  final DateTime timestamp;
  final String? senderName;
  final String? senderImage;
  final bool isRead;
  final String? fileUrl;

  ChatMessage({
    this.id,
    required this.text,
    required this.isFromCounselor,
    required this.timestamp,
    this.senderName,
    this.senderImage,
    this.isRead = false,
    this.fileUrl,
  });

  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;

  bool get isImage {
    if (!hasFile) return false;
    final lowerUrl = fileUrl!.toLowerCase();
    return lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp');
  }
}
