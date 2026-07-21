import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Yêu cầu quyền thông báo (quan trọng cho iOS và Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
      
      // Lấy Token để demo (UC Notification)
      String? token = await _fcm.getToken();
      log('FCM Token: $token');

      // Lắng nghe khi có thông báo đến trong khi app đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log('Nhận thông báo khi app đang mở: ${message.notification?.title}');
      });

      // Lắng nghe khi người dùng bấm vào thông báo để mở app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log('Người dùng đã bấm vào thông báo!');
      });
    } else {
      log('User declined or has not accepted permission');
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
