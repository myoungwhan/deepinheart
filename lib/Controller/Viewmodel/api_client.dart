import 'dart:convert';

import 'package:deepinheart/config/api_endpoints.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/main.dart';
import 'package:deepinheart/screens/auth/login_View.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  String baseUrl = ApiEndPoints.BASE_URL;

  // Main API request method
  Future<dynamic> request({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    BuildContext? context,
  }) async {
    // Default headers

    headers ??= {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'X-CSRF-TOKEN': '',
      'Authorization': 'Bearer ${await getToken()}',
    };

    try {
      // Make the API call based on the method
      http.Response response;

      switch (method.toUpperCase()) {
        case "GET":
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case "POST":
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case "PUT":
          response = await http.put(
            Uri.parse(baseUrl + url),
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case "DELETE":
          response = await http.delete(
            Uri.parse(baseUrl + url),
            headers: headers,
          );
          break;
        default:
          throw Exception("HTTP method not supported");
      }
      print(response.body.toString() + ",," + response.request!.url.toString());

      // Handle the response
      return _handleResponse(response, context);
    } catch (e) {
      debugPrint("Error in API request: $e");
      rethrow;
    }
  }

  Future<dynamic> requestMultiRequest({
    required String url,
    required String method,
    Map<String, String>? body,
    Map<String, String>? headers,
    Map<String, String>? files, // For handling multipart file uploads
    BuildContext? context,
  }) async {
    headers ??= {
      'accept': 'application/json',
      'X-CSRF-TOKEN': '',

      'Authorization': 'Bearer ${await getToken()}',
      // Remove Content-Type for multipart to avoid conflicts; it will be set automatically
    };

    try {
      // Handle multipart requests
      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (body != null) {
        request.fields.addAll(body);
      }
      if (files != null) {
        for (var entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              entry.value.toString(),
            ),
          );
        }
      }

      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      var res = await response.stream.bytesToString();
      print(res);
      return _handleMultipartResponse(response.statusCode, res, context);
    } catch (e) {
      debugPrint("Error in API request: $e");
      rethrow;
    }
  }

  // Handle responses for multipart requests
  dynamic _handleMultipartResponse(
    int statusCode,
    String responseBody,
    BuildContext? context,
  ) {
    print(statusCode.toString() + "*****");
    final body = jsonDecode(responseBody);

    if (statusCode == 200 || statusCode == 201 || statusCode == 404) {
      return body;
    } else if (statusCode == 401) {
      _handleUnauthorized(context);
    } else if (statusCode == 422) {
      // Handle validation errors
      print(body['message'].toString() + ">>>>>");

      throw ValidationException(
        message: 'Validation error',
        errors: Map<String, dynamic>.from(body['message'] ?? {}),
      );
    } else {
      throw Exception(body['message'] ?? 'Unknown error');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response, BuildContext? context) {
    final statusCode = response.statusCode;
    final body = jsonDecode(response.body);
    print(statusCode.toString() + "*****");

    if (statusCode == 200 || statusCode == 201 || statusCode == 404) {
      return body;
    } else if (statusCode == 401) {
      _handleUnauthorized(context);
    } else if (statusCode == 422) {
      // Handle validation errors

      throw ValidationException(
        message: 'Validation error',
        errors: Map<String, dynamic>.from(body['message'] ?? {}),
      );
    } else {
      throw Exception(body['message'] ?? 'Unknown error');
    }
  }

  // Handle unauthorized error
  void _handleUnauthorized(BuildContext? context) async {
    try {
      // Check if "Remember Me" is enabled
      final prefs = await SharedPreferences.getInstance();
      bool? rememberMe = prefs.getBool('remember_me');

      if (rememberMe == true) {
        // User has enabled "Remember Me", attempt to re-authenticate
        String? savedEmail = prefs.getString('saved_email');
        String? savedPassword = prefs.getString('saved_password');
        bool? savedIsRegularUser = prefs.getBool('saved_is_regular_user');

        if (savedEmail != null &&
            savedPassword != null &&
            savedIsRegularUser != null) {
          print("Token expired, attempting auto re-login with Remember Me");

          try {
            // Get UserViewModel and attempt re-authentication
            final userViewModel = Get.find<UserViewModel>();
            String role = savedIsRegularUser ? 'user' : 'counselor';

            // Attempt silent re-login (without showing login screen)
            BuildContext? loginContext = context ?? navigatorKey.currentContext;
            if (loginContext != null) {
              await userViewModel.loginUser(
                context: loginContext,
                role: role,
                email: savedEmail,
                password: savedPassword,
              );
            }

            print("Auto re-login successful after token expiration");
            // Re-authentication successful, user stays logged in
            return;
          } catch (e) {
            print("Auto re-login failed: $e");
            // Re-authentication failed, clear credentials and log out
            await prefs.remove('remember_me');
            await prefs.remove('saved_email');
            await prefs.remove('saved_password');
            await prefs.remove('saved_is_regular_user');
          }
        }
      }

      // If "Remember Me" is not enabled or re-authentication failed,
      // clear user session and navigate to login
      try {
        final userViewModel = Get.find<UserViewModel>();
        await userViewModel.clearUserModel();
      } catch (e) {
        print("Error clearing user model: $e");
        // Fallback: navigate to login screen directly
        if (context != null && context.mounted) {
          Get.offAll(SignInScreen());
        } else if (navigatorKey.currentContext != null) {
          Get.offAll(SignInScreen());
        }
      }
    } catch (e) {
      print("Error in _handleUnauthorized: $e");
      // Fallback: navigate to login screen on error
      if (context != null && context.mounted) {
        Get.offAll(SignInScreen());
      } else if (navigatorKey.currentContext != null) {
        Get.offAll(SignInScreen());
      }
    }
  }

  // Get token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Clear token from SharedPreferences
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}

// Custom exception class for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic> errors;

  ValidationException({required this.message, required this.errors});

  @override
  String toString() {
    return 'ValidationException: $message\nErrors: ${formatErrors(errors)}';
  }

  /// Formats the errors into a single readable string
  String formatErrors(Map<String, dynamic> errors) {
    return errors.entries
        .map(
          (entry) =>
              '${entry.key}: ${entry.value is List ? (entry.value as List).join(", ") : entry.value}',
        )
        .join(" | ");
  }
}
