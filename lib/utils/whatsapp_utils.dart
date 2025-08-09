import 'package:url_launcher/url_launcher.dart';

/// Shares the given message via WhatsApp.
/// Optionally includes a phone number.
Future<void> shareViaWhatsApp(String message, {String? phoneNumber}) async {
  final encodedMessage = Uri.encodeComponent(message);
  final url = phoneNumber != null
      ? 'https://wa.me/$phoneNumber?text=$encodedMessage'
      : 'https://wa.me/?text=$encodedMessage';

  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch WhatsApp';
  }
}

/// Creates an emergency WhatsApp message string including location and medical info.
String createEmergencyWhatsAppMessage({
  Map<String, dynamic>? location,
  Map<String, dynamic>? medicalInfo,
}) {
  String message = "🚨 EMERGENCY ALERT 🚨\n\n";
  message += "I need immediate help!\n\n";

  if (location != null &&
      location['latitude'] != null &&
      location['longitude'] != null) {
    message +=
        "📍 My location: https://maps.google.com/?q=${location['latitude']},${location['longitude']}\n\n";
  }

  if (medicalInfo != null) {
    if (medicalInfo['bloodGroup'] != null) {
      message += "🩸 Blood Group: ${medicalInfo['bloodGroup']}\n";
    }
    if (medicalInfo['allergies'] != null) {
      message += "⚠️ Allergies: ${medicalInfo['allergies']}\n";
    }
    if (medicalInfo['conditions'] != null) {
      message += "🏥 Medical Conditions: ${medicalInfo['conditions']}\n";
    }
    if (medicalInfo['medications'] != null) {
      message += "💊 Medications: ${medicalInfo['medications']}\n";
    }
  }

  message += "\nPlease contact emergency services if needed!";

  return message;
}
