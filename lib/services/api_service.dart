import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = _createHttpClient();

  // URL de la API real
  static const String baseUrlApi = 'https://apideveventaccess.svr.com.mx/api';
  String get baseUrl => baseUrlApi;

  // Endpoint de check-in de ticket
  static const String checkinEndpoint = '/v1/staff/events/tickets/checkin';

  static http.Client _createHttpClient() {
    // ============================================
    // MODO DESARROLLO: Aceptar cualquier certificado SSL
    // HABILITADO actualmente (para dispositivos con problemas de certificado como el moto G41)
    // ============================================
    final securityContext = SecurityContext(withTrustedRoots: true);
    final httpClient = HttpClient(context: securityContext)
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    return IOClient(httpClient);

    // ============================================
    // MODO PRODUCCIÓN: Usar certificado válido del servidor
    // Para producción: eliminar las líneas de arriba y descomentar abajo
    // Descomentar esta línea para producción:
    // return http.Client();
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


  // Realizar check-in de ticket
  Future<Map<String, dynamic>> checkinTicket(String saleItemId, String authToken) async {
    try {
      final uri = Uri.parse('$baseUrl$checkinEndpoint');
      
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'sale_item_id': saleItemId,
        }),
      ).timeout(const Duration(seconds: 10));

      return _handleCheckinResponse(response);
    } on SocketException {
      throw Exception('No hay conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión');
    } catch (e) {
      throw Exception('Error desconocido: $e');
    }
  }

  // Manejar respuesta de check-in
  Map<String, dynamic> _handleCheckinResponse(http.Response response) {
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
      return {};
    } else if (statusCode == 401) {
      throw Exception('No autorizado');
    } else if (statusCode == 404) {
      throw Exception('Boleto no encontrado');
    } else if (statusCode == 409) {
      throw Exception('Boleto ya utilizado');
    } else {
      throw Exception('Error HTTP $statusCode: $body');
    }
  }

  // Cerrar cliente (llamar al salir de la app)
  void dispose() {
    _client.close();
  }
}
