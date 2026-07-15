import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';

import 'firebase_identity.dart';

/// Xác minh Firebase ID token bằng Firebase Admin SDK phía server.
class FirebaseTokenVerifier implements IdentityTokenVerifier {
  FirebaseTokenVerifier(this._app);

  final FirebaseApp _app;

  @override
  Future<FirebaseIdentity> verify(String token) async {
    final decoded = await _app.auth().verifyIdToken(token, checkRevoked: true);
    final email = decoded.claims['email'];
    return FirebaseIdentity(
      uid: decoded.uid,
      email: email is String ? email : '${decoded.uid}@firebase.local',
    );
  }
}

/// Chỉ dùng khi chạy local với FIREBASE_DEV_AUTH=true.
/// Token hợp lệ: dev-teacher hoặc dev-student.
class DevelopmentTokenVerifier implements IdentityTokenVerifier {
  const DevelopmentTokenVerifier();

  @override
  Future<FirebaseIdentity> verify(String token) async {
    return switch (token) {
      'dev-teacher' => const FirebaseIdentity(
        uid: 'dev-teacher',
        email: 'teacher@flashly.local',
      ),
      'dev-student' => const FirebaseIdentity(
        uid: 'dev-student',
        email: 'student@flashly.local',
      ),
      _ => throw const FormatException('Development token không hợp lệ.'),
    };
  }
}
