import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Proves Firebase Auth + Firestore round-trip against the local Firebase
/// Emulator Suite. Assumes `Firebase.initializeApp()` plus
/// `useAuthEmulator`/`useFirestoreEmulator` were already called in
/// `main.dart` before this function runs.
Future<String> testFirebaseInitAuthFirestore() async {
  // Emulator-only test credential (per Security Domain V2 / threat T-0-02):
  // this account only exists inside the local Auth Emulator sandbox, never a
  // real Firebase project, so it is safe to hardcode here.
  const email = 'spike_test_user@example.com';
  const password = 'SpikeTest123!';

  try {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (authError) {
      if (authError.code == 'email-already-in-use') {
        // Re-run of the spike: same emulator-only test account already
        // exists, so fall back to signing in with the same credential.
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    final docRef = FirebaseFirestore.instance
        .collection('spike_test')
        .doc('spike_doc');
    await docRef.set({'value': 'hello-firebase'});
    final snapshot = await docRef.get();

    return 'FIREBASE PASS: ' '${snapshot.data()}';
  } catch (e) {
    return 'FIREBASE FAIL: ' '$e';
  }
}
