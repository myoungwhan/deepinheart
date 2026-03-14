import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPref {
  readObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key)!);
  }

  saveObject(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  removeObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  setBool(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }
  
}
