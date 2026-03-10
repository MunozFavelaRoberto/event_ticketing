import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Pantalla que muestra el resultado de la validación del ticket
/// Se muestra en pantalla completa y vuelve automáticamente al escáner después de X segundos
class TicketResultScreen extends StatefulWidget {
  final bool isValid;
  final String message;
  final String? errorType;
  final int delaySeconds; // Delay dinámico en segundos

  const TicketResultScreen({
    super.key,
    required this.isValid,
    required this.message,
    this.errorType,
    this.delaySeconds = 3, // Valor por defecto
  });

  @override
  State<TicketResultScreen> createState() => _TicketResultScreenState();
}

class _TicketResultScreenState extends State<TicketResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  late int _countdown;
  Timer? _countdownTimer;

  bool get _isNetworkError => widget.errorType == 'networkError';

  Color get _backgroundColor {
    if (_isNetworkError) return Colors.orange;
    return widget.isValid ? Colors.green : Colors.red;
  }

  IconData get _icon {
    if (_isNetworkError) return Icons.signal_wifi_off;
    return widget.isValid ? Icons.check_circle : Icons.cancel;
  }

  @override
  void initState() {
    super.initState();
    
    // Animación de entrada
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // Inicializar countdown
    _countdown = widget.delaySeconds;
    _startCountdown();
    
    // Feedback háptico
    if (widget.isValid) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.vibrate();
      });
    }

    // Volver al escáner después del delay
    Future.delayed(Duration(seconds: widget.delaySeconds), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        
        if (_countdown <= 0) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono grande
                  Icon(
                    _icon,
                    color: Colors.white,
                    size: 180,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Texto principal
                  _isNetworkError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'SIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'CONEXIÓN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.isValid ? '¡PASA!' : 'NO PASA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Mensaje detallado
                  Text(
                    widget.message.isNotEmpty 
                        ? widget.message 
                        : (widget.isValid 
                            ? 'Boleto válido' 
                            : _getDefaultErrorMessage()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Indicador de countdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Volviendo al escáner en $_countdown...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDefaultErrorMessage() {
    switch (widget.errorType) {
      case 'alreadyUsed':
        return 'Boleto ya utilizado';
      case 'notFound':
        return 'Boleto no encontrado';
      case 'eventNotStarted':
        return 'El evento aún no ha iniciado';
      case 'eventEnded':
        return 'El evento ha finalizado';
      case 'invalidFormat':
        return 'Código inválido';
      case 'networkError':
        return 'Error de red. Verifica tu conexión.';
      default:
        return 'Error desconocido';
    }
  }
}
