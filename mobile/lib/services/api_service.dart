import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static String get baseUrl {
    return 'https://nisk-app.onrender.com/api';
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
    String? message;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        if (decoded['msg'] != null) {
          message = decoded['msg'].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        } else if (decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      }
    } catch (_) {}

    if (message != null && message.isNotEmpty) {
      throw Exception(message);
    }
    throw Exception('Server Error: ${response.statusCode}');
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

  Future<dynamic> putMultipart(
      String endpoint, Map<String, String> fields, List<XFile> files) async {
    final token = await _getToken();
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$endpoint'));

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
