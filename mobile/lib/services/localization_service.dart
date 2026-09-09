import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  static Map<String, String> _localizedStrings = {};

  static Future<void> load(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/locales/$languageCode.json');
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Localization fallback loaded: $e');
    }
  }

  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
