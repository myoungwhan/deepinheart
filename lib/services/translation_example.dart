// ========================================
// TRANSLATION SERVICE USAGE EXAMPLES
// ========================================

// ignore_for_file: unused_local_variable, dead_code

import 'package:flutter/material.dart';
import 'translation_service.dart';
import 'translation_helper.dart';

/// This file contains examples of how to use the Translation Service
/// DO NOT import this file in your actual code - it's for reference only

class TranslationExamples {
  // ==================== BASIC USAGE ====================

  /// Example 1: Initialize translation service (do this in main.dart or splash screen)
  Future<void> example1_Initialize() async {
    // Initialize once when app starts
    final success = await translationService.initialize();

    if (success) {
      print('Translation service ready');

      // Optionally download model in advance
      await translationService.downloadModel();
    }
  }

  /// Example 2: Translate a single string
  Future<void> example2_TranslateSingleString() async {
    String koreanText = "프로필이 업데이트되었습니다";
    String translated = await translationService.translate(koreanText);
    print('Translated: $translated'); // Output: "Profile updated successfully"
  }

  /// Example 3: Using extension method
  Future<void> example3_ExtensionMethod() async {
    String koreanText = "안녕하세요";
    String translated = await koreanText.translateML();
    print('Translated: $translated'); // Output: "Hello"
  }

  /// Example 4: Translate multiple strings
  Future<void> example4_TranslateBatch() async {
    List<String> koreanTexts = ["일반", "기술", "결제", "불만사항"];

    List<String> translated = await translationService.translateBatch(
      koreanTexts,
    );
    print(
      'Translated: $translated',
    ); // Output: ["General", "Technical", "Billing", "Complaint"]
  }

  // ==================== API RESPONSE TRANSLATION ====================

  /// Example 5: Translate simple API response
  Future<void> example5_TranslateApiResponse() async {
    // Simulate API response
    final apiResponse = {
      'success': true,
      'message': '프로필이 성공적으로 업데이트되었습니다',
      'data': {'id': 1, 'name': 'John'},
    };

    // Translate message field
    final translated = await translationService.translateResponse(apiResponse);
    print('Translated message: ${translated['message']}');
    // Output: "Profile updated successfully"
  }

  /// Example 6: Translate error response
  Future<void> example6_TranslateErrorResponse() async {
    final errorResponse = {'success': false, 'error': '닉네임은 필수입니다'};

    // Translate error field
    final translated = await translationService.translateResponse(
      errorResponse,
      fieldsToTranslate: ['error'],
    );
    print('Translated error: ${translated['error']}');
    // Output: "Nickname is required"
  }

  /// Example 7: Translate nested API response
  Future<void> example7_TranslateNestedResponse() async {
    final nestedResponse = {
      'success': true,
      'data': [
        {'id': 1, 'title': '공지사항', 'content': '새로운 기능이 추가되었습니다'},
        {'id': 2, 'title': '이벤트', 'content': '할인 이벤트 진행중'},
      ],
    };

    // Translate all title and content fields
    final translated = await translationService.translateNestedResponse(
      nestedResponse,
      fieldsToTranslate: ['title', 'content'],
    );

    print('Translated data: $translated');
    // Output: All titles and contents will be translated
  }

  // ==================== PRACTICAL EXAMPLES ====================

  /// Example 8: Use in edit_profile_dialog.dart
  Future<void> example8_InEditProfileDialog(Map<String, dynamic> result) async {
    if (result['success'] == true) {
      // Translate success message
      final message = await translationService.translate(
        result['message'] ?? 'Profile updated successfully',
      );

      // Show snackbar with translated message
      // Get.snackbar('Success'.tr, message);
    } else {
      // Translate error message
      String errorMessage = result['message'] ?? 'Failed to update profile';
      final translated = await translationService.translate(errorMessage);

      // Get.snackbar('Error'.tr, translated);
    }
  }

  /// Example 9: Use with TranslationHelper
  Future<void> example9_UseTranslationHelper(
    Map<String, dynamic> apiError,
  ) async {
    // Simple error translation
    final errorMessage = await TranslationHelper.translateError(apiError);
    print('Error: $errorMessage');

    // Simple success translation
    final successMessage = await TranslationHelper.translateSuccess({
      'message': '성공',
    });
    print('Success: $successMessage');
  }

  /// Example 10: Translate validation errors
  Future<void> example10_ValidationErrors(Map<String, dynamic> errors) async {
    // errors = {
    //   'email': ['이메일이 유효하지 않습니다'],
    //   'password': ['비밀번호는 8자 이상이어야 합니다', '특수문자를 포함해야 합니다']
    // }

    final translated = await TranslationHelper.translateValidationErrors(
      errors,
    );
    print('Translated errors: $translated');

    // Or format as single string
    final formatted = await TranslationHelper.formatValidationErrors(errors);
    print('Formatted: $formatted');
  }

  /// Example 11: Show translated snackbar
  Future<void> example11_ShowSnackbar(BuildContext context) async {
    await TranslationHelper.showTranslatedSnackbar(
      context,
      message: '프로필이 업데이트되었습니다',
      isError: false,
    );
  }

  /// Example 12: Translate dropdown items
  Future<void> example12_TranslateDropdownItems() async {
    final koreanItems = ['일반', '기술', '결제', '불만사항'];
    final translatedItems = await TranslationHelper.translateList(koreanItems);

    // Use translatedItems in your dropdown
    // DropdownButton<String>(items: translatedItems.map((item) => ...))
  }

  // ==================== ADVANCED USAGE ====================

  /// Example 13: Handle locale changes
  Future<void> example13_HandleLocaleChange() async {
    // When user changes language, reinitialize translation service
    await translationService.onLocaleChange();

    print('Translation service reinitialized for new locale');
  }

  /// Example 14: Check if translation is needed
  Future<void> example14_CheckIfNeeded() async {
    if (translationService.needsTranslation) {
      print(
        'Translation needed: ${translationService.sourceLanguageName} → ${translationService.targetLanguageName}',
      );
    } else {
      print('No translation needed - same language');
    }
  }

  /// Example 15: Manual model management
  Future<void> example15_ModelManagement() async {
    // Check if initialized
    if (!translationService.isInitialized) {
      await translationService.initialize();
    }

    // Check if model is downloaded
    if (!translationService.isModelDownloaded) {
      print('Downloading translation model...');
      await translationService.downloadModel();
    }

    // Delete model to free space (optional)
    // await translationService.deleteModel();
  }

  /// Example 16: Complete implementation in API call
  Future<Map<String, dynamic>> example16_CompleteApiCall() async {
    try {
      // 1. Make API call (example)
      // final response = await http.post(...);
      // final data = jsonDecode(response.body);

      final data = {
        'success': false,
        'message': '닉네임은 필수입니다',
        'errors': {
          'nickname': ['닉네임은 필수입니다'],
          'phone': ['전화번호 형식이 올바르지 않습니다'],
        },
      };

      // 2. Translate response
      final translated = await translationService.translateNestedResponse(
        data,
        fieldsToTranslate: ['message', 'error'],
      );

      // 3. Translate validation errors if present
      if (translated['errors'] != null) {
        final errorMessage = await TranslationHelper.formatValidationErrors(
          translated['errors'],
        );
        translated['formatted_errors'] = errorMessage;
      }

      return translated;
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'An error occurred'};
    }
  }

  // ==================== INTEGRATION WITH YOUR CODE ====================

  /// Example 17: Modify _extractErrorMessage in edit_profile_dialog.dart
  Future<String> example17_ExtractErrorMessageWithTranslation(
    Map<String, dynamic> result,
  ) async {
    try {
      // First, extract error message (your existing logic)
      String errorMessage = 'Failed to update profile';

      if (result['message'] != null) {
        final message = result['message'];
        if (message is String) {
          errorMessage = message;
        } else if (message is Map<String, dynamic>) {
          List<String> errorMessages = [];
          message.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else if (value is String) {
              errorMessages.add(value);
            }
          });
          errorMessage =
              errorMessages.isNotEmpty
                  ? errorMessages.join('\n')
                  : 'Failed to update profile';
        }
      }

      // Then, translate it
      final translated = await translationService.translate(errorMessage);
      return translated;
    } catch (e) {
      return 'Failed to update profile';
    }
  }
}

// ==================== INITIALIZATION IN MAIN.DART ====================

/// Add this to your main.dart file:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize translation service
///   await translationService.initialize();
///   
///   runApp(MyApp());
/// }
/// ```

// ==================== HANDLE LOCALE CHANGES ====================

/// In your locale_controller.dart, add this to changeLocale method:
/// 
/// ```dart
/// void changeLocale(String lang) async {
///   final locale = _getLocaleFromLanguage(lang);
///   Get.updateLocale(locale);
///   
///   // Reinitialize translation service for new locale
///   await translationService.onLocaleChange();
///   
///   Get.back();
/// }
/// ```

