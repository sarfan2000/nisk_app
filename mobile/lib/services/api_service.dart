import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Automatically route to 10.0.2.2 if on Android Emulator, otherwise localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5001/api';
    // Use the computer's local IP address for real Android devices over Wi-Fi
    return 'http://192.168.8.148:5001/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }

  Map<String, String> _buildHeaders(String? token) {
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      };
    }
    return {'Content-Type': 'application/json'};
  }

  dynamic _extractError(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded != null && decoded['msg'] != null) {
        throw Exception(decoded['msg']);
      }
      throw Exception('Server Error: ${response.statusCode}');
    } catch (_) {
      throw Exception('Network Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> get(String endpoint) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token), body: json.encode(data));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }

  Future<dynamic> postMultipart(
      String endpoint, Map<String, String> fields, List<XFile> files) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    if (token != null) {
      request.headers['x-auth-token'] = token;
    }

    request.fields.addAll(fields);

    for (var file in files) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          file.path,
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token), body: json.encode(data));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token), body: json.encode(data));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final token = await _getToken();
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      _extractError(response);
    }
  }
}
