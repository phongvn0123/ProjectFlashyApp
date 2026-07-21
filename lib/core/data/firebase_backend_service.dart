import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBackendService {
  FirebaseBackendService._();

  static final FirebaseBackendService instance = FirebaseBackendService._();

  Future<bool> tryInitialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } on FirebaseException catch (error) {
      return error.code == 'duplicate-app';
    } catch (_) {
      return false;
    }
  }

  Future<void> writeHeartbeat() async {
    final initialized = await tryInitialize();
    if (!initialized) return;
    await FirebaseFirestore.instance
        .collection('app_health')
        .doc('android')
        .set({
          'app': 'memocard',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
