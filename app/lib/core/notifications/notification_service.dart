import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    // Canal de alarma — bypasea DND y enciende pantalla
    final channel = AndroidNotificationChannel(
      'productivity_alerts',
      'Alertas de Productividad',
      description: 'Alertas de postura y ambiente del cuarto de trabajo.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
      enableLights: true,
      ledColor: Colors.red,
      showBadge: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Solicitar permiso de notificaciones (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      42,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'productivity_alerts',
          'Alertas de Productividad',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
          visibility: NotificationVisibility.public,
          autoCancel: false,
        ),
      ),
    );
  }

  static Future<void> cancelAlert() async {
    await _plugin.cancel(42);
  }
}
