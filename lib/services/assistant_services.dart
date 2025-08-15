import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:medsafe/widgets/toast.dart';
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

  static Future<List<Map<String, dynamic>>> listContacts() async {
    final b = await box();
    final raw = (b.get('contacts') as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final list = <Map<String, dynamic>>[];
    raw.forEach((id, value) {
      final m = (value as Map).cast<String, dynamic>();
      list.add({'id': id, 'name': m['name'], 'phone': m['phone']});
    });
    // Optional: sort by name
    list.sort((a, b_) => (a['name'] as String)
        .toLowerCase()
        .compareTo((b_['name'] as String).toLowerCase()));
    return list;
  }

  static Future<void> upsertContact(
      {String? id, required String name, required String phone}) async {
    final b = await box();
    final Map<String, dynamic> raw =
        (b.get('contacts') as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final contactId = id ?? _randId();
    raw[contactId] = {'name': name, 'phone': phone};
    await b.put('contacts', raw);
  }

  static Future<void> updateContact(
      {required String id, required String name, required String phone}) async {
    final b = await box();
    final Map<String, dynamic> raw =
        (b.get('contacts') as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    if (!raw.containsKey(id)) return;
    raw[id] = {'name': name, 'phone': phone};
    await b.put('contacts', raw);
  }

  static Future<void> deleteContact(String id) async {
    final b = await box();
    final Map<String, dynamic> raw =
        (b.get('contacts') as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    raw.remove(id);
    await b.put('contacts', raw);
  }

  static String _randId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(12, (_) => chars[rnd.nextInt(chars.length)]).join();
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

  static Future<void> bookRideToHospital(BuildContext context,
      {String dropLabel = 'Nearest Hospital'}) async {
    final encoded = Uri.encodeComponent(dropLabel);

    // Known ride apps (add more if you support them)
    final candidates = <_RideApp>[
      _RideApp(
        name: 'Uber',
        scheme: Uri.parse(
            'uber://?action=setPickup&dropoff[formatted_address]=$encoded'),
        web: Uri.parse(
            'https://m.uber.com/ul/?action=setPickup&dropoff[formatted_address]=$encoded'),
        icon: Icons.directions_car_filled,
      ),
      _RideApp(
        name: 'Ola',
        scheme: Uri.parse(
            'olacabs://ride'), // basic entry; Ola supports richer params if you add them
        web: Uri.parse('https://book.olacabs.com/'),
        icon: Icons.local_taxi,
      ),
      _RideApp(
        name: 'Rapido',
        scheme: Uri.parse(
            'rapido://'), // some installs respond to rapido:// or rapidobike://
        web: Uri.parse('https://rapido.bike/'),
        icon: Icons.pedal_bike,
      ),
      _RideApp(
        name: 'inDrive',
        scheme: Uri.parse('indriver://'),
        web: Uri.parse('https://indrive.com/'),
        icon: Icons.directions_car,
      ),
      _RideApp(
        name: 'Lyft',
        scheme: Uri.parse('lyft://ridetype?id=lyft'), // if present on device
        web: Uri.parse('https://ride.lyft.com/'),
        icon: Icons.time_to_leave,
      ),
      _RideApp(
        name: 'Bolt',
        scheme: Uri.parse('bolt://ride'), // EMEA/India in some regions
        web: Uri.parse('https://bolt.eu/'),
        icon: Icons.electric_bolt,
      ),
      _RideApp(
        name: 'Meru',
        scheme: Uri.parse('merucabs://'),
        web: Uri.parse('https://www.meru.in/'),
        icon: Icons.local_taxi_outlined,
      ),
    ];

    // Filter to installed via deep link scheme
    final installed = <_RideApp>[];
    for (final app in candidates) {
      try {
        if (await canLaunchUrl(app.scheme)) {
          installed.add(app);
        }
      } catch (_) {}
    }

    // If nothing installed, offer web fallbacks picker
    final listToShow = installed.isNotEmpty ? installed : candidates;

    // Show a simple picker
    final selected = await showModalBottomSheet<_RideApp>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Book a ride', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (installed.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No ride apps detected. You can use a website instead.',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                ...listToShow.map((app) => ListTile(
                      leading: Icon(app.icon),
                      title: Text(app.name),
                      subtitle: installed.isNotEmpty
                          ? null
                          : Text(app.web.host,
                              style: Theme.of(ctx).textTheme.bodySmall),
                      onTap: () => Navigator.of(ctx).pop(app),
                    )),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    // Prefer deep link if installed list; otherwise open web
    final target = installed.isNotEmpty ? selected.scheme : selected.web;

    try {
      final ok = await launchUrl(target, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('Could not open ${selected.name}');
    } catch (e) {
      // Try the other link as fallback
      final fallback =
          target == selected.scheme ? selected.web : selected.scheme;
      if (fallback != null) {
        try {
          final ok2 =
              await launchUrl(fallback, mode: LaunchMode.externalApplication);
          if (!ok2) throw Exception('Could not open ${selected.name}');
        } catch (_) {
          showToast(context,
              title: 'Could not open app',
              description: 'Please try another option.',
              isError: true);
        }
      } else {
        showToast(context,
            title: 'Could not open app',
            description: 'Please try another option.',
            isError: true);
      }
    }
  }
}

class _RideApp {
  final String name;
  final Uri scheme; // deep-link
  final Uri web; // website fallback
  final IconData icon;
  _RideApp(
      {required this.name,
      required this.scheme,
      required this.web,
      required this.icon});
}
