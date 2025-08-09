import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ManualLocationEntry extends StatefulWidget {
  @override
  _ManualLocationEntryState createState() => _ManualLocationEntryState();
}

class _ManualLocationEntryState extends State<ManualLocationEntry> {
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      address = prefs.getString('address') ?? '';
      latitude = prefs.getString('latitude') ?? '';
      longitude = prefs.getString('longitude') ?? '';
      isEditing = address.isEmpty && latitude.isEmpty && longitude.isEmpty;
    });
  }

  Future<void> saveLocation() async {
    if (address.trim().isEmpty && (latitude.isEmpty || longitude.isEmpty)) {
      showToast(context, "Please enter either an address or coordinates.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', address.trim());
    await prefs.setString('latitude', latitude);
    await prefs.setString('longitude', longitude);

    setState(() {
      isEditing = false;
    });

    showToast(context, "Location saved successfully.");
  }

  Future<void> openInMaps() async {
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      final url =
          Uri.parse("https://www.google.com/maps?q=$latitude,$longitude");
      if (await canLaunchUrl(url)) {
        launchUrl(url);
      }
    }
  }

  Future<void> shareLocation() async {
    if (latitude.isNotEmpty && longitude.isNotEmpty) {
      final message =
          "My current location: https://www.google.com/maps?q=$latitude,$longitude";
      await Share.share(message);
      showToast(context, "Location shared (or copied).");
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedLocation =
        address.isNotEmpty || (latitude.isNotEmpty && longitude.isNotEmpty);

    return Card(
      color: Colors.green.shade900.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade600.withOpacity(0.3),
                    Colors.green.shade700.withOpacity(0.2)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.green.shade400.withOpacity(0.3)),
              ),
              child: Icon(Icons.location_on,
                  color: Colors.green.shade300, size: 32),
            ),
            SizedBox(height: 12),
            Text('Current Location',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade100)),

            const SizedBox(height: 20),

            isEditing ? _buildEditingUI() : _buildSavedUI(hasSavedLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingUI() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Address (Optional)',
            labelStyle: TextStyle(color: Colors.green.shade200),
          ),
          style: TextStyle(color: Colors.green.shade100),
          onChanged: (value) => setState(() => address = value),
          controller: TextEditingController(text: address),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(color: Colors.green.shade200),
                ),
                style: TextStyle(color: Colors.green.shade100),
                onChanged: (value) => setState(() => latitude = value),
                controller: TextEditingController(text: latitude),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: TextStyle(color: Colors.green.shade200),
                ),
                style: TextStyle(color: Colors.green.shade100),
                onChanged: (value) => setState(() => longitude = value),
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
                icon: Icon(Icons.save),
                label: Text("Save Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
              ),
            ),
            if (address.isNotEmpty ||
                latitude.isNotEmpty ||
                longitude.isNotEmpty)
              const SizedBox(width: 8),
            if (address.isNotEmpty ||
                latitude.isNotEmpty ||
                longitude.isNotEmpty)
              OutlinedButton(
                onPressed: () => setState(() => isEditing = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade200,
                ),
                child: Text("Cancel"),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavedUI(bool hasSavedLocation) {
    if (!hasSavedLocation) {
      return Column(
        children: [
          Text("No current location saved",
              style: TextStyle(color: Colors.green.shade200)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() => isEditing = true),
            icon: Icon(Icons.add_location_alt),
            label: Text("Add Location"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Address:",
                  style: TextStyle(
                      color: Colors.green.shade100,
                      fontWeight: FontWeight.bold)),
              Text(address, style: TextStyle(color: Colors.green.shade100)),
              const SizedBox(height: 12),
            ],
          ),
        if (latitude.isNotEmpty && longitude.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Coordinates:",
                  style: TextStyle(
                      color: Colors.green.shade100,
                      fontWeight: FontWeight.bold)),
              Text("$latitude, $longitude",
                  style: TextStyle(color: Colors.green.shade100)),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => isEditing = true),
                icon: Icon(Icons.edit),
                label: Text("Edit Location"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
              ),
            ),
            const SizedBox(width: 8),
            if (latitude.isNotEmpty && longitude.isNotEmpty)
              IconButton(
                onPressed: openInMaps,
                icon: Icon(Icons.map_outlined, color: Colors.green.shade100),
              ),
            if (latitude.isNotEmpty && longitude.isNotEmpty)
              IconButton(
                onPressed: shareLocation,
                icon: Icon(Icons.share_outlined, color: Colors.green.shade100),
              ),
          ],
        )
      ],
    );
  }

  void showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text(message)));
  }
}
