import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage.dart';
import 'api.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/login"),
      headers: {"Accept": "application/json"},
      body: {
        "email": email,
        "password": password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await Storage.saveToken(data['token']);
      return true;
    }

    return false;
  }

  Future<Map<String, dynamic>?> getUser() async {
    final token = await Storage.getToken();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/user"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print('AuthService.getUser Status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('AuthService.getUser Error: ${response.body}');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}
