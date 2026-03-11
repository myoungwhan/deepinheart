# Translation Service - Quick Start Guide

## ✅ Already Done
1. ✅ Translation service created
2. ✅ Integrated with `locale_controller.dart`
3. ✅ Initialized in `main.dart`
4. ✅ Helper methods created

## 🚀 How to Use

### Simple Example - Translate API Error Message

```dart
// In edit_profile_dialog.dart or any file
import 'package:deepinheart/services/translation_service.dart';

// When you get an error from API
if (result['success'] == false) {
  String errorMessage = result['message'] ?? 'Failed to update profile';
  
  // Translate it
  String translated = await translationService.translate(errorMessage);
  
  // Show to user
  Get.snackbar('Error'.tr, translated);
}
```

### Example - Translate Success Message

```dart
if (result['success'] == true) {
  String successMessage = result['message'] ?? 'Success';
  
  // Translate it
  String translated = await translationService.translate(successMessage);
  
  Get.snackbar('Success'.tr, translated);
}
```

### Example - Translate Entire API Response

```dart
import 'package:deepinheart/services/translation_service.dart';

// After getting API response
final response = await http.post(...);
final data = jsonDecode(response.body);

// Translate message field automatically
final translated = await translationService.translateResponse(data);

// Now use translated['message']
if (translated['success']) {
  Get.snackbar('Success'.tr, translated['message']);
}
```

### Example - Using Helper (Easiest Way)

```dart
import 'package:deepinheart/services/translation_helper.dart';

// Translate error
String error = await TranslationHelper.translateError(apiResponse);
Get.snackbar('Error'.tr, error);

// Translate success
String success = await TranslationHelper.translateSuccess(apiResponse);
Get.snackbar('Success'.tr, success);

// Show translated snackbar (all in one)
await TranslationHelper.showTranslatedSnackbar(
  context,
  message: '프로필이 업데이트되었습니다',
  isError: false,
);
```

### Example - Extension Method (Shortest Way)

```dart
import 'package:deepinheart/services/translation_helper.dart';

String korean = "프로필이 업데이트되었습니다";
String translated = await korean.translateML();
print(translated); // "Profile updated successfully"
```

## 📝 Real Implementation Example

### Before (Without Translation)
```dart
if (result['success'] == true) {
  Get.snackbar('Success'.tr, result['message'] ?? 'Profile updated');
} else {
  Get.snackbar('Error'.tr, result['message'] ?? 'Failed');
}
```

### After (With Translation)
```dart
if (result['success'] == true) {
  final message = await translationService.translate(
    result['message'] ?? 'Profile updated',
  );
  Get.snackbar('Success'.tr, message);
} else {
  final error = await translationService.translate(
    result['message'] ?? 'Failed',
  );
  Get.snackbar('Error'.tr, error);
}
```

### Or Even Simpler (Using Helper)
```dart
if (result['success'] == true) {
  final message = await TranslationHelper.translateSuccess(result);
  Get.snackbar('Success'.tr, message);
} else {
  final error = await TranslationHelper.translateError(result);
  Get.snackbar('Error'.tr, error);
}
```

## 🎯 Where to Use

Use translation service for:
- ✅ API error messages
- ✅ API success messages
- ✅ Dynamic content from server
- ✅ Announcements
- ✅ Notifications
- ✅ Validation errors from server

Do NOT use for:
- ❌ Static UI text (use `.tr` instead)
- ❌ Button labels (use `.tr` instead)
- ❌ Screen titles (use `.tr` instead)

## 💡 Pro Tips

1. **Check if translation is needed:**
```dart
if (translationService.needsTranslation) {
  // Only translate if user's language is different from Korean
  translated = await translationService.translate(text);
} else {
  translated = text; // No need to translate
}
```

2. **Translate multiple items at once:**
```dart
List<String> items = ['항목1', '항목2', '항목3'];
List<String> translated = await translationService.translateBatch(items);
```

3. **Translate nested API response:**
```dart
final response = {
  'data': [
    {'title': '공지', 'content': '내용'},
    {'title': '이벤트', 'content': '할인'}
  ]
};

final translated = await translationService.translateNestedResponse(
  response,
  fieldsToTranslate: ['title', 'content'],
);
```

## 🔧 Troubleshooting

**Q: Translation not working?**
A: Make sure service is initialized in `main.dart` (already done ✅)

**Q: First translation is slow?**
A: Normal! Model is downloading. Subsequent translations are fast.

**Q: Want to pre-download model?**
A: Uncomment this line in `main.dart`:
```dart
await translationService.downloadModel();
```

**Q: How to check if model is downloaded?**
```dart
if (translationService.isModelDownloaded) {
  print('Ready for offline translation');
}
```

## 📚 More Examples

See `translation_example.dart` for 17 detailed examples!
See `README_TRANSLATION.md` for complete documentation!

## 🎉 That's It!

You can now easily translate API responses in your app!

