import 'package:shelf/shelf.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.role,
    required this.status,
  });

  final int id;
  final String firebaseUid;
  final String email;
  final String role;
  final String status;

  bool get isStudent => role == 'student';
  bool get isTeacher => role == 'teacher';
  bool get isAdmin => role == 'admin';

  factory AppUser.fromRow(Map<String, Object?> row) {
    return AppUser(
      id: row['user_id'] as int,
      firebaseUid: row['firebase_uid'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
      status: row['status'] as String,
    );
  }

  Map<String, Object?> toJson() => {
    'userId': id,
    'firebaseUid': firebaseUid,
    'email': email,
    'role': role,
    'status': status,
  };
}

const authenticatedUserContextKey = 'flashly.authenticated_user';

extension AuthenticatedRequest on Request {
  AppUser get currentUser {
    final user = context[authenticatedUserContextKey];
    if (user is! AppUser) {
      throw StateError('Request chưa đi qua authentication middleware.');
    }
    return user;
  }
}
