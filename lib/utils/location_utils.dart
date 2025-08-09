import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

class LocationUtils {
  /// Gets the current location of the user.
  static Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location access denied by user');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      throw Exception('Unable to retrieve location: $e');
    }
  }

  /// Generates a Google Maps link for the given latitude and longitude.
  static String generateGoogleMapsLink(double lat, double lng) {
    return 'https://www.google.com/maps?q=$lat,$lng';
  }

  /// Generates an emergency message with an optional custom message.
  static String generateLocationMessage(
      double lat, double lng, String? customMessage) {
    final mapsLink = generateGoogleMapsLink(lat, lng);
    const defaultMessage =
        'EMERGENCY! I need immediate help. Please check my location:';
    return '${customMessage ?? defaultMessage} $mapsLink';
  }
}
