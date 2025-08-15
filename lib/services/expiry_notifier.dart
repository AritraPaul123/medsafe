import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ExpiryNotifier {
  static final _fln = FlutterLocalNotificationsPlugin();

  static Future<void> schedule(
    int itemId, {
    required String itemName,
    required DateTime expiryDate,
  }) async {
    final android = AndroidNotificationDetails(
      'medsafe_expiry',
      'Medical Kit Expiry',
      channelDescription: 'Expiry reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();

    final details = NotificationDetails(android: android, iOS: ios);

    Future<void> _scheduleAt(DateTime when, int idOffset, String label) async {
      if (when.isBefore(DateTime.now())) return;
      await _fln.zonedSchedule(
        itemId * 10 + idOffset,
        'Expiry: $itemName ($label)',
        'Expires on ${DateFormat('dd MMM yyyy').format(expiryDate)}',
        tz.TZDateTime.from(when, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
    }

    // Prep TZ (call once in app startup)
    await _ensureTZ();

    final d30 = expiryDate.subtract(const Duration(days: 30));
    final d7 = expiryDate.subtract(const Duration(days: 7));

    await _scheduleAt(d30, 1, '30 days left');
    await _scheduleAt(d7, 2, '7 days left');
  }

  static bool _tzInited = false;
  static Future<void> _ensureTZ() async {
    if (_tzInited) return;
    tz.initializeTimeZones();
    _tzInited = true;
  }
}
