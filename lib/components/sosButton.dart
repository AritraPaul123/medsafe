import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool isActivating = false;

  Future<void> activateSOS() async {
    setState(() {
      isActivating = true;
    });

    try {
      // Get current location
      final location = await getCurrentLocation();

      // Get medical info and contacts
      final medicalInfo = await getMedicalInfo();
      final contacts = await getEmergencyContacts();

      // Create emergency message with location
      final emergencyMessage =
          createEmergencyWhatsAppMessage(location, medicalInfo);

      // Share via WhatsApp
      await shareViaWhatsApp(emergencyMessage);

      // Save location
      await saveLocation(location);

      // Call first contact
      if (contacts.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          makePhoneCall(contacts[0]['phone']);
          showToast(
              "Calling Emergency Contact", "Calling ${contacts[0]['name']}...");
        });
      }

      showToast("SOS Activated!", "Emergency alert sent with your location");
    } catch (e) {
      showToast("SOS Failed", e.toString(), isError: true);
    } finally {
      setState(() {
        isActivating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: isActivating ? null : activateSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(32),
              elevation: 10,
            ),
            child: isActivating
                ? const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.warning, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            isActivating ? 'ACTIVATING SOS...' : 'ACTIVATE SOS',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          Text(
            isActivating
                ? 'Getting your location and sending emergency alert...'
                : 'Press to send your location to emergency contacts and call for help',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> getCurrentLocation() async {
    // Simulate fetching current location
    return {'latitude': 40.7128, 'longitude': -74.0060};
  }

  Future<Map<String, dynamic>> getMedicalInfo() async {
    // Simulate retrieving stored medical info
    return {
      'bloodType': 'O+',
      'conditions': ['Asthma']
    };
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    // Simulate stored contacts
    return [
      {'name': 'John Doe', 'phone': '+919875668732'}
    ];
  }

  String createEmergencyWhatsAppMessage(
      Map<String, dynamic> location, Map<String, dynamic> medicalInfo) {
    return "Emergency! My location is ${location['latitude']}, ${location['longitude']}. Blood type: ${medicalInfo['bloodType']}. Conditions: ${medicalInfo['conditions'].join(",")}";
  }

  Future<void> shareViaWhatsApp(String message) async {
    final uri =
        Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception("Could not launch WhatsApp");
    }
  }

  Future<void> saveLocation(Map<String, dynamic> location) async {
    // Simulate saving location
    debugPrint("Location saved: $location");
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception("Could not place call");
    }
  }

  void showToast(String title, String description, {bool isError = false}) {
    final color = isError ? Colors.red : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title\n$description"),
        backgroundColor: color,
      ),
    );
  }
}
