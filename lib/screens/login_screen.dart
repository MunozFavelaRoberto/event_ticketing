import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kiosko/services/auth_service.dart';
import 'package:kiosko/services/data_provider.dart';
import 'package:kiosko/utils/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Instancia de autenticación
  late final AuthService _authService;

  // Form key para validación
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar texto de los campos
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  // Focus nodes para detectar cuando el campo pierde el foco
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();

  // Variable indicador de carga
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Validación de usuario
  String? _validateUser(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su correo';
    }
    return null;
  }

  // Validación de contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su contraseña';
    }
    return null;
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    
    // Agregar listeners para detectar cuando el campo pierde el foco
    _userFocusNode.addListener(() {
      if (!_userFocusNode.hasFocus && _userController.text.trim().isEmpty) {
        _formKey.currentState?.validate();
      }
    });
    
    _passFocusNode.addListener(() {
      if (!_passFocusNode.hasFocus && _passController.text.trim().isEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }
  
  // Función que centraliza el éxito del login
  Future<void> _handleLoginSuccess() async {
    // Guardar datos del usuario en DataProvider
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    dataProvider.setUserFromLogin(
      authService.loggedUserId ?? 0,
      authService.loggedUserFullName ?? 'Usuario',
      authService.loggedUserEmail ?? 'email@desconocido.com',
    );
    
    // Resetear estado de autorización en DataProvider
    dataProvider.resetUnauthorized();
    
    if (!mounted) return;
    
    // Navegamos al Home y eliminamos la pantalla de login del historial
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  // Login por botón
  void _loginWithPassword() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    final email = _userController.text.trim();
    final pass = _passController.text.trim();

    if (email.isNotEmpty && pass.isNotEmpty) {
      try {
        final response = await _authService.login(email, pass);
        
        // Delay obligatorio de 1 segundo para mostrar al usuario que su petición está siendo procesada
        await Future.delayed(const Duration(seconds: 1));
        
        if (response != null) {
          await _handleLoginSuccess();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenciales incorrectas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Mostrar error genérico para no revelar detalles internos
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBlocked = _isLoading;

    return PopScope(
      canPop: !isBlocked,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // logo original en la parte superior
                          Image.asset('assets/images/svr_logo.png', height: 100, width: 100),
                          const SizedBox(height: 40),

                          // Campo Email
                          AbsorbPointer(
                            absorbing: isBlocked,
                            child: Opacity(
                              opacity: isBlocked ? 0.5 : 1.0,
                              child: TextFormField(
                                controller: _userController,
                                focusNode: _userFocusNode,
                                style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Usuario',
                                  hintStyle: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                  prefixIcon: Icon(Icons.email_outlined, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                                  errorStyle: const TextStyle(color: Color(0xFFCF6679)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colorScheme.primary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFCF6679)),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFCF6679)),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateUser,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Campo Contraseña
                          AbsorbPointer(
                            absorbing: isBlocked,
                            child: Opacity(
                              opacity: isBlocked ? 0.5 : 1.0,
                              child: TextFormField(
                                controller: _passController,
                                focusNode: _passFocusNode,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Contraseña',
                                  hintStyle: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                                  prefixIcon: Icon(Icons.lock_outline, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                                    ),
                                    onPressed: isBlocked ? null : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  errorStyle: const TextStyle(color: Color(0xFFCF6679)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: colorScheme.primary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFCF6679)),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFCF6679)),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                validator: _validatePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Botón Ingresar
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _loginWithPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.green)
                                  : Text("INICIAR SESIÓN", style: theme.textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
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
