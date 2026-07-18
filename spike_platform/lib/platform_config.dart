import 'dart:io';

/// Platform-conditional Firebase Emulator Suite connection constants.
///
/// The Android emulator cannot reach the host machine's `localhost` directly —
/// it must use the special loopback alias `10.0.2.2`, which routes to
/// `127.0.0.1` on the host running `firebase emulators:start`. Non-Android
/// platforms (used only for `flutter analyze` / unit tests in this spike)
/// fall back to `localhost`.
///
/// See 00-RESEARCH.md Pattern 1 (Platform-Conditional Emulator Constants).

/// Port the Firebase Auth Emulator listens on (see firebase.json).
const int kAuthEmulatorPort = 9099;

/// Port the Firestore Emulator listens on (see firebase.json).
const int kFirestoreEmulatorPort = 8080;

/// Host to reach the Auth Emulator from the running app.
String get kAuthEmulatorHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';

/// Host to reach the Firestore Emulator from the running app.
String get kFirestoreEmulatorHost =>
    Platform.isAndroid ? '10.0.2.2' : 'localhost';
