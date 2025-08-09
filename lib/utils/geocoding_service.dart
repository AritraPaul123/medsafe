import 'dart:convert';
import 'package:http/http.dart' as http;

class Address {
  final String formatted;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  Address({
    required this.formatted,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });
}

class GeocodingService {
  /// Reverse geocoding: Get address from coordinates
  static Future<Address> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'MedsafeApp/1.0'},
      );

      if (response.statusCode != 200) {
        throw Exception('Geocoding service unavailable');
      }

      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('Address not found');
      }

      final address = data['address'] ?? {};
      final formatted = data['display_name'] ??
          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

      return Address(
        formatted: formatted,
        street:
            '${address['house_number'] ?? ''} ${address['road'] ?? ''}'.trim(),
        city: address['city'] ??
            address['town'] ??
            address['village'] ??
            address['suburb'],
        state: address['state'] ?? address['province'],
        country: address['country'],
        postalCode: address['postcode'],
      );
    } catch (e) {
      print('Reverse geocoding error: $e');
      return Address(
          formatted: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}');
    }
  }

  /// Forward geocoding: Get coordinates from address string
  static Future<Map<String, double>?> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'MedsafeApp/1.0'},
      );

      if (response.statusCode != 200) {
        throw Exception('Geocoding service unavailable');
      }

      final data = jsonDecode(response.body);
      if (data.isEmpty) {
        return null;
      }

      return {
        'lat': double.parse(data[0]['lat']),
        'lng': double.parse(data[0]['lon']),
      };
    } catch (e) {
      print('Forward geocoding error: $e');
      return null;
    }
  }
}
