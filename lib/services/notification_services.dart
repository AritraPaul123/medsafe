import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medsafe/controllers/sos_controller.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navKey;

  static const _channelId = 'sos_channel';
  static const _channelName = 'SOS';
  static const _channelDesc = 'Emergency alerts';

  @pragma('vm:entry-point') // needed for background taps on Android
  static void _onBackgroundTap(NotificationResponse r) {
    // no-op; just registering the callback keeps Android happy
  }

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navKey = navigatorKey;

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: initAndroid),
      onDidReceiveNotificationResponse: (resp) => _handleTap(resp.payload),
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Android 13+ runtime notif permission
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      // High-importance channel for full-screen intents
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl
          ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));
    }

    // If app was launched by a full-screen notif (cold start), handle it
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch!.notificationResponse?.payload;
      if (payload == 'sos') {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runSos());
      }
    }
  }

  static void _handleTap(String? payload) {
    if (payload == 'sos') _runSos();
  }

  static void _runSos() {
    final ctx = _navKey?.currentContext;
    if (ctx != null) {
      SosController.activateSOS(ctx);
    }
  }

  /// Post a **full-screen** notification that wakes screen and opens the app
  static Future<void> showSosFullScreen() async {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call, // eligible for full-screen
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );

    await _plugin.show(
      1001,
      'Emergency SOS',
      'Tap to open SOS controls',
      const NotificationDetails(android: android),
      payload: 'sos',
    );
  }

  /// (Optional) a small quick-action notification (heads-up only)
  static Future<void> showSosQuickAction() async {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    await _plugin.show(
      1002,
      'SOS',
      'Tap to open SOS',
      const NotificationDetails(android: android),
      payload: 'sos',
    );
  }
}
