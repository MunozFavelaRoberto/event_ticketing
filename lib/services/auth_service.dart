import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosko/models/auth_response.dart';
import 'package:kiosko/services/api_service.dart';

/// Servicio de autenticación que gestiona login, logout y persistencia de sesión
class AuthService {
  final ApiService _apiService = ApiService();

  // Session Persistence

  Future<void> saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  // Authentication Methods

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('authToken');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _apiService.get('/user', headers: {
        'Authorization': 'Bearer $token',
      });

      return response != null;
    } catch (e) {
      debugPrint('Error verificando token: $e');
      if (e is SocketException || e is http.ClientException) {
        return true;
      }
      return false;
    }
  }

  // Rol requerido para acceder a la app móvil
  static const int requiredRoleId = 4;

  /// Datos del usuario logueado
  int? _loggedUserId;
  String? _loggedUserFullName;
  String? _loggedUserEmail;

  int? get loggedUserId => _loggedUserId;
  String? get loggedUserFullName => _loggedUserFullName;
  String? get loggedUserEmail => _loggedUserEmail;

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _apiService.post('/login', body: {
        'email': email,
        'password': password,
      });

      if (response != null) {
        final authResponse = AuthResponse.fromJson(response);
        
        // Validar que el role_id sea 4 (usuario móvil)
        final userRoleId = authResponse.data.auth.user.roleId;
        if (userRoleId != requiredRoleId) {
          debugPrint('Login denegado: role_id $userRoleId no es válido para app móvil (requerido: $requiredRoleId)');
          throw Exception('Rol no autorizado: $userRoleId. Se requiere rol $requiredRoleId');
        }
        
        // Guardar datos del usuario
        _loggedUserId = authResponse.data.auth.user.id;
        _loggedUserFullName = authResponse.data.auth.user.fullName;
        _loggedUserEmail = authResponse.data.auth.user.email;
        
        await _saveToken(authResponse.data.auth.token);
        await saveLoginState();
        return authResponse;
      }
      return null;
    } catch (e) {
      debugPrint('Error en login: $e');
      rethrow; // Re-lanzar para que el UI muestre el error real
    }
  }
}
