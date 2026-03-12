import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kiosko/main.dart';
import 'package:kiosko/services/theme_provider.dart';
import 'package:kiosko/services/auth_service.dart';
import 'package:kiosko/services/api_service.dart';
import 'package:kiosko/services/data_provider.dart';

// simple fake that overrides network/storage interactions
class FakeAuthService extends AuthService {
  @override
  Future<bool> isLoggedIn() async => false;
}


Widget buildAppForTest() {
  final themeProvider = ThemeProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      Provider<AuthService>(create: (_) => FakeAuthService()),
      Provider<ApiService>(create: (_) => ApiService()),
      ChangeNotifierProvider<DataProvider>(
        create: (context) => DataProvider(
          authService: Provider.of<AuthService>(context, listen: false),
          apiService: Provider.of<ApiService>(context, listen: false),
        ),
      ),
    ],
    child: const KioskoApp(),
  );
}

void main() {
  testWidgets('App shows loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(buildAppForTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
