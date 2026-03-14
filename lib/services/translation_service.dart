import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Custom Translation Service using Google ML Kit Translation
/// Automatically translates API responses based on current locale
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  OnDeviceTranslator? _translator;
  TranslateLanguage? _sourceLanguage;
  TranslateLanguage? _targetLanguage;
  bool _isInitialized = false;
  bool _isModelDownloaded = false;

  // Translation cache to avoid re-translating the same text
  final Map<String, String> _translationCache = {};

  /// Initialize the translation service
  /// Call this once when app starts or when locale changes
  Future<bool> initialize() async {
    try {
      // Get current locale
      final currentLocale = Get.locale ?? const Locale('ko', 'KR');

      // Determine source and target languages
      // Assume API responses are in Korean, translate to user's locale
      _sourceLanguage = _getTranslateLanguage('en');
      _targetLanguage = _getTranslateLanguage(currentLocale.languageCode);

      // If target is same as source, no need to translate
      if (_sourceLanguage == _targetLanguage) {
        debugPrint('🌐 Translation: Source and target languages are the same');
        _isInitialized = true;
        return true;
      }

      // Create translator
      _translator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage!,
        targetLanguage: _targetLanguage!,
      );

      _isInitialized = true;
      debugPrint(
        '✅ Translation Service initialized: ${_sourceLanguage?.name} → ${_targetLanguage?.name}',
      );

      // Check if model is downloaded
      await _checkModelAvailability();

      return true;
    } catch (e) {
      debugPrint('❌ Translation Service initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Check if translation model is available
  Future<void> _checkModelAvailability() async {
    if (_translator == null) return;

    try {
      final modelManager = OnDeviceTranslatorModelManager();
      _isModelDownloaded = await modelManager.isModelDownloaded(
        _sourceLanguage!.bcpCode,
      );

      if (!_isModelDownloaded) {
        debugPrint('⚠️ Translation model not downloaded. Downloading...');
        // Model will be downloaded automatically on first translation
      } else {
        debugPrint('✅ Translation model is available');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking model availability: $e');
    }
  }

  /// Download translation model manually
  /// Returns true if download was successful or model already exists
  Future<bool> downloadModel() async {
    if (_translator == null) {
      await initialize();
    }

    if (_translator == null ||
        _sourceLanguage == null ||
        _targetLanguage == null) {
      return false;
    }

    // If source and target are same, no model needed
    if (_sourceLanguage == _targetLanguage) {
      _isModelDownloaded = true;
      return true;
    }

    try {
      final modelManager = OnDeviceTranslatorModelManager();

      // Check and download source language model
      bool sourceDownloaded = await modelManager.isModelDownloaded(
        _sourceLanguage!.bcpCode,
      );

      if (!sourceDownloaded) {
        debugPrint('📥 Downloading source language model (${_sourceLanguage!.bcpCode})...');
        sourceDownloaded = await modelManager.downloadModel(
          _sourceLanguage!.bcpCode,
        );
        if (sourceDownloaded) {
          debugPrint('✅ Source language model downloaded');
        } else {
          debugPrint('⚠️ Source language model download failed');
          return false;
        }
      } else {
        debugPrint('✅ Source language model already available');
      }

      // Check and download target language model
      bool targetDownloaded = await modelManager.isModelDownloaded(
        _targetLanguage!.bcpCode,
      );

      if (!targetDownloaded) {
        debugPrint('📥 Downloading target language model (${_targetLanguage!.bcpCode})...');
        targetDownloaded = await modelManager.downloadModel(
          _targetLanguage!.bcpCode,
        );
        if (targetDownloaded) {
          debugPrint('✅ Target language model downloaded');
        } else {
          debugPrint('⚠️ Target language model download failed');
          return false;
        }
      } else {
        debugPrint('✅ Target language model already available');
      }

      _isModelDownloaded = sourceDownloaded && targetDownloaded;
      return _isModelDownloaded;
    } catch (e) {
      debugPrint('❌ Error downloading translation model: $e');
      return false;
    }
  }

  /// Delete translation model to free up space
  Future<bool> deleteModel() async {
    if (_sourceLanguage == null) return false;

    try {
      final modelManager = OnDeviceTranslatorModelManager();
      await modelManager.deleteModel(_sourceLanguage!.bcpCode);
      _isModelDownloaded = false;
      debugPrint('🗑️ Translation model deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting translation model: $e');
      return false;
    }
  }

  /// Translate a single string
  /// Returns original text if translation fails or not needed
  /// Uses cache to avoid re-translating the same text
  Future<String> translate(String text) async {
    if (text.isEmpty) return text;

    // Check cache first
    if (_translationCache.containsKey(text)) {
      return _translationCache[text]!;
    }

    // Initialize if not already done
    if (!_isInitialized) {
      await initialize();
    }

    // If translator is null or languages are same, return original
    if (_translator == null || _sourceLanguage == _targetLanguage) {
      _translationCache[text] = text; // Cache original text
      return text;
    }

    try {
      final translated = await _translator!.translateText(text);
      _translationCache[text] = translated; // Cache translated text
      return translated;
    } catch (e) {
      debugPrint('⚠️ Translation failed for: "$text" - Error: $e');
      _translationCache[text] = text; // Cache original text on failure
      return text; // Return original text if translation fails
    }
  }

  /// Pre-translate a list of texts and cache them
  /// Useful for translating items before displaying them
  Future<void> preTranslate(List<String> texts) async {
    if (texts.isEmpty) return;

    // Filter out already cached texts
    final textsToTranslate =
        texts
            .where(
              (text) => text.isNotEmpty && !_translationCache.containsKey(text),
            )
            .toList();

    if (textsToTranslate.isEmpty) return;

    // Initialize if not already done
    if (!_isInitialized) {
      await initialize();
    }

    // If translator is null or languages are same, cache originals
    if (_translator == null || _sourceLanguage == _targetLanguage) {
      for (final text in textsToTranslate) {
        _translationCache[text] = text;
      }
      return;
    }

    // Translate in batch
    try {
      for (final text in textsToTranslate) {
        try {
          final translated = await _translator!.translateText(text);
          _translationCache[text] = translated;
        } catch (e) {
          _translationCache[text] = text; // Cache original on failure
        }
      }
    } catch (e) {
      debugPrint('⚠️ Batch pre-translation failed: $e');
    }
  }

  /// Get cached translation if available, otherwise return null
  /// Useful for synchronous access without async call
  String? getCachedTranslation(String text) {
    return _translationCache[text];
  }

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
  }

  /// Translate multiple strings at once
  /// Returns original texts if translation fails
  Future<List<String>> translateBatch(List<String> texts) async {
    if (texts.isEmpty) return texts;

    // Initialize if not already done
    if (!_isInitialized) {
      await initialize();
    }

    // If translator is null or languages are same, return originals
    if (_translator == null || _sourceLanguage == _targetLanguage) {
      return texts;
    }

    try {
      final List<String> translated = [];
      for (final text in texts) {
        if (text.isEmpty) {
          translated.add(text);
        } else {
          final result = await _translator!.translateText(text);
          translated.add(result);
        }
      }
      return translated;
    } catch (e) {
      debugPrint('⚠️ Batch translation failed: $e');
      return texts; // Return original texts if translation fails
    }
  }

  /// Translate API response fields
  /// Useful for translating specific fields in JSON responses
  ///
  /// Example:
  /// ```dart
  /// final response = {'message': '프로필이 업데이트되었습니다', 'status': 'success'};
  /// final translated = await translationService.translateResponse(
  ///   response,
  ///   fieldsToTranslate: ['message']
  /// );
  /// ```
  Future<Map<String, dynamic>> translateResponse(
    Map<String, dynamic> response, {
    List<String> fieldsToTranslate = const ['message', 'error', 'description'],
  }) async {
    if (response.isEmpty) return response;

    // Initialize if not already done
    if (!_isInitialized) {
      await initialize();
    }

    // If translator is null or languages are same, return original
    if (_translator == null || _sourceLanguage == _targetLanguage) {
      return response;
    }

    try {
      final translatedResponse = Map<String, dynamic>.from(response);

      for (final field in fieldsToTranslate) {
        if (response.containsKey(field) && response[field] is String) {
          final originalText = response[field] as String;
          if (originalText.isNotEmpty) {
            translatedResponse[field] = await translate(originalText);
          }
        }
      }

      return translatedResponse;
    } catch (e) {
      debugPrint('⚠️ Response translation failed: $e');
      return response; // Return original response if translation fails
    }
  }

  /// Translate nested API response (handles nested objects and arrays)
  ///
  /// Example:
  /// ```dart
  /// final response = {
  ///   'data': [
  ///     {'title': '공지사항', 'content': '새로운 기능이 추가되었습니다'},
  ///     {'title': '이벤트', 'content': '할인 이벤트 진행중'}
  ///   ]
  /// };
  /// final translated = await translationService.translateNestedResponse(
  ///   response,
  ///   fieldsToTranslate: ['title', 'content']
  /// );
  /// ```
  Future<dynamic> translateNestedResponse(
    dynamic data, {
    List<String> fieldsToTranslate = const [
      'message',
      'error',
      'description',
      'title',
      'content',
    ],
  }) async {
    if (data == null) return data;

    // Initialize if not already done
    if (!_isInitialized) {
      await initialize();
    }

    // If translator is null or languages are same, return original
    if (_translator == null || _sourceLanguage == _targetLanguage) {
      return data;
    }

    try {
      if (data is Map<String, dynamic>) {
        final translatedMap = <String, dynamic>{};

        for (final entry in data.entries) {
          if (fieldsToTranslate.contains(entry.key) && entry.value is String) {
            final originalText = entry.value as String;
            translatedMap[entry.key] =
                originalText.isNotEmpty
                    ? await translate(originalText)
                    : originalText;
          } else if (entry.value is Map || entry.value is List) {
            translatedMap[entry.key] = await translateNestedResponse(
              entry.value,
              fieldsToTranslate: fieldsToTranslate,
            );
          } else {
            translatedMap[entry.key] = entry.value;
          }
        }

        return translatedMap;
      } else if (data is List) {
        final translatedList = [];

        for (final item in data) {
          translatedList.add(
            await translateNestedResponse(
              item,
              fieldsToTranslate: fieldsToTranslate,
            ),
          );
        }

        return translatedList;
      } else {
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ Nested response translation failed: $e');
      return data; // Return original data if translation fails
    }
  }

  /// Get TranslateLanguage from language code
  TranslateLanguage _getTranslateLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ko':
        return TranslateLanguage.korean;
      case 'en':
        return TranslateLanguage.english;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ru':
        return TranslateLanguage.russian;
      case 'it':
        return TranslateLanguage.italian;
      default:
        return TranslateLanguage.english; // Default to English
    }
  }

  /// Check if translation is needed
  bool get needsTranslation => _sourceLanguage != _targetLanguage;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if model is downloaded
  bool get isModelDownloaded => _isModelDownloaded;

  /// Get source language name
  String? get sourceLanguageName => _sourceLanguage?.name;

  /// Get target language name
  String? get targetLanguageName => _targetLanguage?.name;

  /// Close and cleanup translator
  Future<void> dispose() async {
    try {
      _translator?.close();
      _translator = null;
      _isInitialized = false;
      debugPrint('🔒 Translation Service closed');
    } catch (e) {
      debugPrint('❌ Error closing translation service: $e');
    }
  }

  /// Reinitialize when locale changes
  Future<void> onLocaleChange() async {
    await dispose();
    clearCache(); // Clear cache when locale changes
    await initialize();
  }
}

/// Global instance for easy access
final translationService = TranslationService();
