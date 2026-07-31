import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static const String _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('RESPUESTA CRUDA DEL SERVIDOR: ${response.body}');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(body['message'] ?? 'Error en la solicitud', response.statusCode);
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> loginWithGoogle({
    String? idToken,
    String? googleId,
    String? email,
    String? name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (idToken != null) {
      body['id_token'] = idToken;
    } else {
      body['google_id'] = googleId;
      body['email'] = email;
      body['name'] = name;
      body['avatar'] = avatar;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/login/google'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerWithGoogle({
    required String googleId,
    required String email,
    required String name,
    required String password,
    String? avatar,
  }) async {
    final body = {
      'google_id': googleId,
      'email': email,
      'name': name,
      'password': password,
      'password_confirmation': password,
      if (avatar != null) 'avatar': avatar,
    };

final response = await http.post(
      Uri.parse('$_baseUrl/register/google'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserName(String name) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user/name'),
      headers: await _headers(),
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user/password'),
      headers: await _headers(),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserAvatar(String avatarBase64) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/user/avatar'),
      headers: await _headers(),
      body: jsonEncode({'avatar': avatarBase64}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTransactions({String? type, int? categoryId, String? dateFrom, String? dateTo}) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;

    final uri = Uri.parse('$_baseUrl/transactions').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSavingsGoals() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/savings-goals'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createSavingsGoal(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/savings-goals'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateSavingsGoal(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/savings-goals/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteSavingsGoal(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/savings-goals/$id'),
      headers: await _headers(),
    );
    _handleResponse(response);
  }

  static Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: await _headers(),
    );
    _handleResponse(response);
    await removeToken();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}



