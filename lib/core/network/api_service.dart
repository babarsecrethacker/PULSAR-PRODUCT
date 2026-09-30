import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8090';

  static Future<bool> checkServer() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true;
      }

      return false;
    } catch (e) {
      print('Server connection error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }

    return jsonDecode(response.body);
  }
}