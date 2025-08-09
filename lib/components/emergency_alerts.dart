import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:medsafe/utils/location_utils.dart';
import 'package:medsafe/utils/communication_service.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:medsafe/widgets/toast.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmergencyAlert extends StatefulWidget {
  const EmergencyAlert({super.key});

  @override
  State<EmergencyAlert> createState() => _EmergencyAlertState();
}

class _EmergencyAlertState extends State<EmergencyAlert> {
  bool isLoading = false;

  Future<void> sendEmergencyAlert() async {
    setState(() => isLoading = true);

    try {
      final contacts = await StorageUtils.getEmergencyContacts();
      if (contacts.isEmpty) {
        showToast(
          context,
          title: "No Emergency Contacts",
          description: "Please add emergency contacts before sending alerts",
          isError: true,
        );
        setState(() => isLoading = false);
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

      await StorageUtils.saveLocation(UserLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));

      showToast(
        context,
        title: "Emergency Alerts Sent!",
        description: "Alerts sent to ${contacts.length} contact(s)",
      );
    } catch (e) {
      showToast(
        context,
        title: "Alert Failed",
        description: e.toString(),
        isError: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF7F1D1D).withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Color(0xFFFCA5A5),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            // Heading
            const Text(
              "Emergency Alert",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFECACA),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This will:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text("• Get your current location",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("• Send SMS to all emergency contacts",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("• Include Google Maps link to your location",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("• Include your custom emergency message",
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : sendEmergencyAlert,
                icon: isLoading
                    ? const SpinKitFadingCircle(color: Colors.white, size: 20)
                    : const Icon(LucideIcons.messageSquare),
                label: Text(
                  isLoading
                      ? "Sending Emergency Alert..."
                      : "SEND EMERGENCY ALERT",
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Footer Note
            const Text(
              "Only use in real emergencies. This will send SMS messages to your emergency contacts.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFECACA), fontSize: 11),
            )
          ],
        ),
      ),
    );
  }
}
