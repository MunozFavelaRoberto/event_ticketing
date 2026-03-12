class AppStrings {
  // Constructor privado para evitar instanciación
  AppStrings._();

  // ========== QR Scanner ==========
  static const String scannerTitle = "Escaner de Boletos";
  static const String scannerScanning = "ESCANEANDO...";
  static const String scannerValidating = "Validando...";
  static const String scannerAccessGranted = "¡PASA!";
  static const String scannerAccessDenied = "NO PASA";
  static const String scannerPermissionDenied = "Permiso de cámara denegado. Por favor, habilítalo en la configuración de la aplicación.";
  static const String scannerNetworkError = "Error de red. Verifica tu conexión.";
  static const String scannerTryAgain = "Intentar de nuevo";
  static const String scannerPointAtQr = "Apunta al código QR";

  // ========== Login ==========
  static const String loginTitle = "Iniciar Sesión";
  static const String loginUser = "Usuario";
  static const String loginPassword = "Contraseña";
  static const String loginInvalidCredentials = "Credenciales incorrectas";
  static const String loginFillFields = "Por favor, completa todos los campos";

  // ========== Common ==========
  static const String logout = "Cerrar sesión";
  static const String logoutConfirm = "¿Estás seguro de que deseas salir?";
  static const String loggingOut = "Cerrando sesión...";
  static const String loading = "Cargando...";
}
