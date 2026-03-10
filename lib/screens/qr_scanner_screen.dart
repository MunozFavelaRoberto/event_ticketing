import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kiosko/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:kiosko/screens/ticket_result_screen.dart';

enum ScanState { waiting, validating, success, failure, permissionDenied, networkError }

enum TicketErrorType {
  none,
  invalidFormat,
  alreadyUsed,
  notFound,
  eventNotStarted,
  eventEnded,
  networkError,
  unknown
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  ScanState _state = ScanState.waiting;
  TicketErrorType _errorType = TicketErrorType.none;
  final ApiService _apiService = ApiService();
  
  late MobileScannerController _controller;
  
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  
  bool _isInitialized = false;
  bool _isProcessing = false; // Para bloquear UI durante validación

  // Textos
  static const String _scanningText = 'ESCANEANDO...';
  static const String _accessGranted = '¡PASA!';
  static const String _accessDenied = 'NO PASA';
  static const String _permissionDeniedText = 'Permiso de cámara denegado. Habilita la cámara en Configuración.';
  static const String _networkErrorText = 'Error de red. Verifica tu conexión.';
  static const String _tryAgain = 'Intentar de nuevo';

  static const Map<TicketErrorType, String> _errorMessages = {
    TicketErrorType.invalidFormat: 'Qr inválido',
    TicketErrorType.alreadyUsed: 'Boleto ya utilizado',
    TicketErrorType.notFound: 'Boleto no encontrado',
    TicketErrorType.eventNotStarted: 'El evento aún no ha iniciado',
    TicketErrorType.eventEnded: 'El evento ha finalizado',
    TicketErrorType.networkError: 'Error de red. Verifica tu conexión.',
    TicketErrorType.unknown: 'Error desconocido',
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController!);
  }

  void _initCamera() {
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
    );
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  TicketErrorType _parseErrorType(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('usado') || lowerMessage.contains('used')) {
      return TicketErrorType.alreadyUsed;
    } else if (lowerMessage.contains('no encontrado') || lowerMessage.contains('not found')) {
      return TicketErrorType.notFound;
    } else if (lowerMessage.contains('no iniciado') || lowerMessage.contains('not started')) {
      return TicketErrorType.eventNotStarted;
    } else if (lowerMessage.contains('finalizado') || lowerMessage.contains('ended')) {
      return TicketErrorType.eventEnded;
    } else if (lowerMessage.contains('inválido') || lowerMessage.contains('invalid') || lowerMessage.contains('formato')) {
      return TicketErrorType.invalidFormat;
    } else if (lowerMessage.contains('network') || lowerMessage.contains('red') || lowerMessage.contains('conexión')) {
      return TicketErrorType.networkError;
    }
    return TicketErrorType.unknown;
  }

  String _getErrorMessage() {
    if (_errorType == TicketErrorType.none) {
      return _errorMessages[TicketErrorType.unknown]!;
    }
    return _errorMessages[_errorType] ?? _errorMessages[TicketErrorType.unknown]!;
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (!mounted) return;
    if (_isProcessing) return;
    
    if (_state == ScanState.validating || 
        _state == ScanState.permissionDenied || 
        _state == ScanState.networkError ||
        _state == ScanState.success) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Bloquear UI durante validación
    setState(() {
      _isProcessing = true;
      _state = ScanState.validating;
      _errorType = TicketErrorType.none;
    });

    try {
      final result = await _apiService.validateTicket(code);
      
      // Delay obligatorio de 1 segundo para mostrar que se procesó
      await Future.delayed(const Duration(seconds: 1));
      
      final bool valid = result['isValid'] as bool;
      final String message = result['message'] as String? ?? '';

      if (!mounted) return;
      
      if (valid) {
        HapticFeedback.lightImpact();
        // Navegar a pantalla de resultado
        _navigateToResult(isValid: true, message: '');
      } else {
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.vibrate();
        
        final errorType = _parseErrorType(message);
        
        // Navegar a pantalla de resultado
        _navigateToResult(
          isValid: false, 
          message: message.isNotEmpty ? message : _getErrorMessage(),
          errorType: errorType.name,
        );
      }
    } on Exception catch (e) {
      debugPrint('Error al validar ticket: $e');
      final errorStr = e.toString().toLowerCase();
      
      if (!mounted) return;
      
      // Delay obligatorio de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      
      if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('conexión')) {
        _navigateToResult(
          isValid: false,
          message: 'Error de red. Verifica tu conexión.',
          errorType: 'networkError',
        );
      } else {
        _navigateToResult(
          isValid: false,
          message: 'Error: ${e.toString()}',
          errorType: 'unknown',
        );
      }
    }
  }

  void _navigateToResult({
    required bool isValid,
    required String message,
    String? errorType,
  }) {
    // Delay para volver al escáner después de mostrar resultado
    const int resultDelaySeconds = 3;
    
    // Pausar el escáner temporalmente
    _controller.stop();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TicketResultScreen(
            isValid: isValid,
            message: message,
            errorType: errorType,
            delaySeconds: resultDelaySeconds,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      // Cuando regrese del resultado, reiniciar el escáner
      if (mounted) {
        _controller.start();
        setState(() {
          _state = ScanState.waiting;
          _errorType = TicketErrorType.none;
          _isProcessing = false;
        });
      }
    });
  }

  Color _backgroundColor() {
    switch (_state) {
      case ScanState.success:
        return Colors.green;
      case ScanState.failure:
        return Colors.red;
      case ScanState.networkError:
        return Colors.orange;
      case ScanState.permissionDenied:
        return Colors.grey;
      case ScanState.validating:
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case ScanState.waiting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [ 
            const Text(
              _scanningText,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildScanningAnimation(),
          ],
        );
      case ScanState.validating:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Validando...', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        );
      case ScanState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 150),
            SizedBox(height: 8),
            Text(_accessGranted, style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          ],
        );
      case ScanState.failure:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, color: Colors.white, size: 150),
            const SizedBox(height: 8),
            const Text(_accessDenied, style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_getErrorMessage(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        );
      case ScanState.networkError:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.white, size: 150),
            const SizedBox(height: 8),
            const Text(_networkErrorText, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restartScanner,
              icon: const Icon(Icons.refresh),
              label: const Text(_tryAgain),
            ),
          ],
        );
      case ScanState.permissionDenied:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 150),
            const SizedBox(height: 8),
            const Text(_permissionDeniedText, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Abrir configuración de la app
                setState(() => _state = ScanState.waiting);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        );
    }
  }

  Widget _buildScanningAnimation() {
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment(0, _animation!.value * 2 - 1),
                child: Container(
                  width: 200,
                  height: 2,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  void _switchCamera() {
    _controller.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  void _restartScanner() {
    setState(() {
      _state = ScanState.waiting;
      _errorType = TicketErrorType.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text('Iniciando cámara...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor(),
      appBar: AppBar(
        title: const Text('Escaner de Boletos'),
        backgroundColor: _backgroundColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _isProcessing ? null : _toggleFlash,
            tooltip: 'Linterna',
          ),
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_rear : Icons.camera_front),
            onPressed: _isProcessing ? null : _switchCamera,
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _isProcessing ? null : _handleDetection,
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Center(child: _buildContent()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AbsorbPointer(
              absorbing: _isProcessing,
              child: Opacity(
                opacity: _isProcessing ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: _backgroundColor().withValues(alpha: 0.8),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _state == ScanState.validating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              )
                            : Icon(
                                _state == ScanState.waiting
                                    ? Icons.qr_code_scanner
                                    : _state == ScanState.success
                                        ? Icons.check_circle
                                        : Icons.error,
                                color: Colors.white,
                                size: 20,
                              ),
                        const SizedBox(width: 8),
                        Text(
                          _state == ScanState.waiting ? 'Apunta al código QR' :
                          _state == ScanState.validating ? 'Validando...' :
                          _state == ScanState.success ? 'Acceso concedido' : 'Acceso denegado',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
