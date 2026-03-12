import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosko/models/user.dart';
import 'package:kiosko/services/api_service.dart';
import 'package:kiosko/services/auth_service.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService? _authService;

  // Clave para SharedPreferences
  static const String _userDataKey = 'cached_user_data';

  DataProvider({AuthService? authService, ApiService? apiService})
      : _authService = authService,
        _apiService = apiService ?? ApiService() {
    // Cargar datos de usuario desde cache al iniciar
    _loadCachedUser();
  }

  User? _user;
  bool _isLoading = false;
  bool _isUnauthorized = false;
  bool _isInitialLoading = true;
  bool _hasAttemptedFetch = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUnauthorized => _isUnauthorized;
  bool get isInitialLoading => _isInitialLoading;
  bool get hasAttemptedFetch => _hasAttemptedFetch;
  
  // Getters para ticket
  String? get ticketId => _user?.ticketId;
  String? get ticketStatus => _user?.ticketStatus;
  bool get hasActiveTicket => _user?.ticketId != null && _user?.ticketId!.isNotEmpty == true;

  // Cargar usuario desde cache local
  Future<void> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);
      if (userJson != null) {
        final Map<String, dynamic> userMap = json.decode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(userMap);
        _isInitialLoading = false;
        debugPrint('Usuario cargado desde cache: ${_user?.fullName}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando usuario desde cache: $e');
    }
  }

  // Guardar usuario en cache local
  Future<void> _cacheUser() async {
    if (_user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = _user!.toJson();
      await prefs.setString(_userDataKey, json.encode(userJson));
      debugPrint('Usuario guardado en cache');
    } catch (e) {
      debugPrint('Error guardando usuario en cache: $e');
    }
  }

  // Limpiar cache de usuario (logout)
  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      debugPrint('Cache de usuario limpiada');
    } catch (e) {
      debugPrint('Error limpiando cache: $e');
    }
  }

  /// Establecer usuario después de login exitoso (desde AuthService)
  void setUserFromLogin(int id, String fullName, String email) {
    _user = User(
      id: id,
      fullName: fullName,
      email: email,
    );
    _isUnauthorized = false;
    _isInitialLoading = false;
    _cacheUser();
    notifyListeners();
  }

  Future<void> fetchUser() async {
    _isLoading = true;
    _hasAttemptedFetch = true;

    try {
      final token = await _authService?.getToken();
      if (token != null) {
        final data = await _apiService.get('/client/profile', headers: {
          'Authorization': 'Bearer $token',
        });
        debugPrint('Profile API response: $data');

        final profileData = data['data']?['item'];
        if (profileData != null) {
          _user = User(
            id: profileData['id'] as int? ?? 0,
            fullName: profileData['full_name'] as String? ?? 'Usuario',
            email: profileData['email'] as String? ?? 'email@desconocido.com',
            ticketId: profileData['ticket_id'] as String?,
            ticketStatus: profileData['ticket_status'] as String?,
          );
          _isUnauthorized = false;
          _isInitialLoading = false;
          await _cacheUser();
        }
      } else {
        _isInitialLoading = false;
        _isUnauthorized = true;
        _user = null;
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _isInitialLoading = false;
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('no autorizado') || errorMsg.contains('401') || errorMsg.contains('unauthorized')) {
        _isUnauthorized = true;
        _user = null;
      } else {
        _isUnauthorized = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para actualizar el usuario
  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }

  // Resetear estado de autorización (para cuando usuario hace logout o inicia sesión)
  void resetUnauthorized() {
    _isUnauthorized = false;
    _user = null;
    _hasAttemptedFetch = false;
    _clearUserCache();
    notifyListeners();
  }

  // Método para establecer usuario manualmente
  void setUser(User user) {
    _user = user;
    _isUnauthorized = false;
    _isInitialLoading = false;
    notifyListeners();
  }

  // Refresh completo para pull-to-refresh
  Future<void> refreshAllData() async {
    _isInitialLoading = false;
    await fetchUser();
    notifyListeners();
  }

  /// Obtiene el ticket del usuario desde la API
  Future<String?> fetchTicket() async {
    try {
      final token = await _authService?.getToken();
      if (token == null) return null;

      final data = await _apiService.get('/client/ticket', headers: {
        'Authorization': 'Bearer $token',
      });

      if (data != null && data['data'] != null) {
        final ticketData = data['data'];
        final ticketId = ticketData['ticket_id'] as String?;
        final ticketStatus = ticketData['status'] as String?;

        // Actualizar el usuario con los datos del ticket
        if (_user != null && ticketId != null) {
          _user = User(
            id: _user!.id,
            fullName: _user!.fullName,
            email: _user!.email,
            ticketId: ticketId,
            ticketStatus: ticketStatus,
          );
          await _cacheUser();
          notifyListeners();
        }

        return ticketId;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching ticket: $e');
      return null;
    }
  }
}
