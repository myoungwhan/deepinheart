import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'translation_service.dart';

/// Extension methods for easy translation
extension TranslationExtension on String {
  /// Translate this string using TranslationService
  ///
  /// Usage:
  /// ```dart
  /// String koreanText = "안녕하세요";
  /// String translated = await koreanText.translateML();
  /// ```
  Future<String> translateML() async {
    return await translationService.translate(this);
  }
}

/// Helper class with common translation patterns
class TranslationHelper {
  /// Translate error message from API
  ///
  /// Usage:
  /// ```dart
  /// final errorMessage = await TranslationHelper.translateError(apiError);
  /// ```
  static Future<String> translateError(dynamic error) async {
    if (error == null) return 'An error occurred'.tr;

    String errorText;
    if (error is String) {
      errorText = error;
    } else if (error is Map) {
      errorText =
          error['message']?.toString() ??
          error['error']?.toString() ??
          'An error occurred'.tr;
    } else {
      errorText = error.toString();
    }

    // Try to translate

    final translated = await translationService.translate(errorText);
    print('translated: $translated');
    print('errorText: $errorText');
    return translated;
  }

  /// Translate success message from API
  ///
  /// Usage:
  /// ```dart
  /// final successMessage = await TranslationHelper.translateSuccess(apiResponse);
  /// ```
  static Future<String> translateSuccess(dynamic response) async {
    if (response == null) return 'Success'.tr;

    String successText;
    if (response is String) {
      successText = response;
    } else if (response is Map) {
      successText = response['message']?.toString() ?? 'Success'.tr;
    } else {
      successText = response.toString();
    }

    // Try to translate
    final translated = await translationService.translate(successText);
    return translated;
  }

  /// Show translated snackbar
  ///
  /// Usage:
  /// ```dart
  /// await TranslationHelper.showTranslatedSnackbar(
  ///   context,
  ///   message: '프로필이 업데이트되었습니다',
  ///   isError: false,
  /// );
  /// ```
  static Future<void> showTranslatedSnackbar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final translatedMessage = await translationService.translate(message);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translatedMessage),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: duration,
        ),
      );
    }
  }

  /// Translate list of items (useful for dropdowns, lists, etc.)
  ///
  /// Usage:
  /// ```dart
  /// final items = ['항목1', '항목2', '항목3'];
  /// final translated = await TranslationHelper.translateList(items);
  /// ```
  static Future<List<String>> translateList(List<String> items) async {
    return await translationService.translateBatch(items);
  }

  /// Translate API response with common fields
  /// Automatically detects and translates message, error, description fields
  ///
  /// Usage:
  /// ```dart
  /// final response = await http.get(...);
  /// final jsonData = jsonDecode(response.body);
  /// final translatedData = await TranslationHelper.translateApiResponse(jsonData);
  /// ```
  static Future<Map<String, dynamic>> translateApiResponse(
    Map<String, dynamic> response,
  ) async {
    return await translationService.translateResponse(response);
  }

  /// Translate validation errors (handles multiple error messages)
  ///
  /// Usage:
  /// ```dart
  /// final errors = {
  ///   'email': ['이메일이 유효하지 않습니다'],
  ///   'password': ['비밀번호는 8자 이상이어야 합니다']
  /// };
  /// final translated = await TranslationHelper.translateValidationErrors(errors);
  /// ```
  static Future<Map<String, List<String>>> translateValidationErrors(
    Map<String, dynamic> errors,
  ) async {
    final translatedErrors = <String, List<String>>{};

    for (final entry in errors.entries) {
      if (entry.value is List) {
        final errorList = entry.value as List;
        final translatedList = await translationService.translateBatch(
          errorList.map((e) => e.toString()).toList(),
        );
        translatedErrors[entry.key] = translatedList;
      } else if (entry.value is String) {
        final translated = await translationService.translate(entry.value);
        translatedErrors[entry.key] = [translated];
      }
    }

    return translatedErrors;
  }

  /// Format and translate validation errors to a single string
  ///
  /// Usage:
  /// ```dart
  /// final errors = {'email': ['Invalid email'], 'password': ['Too short']};
  /// final message = await TranslationHelper.formatValidationErrors(errors);
  /// // Returns: "email: Invalid email\npassword: Too short"
  /// ```
  static Future<String> formatValidationErrors(
    Map<String, dynamic> errors,
  ) async {
    final translated = await translateValidationErrors(errors);
    final messages = <String>[];

    translated.forEach((field, errorList) {
      messages.addAll(errorList);
    });

    return messages.join('\n');
  }
}
