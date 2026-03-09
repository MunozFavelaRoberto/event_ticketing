# Ticketing App Shell

This repository started as a sample kiosk/payment application and has been
refactored into a lightweight Flutter "shell" for experimenting with a
QR-based ticket validation workflow.

## Features included

- Email/password login (existing implementation preserved)
- Biometric support and session persistence
- Global theme provider
- Simple home screen with navigation drawer
- QR generator and scanner using `qr_flutter` and `mobile_scanner`
- Fake API service stub (`validateTicket`) for offline testing
- Minimal `DataProvider` managing user profile caching
- Example widget test demonstrating provider setup

## Getting Started

1. **Clone and open** this project in VS Code / Android Studio.
2. Run `flutter pub get` to fetch dependencies.
3. Use `flutter run` on an Android or iOS device/emulator.
4. A login screen will appear; you can type any credentials to reach home.
5. From the drawer, generate a hardcoded QR or open the scanner.

### Using as a template

- Rename the package (`kiosko`) by updating `pubspec.yaml` and
  corresponding Android/iOS identifiers.
- Customize the login flow or replace the backend client with your own
  implementation.
- Add more screens or models under `lib/screens` and `lib/models`.
- Replace `ApiService.validateTicket` with real network calls.

## Dependencies

Only essential packages are kept:

- `provider` for state management
- `local_auth` for biometrics
- `qr_flutter` & `mobile_scanner` for QR operations

Feel free to remove or add libraries as your project evolves.

## Testing

A basic widget test is located at `test/widget_test.dart`. It sets up
providers similarly to `main.dart` and asserts the initial loading
indicator. Expand this as you add new features.

---

This shell is intended as a starting point. Follow the comments in the
source code to understand how pieces fit together, and iterate freely!