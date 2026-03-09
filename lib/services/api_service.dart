import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = _createHttpClient();

  // URL de la API real
  static const String baseUrlApi = 'https://apipagoselectronicos.svr.com.mx/api';
  String get baseUrl => baseUrlApi;

  static http.Client _createHttpClient() {
    return http.Client();
  }

  // Método GET
  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Método POST
  Future<dynamic> post(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };
      final response = await _client.post(
        uri,
        headers: defaultHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Método PUT
  Future<dynamic> put(String endpoint, {Map<String, String>? headers, dynamic body}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Método DELETE
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Manejar respuesta HTTP
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isNotEmpty) {
        try {
          return jsonDecode(body);
        } catch (e) {
          throw Exception('Error al parsear JSON: $e');
        }
      }
      return null;
    } else if (statusCode == 401) {
      throw Exception('No autorizado');
    } else {
      throw Exception('Error HTTP $statusCode: $body');
    }
  }


  // Simulador de validación de boleto con mensajes específicos.
  Future<Map<String, dynamic>> validateTicket(String qrCode) async {
    // retraso para simular latencia
    await Future.delayed(const Duration(seconds: 2)); // Aumento el retraso para apreciar mejor el estado de validación
    
    // Simular diferentes escenarios
    if (qrCode == "J63qRTDLub5NuZvP+kb8YIorGS6qFYHKVo6u7179stY=") {
      return {'isValid': true, 'message': 'Acceso concedido'};
    } else if (qrCode == "CODIGO_INVALIDO_TEST_123") {
      return {'isValid': false, 'message': 'Código inválido o formato incorrecto'};
    } else if (qrCode == "CODIGO_USADO_TEST_456") {
      return {'isValid': false, 'message': 'Boleto ya utilizado'};
    } else if (qrCode == "ERROR_RED_TEST_789") {
      // Simular un error de red
      throw Exception('Network error: Could not connect to server.');
    } else {
      return {'isValid': false, 'message': 'Boleto no encontrado'};
    }
  }

  // Cerrar cliente (llamar al salir de la app)
  void dispose() {
    _client.close();
  }
}
