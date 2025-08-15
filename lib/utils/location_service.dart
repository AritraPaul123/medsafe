// lib/utils/location_service.dart
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medsafe/widgets/toast.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medsafe/utils/geocoding_service.dart';
import 'package:medsafe/utils/location_utils.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:medsafe/widgets/toast.dart';

class LocationService extends StatefulWidget {
  const LocationService({super.key});

  @override
  State<LocationService> createState() => _LocationServiceState();
}

class _LocationServiceState extends State<LocationService> {
  bool _isLoading = false;
  Position? _currentPosition;
  Address? _currentAddress;

  // ——— Permissions & location ———

  Future<bool> _ensurePermission() async {
    // Check service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToast(
        context,
        title: 'Location disabled',
        description: 'Turn on GPS/Location Services.',
        isError: true,
      );
      // Offer to open settings
      await Geolocator.openLocationSettings();
      return false;
    }

    // Check permission state
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      showToast(
        context,
        title: 'Permission blocked',
        description: 'Enable location in app settings.',
        isError: true,
      );
      await Geolocator.openAppSettings();
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showToast(
          context,
          title: 'Permission required',
          description: 'We need location to fetch your position.',
          isError: true,
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final ok = await _ensurePermission();
      if (!ok) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      setState(() => _currentPosition = position);

      final address = await GeocodingService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      setState(() => _currentAddress = address);

      await StorageUtils.saveLocation(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      showToast(
        context,
        title: 'Location retrieved',
        description: 'Accuracy ~${position.accuracy.toStringAsFixed(0)} m',
      );
    } catch (e) {
      showToast(
        context,
        title: 'Location error',
        description: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openInMaps() async {
    final pos = _currentPosition;
    if (pos == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showToast(
        context,
        title: 'Could not open Maps',
        description: 'Try again or copy the coordinates.',
        isError: true,
      );
    }
  }

  // ——— UI ———

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
            // Icon + title
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.my_location, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Location',
                    style: t.textTheme.titleLarge,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Get location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                    _isLoading ? 'Getting location…' : 'Get current location'),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (_currentPosition != null) ...[
              _LocationInfoCard(
                address: _currentAddress,
                position: _currentPosition!,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Google Maps'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  final Address? address;
  final Position position;

  const _LocationInfoCard({
    required this.address,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.colorScheme.outline.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address != null) ...[
            Text('Address', style: t.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              address!.formatted,
              style: t.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _kv('Street', address!.street),
            _kv('City', address!.city),
            _kv('State', address!.state),
            _kv('Country', address!.country),
            const SizedBox(height: 12),
          ],
          Text(
            'Coordinates',
            style: t.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            style: t.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
