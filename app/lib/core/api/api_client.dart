import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';
import 'endpoints.dart';

class ApiClient {
  static Future<http.Response> get(String endpoint) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${Endpoints.baseUrl}$endpoint');
    
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${Endpoints.baseUrl}$endpoint');
    
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String endpoint, [Map<String, dynamic>? body]) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${Endpoints.baseUrl}$endpoint');
    
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${Endpoints.baseUrl}$endpoint');

    return await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${Endpoints.baseUrl}$endpoint');
    
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
