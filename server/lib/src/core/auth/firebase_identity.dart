class FirebaseIdentity {
  const FirebaseIdentity({required this.uid, required this.email});

  final String uid;
  final String email;
}

abstract interface class IdentityTokenVerifier {
  Future<FirebaseIdentity> verify(String token);
}
