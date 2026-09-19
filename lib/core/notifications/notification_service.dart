import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'waffart_high',
        'Waffart Notifications',
        importance: Importance.high,
      ),
    );

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    await _saveToken();
    _fcm.onTokenRefresh.listen(_saveTokenToServer);
  }

  static Future<void> _saveToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveTokenToServer(token);
  }

  static Future<void> _saveTokenToServer(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id': userId,
      'fcm_token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'is_active': true,
    }, onConflict: 'fcm_token');
  }

  static void _handleForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _localNotifications.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'waffart_high',
          'Waffart',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleOpened(RemoteMessage message) {
    final type = message.data['type'];
    final refId = message.data['reference_id'];
    if (kDebugMode) debugPrint('Opened: $type - $refId');
  }

  static void _onTap(NotificationResponse response) {
  }
}
