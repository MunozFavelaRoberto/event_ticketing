import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kiosko/services/data_provider.dart';
import 'package:kiosko/utils/app_strings.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  // Códigos QR hardcodeados para simulación/testing
  // IMPORTANTE: Estos códigos deben coincidir con los de ApiService.validateTicket()
  static const Map<String, String> _hardcodedQrCodes = {
    'valid': 'J63qRTDLub5NuZvP+kb8YIorGS6qFYHKVo6u7179stY=',
    'invalid': 'CODIGO_INVALIDO_TEST_123',
    'used': 'CODIGO_USADO_TEST_456',
    'network_error': 'ERROR_RED_TEST_789',
  };

  String? _qrData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRetrying = false;

  // Selector para simulación (por defecto usa el válido)
  String _selectedQrCode = 'valid';

  @override
  void initState() {
    super.initState();
    _loadQrData();
  }

  Future<void> _loadQrData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isRetrying = false;
    });

    try {
      // Simular una carga asíncrona de datos (como si viniera de la API)
      await Future.delayed(const Duration(milliseconds: 500)); 

      // Delay obligatorio de 1 segundo para mostrar que se procesó
      await Future.delayed(const Duration(seconds: 1));

      // Verificar que el widget sigue montado
      if (!mounted) return;

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      // Primero verificar si ya tenemos un ticket en cache del usuario
      String? ticketId = dataProvider.ticketId;

      // Si no hay ticket del usuario, usar código hardcodeado para simulación
      if (ticketId == null || ticketId.isEmpty) {
        // Usar código hardcodeado según selección
        // Por defecto usamos el código válido para simular un boleto real
        ticketId = _hardcodedQrCodes[_selectedQrCode];
      }

      // Verificar que tenemos datos del QR
      if (ticketId != null && ticketId.isNotEmpty) {
        _qrData = ticketId;
      } else {
        // No hay datos disponibles
        _errorMessage = AppStrings.qrNoTicket;
      }
    } catch (e) {
      _errorMessage = "Error al obtener datos del QR: $e";
      debugPrint("Error al cargar datos QR: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRetrying = false;
        });
      }
    }
  }

  void _handleRetry() {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });
    _loadQrData();
  }

  /// Cambia el código QR seleccionado (para testing)
  void _changeQrCode(String codeKey) {
    if (_isLoading) return;
    setState(() {
      _selectedQrCode = codeKey;
    });
    _loadQrData();
  }

  @override
  Widget build(BuildContext context) {
    // Bloquear UI durante carga o reintento
    final isBlocked = _isLoading || _isRetrying;
    
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.qrTitle)),
      body: AbsorbPointer(
        absorbing: isBlocked,
        child: Opacity(
          opacity: isBlocked ? 0.5 : 1.0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.qrInstruction,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildQrContent(),
                const SizedBox(height: 20),
                _buildBottomActions(),
                const SizedBox(height: 16),
                _buildQrSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrContent() {
    if (_isLoading) {
      return Column(
        children: const [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 10),
          Text(AppStrings.qrLoading),
        ],
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (_qrData != null && _qrData!.isNotEmpty) {
      return Column(
        children: [
          QrImageView(
            data: _qrData!,
            version: QrVersions.auto,
            size: 300.0,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Indicador visual según el tipo de QR
          _buildQrStatusIndicator(),
        ],
      );
    }

    // Caso por defecto
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        AppStrings.qrNoData,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.red),
      ),
    );
  }

  Widget _buildQrStatusIndicator() {
    // Mostrar diferente estado según el código seleccionado
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_selectedQrCode) {
      case 'valid':
        statusColor = Colors.green;
        statusText = AppStrings.qrValid;
        statusIcon = Icons.check_circle;
        break;
      case 'invalid':
        statusColor = Colors.orange;
        statusText = "Boleto inválido (simulación)";
        statusIcon = Icons.warning;
        break;
      case 'used':
        statusColor = Colors.red;
        statusText = "Boleto ya usado (simulación)";
        statusIcon = Icons.cancel;
        break;
      case 'network_error':
        statusColor = Colors.grey;
        statusText = "Error de red (simulación)";
        statusIcon = Icons.signal_wifi_off;
        break;
      default:
        statusColor = Colors.green;
        statusText = AppStrings.qrValid;
        statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    // Mostrar botón de reintentar si hay error
    if (_errorMessage != null && !_isLoading) {
      return ElevatedButton.icon(
        onPressed: _isRetrying ? null : _handleRetry,
        icon: _isRetrying 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(_isRetrying ? AppStrings.loading : AppStrings.retry),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Widget para seleccionar diferentes QR (solo para testing/simulación)
  Widget _buildQrSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Simular código QR:",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQrChip('valid', 'Válido'),
              _buildQrChip('invalid', 'Inválido'),
              _buildQrChip('used', 'Usado'),
              _buildQrChip('network_error', 'Sin red'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrChip(String key, String label) {
    final isSelected = _selectedQrCode == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: _isLoading ? null : (selected) {
        if (selected) {
          _changeQrCode(key);
        }
      },
      selectedColor: Colors.green.withAlpha(50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.green : Colors.black87,
        fontSize: 12,
      ),
    );
  }
}
