import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kiosko/services/theme_provider.dart';
import 'package:kiosko/services/data_provider.dart';
import 'package:kiosko/services/api_service.dart';
import 'package:kiosko/services/auth_service.dart';
import 'package:kiosko/screens/login_screen.dart';
import 'package:kiosko/screens/home_screen.dart';
import 'package:kiosko/screens/qr_generator_screen.dart';
import 'package:kiosko/screens/qr_scanner_screen.dart';
import 'package:kiosko/utils/app_routes.dart';

Future<void> main() async {
  // Necesario para que SharedPreferences funcione antes del runApp
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<DataProvider>(
          create: (context) => DataProvider(
            authService: Provider.of<AuthService>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
          ),
        ),
      ],
      child: const KioskoApp(),
    ),
  );
}

// Navegador global para empujar rutas desde Widgets fuera del árbol
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class KioskoApp extends StatelessWidget {
  const KioskoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return MaterialApp(
      title: 'Kiosko',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return _UnauthorizedWrapper(child: child ?? const SizedBox.shrink());
      },
      home: const CheckAuthScreen(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.generateQr: (context) => const QrGeneratorScreen(),
        AppRoutes.scanQr: (context) => const QrScannerScreen(),
      },
    );
  }
}

/// Wrapper que muestra pantalla de "No Autorizado" cuando es necesario
class _UnauthorizedWrapper extends StatelessWidget {
  final Widget child;
  const _UnauthorizedWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Verificar estado de autorización
    final dataProvider = context.watch<DataProvider>();
    
    // Solo mostrar pantalla de "No Autorizado" después de que:
    // 1. Se haya intentado obtener los datos del usuario (hasAttemptedFetch)
    // 2. Y el servidor haya rechazado la solicitud explícitamente
    if (dataProvider.hasAttemptedFetch && dataProvider.isUnauthorized) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Text(
            'NO AUTORIZADO',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
    
    return child;
  }
}

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bool loggedIn = await authService.isLoggedIn();
    
    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}
