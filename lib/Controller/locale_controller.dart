import 'package:deepinheart/Locales/ko_kr.dart';
import 'package:deepinheart/Locales/ko_kr_old.dart';
import 'package:deepinheart/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deepinheart/Locales/de_de.dart';
import 'package:deepinheart/Locales/en_uk.dart';
import 'package:deepinheart/Locales/es_es.dart';
import 'package:deepinheart/Locales/fr_fr.dart';
import 'package:deepinheart/Locales/ja_jp.dart';

import '../Locales/ar_sa.dart';
import '../Locales/en_us.dart';

class LocalizationService extends Translations {
  // Default locale
  // static final locale = Locale('ar', 'SA');
  static final locale = Locale('ko', 'KR');

  // fallbackLocale saves the day when the locale gets in trouble
  static final fallbackLocale = Locale('en', 'US');

  // Supported languages
  // Needs to be same order with locales

  //check for language codes
  // https://www.fincher.org/Utilities/CountryLanguageList.shtml
  static final langs = ['Korean (KO)', 'English (US)'];

  // Supported locales
  // Needs to be same order with langs
  static final locales = [Locale('ko', 'KR'), Locale('en', 'UK')];

  // Keys and their translations
  // Translations are separated maps in `lang` file
  @override
  Map<String, Map<String, String>> get keys => {
    'ko_KR': koKR,
    'en_US': enUS, // lang/en_us.dart
    // lang/en_us.dart
    // 'ar_SA': arSA, // lang/tr_tr.dart
    // 'es_ES': esES, // lang/tr_tr.dart
  };

  // Gets locale from language, and updates the locale
  void changeLocale(String lang) async {
    final locale = _getLocaleFromLanguage(lang);
    Get.updateLocale(locale);

    // Reinitialize translation service for new locale
    await translationService.onLocaleChange();

    //  Get.back();
  }

  // Finds language in `langs` list and returns it as Locale
  Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale!;
  }

  /// Returns the API language code ('ko' or 'en') based on current locale
  /// Falls back to 'en' if locale is null or not supported
  static String getApiLanguageCode() {
    final currentLocale = Get.locale;
    if (currentLocale == null) {
      return 'en';
    }
    // Check if current locale is Korean
    if (currentLocale.languageCode == 'ko') {
      return 'ko';
    }
    // Default to English for all other cases
    return 'en';
  }
}
