import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PlatformException for error surfacing
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ManualLocationPage extends StatelessWidget {
  const ManualLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Location')),
      body: const SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(child: ManualLocationEntry()),
      ),
    );
  }
}

class ManualLocationEntry extends StatefulWidget {
  const ManualLocationEntry({super.key});

  @override
  State<ManualLocationEntry> createState() => _ManualLocationEntryState();
}

class _ManualLocationEntryState extends State<ManualLocationEntry> {
  // Replace with your real key (keep it out of source control in production)
  static const String _kGoogleApiKey =
      'AIzaSyCFT2bpuZamzvz49My7QVc0trVrZHmqLaY';

  final _formKey = GlobalKey<FormState>();
  final _searchCtrl = TextEditingController();

  late final places.FlutterGooglePlacesSdk _places;
  GoogleMapController? _mapCtrl;

  List<places.AutocompletePrediction> _predictions = [];

  // Debug flags to surface problems
  bool _loadingPreds = false;
  String? _placesError;

  // Default camera over India
  static const _initialTarget = LatLng(20.5937, 78.9629);
  LatLng? _picked;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _places = places.FlutterGooglePlacesSdk(_kGoogleApiKey);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.trim().length < 2) {
      setState(() {
        _predictions = [];
        _placesError = null;
      });
      return;
    }
    setState(() {
      _loadingPreds = true;
      _placesError = null;
    });
    try {
      final res = await _places.findAutocompletePredictions(
        value,
        countries: const ['in'], // optional bias
      );
      if (!mounted) return;
      setState(() => _predictions = res.predictions);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _placesError = '${e.code}: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPreds = false);
    }
  }

  Future<void> _selectPrediction(places.AutocompletePrediction p) async {
    final placeId = p.placeId;
    if (placeId.isEmpty) return;

    try {
      final details = await _places.fetchPlace(
        placeId,
        fields: const [places.PlaceField.Location, places.PlaceField.Address],
      );

      final loc = details.place?.latLng;
      if (loc == null) return;

      final pos = LatLng(loc.lat, loc.lng);
      setState(() {
        _picked = pos;
        _marker = Marker(markerId: const MarkerId('picked'), position: pos);
        _searchCtrl.text = details.place?.address ?? p.fullText;
        _predictions = [];
      });

      await _mapCtrl?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16)),
      );
    } on PlatformException catch (e) {
      setState(() => _placesError = '${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _placesError = e.toString());
    }
  }

  void _saveLocation() {
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search and select a place first')),
      );
      return;
    }
    // Save logic here...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Pick a Location', style: t.textTheme.titleLarge),
              const SizedBox(height: 12),

              // Search field
              TextFormField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search place or address',
                  hintText: 'Type to search…',
                  border: const OutlineInputBorder(),
                  prefixIcon: _loadingPreds
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
                validator: (_) =>
                    (_picked == null) ? 'Please select a place' : null,
              ),

              if (_placesError != null) ...[
                const SizedBox(height: 8),
                Text('Places error: $_placesError',
                    style: TextStyle(color: cs.error)),
              ],

              // Autocomplete dropdown
              if (_predictions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: t.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: t.colorScheme.outline.withOpacity(0.35)),
                  ),
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _predictions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = _predictions[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(
                                p.fullText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectPrediction(p),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Image(
                          image: places.FlutterGooglePlacesSdk
                              .ASSET_POWERED_BY_GOOGLE_ON_WHITE,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Map
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _initialTarget,
                      zoom: 4,
                    ),
                    onMapCreated: (c) => _mapCtrl = c,
                    markers: _marker != null ? {_marker!} : {},
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Location'),
                  onPressed: _saveLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
