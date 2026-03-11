import 'dart:convert';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/screens_consoler/chat/models/conversation_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ChatProvider extends ChangeNotifier {
  List<ConversationData> _conversations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ConversationData> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasConversations => _conversations.isNotEmpty;

  /// Fetch conversations from API
  Future<void> fetchConversations(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final token = userViewModel.userModel?.data.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      debugPrint('📱 Fetching conversations...');

      final response = await http.get(
        Uri.parse(ApiEndPoints.CONVERSATIONS),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversationsResponse = ConversationsResponse.fromJson(data);

        if (conversationsResponse.success) {
          _conversations = conversationsResponse.data;
          _error = null;
          debugPrint('✅ Fetched ${_conversations.length} conversations');
        } else {
          _error = conversationsResponse.message;
          debugPrint('❌ API error: $_error');
        }
      } else {
        _error = 'Failed to fetch conversations: ${response.statusCode}';
        debugPrint('❌ HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error fetching conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh conversations
  Future<void> refreshConversations(BuildContext context) async {
    await fetchConversations(context);
  }

  /// Get unread count
  int get unreadCount {
    return _conversations.where((c) => c.hasUnread).length;
  }

  /// Clear conversations
  void clear() {
    _conversations = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
