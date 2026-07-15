# Flashly Dart backend

Backend REST API viết bằng Dart. Firebase chỉ dùng để xác minh ID token; CRUD
Quiz/Test được lưu trong SQLite riêng của server.

## Chạy local bằng tài khoản demo

PowerShell:

```powershell
$env:FIREBASE_DEV_AUTH='true'
dart run bin/server.dart
```

Token demo:

- Teacher: `Authorization: Bearer dev-teacher`
- Student: `Authorization: Bearer dev-student`

Không bật `FIREBASE_DEV_AUTH` khi deploy.

## Chạy với Firebase thật

Thiết lập `GOOGLE_APPLICATION_CREDENTIALS` trỏ tới service-account JSON, sau đó
chạy `dart run bin/server.dart`. Không commit service-account JSON vào Git.

## API Quiz/Test

- `GET /api/quizzes/`
- `GET /api/quizzes/:id`
- `POST /api/quizzes/`
- `PUT /api/quizzes/:id`
- `DELETE /api/quizzes/:id`
