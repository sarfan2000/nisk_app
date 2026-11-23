import 'dart:convert';
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
        List<dynamic> roles = data['user']['roles'] ?? [];
        final prefs = await SharedPreferences.getInstance();
        
        String? savedActiveRole = prefs.getString('activeRole');
        String activeRole = savedActiveRole ?? data['user']['userType'] ?? 'Buyer'; 
        
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
        await prefs.setString('userType', data['user']['userType'] ?? 'Buyer');
        await prefs.setString('roles', jsonEncode(roles));
        await prefs.setString('activeRole', activeRole);
        await prefs.setString('profilePic', data['user']['profilePic'] ?? '');
        await prefs.setString('userName', data['user']['name'] ?? 'User');
        await prefs.setString('userId', data['user']['id'] ?? data['user']['_id'] ?? '');

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
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('profilePic');
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

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? location,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        if (data['user'] != null) {
          if (data['user']['name'] != null) {
            await prefs.setString('userName', data['user']['name']);
          }
          if (data['user']['email'] != null) {
            await prefs.setString('userEmail', data['user']['email']);
          }
        }
        
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['msg'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['msg'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> uploadProfilePicture(String imagePath) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-profile-pic'),
      );
      
      request.headers['x-auth-token'] = token ?? '';
      request.files.add(await http.MultipartFile.fromPath('images', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        if (data['profilePic'] != null) {
          await prefs.setString('profilePic', data['profilePic']);
        }
        
        return data['profilePic'] ?? '';
      } else {
        throw Exception(jsonDecode(response.body)['msg'] ?? 'Failed to upload profile picture');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
