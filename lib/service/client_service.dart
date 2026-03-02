import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage.dart';
import 'api.dart';

class ClientService {
  Future<List<dynamic>> getClients() async {
    final token = await Storage.getToken();

    final response = await http.get(
      Uri.parse('${Api.baseUrl}/clients'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('ClientService.getClients Status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('ClientService.getClients Error: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['clients'] != null) {
        return data['clients'];
      }
      if (data is List) return data;
      if (data['data'] != null) return data['data'];
      return [];
    } else {
      throw Exception('Failed to load clients: ${response.statusCode}');
    }
  }
}