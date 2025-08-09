import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class AssistantService {
  static Future<Box> box() => Hive.openBox('assistant');

  // ====== Storage ======
  static Future<void> setAssistant(
      {required String phone, String? name}) async {
    final b = await box();
    await b.put('phone', phone.trim());
    if (name != null) await b.put('name', name.trim());
  }

  static Future<String?> getPhone() async =>
      (await box()).get('phone') as String?;
  static Future<String?> getName() async =>
      (await box()).get('name') as String?;

  // ====== Helpers ======
  static Future<bool> _ensureAssistantExists(BuildContext context) async {
    final phone = await getPhone();
    if (phone != null && phone.isNotEmpty) return true;

    // Prompt once if empty
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Set Personal Assistant'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+911234567890',
            labelText: 'WhatsApp / Phone number (with country code)',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await setAssistant(phone: ctrl.text.trim());
      return true;
    }
    return false;
  }

  static String _normalizePhone(String phone) =>
      phone.replaceAll('+', '').replaceAll(' ', '');

  // ====== Actions ======
  static Future<void> callAssistant(BuildContext context) async {
    if (!await _ensureAssistantExists(context)) return;
    final phone = await getPhone();
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  static Future<void> whatsappAssistant({
    required BuildContext context,
    required String message,
  }) async {
    if (!await _ensureAssistantExists(context)) return;
    final phone = _normalizePhone((await getPhone())!);
    final wa =
        Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    await launchUrl(wa, mode: LaunchMode.externalApplication);
  }

  static Future<void> whatsappAssistantWithLocation(
      BuildContext context) async {
    if (!await _ensureAssistantExists(context)) return;

    // Get current coords; if denied, fall back to plain message
    Position? pos;
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    final link = (pos != null)
        ? 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}'
        : 'Location: unavailable';
    final msg = '🚨 Need help. Location: $link';

    await whatsappAssistant(context: context, message: msg);
  }

  static Future<void> callNearestHospital() async {
    // Dialer/Maps search
    // geo: works on Android; on iOS fallback to Apple/Google maps query
    if (Platform.isAndroid) {
      await launchUrl(Uri.parse('geo:0,0?q=hospital'));
    } else {
      final q = Uri.encodeComponent('hospital');
      // Try Apple Maps
      if (!await launchUrl(Uri.parse('http://maps.apple.com/?q=$q'))) {
        await launchUrl(Uri.parse('https://maps.google.com/?q=$q'));
      }
    }
  }

  static Future<void> bookRideToHospital() async {
    // Try Uber first, then Ola, then web fallback
    final uberDeep = Uri.parse(
        'uber://?action=setPickup&dropoff[formatted_address]=Nearest%20Hospital');
    final olaDeep = Uri.parse('olacabs://ride');
    if (await canLaunchUrl(uberDeep)) {
      await launchUrl(uberDeep, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(olaDeep)) {
      await launchUrl(olaDeep, mode: LaunchMode.externalApplication);
      return;
    }
    await launchUrl(Uri.parse('https://m.uber.com/ul/')); // generic fallback
  }
}
