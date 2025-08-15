// lib/pages/live_location_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medsafe/utils/geocoding_service.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:medsafe/widgets/toast.dart';

class LiveLocationPage extends StatelessWidget {
  const LiveLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Location')),
      body: const SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: LiveLocationCard(), // defined below in the same file
        ),
      ),
    );
  }
}

class LiveLocationCard extends StatefulWidget {
  const LiveLocationCard({super.key});

  @override
  State<LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<LiveLocationCard> {
  bool _loading = false;
  Position? _pos;
  Address? _addr;

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      // Ensure permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        showToast(context,
            title: 'Location permission required',
            description: 'Enable location access to get your position.',
            isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final addr =
          await GeocodingService.reverseGeocode(pos.latitude, pos.longitude);

      setState(() {
        _pos = pos;
        _addr = addr;
      });

      // Persist last known location (if you use it elsewhere)
      await StorageUtils.saveLocation(
        UserLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      showToast(
        context,
        title: 'Location retrieved',
        description: 'Accuracy ${pos.accuracy.toStringAsFixed(0)} m',
      );
    } catch (e) {
      showToast(context,
          title: 'Location error', description: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInMaps() async {
    if (_pos == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_pos!.latitude},${_pos!.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      showToast(context,
          title: 'Could not open Maps', description: '', isError: true);
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
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      Text('Current Location', style: t.textTheme.titleLarge),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _getCurrentLocation,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                    _loading ? 'Getting location…' : 'Get current location'),
              ),
            ),

            const SizedBox(height: 16),

            if (_pos != null) ...[
              if (_addr != null)
                _InfoBlock(
                  title: 'Address',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_addr!.formatted, style: t.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (_addr!.street != null) 'Street: ${_addr!.street}',
                          if (_addr!.city != null) 'City: ${_addr!.city}',
                          if (_addr!.state != null) 'State: ${_addr!.state}',
                          if (_addr!.country != null)
                            'Country: ${_addr!.country}',
                        ].join(' • '),
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              _InfoBlock(
                title: 'Coordinates',
                child: Text(
                  '${_pos!.latitude.toStringAsFixed(6)}, ${_pos!.longitude.toStringAsFixed(6)}',
                  style: t.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.map_outlined),
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.labelLarge),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
