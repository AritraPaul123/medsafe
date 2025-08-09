import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class CommunicationUtils {
  /// Make a phone call
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  /// Send a single SMS
  static Future<void> sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch $smsUri';
    }
  }

  /// Send emergency alerts to a list of contacts with delay
  static Future<void> sendEmergencyAlerts(
      List<String> contacts, String message) async {
    for (int i = 0; i < contacts.length; i++) {
      await Future.delayed(Duration(seconds: i)); // Staggered delay
      await sendSMS(contacts[i], message);
    }
  }
}
