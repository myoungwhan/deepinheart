# Translation Service Documentation

## Overview
This custom translation service uses Google ML Kit Translation to automatically translate API responses based on the user's current locale.

## Features
- ✅ Automatic translation based on locale
- ✅ Translate single strings, lists, and nested JSON objects
- ✅ Easy-to-use helper methods
- ✅ Offline translation (after model download)
- ✅ Handles validation errors
- ✅ Extension methods for strings
- ✅ Integration with GetX locale management

## Quick Start

### 1. Initialize in main.dart

Add this to your `main()` function:

```dart
import 'package:deepinheart/services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize translation service
  await translationService.initialize();
  // Optionally download model in advance
  await translationService.downloadModel();
  
  runApp(MyApp());
}
```

### 2. Basic Usage

```dart
// Translate a single string
String korean = "프로필이 업데이트되었습니다";
String translated = await translationService.translate(korean);
// Result: "Profile updated successfully"

// Using extension method
String translated2 = await korean.translateML();
```

### 3. Translate API Responses

```dart
// Simple API response
final response = {
  'success': true,
  'message': '프로필이 성공적으로 업데이트되었습니다',
};

final translated = await translationService.translateResponse(response);
print(translated['message']); // "Profile updated successfully"

// Nested response (announcements, lists, etc.)
final nestedResponse = {
  'data': [
    {'title': '공지사항', 'content': '새로운 기능'},
    {'title': '이벤트', 'content': '할인 진행중'}
  ]
};

final translated = await translationService.translateNestedResponse(
  nestedResponse,
  fieldsToTranslate: ['title', 'content'],
);
```

### 4. Use Helper Methods

```dart
import 'package:deepinheart/services/translation_helper.dart';

// Translate error message
String error = await TranslationHelper.translateError(apiError);

// Show translated snackbar
await TranslationHelper.showTranslatedSnackbar(
  context,
  message: '프로필이 업데이트되었습니다',
  isError: false,
);

// Translate validation errors
final errors = {
  'email': ['이메일이 유효하지 않습니다'],
  'password': ['비밀번호가 너무 짧습니다']
};
String formattedError = await TranslationHelper.formatValidationErrors(errors);
```

## Integration Examples

### In edit_profile_dialog.dart

```dart
// Modify your _saveProfile method:
if (result['success'] == true) {
  // Translate success message
  final message = await translationService.translate(
    result['message'] ?? 'Profile updated successfully',
  );
  
  Get.snackbar('Success'.tr, message);
} else {
  // Use your existing error extraction
  String errorMessage = _extractErrorMessage(result);
  
  // Then translate it
  final translated = await translationService.translate(errorMessage);
  
  Get.snackbar('Error'.tr, translated);
}
```

### In any API call

```dart
Future<void> fetchData() async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    final data = jsonDecode(response.body);
    
    // Translate the response
    final translated = await TranslationHelper.translateApiResponse(data);
    
    // Use translated data
    if (translated['success']) {
      showMessage(translated['message']);
    }
  } catch (e) {
    // Handle error
  }
}
```

### Translate List Items (Dropdowns, etc.)

```dart
final koreanItems = ['일반', '기술', '결제', '불만사항'];
final translatedItems = await TranslationHelper.translateList(koreanItems);

// Use in DropdownButton
DropdownButton<String>(
  items: translatedItems.map((item) => 
    DropdownMenuItem(value: item, child: Text(item))
  ).toList(),
)
```

## Important Notes

### Translation Direction
By default, the service assumes:
- **Source Language**: Korean (KO) - API responses are in Korean
- **Target Language**: User's current locale

You can modify this in `translation_service.dart` by changing the `initialize()` method.

### Model Download
- The translation model is downloaded automatically on first use
- Models are stored on device for offline use
- You can pre-download with `translationService.downloadModel()`
- Delete model to free space: `translationService.deleteModel()`

### Performance
- First translation may take longer (model download)
- Subsequent translations are fast and offline
- Batch translations are more efficient than individual calls

### Error Handling
- Service gracefully falls back to original text if translation fails
- No translation is performed if source and target languages are the same
- Check `translationService.needsTranslation` to avoid unnecessary calls

## Advanced Usage

### Check Status

```dart
// Check if initialized
if (!translationService.isInitialized) {
  await translationService.initialize();
}

// Check if translation is needed
if (translationService.needsTranslation) {
  // Perform translation
}

// Check model status
if (translationService.isModelDownloaded) {
  print('Model ready for offline translation');
}
```

### Handle Locale Changes

Already integrated in `locale_controller.dart`:

```dart
void changeLocale(String lang) async {
  final locale = _getLocaleFromLanguage(lang);
  Get.updateLocale(locale);
  
  // Reinitialize translation service
  await translationService.onLocaleChange();
  
  Get.back();
}
```

### Cleanup

```dart
// When app is closing (optional)
await translationService.dispose();
```

## Supported Languages

The service supports translation to/from:
- Korean (ko)
- English (en)
- Japanese (ja)
- Chinese (zh)
- Spanish (es)
- French (fr)
- German (de)
- Arabic (ar)
- Hindi (hi)
- Portuguese (pt)
- Russian (ru)
- Italian (it)

## Files

1. **translation_service.dart** - Core translation service
2. **translation_helper.dart** - Helper methods and extensions
3. **translation_example.dart** - Usage examples (for reference only)
4. **README_TRANSLATION.md** - This documentation

## FAQ

**Q: Do I need internet connection?**
A: Only for the initial model download. After that, translations work offline.

**Q: How much space does the model take?**
A: Approximately 20-40 MB per language pair.

**Q: What if translation fails?**
A: The service returns the original text, so your app won't break.

**Q: Can I change the source language?**
A: Yes, modify the `_sourceLanguage` assignment in `initialize()` method.

**Q: Should I translate everything?**
A: No, only translate dynamic content from APIs. Static UI text should use GetX translations (.tr).

## Best Practices

1. ✅ Initialize once in main.dart
2. ✅ Use for dynamic API content only
3. ✅ Use `.tr` for static UI text
4. ✅ Batch translate lists when possible
5. ✅ Handle errors gracefully
6. ✅ Pre-download models for better UX
7. ❌ Don't translate every single string
8. ❌ Don't forget to update on locale change

## Support

For issues or questions, refer to:
- `translation_example.dart` - Comprehensive examples
- Google ML Kit documentation: https://developers.google.com/ml-kit/language/translation

