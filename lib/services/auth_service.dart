import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Reemplaza con tu URL de API
  static const String baseUrl = 'https://motolineparts.com/api';
  
  String? _token;
  
  String? get token => _token;

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
  }
}