// lib/widgets/sos_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medsafe/widgets/toast.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isActivating = false;

  Future<void> _confirmAndActivate() async {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 40),
            const SizedBox(height: 8),
            Text('Activate SOS?', style: t.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This will send your location and emergency note to your contacts, then place a call to the first contact.',
              style: t.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sos),
                label: const Text('Send SOS now'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _activateSOS();
    }
  }

  Future<void> _activateSOS() async {
    if (!mounted) return;
    setState(() => _isActivating = true);
    HapticFeedback.selectionClick();

    try {
      // Get current location
      final location = await getCurrentLocation();

      // Get medical info and contacts
      final medicalInfo = await getMedicalInfo();
      final contacts = await getEmergencyContacts();

      if (contacts.isEmpty) {
        showToast(
          context,
          title: 'No contacts found',
          description: 'Add emergency contacts before using SOS.',
          isError: true,
        );
        return;
      }

      // Create emergency message with location
      final emergencyMessage =
          createEmergencyWhatsAppMessage(location, medicalInfo);

      // Share via WhatsApp
      await shareViaWhatsApp(emergencyMessage);

      // Save location
      await saveLocation(location);

      // Call first contact after a short pause
      Future.delayed(const Duration(seconds: 2), () {
        makePhoneCall(contacts[0]['phone']);
        if (mounted) {
          showToast(
            context,
            title: 'Calling emergency contact',
            description: 'Calling ${contacts[0]['name']}…',
          );
        }
      });

      if (mounted) {
        showToast(
          context,
          title: 'SOS activated',
          description: 'Location sent to your contacts.',
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          title: 'SOS failed',
          description: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big round SOS button
          Semantics(
            button: true,
            label: _isActivating ? 'Activating SOS' : 'Activate SOS',
            child: ElevatedButton(
              onPressed: _isActivating ? null : _confirmAndActivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(32),
                elevation: 2,
              ),
              child: _isActivating
                  ? const SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.sos, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isActivating ? 'Activating SOS…' : 'Activate SOS',
            style: t.textTheme.headlineMedium?.copyWith(color: cs.error),
          ),
          const SizedBox(height: 8),
          Text(
            _isActivating
                ? 'Getting your location and sending alerts…'
                : 'Sends your location to emergency contacts and initiates a call.',
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // --- Replace these with your real implementations/services as needed ---

  Future<Map<String, dynamic>> getCurrentLocation() async {
    // Simulate fetching current location
    return {'latitude': 40.7128, 'longitude': -74.0060};
  }

  Future<Map<String, dynamic>> getMedicalInfo() async {
    // Simulate retrieving stored medical info
    return {
      'bloodType': 'O+',
      'conditions': ['Asthma'],
      'note': 'Carry inhaler',
    };
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    // Simulate stored contacts
    return [
      {'name': 'John Doe', 'phone': '+919875668732'}
    ];
  }

  String createEmergencyWhatsAppMessage(
    Map<String, dynamic> location,
    Map<String, dynamic> medicalInfo,
  ) {
    final lat = location['latitude'];
    final lng = location['longitude'];
    final maps = 'https://www.google.com/maps?q=$lat,$lng';
    final cond = (medicalInfo['conditions'] as List?)?.join(', ') ?? 'None';
    final note = (medicalInfo['note'] ?? '').toString();

    return 'EMERGENCY!\n'
        'My location: $maps\n'
        'Blood type: ${medicalInfo['bloodType']}\n'
        'Conditions: $cond\n'
        '${note.isNotEmpty ? 'Note: $note' : ''}';
  }

  Future<void> shareViaWhatsApp(String message) async {
    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }

  Future<void> saveLocation(Map<String, dynamic> location) async {
    // Simulate saving location
    debugPrint('Location saved: $location');
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not place call');
    }
  }
}
