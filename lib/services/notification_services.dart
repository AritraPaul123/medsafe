// lib/services/notification_services.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/main.dart'; // for navigatorKey if you keep it there

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'sos_quick';
  static const _channelName = 'SOS Quick Action';
  static const _channelDesc = 'Quick SOS button on lock screen';
  static const _notifId = 1001;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload ?? '';
        if (payload == 'medsafe://sos') {
          final ctx = navigatorKey.currentContext;
          if (ctx != null) SosController.activateSOS(ctx);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ runtime permission
      await androidImpl?.requestNotificationsPermission();

      // High-importance, lock-screen visible channel
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: false,
        showBadge: false,
      );
      await androidImpl?.createNotificationChannel(channel);
    }
  }

  static Future<void> showSosQuickAction() async {
    if (!Platform.isAndroid) return;

    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      visibility: NotificationVisibility.public, // <- show on lock screen
      category: AndroidNotificationCategory.service,
      ongoing: true, // <- persistent
      autoCancel: false,
      onlyAlertOnce: true,
    );

    await _plugin.show(
      _notifId,
      'SOS Emergency',
      'Tap to activate SOS',
      const NotificationDetails(android: android),
      payload: 'medsafe://sos', // handled in initialize() above
    );
  }

  static Future<void> cancelQuickAction() async {
    await _plugin.cancel(_notifId);
  }
}

// Background tap handler (required by plugin >= 10)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // On cold start, plugin will forward this to onDidReceive... after init,
  // so we generally don’t need to do anything special here.
}
