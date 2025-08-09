import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HometownAddressWidget extends StatefulWidget {
  const HometownAddressWidget({super.key});

  @override
  State<HometownAddressWidget> createState() => _HometownAddressWidgetState();
}

class _HometownAddressWidgetState extends State<HometownAddressWidget> {
  bool isEditing = false;
  String address = '';
  String latitude = '';
  String longitude = '';

  @override
  void initState() {
    super.initState();
    loadSavedLocation();
  }

  Future<void> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('hometown_address');
    final lat = prefs.getString('hometown_latitude');
    final lng = prefs.getString('hometown_longitude');

    if (savedAddress != null || (lat != null && lng != null)) {
      setState(() {
        address = savedAddress ?? '';
        latitude = lat ?? '';
        longitude = lng ?? '';
      });
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  Future<void> saveLocation() async {
    if (address.trim().isNotEmpty ||
        (latitude.isNotEmpty && longitude.isNotEmpty)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hometown_address', address.trim());
      await prefs.setString('hometown_latitude', latitude);
      await prefs.setString('hometown_longitude', longitude);

      Fluttertoast.showToast(msg: "Hometown Saved");
      setState(() => isEditing = false);
    } else {
      Fluttertoast.showToast(
        msg: "Enter address or coordinates",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void openInMaps() {
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      final url = "https://www.google.com/maps?q=$latitude,$longitude";
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade900,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.home, color: Colors.lightBlueAccent, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Hometown Address',
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isEditing) ...[
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Address (Optional)',
                    labelStyle: TextStyle(color: Colors.white)),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => address = value,
                controller: TextEditingController(text: address),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Latitude',
                          labelStyle: TextStyle(color: Colors.white)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => latitude = value,
                      controller: TextEditingController(text: latitude),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Longitude',
                          labelStyle: TextStyle(color: Colors.white)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) => longitude = value,
                      controller: TextEditingController(text: longitude),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: saveLocation,
                      icon: const Icon(Icons.save),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (address.isNotEmpty ||
                      (latitude.isNotEmpty && longitude.isNotEmpty))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: const Text("Cancel"),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                    )
                ],
              )
            ] else ...[
              if (address.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Address:",
                        style: TextStyle(color: Colors.blueAccent)),
                    Text(address, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                  ],
                ),
              if (latitude.isNotEmpty && longitude.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Coordinates:",
                        style: TextStyle(color: Colors.blueAccent)),
                    Text("$latitude, $longitude",
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (latitude.isNotEmpty && longitude.isNotEmpty)
                    IconButton(
                      onPressed: openInMaps,
                      icon:
                          const Icon(Icons.map, color: Colors.lightBlueAccent),
                    ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
