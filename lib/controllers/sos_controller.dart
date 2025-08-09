import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:live_activities/live_activities.dart';
import 'package:medsafe/services/insurance_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

// Very small local store for MVP
class ContactsStore {
  // Expect your /contacts page to write into this box
  static Future<Box> _box() async => await Hive.openBox('emergency_store');

  static Future<List<String>> getWhatsAppNumbers() async {
    final b = await _box();
    // expecting a List<String> like ["+919875668732", "+919876543210"]
    final list = (b.get('wa_numbers') as List?)?.cast<String>() ?? const [];
    return list;
  }

  static Future<void> seedIfEmpty() async {
    final b = await _box();
    if (b.get('wa_numbers') == null) {
      await b.put('wa_numbers', <String>["+919875668732"]); // replace later
    }
  }
}

class SosLogEntry {
  final DateTime at;
  final double lat;
  final double lng;
  SosLogEntry(this.at, this.lat, this.lng);
  Map<String, dynamic> toJson() =>
      {"at": at.toIso8601String(), "lat": lat, "lng": lng};
}

class SosLogger {
  static Future<void> save(SosLogEntry e) async {
    final b = await Hive.openBox('sos_logs');
    final list = (b.get('items') as List?)?.cast<Map<String, dynamic>>() ?? [];
    list.add(e.toJson());
    await b.put('items', list);
  }
}

class SosController {
  static final LiveActivities _live = LiveActivities();
  static String? _activityId;

  static Future<void> startLiveActivity(double lat, double lng) async {
    try {
      final enabled = await _live.areActivitiesEnabled();
      if (!enabled) return;

      final attributes = jsonEncode({
        "incidentId": DateTime.now().toIso8601String(),
      });

      final contentState = {
        "status": "active",
        "latitude": lat,
        "longitude": lng,
        "startedAt": DateTime.now().toIso8601String(),
      };

      final id = await _live.createActivity(attributes, contentState);
      _activityId = id;
    } catch (e) {
      // See compat wrapper below if you want to handle both signatures
      print("Failed to start Live Activity: $e");
    }
  }

  static Future<void> endLiveActivity() async {
    try {
      if (_activityId != null) {
        await _live.endActivity(_activityId!);
        _activityId = null;
      }
    } catch (e) {
      print("Failed to end Live Activity: $e");
    }
  }

  static Future<void> activateSOS(BuildContext context) async {
    try {
      await ContactsStore.seedIfEmpty();

      // 1) Permissions
      final locStatus = await Permission.location.request();
      if (!locStatus.isGranted) {
        _toast(context, 'Location permission is required.');
        return;
      }

      // 2) Get current location
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      final lat = pos.latitude;
      final lng = pos.longitude;
      /*final mapsLink = Platform.isIOS
          ? "http://maps.apple.com/?ll=$lat,$lng"
          : "https://maps.google.com/?q=$lat,$lng";

      final ts = DateFormat('dd/MM/yyyy, HH:mm:ss').format(DateTime.now());

// 4) Build WhatsApp message (exact template)
      final message = Uri.encodeComponent("🚨 Medical Emergency Alert 🚨\n"
          "Location: https://maps.google.com/?q=$lat,$lng\n"
          "Time: $ts\n"
          "Message: Need ambulance or medical help immediately.");

      // 3) Build message (edit to taste)

      // 4) Fetch WhatsApp contacts from store
      final targets = await ContactsStore.getWhatsAppNumbers();
      if (targets.isEmpty) {
        _toast(context, 'Add emergency WhatsApp contacts first.');
        return;
      }

      // 5) Open WhatsApp deep link for each contact (user taps Send)
      for (final phone in targets) {
        final wa = Uri.parse(
            "https://wa.me/${phone.replaceAll('+', '')}?text=$message");
        print("WhatsApp link: $wa");
        try {
          await launchUrl(wa, mode: LaunchMode.externalApplication);
        } catch (e) {
          _toast(context, 'Cannot open WhatsApp for $phone');
        }
      }*/
      // Build message with insurance
      final ts = DateFormat('dd/MM/yyyy, HH:mm:ss').format(DateTime.now());
      final maps = "https://maps.google.com/?q=$lat,$lng";
      final insuranceBrief = await InsuranceService.briefForSOS();

      final rawMsg = "🚨 Medical Emergency Alert 🚨\n"
          "Location: $maps\n"
          "Time: $ts\n"
          "Insurance: $insuranceBrief\n"
          "Message: Need ambulance or medical help immediately.";
      final targets = await ContactsStore.getWhatsAppNumbers();
// 1) WhatsApp (your existing loop)
      final waMsg = Uri.encodeComponent(rawMsg);
      for (final phone in targets) {
        final wa =
            Uri.parse("https://wa.me/${phone.replaceAll('+', '')}?text=$waMsg");
        if (await canLaunchUrl(wa)) {
          await launchUrl(wa, mode: LaunchMode.externalApplication);
        }
      }

// 2) SMS (open composer per contact)
      Future<void> sendSms(String number, String message) async {
        // iOS/Android both understand sms:… with body (UI will open; user taps Send)
        final smsUri = Uri(
          scheme: 'sms',
          path: number,
          queryParameters: {"body": message},
        );
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }

      for (final phone in targets) {
        await sendSms(phone, rawMsg);
      }
      // 6) Log it
      await SosLogger.save(SosLogEntry(DateTime.now(), lat, lng));
      _toast(context, 'SOS prepared in WhatsApp. Send the messages.');
    } catch (e) {
      _toast(context, 'SOS failed: $e');
    }
  }

  static void _toast(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
  }
}
