class AppStrings {
  // Constructor privado para evitar instanciación
  AppStrings._();

  // ========== QR Generator ==========
  static const String qrTitle = "Mi boleto digital";
  static const String qrInstruction = "Muestra este código en la entrada";
  static const String qrLoading = "Generando QR...";
  static const String qrNoData = "No se pudo generar el QR: datos de usuario no disponibles.";
  static const String qrNoTicket = "No tienes un boleto activo en este momento.";
  static const String qrError = "Error al cargar el boleto. Intenta de nuevo.";
  static const String qrRetry = "Reintentar";
  static const String qrValid = "Boleto válido";

  // ========== QR Scanner ==========
  static const String scannerTitle = "Escaner de Boletos";
  static const String scannerScanning = "ESCANEANDO...";
  static const String scannerValidating = "Validando...";
  static const String scannerAccessGranted = "¡PASA!";
  static const String scannerAccessDenied = "NO PASA";
  static const String scannerPermissionDenied = "Permiso de cámara denegado. Por favor, habilítalo en la configuración de la aplicación.";
  static const String scannerOpenSettings = "Abrir configuración";
  static const String scannerNetworkError = "Error de red. Verifica tu conexión.";
  static const String scannerTryAgain = "Intentar de nuevo";
  static const String scannerPointAtQr = "Apunta al código QR";

  // ========== Errores de Ticket ==========
  static const String ticketErrorInvalid = "Código inválido o formato incorrecto";
  static const String ticketErrorUsed = "Boleto ya utilizado";
  static const String ticketErrorNotFound = "Boleto no encontrado";
  static const String ticketErrorEventNotStarted = "El evento aún no ha iniciado";
  static const String ticketErrorEventEnded = "El evento ha finalizado";
  static const String ticketErrorNetwork = "Error de red. Verifica tu conexión.";
  static const String ticketErrorUnknown = "Error desconocido";

  // ========== Login ==========
  static const String loginTitle = "Iniciar Sesión";
  static const String loginUser = "Usuario";
  static const String loginPassword = "Contraseña";
  static const String loginInvalidCredentials = "Credenciales incorrectas";
  static const String loginFillFields = "Por favor, completa todos los campos";

  // ========== Common ==========
  static const String save = "Guardar";
  static const String cancel = "Cancelar";
  static const String retry = "Reintentar";
  static const String ok = "Aceptar";
  static const String yes = "Sí";
  static const String no = "No";
  static const String logout = "Cerrar sesión";
  static const String logoutConfirm = "¿Estás seguro de que deseas salir?";
  static const String loggingOut = "Cerrando sesión...";
  static const String loading = "Cargando...";
}
