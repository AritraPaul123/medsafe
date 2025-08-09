// services/insurance_service.dart
import 'package:hive/hive.dart';

class InsuranceService {
  static Future<Box> _box() => Hive.openBox('insurance');

  static Future<void> save({
    required String provider,
    required String policy,
    String? hotline,
  }) async {
    final b = await _box();
    await b.put('provider', provider);
    await b.put('policy', policy);
    if (hotline != null) await b.put('hotline', hotline);
  }

  static Future<Map<String, String>> get() async {
    final b = await _box();
    return {
      'provider': (b.get('provider') ?? '') as String,
      'policy': (b.get('policy') ?? '') as String,
      'hotline': (b.get('hotline') ?? '') as String,
    };
  }

  static Future<String> briefForSOS() async {
    final m = await get();
    final p = (m['provider']?.isNotEmpty ?? false) ? m['provider']! : 'N/A';
    final po = (m['policy']?.isNotEmpty ?? false) ? m['policy']! : 'N/A';
    final h = (m['hotline']?.isNotEmpty ?? false) ? m['hotline']! : 'N/A';
    return "$p | Policy: $po | Hotline: $h";
  }
}
