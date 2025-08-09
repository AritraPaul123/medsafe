import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:medsafe/utils/geocoding_service.dart';
import 'package:medsafe/utils/location_utils.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LocationService extends StatefulWidget {
  const LocationService({super.key});

  @override
  State<LocationService> createState() => _LocationServiceState();
}

class _LocationServiceState extends State<LocationService> {
  bool isLoading = false;
  Position? currentPosition;
  Address? currentAddress;

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => currentPosition = position);

      Address address = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      setState(() => currentAddress = address);

      await StorageUtils.saveLocation(UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch));

      Fluttertoast.showToast(
        msg:
            "Location Retrieved: Accuracy ${position.accuracy.toStringAsFixed(0)}m",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Location Error: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openInMaps() async {
    if (currentPosition != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${currentPosition!.latitude},${currentPosition!.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        Fluttertoast.showToast(msg: 'Could not open Google Maps');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade900,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurpleAccent, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: const Icon(Icons.location_pin,
                  size: 36, color: Colors.purpleAccent),
            ),
            const SizedBox(height: 12),
            const Text(
              'Current Location',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _getCurrentLocation,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                  isLoading ? 'Getting Location...' : 'Get Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            if (currentPosition != null) ...[
              if (currentAddress != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade700,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Address:',
                          style: TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentAddress!.formatted,
                          style: const TextStyle(color: Colors.white70)),
                      const Divider(color: Colors.purpleAccent),
                      if (currentAddress!.street != null)
                        Text('Street: ${currentAddress!.street}',
                            style: const TextStyle(color: Colors.white70)),
                      if (currentAddress!.city != null)
                        Text('City: ${currentAddress!.city}',
                            style: const TextStyle(color: Colors.white70)),
                      if (currentAddress!.state != null)
                        Text('State: ${currentAddress!.state}',
                            style: const TextStyle(color: Colors.white70)),
                      if (currentAddress!.country != null)
                        Text('Country: ${currentAddress!.country}',
                            style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${currentPosition!.latitude.toStringAsFixed(6)}, ${currentPosition!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(color: Colors.purpleAccent),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
