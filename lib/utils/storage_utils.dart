import 'dart:convert';
import 'package:medsafe/utils/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageUtils {
  static const _EMERGENCY_CONTACTS = 'medsafe_emergency_contacts';
  static const _MEDICAL_INFO = 'medsafe_medical_info';
  static const _LAST_LOCATION = 'medsafe_last_location';
  static const _HOMETOWN_ADDRESS = 'medsafe_hometown_address';
  static const _CURRENT_MANUAL_LOCATION = 'medsafe_current_manual_location';

  // Emergency Contacts
  static Future<void> saveEmergencyContacts(
      List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_EMERGENCY_CONTACTS,
        jsonEncode(contacts.map((e) => e.toJson()).toList()));
  }

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_EMERGENCY_CONTACTS);
    if (stored == null) return [];
    final List parsed = jsonDecode(stored);
    return parsed.map((e) => EmergencyContact.fromJson(e)).toList();
  }

  // Medical Info
  static Future<void> saveMedicalInfo(MedicalInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_MEDICAL_INFO, jsonEncode(info.toJson()));
  }

  static Future<MedicalInfo> getMedicalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_MEDICAL_INFO);
    if (stored == null) {
      return MedicalInfo(
        bloodGroup: '',
        allergies: '',
        conditions: '',
        medications: '',
        emergencyMessage:
            'EMERGENCY! I need immediate help. Please check my location:',
      );
    }
    return MedicalInfo.fromJson(jsonDecode(stored));
  }

  // Last Location
  static Future<void> saveLocation(UserLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_LAST_LOCATION, jsonEncode(location.toJson()));
  }

  static Future<UserLocation?> getLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_LAST_LOCATION);
    return stored != null ? UserLocation.fromJson(jsonDecode(stored)) : null;
  }

  // Hometown Manual Location
  static Future<void> saveHometownLocation(ManualLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_HOMETOWN_ADDRESS, jsonEncode(location.toJson()));
  }

  static Future<ManualLocation?> getHometownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_HOMETOWN_ADDRESS);
    if (stored == null) return null;

    try {
      final parsed = jsonDecode(stored);
      if (parsed is String) {
        return ManualLocation(
            address: parsed, timestamp: DateTime.now().millisecondsSinceEpoch);
      }
      return ManualLocation.fromJson(parsed);
    } catch (_) {
      return ManualLocation(
          address: stored, timestamp: DateTime.now().millisecondsSinceEpoch);
    }
  }

  static Future<String> getHometownAddress() async {
    final location = await getHometownLocation();
    return location?.address ?? '';
  }

  // Current Manual Location
  static Future<void> saveCurrentManualLocation(ManualLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_CURRENT_MANUAL_LOCATION, jsonEncode(location.toJson()));
  }

  static Future<ManualLocation?> getCurrentManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_CURRENT_MANUAL_LOCATION);
    return stored != null ? ManualLocation.fromJson(jsonDecode(stored)) : null;
  }
}
