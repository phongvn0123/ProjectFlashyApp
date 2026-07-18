import 'package:firebase_core/firebase_core.dart';

/// Dummy, emulator-only Firebase configuration for the `spike_platform`
/// throwaway project.
///
/// This is NOT a real Firebase project — `apiKey` deliberately avoids the
/// real Firebase Web API key prefix so that credential-hygiene grep checks
/// (Plan 00-03 Task 1) never produce a false positive. Firebase Auth/Firestore are
/// only ever reached through the local Firebase Emulator Suite (see
/// `platform_config.dart` for host/port), so no real backend credentials are
/// needed for this spike.
const FirebaseOptions spikeFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-api-key-not-a-real-key',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-spike-project',
  storageBucket: 'demo-spike-project.appspot.com',
);
