// lib/widgets/hometown_address.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medsafe/widgets/toast.dart';

class HometownAddressWidget extends StatefulWidget {
  const HometownAddressWidget({super.key});

  @override
  State<HometownAddressWidget> createState() => _HometownAddressWidgetState();
}

class _HometownAddressWidgetState extends State<HometownAddressWidget> {
  bool _loading = true;
  String _address = '';
  String _lat = '';
  String _lng = '';

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _address = prefs.getString('hometown_address') ?? '';
      _lat = prefs.getString('hometown_latitude') ?? '';
      _lng = prefs.getString('hometown_longitude') ?? '';
      _loading = false;
    });
  }

  Future<void> _saveLocation({
    required String address,
    required String lat,
    required String lng,
  }) async {
    // Either address OR both coordinates must be present
    final hasAddress = address.trim().isNotEmpty;
    final hasCoords = lat.trim().isNotEmpty && lng.trim().isNotEmpty;

    if (!hasAddress && !hasCoords) {
      showToast(
        context,
        title: 'Missing info',
        description: 'Enter an address or both latitude and longitude.',
        isError: true,
      );
      return;
    }

    // If coordinates provided, validate they’re doubles
    if (hasCoords) {
      final dLat = double.tryParse(lat.trim());
      final dLng = double.tryParse(lng.trim());
      if (dLat == null || dLng == null || dLat.isNaN || dLng.isNaN) {
        showToast(
          context,
          title: 'Invalid coordinates',
          description: 'Use numeric values, e.g. 12.9716, 77.5946',
          isError: true,
        );
        return;
      }
      if (dLat < -90 || dLat > 90 || dLng < -180 || dLng > 180) {
        showToast(
          context,
          title: 'Out of range',
          description: 'Latitude must be -90..90 and longitude -180..180.',
          isError: true,
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hometown_address', address.trim());
    await prefs.setString('hometown_latitude', lat.trim());
    await prefs.setString('hometown_longitude', lng.trim());

    setState(() {
      _address = address.trim();
      _lat = lat.trim();
      _lng = lng.trim();
    });

    showToast(context,
        title: 'Hometown saved', description: 'We’ve updated your details.');
  }

  Future<void> _openInMaps() async {
    if (_lat.isEmpty || _lng.isEmpty) {
      showToast(
        context,
        title: 'No coordinates',
        description: 'Add latitude and longitude to open in Maps.',
        isError: true,
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps?q=$_lat,$_lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast(context,
          title: 'Could not open Maps', isError: true, description: '');
    }
  }

  Future<void> _openEditSheet() async {
    final t = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final addressCtrl = TextEditingController(text: _address);
    final latCtrl = TextEditingController(text: _lat);
    final lngCtrl = TextEditingController(text: _lng);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: t.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final inset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + inset),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Edit Hometown', style: t.textTheme.titleLarge),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    hintText: 'e.g. 221B Baker Street, London',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'e.g. 12.9716',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'e.g. 77.5946',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      // Soft validation: allow address only OR both coords
                      final a = addressCtrl.text;
                      final la = latCtrl.text;
                      final lo = lngCtrl.text;
                      await _saveLocation(address: a, lat: la, lng: lo);
                      if (mounted) Navigator.of(sheetCtx).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: Icon(Icons.home, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      Text('Hometown Address', style: t.textTheme.titleLarge),
                ),
                FilledButton.icon(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Address block
            if (_address.isNotEmpty)
              _InfoBlock(
                label: 'Address',
                value: _address,
              ),

            if (_lat.isNotEmpty && _lng.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoBlock(
                label: 'Coordinates',
                value: '$_lat, $_lng',
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

            if (_address.isEmpty && (_lat.isEmpty || _lng.isEmpty)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hometown set yet.',
                  style: t.textTheme.bodyMedium,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Add hometown'),
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
  final String label;
  final String value;

  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: t.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
