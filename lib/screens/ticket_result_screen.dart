import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pantalla que muestra el resultado de la validación del ticket
/// Se muestra en pantalla completa con un botón para regresar al escáner
class TicketResultScreen extends StatefulWidget {
  final bool isValid;
  final String message;
  final String? ticketCode;
  final String? fullName;

  const TicketResultScreen({
    super.key,
    required this.isValid,
    required this.message,
    this.ticketCode,
    this.fullName,
  });

  @override
  State<TicketResultScreen> createState() => _TicketResultScreenState();
}

class _TicketResultScreenState extends State<TicketResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Color get _backgroundColor {
    return widget.isValid ? Colors.green : Colors.red;
  }

  IconData get _icon {
    return widget.isValid ? Icons.check_circle : Icons.cancel;
  }

  @override
  void initState() {
    super.initState();
    
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
    
    if (widget.isValid) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.vibrate();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _returnToScanner() {
    Navigator.of(context).pop();
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
                  Icon(
                    _icon,
                    color: Colors.white,
                    size: 180,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    widget.isValid ? '¡PASA!' : 'NO PASA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (widget.ticketCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.ticketCode!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  if (widget.fullName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.fullName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 50),
                  
                  // Botón para regresar al escáner
                  ElevatedButton.icon(
                    onPressed: _returnToScanner,
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      'Escanear otro ticket',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _backgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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
}
