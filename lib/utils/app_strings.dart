import 'dart:ui';

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

  // ========== Biometric Lock ==========
  static const String biometricTitle = "Kiosko Protegido";
  static const String biometricConfirmIdentity = "Confirma tu identidad";
  static const String biometricIdentify = "Identifícate para continuar";
  static const String biometricUse = "Usar";
  static const String biometricUsePassword = "Entrar con contraseña";
  static const String biometricTooManyAttempts = "Demasiados intentos. Usa contraseña.";

  // ========== Login ==========
  static const String loginTitle = "Iniciar Sesión";
  static const String loginUser = "Usuario";
  static const String loginPassword = "Contraseña";
  static const String loginInvalidCredentials = "Credenciales incorrectas";
  static const String loginFillFields = "Por favor, completa todos los campos";

  // ========== Profile ==========
  static const String profileTitle = "Mi perfil";
  static const String profileFullName = "Nombre completo";
  static const String profileEmail = "Correo electrónico";
  static const String profileEditEmail = "Editar correo electrónico";
  static const String profileEmailUpdated = "Correo actualizado correctamente";
  static const String profileErrorUpdating = "Error al actualizar el correo";
  static const String profileDarkMode = "Modo oscuro";
  static const String profileBiometrics = "Biometría";
  static const String profileBiometricActive = "Seguridad activa";
  static const String profileBiometricInactive = "Sin biometría activada";
  static const String profileNotAvailable = "No disponible";
  static const String profileNotSupported = "Tu dispositivo no admite biometría";
  static const String profileLoading = "Cargando perfil...";
  static const String profileConnectionError = "Error de conexión";
  static const String profileLoadError = "No se pudo cargar los datos del perfil";

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

/// Clase para manejar la localización de la app
/// Uso futuro con flutter_localizations
class AppLocalizations {
  // Locale actual - se configurará dinámicamente
  static Locale _locale = const Locale('es'); // Default: Español

  static Locale get locale => _locale;

  static void setLocale(Locale locale) {
    _locale = locale;
  }

  /// Obtener string traducida según el locale actual
  static String get(String key) {
    // Implementación futura con Map<String, Map<String, String>>
    // Por ahora retorna la clave
    return key;
  }
}
