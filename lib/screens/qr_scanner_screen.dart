import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kiosko/services/api_service.dart';
import 'package:kiosko/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:kiosko/screens/ticket_result_screen.dart';
import 'package:kiosko/utils/app_strings.dart';

enum ScanState { waiting, validating, success, failure, permissionDenied, networkError }

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  ScanState _state = ScanState.waiting;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  late MobileScannerController _controller;
  
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  AnimationController? _animationController;
  Animation<double>? _animation;
  
  bool _isInitialized = false;
  bool _isProcessing = false;

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
    });

    try {
      // Enviar el QR al backend para check-in
      final authToken = await _authService.getToken() ?? '';
      final result = await _apiService.checkinTicket(code, authToken);
      
      // Delay obligatorio de 1 segundo para mostrar que se procesó
      await Future.delayed(const Duration(seconds: 1));
      
      // Obtener datos de la respuesta
      final String message = result['message'] as String? ?? '';
      final Map<String, dynamic>? data = result['data'] as Map<String, dynamic>?;
      
      // Determinar si fue exitoso:
      // is_checked_in = 1 → NO está checkeado (puede pasar = true)
      // is_checked_in = 0 → YA está checkeado (no puede pasar = false)
      bool isValid = false;
      if (data != null) {
        final isCheckedIn = data['is_checked_in'] as int? ?? 1;
        // Si es 1, NO está checkeado → puede pasar
        // Si es 0, YA está checkeado → no puede pasar
        isValid = isCheckedIn == 1;
      }
      
      // Extraer datos del asistente
      String? ticketCode;
      String? fullName;
      if (data != null) {
        ticketCode = data['ticket_code'] as String?;
        final assistant = data['assistant'] as Map<String, dynamic>?;
        if (assistant != null) {
          fullName = assistant['full_name'] as String?;
        }
      }

      if (!mounted) return;
      
      if (isValid) {
        HapticFeedback.lightImpact();
        _navigateToResult(
          isValid: true, 
          message: message,
          ticketCode: ticketCode,
          fullName: fullName,
        );
      } else {
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.vibrate();
        
        _navigateToResult(
          isValid: false, 
          message: message,
          ticketCode: ticketCode,
          fullName: fullName,
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
          message: AppStrings.scannerNetworkError,
        );
      } else {
        _navigateToResult(
          isValid: false,
          message: e.toString(),
        );
      }
    }
  }

  void _navigateToResult({
    required bool isValid,
    required String message,
    String? ticketCode,
    String? fullName,
  }) {
    _controller.stop();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return TicketResultScreen(
            isValid: isValid,
            message: message,
            ticketCode: ticketCode,
            fullName: fullName,
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
      if (mounted) {
        _controller.start();
        setState(() {
          _state = ScanState.waiting;
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
              AppStrings.scannerScanning,
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
            Text(AppStrings.scannerValidating, style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        );
      case ScanState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 150),
            SizedBox(height: 8),
            Text(AppStrings.scannerAccessGranted, style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          ],
        );
      case ScanState.failure:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel, color: Colors.white, size: 150),
            SizedBox(height: 8),
            Text(AppStrings.scannerAccessDenied, style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          ],
        );
      case ScanState.networkError:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.white, size: 150),
            const SizedBox(height: 8),
            Text(AppStrings.scannerNetworkError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restartScanner,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.scannerTryAgain),
            ),
          ],
        );
      case ScanState.permissionDenied:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 150),
            const SizedBox(height: 8),
            Text(AppStrings.scannerPermissionDenied, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _state = ScanState.waiting);
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.scannerTryAgain),
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
        title: const Text(AppStrings.scannerTitle),
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
                          _state == ScanState.waiting ? AppStrings.scannerPointAtQr :
                          _state == ScanState.validating ? AppStrings.scannerValidating :
                          _state == ScanState.success ? AppStrings.scannerAccessGranted : AppStrings.scannerAccessDenied,
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
