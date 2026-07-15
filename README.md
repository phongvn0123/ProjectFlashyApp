# Flashly

Flashly has a Flutter frontend in `lib/` and a separate Dart REST backend in
`server/`. Flutter can run directly as a Windows desktop application; an
Android Emulator is not required.

## One-time Windows setup

1. Install Flutter and Visual Studio 2022 (not only Visual Studio Code).
2. In Visual Studio Installer, enable **Desktop development with C++**.
3. Enable **Developer Mode** in Windows Settings so Flutter plugins can create
   symbolic links.
4. Check the toolchain:

```powershell
flutter doctor
flutter config --enable-windows-desktop
flutter pub get
```

## Run locally

Start the Dart backend in the first terminal:

```powershell
cd server
$env:FIREBASE_DEV_AUTH='true'
dart pub get
dart run bin/server.dart
```

Start the Flutter Windows frontend in a second terminal from the project root:

```powershell
flutter run -d windows
```

On Windows the frontend calls `http://localhost:8080/api/`. On an Android
Emulator it uses `http://10.0.2.2:8080/api/`. Override the address for a real
device or shared server when needed:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/
```

## Local SQLite

- Android/iOS use `sqflite`.
- Windows/Linux use `sqflite_common_ffi`.
- Features continue using `LocalDbService`; they do not call FFI directly.
- The SQLite file on each member's computer is only local cache/offline data.
- Shared application data remains in the SQLite database owned by the Dart
  backend.

## Team boundaries

Feature code normally stays in both:

- `lib/features/<feature>/`
- `server/lib/src/features/<feature>/`

Notify the team before changing shared router/constants, `lib/services/`,
`server/lib/flashly_server.dart`, dependencies, or `server/migrations/`.
