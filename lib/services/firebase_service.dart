/// Shared Firebase Authentication bootstrap for the Flutter application.
///
/// This is currently a stub so the project can run before Firebase is
/// configured. The Auth feature owner must:
///
/// 1. Add `firebase_core` and `firebase_auth` to the Flutter project.
/// 2. Run `flutterfire configure` to generate `firebase_options.dart`.
/// 3. Replace the stub in [init] with `Firebase.initializeApp(...)`.
/// 4. Send the Firebase ID token to [ApiService] after sign-in.
///
/// Flashly uses Firebase only for identity. Application data and roles remain
/// in the Dart server database; Cloud Firestore is not required.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    // TODO(auth): await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    _initialized = true;
  }
}
