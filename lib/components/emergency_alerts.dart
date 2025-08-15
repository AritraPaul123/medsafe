// lib/widgets/emergency_alerts.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:medsafe/utils/location_utils.dart';
import 'package:medsafe/utils/communication_service.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:medsafe/widgets/toast.dart';

class EmergencyAlert extends StatefulWidget {
  const EmergencyAlert({super.key});

  @override
  State<EmergencyAlert> createState() => _EmergencyAlertState();
}

class _EmergencyAlertState extends State<EmergencyAlert> {
  bool _isLoading = false;

  Future<void> _sendEmergencyAlert() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final contacts = await StorageUtils.getEmergencyContacts();
      if (contacts.isEmpty) {
        showToast(
          context,
          title: 'No emergency contacts',
          description: 'Add at least one contact before sending alerts.',
          isError: true,
        );
        return;
      }

      final location = await LocationUtils.getCurrentLocation();
      final medicalInfo = await StorageUtils.getMedicalInfo();

      final emergencyMessage = LocationUtils.generateLocationMessage(
        location.latitude,
        location.longitude,
        medicalInfo.emergencyMessage,
      );

      final phoneNumbers = contacts.map((c) => c.phone).toList();
      await CommunicationUtils.sendEmergencyAlerts(
          phoneNumbers, emergencyMessage);

      await StorageUtils.saveLocation(
        UserLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      showToast(
        context,
        title: 'Emergency alerts sent',
        description: 'Sent to ${contacts.length} contact(s).',
      );
    } catch (e) {
      showToast(
        context,
        title: 'Alert failed',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.alertTriangle, color: cs.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Emergency Alert', style: t.textTheme.titleLarge),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Info block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This will:', style: t.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  _InfoLine(text: 'Get your current location'),
                  _InfoLine(text: 'Send SMS to all emergency contacts'),
                  _InfoLine(text: 'Include a Google Maps link'),
                  _InfoLine(text: 'Include your custom emergency message'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Primary action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendEmergencyAlert,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.messageSquare),
                label: Text(_isLoading
                    ? 'Sending emergency alert…'
                    : 'Send emergency alert'),
              ),
            ),

            const SizedBox(height: 10),

            // Footer note
            Text(
              'Use only in real emergencies. This will send SMS messages to your emergency contacts.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;
  const _InfoLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: t.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
