import 'dart:convert';
import 'package:deepinheart/Controller/Model/notification_model.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  DateTime? _lastFetchTime;
  Future<void>? _currentFetchFuture;
  static const Duration _minFetchInterval = Duration(seconds: 2);

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  /// Fetch notifications from API
  Future<void> fetchNotifications(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    // Prevent duplicate calls - if already loading, return the existing future
    if (_isLoading && _currentFetchFuture != null && !forceRefresh) {
      debugPrint(
        '📢 fetchNotifications: Already loading, returning existing future',
      );
      return _currentFetchFuture!;
    }

    // Prevent too frequent calls - check minimum interval
    if (!forceRefresh && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        debugPrint(
          '📢 fetchNotifications: Too soon since last fetch (${timeSinceLastFetch.inSeconds}s), skipping',
        );
        return;
      }
    }

    // If we have data and it's not a forced refresh, skip if recently fetched
    if (!forceRefresh && _notifications.isNotEmpty && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        debugPrint(
          '📢 fetchNotifications: Recent data available, skipping unnecessary call',
        );
        return;
      }
    }

    try {
      // Create and store the future to prevent duplicate calls
      _currentFetchFuture = _performFetch(context);
      await _currentFetchFuture;
    } finally {
      _currentFetchFuture = null;
    }
  }

  /// Internal method to perform the actual API call
  Future<void> _performFetch(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _lastFetchTime = DateTime.now();

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No authentication token found';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndPoints.NOTIFICATIONS),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationResponse = NotificationResponse.fromJson(data);

        if (notificationResponse.success) {
          setState(() {
            _notifications = notificationResponse.data;
            _unreadCount = _notifications.where((n) => !n.isRead).length;
            _isLoading = false;
          });
          debugPrint(
            '📢 fetchNotifications: Successfully fetched ${_notifications.length} notifications',
          );
        } else {
          setState(() {
            _error = notificationResponse.message;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch notifications';
          _isLoading = false;
        });
        // Only show error flash if we don't have existing data
        if (_notifications.isEmpty) {
          UIHelper.showBottomFlash(
            context,
            title: 'Error',
            message: 'Failed to fetch notifications',
            isError: true,
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      // Only show error flash if we don't have existing data
      if (_notifications.isEmpty) {
        UIHelper.showBottomFlash(
          context,
          title: 'Error',
          message: 'Error: ${e.toString()}',
          isError: true,
        );
      }
      debugPrint('📢 fetchNotifications: Error - $e');
    }
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(BuildContext context, String notificationId) async {
    print(notificationId.toString() + "notificationId");
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiEndPoints.NOTIFICATION_READ}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      print(data.toString() + response.request.toString());

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          // Update local state immediately for instant UI feedback
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1) {
            final notification = _notifications[index];
            final updatedNotification = NotificationItem(
              id: notification.id,
              notificationData: notification.notificationData,
              readAt: DateTime.now().toIso8601String(),
              createdAt: notification.createdAt,
              type: notification.type,
            );
            setState(() {
              _notifications[index] = updatedNotification;
              _unreadCount = _notifications.where((n) => !n.isRead).length;
            });
          }

          // Refresh from API silently to ensure consistency
          await refreshNotificationsSilently(context);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(BuildContext context) async {
    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiEndPoints.NOTIFICATION_READ_ALL),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local state immediately for instant UI feedback
          final now = DateTime.now().toIso8601String();
          setState(() {
            _notifications =
                _notifications.map((notification) {
                  return NotificationItem(
                    id: notification.id,
                    notificationData: notification.notificationData,
                    readAt: now,
                    createdAt: notification.createdAt,
                    type: notification.type,
                  );
                }).toList();
            _unreadCount = 0;
          });

          // Refresh from API silently to ensure consistency
          await refreshNotificationsSilently(context);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Refresh notifications silently (without showing loading state)
  Future<void> refreshNotificationsSilently(BuildContext context) async {
    // Prevent silent refresh if already loading or too soon after last fetch
    if (_isLoading) {
      debugPrint('📢 refreshNotificationsSilently: Already loading, skipping');
      return;
    }

    if (_lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        debugPrint(
          '📢 refreshNotificationsSilently: Too soon since last fetch, skipping',
        );
        return;
      }
    }

    try {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        return;
      }

      _lastFetchTime = DateTime.now();

      final response = await http.get(
        Uri.parse(ApiEndPoints.NOTIFICATIONS),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notificationResponse = NotificationResponse.fromJson(data);

        if (notificationResponse.success) {
          setState(() {
            _notifications = notificationResponse.data;
            _unreadCount = _notifications.where((n) => !n.isRead).length;
          });
          debugPrint(
            '📢 refreshNotificationsSilently: Successfully refreshed ${_notifications.length} notifications',
          );
        }
      }
    } catch (e) {
      debugPrint('📢 refreshNotificationsSilently: Error - $e');
    }
  }

  /// Refresh notifications (force refresh)
  Future<void> refreshNotifications(BuildContext context) async {
    await fetchNotifications(context, forceRefresh: true);
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
