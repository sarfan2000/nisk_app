import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static String get baseUrl {
    return '${ApiService.baseUrl}/auth';
  }
  Future<User?> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token'];
        
        // Persist token securely
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('x-auth-token', token);
        await prefs.setString('userType', data['user']['userType']);

        return User.fromJson(data['user'], token);
      } else {
        throw Exception(jsonDecode(response.body)['msg'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('x-auth-token');
    await prefs.remove('userType');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }
}
