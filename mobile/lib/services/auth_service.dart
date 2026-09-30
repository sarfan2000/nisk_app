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
        // Extract roles
        List<dynamic> roles = data['user']['roles'] ?? [];
        final prefs = await SharedPreferences.getInstance();
        
        // Preserve activeRole if already set in SharedPreferences and still valid
        String? savedActiveRole = prefs.getString('activeRole');
        String activeRole = savedActiveRole ?? data['user']['userType'] ?? 'Buyer'; 
        
        // Ensure the chosen role is actually in their roles array, otherwise fallback
        if (roles.isNotEmpty) {
           bool hasRegisteredRole = roles.any((r) => r['role'] == activeRole && r['status'] == 'Active');
           if (!hasRegisteredRole) {
               activeRole = data['user']['userType'] ?? roles.first['role'];
               bool hasFallbackRole = roles.any((r) => r['role'] == activeRole && r['status'] == 'Active');
               if (!hasFallbackRole) {
                   activeRole = roles.first['role'];
               }
           }
        }

        // Persist token and roles securely
        await prefs.setString('x-auth-token', token);
        await prefs.setString('userType', data['user']['userType'] ?? 'Buyer'); // Legacy support
        await prefs.setString('roles', jsonEncode(roles));
        await prefs.setString('activeRole', activeRole);
        await prefs.setString('profilePic', data['user']['profilePic'] ?? '');
        await prefs.setString('userName', data['user']['name'] ?? 'User');


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
    await prefs.remove('roles');
    await prefs.remove('activeRole');
  }

  Future<List<dynamic>> addRole(String roleName) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/add-role'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({'role': roleName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> updatedRoles = data['roles'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('roles', jsonEncode(updatedRoles));
        
        if (data['token'] != null) {
          await prefs.setString('x-auth-token', data['token']);
        }
        
        return updatedRoles;
      } else {
        throw Exception(jsonDecode(response.body)['msg'] ?? 'Failed to add role');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }
}
