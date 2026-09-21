import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return dotenv.env['API_BASE_URL_WEB'] ?? 'http://localhost:5001/api';
    } else if (Platform.isAndroid) {
      return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:5001/api';
    } else {
      return dotenv.env['API_BASE_URL_IOS'] ?? 'http://localhost:5001/api';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('x-auth-token') ?? '';
    return {
      'Content-Type': 'application/json',
      'x-auth-token': token,
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API GET Request logic failed: ${response.statusCode}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API POST Request failed: ${response.body}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API PATCH Request failed: ${response.body}');
    }
  }
  Future<dynamic> postMultipart(String endpoint, Map<String, String> body, List<dynamic> imageFiles) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('x-auth-token') ?? '';

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    request.headers['x-auth-token'] = token;
    
    // Add text fields
    body.forEach((key, value) {
      request.fields[key] = value;
    });

    // Add files
    for (var file in imageFiles) {
      if (kIsWeb) {
        // file is an instance of XFile
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: file.name,
          )
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('images', file.path)
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API POST Multipart failed: ${response.body}');
    }
  }
}
