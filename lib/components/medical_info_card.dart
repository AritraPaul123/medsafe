import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

class MedicalInfoCard extends StatefulWidget {
  @override
  _MedicalInfoCardState createState() => _MedicalInfoCardState();
}

class _MedicalInfoCardState extends State<MedicalInfoCard> {
  bool isEditing = false;

  // Medical fields
  String bloodGroup = '';
  String allergies = '';
  String conditions = '';
  String medications = '';
  String emergencyMessage = '';

  // File upload simulation
  PlatformFile? firstAidKitPhoto;
  PlatformFile? insuranceDocument;

  @override
  void initState() {
    super.initState();
    _loadMedicalInfo();
  }

  Future<void> _loadMedicalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bloodGroup = prefs.getString('bloodGroup') ?? '';
      allergies = prefs.getString('allergies') ?? '';
      conditions = prefs.getString('conditions') ?? '';
      medications = prefs.getString('medications') ?? '';
      emergencyMessage = prefs.getString('emergencyMessage') ?? '';
    });
  }

  Future<void> _saveMedicalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloodGroup', bloodGroup);
    await prefs.setString('allergies', allergies);
    await prefs.setString('conditions', conditions);
    await prefs.setString('medications', medications);
    await prefs.setString('emergencyMessage', emergencyMessage);

    setState(() => isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Medical Information Saved")),
    );
  }

  Future<void> _pickFile(Function(PlatformFile) onSelected) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      onSelected(result.files.first);
    }
  }

  void _shareWhatsApp() async {
    final message = '''
EMERGENCY MEDICAL INFO:
- Blood Group: $bloodGroup
- Allergies: $allergies
- Conditions: $conditions
- Medications: $medications
- Note: $emergencyMessage
''';
    final uri =
        Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInfoCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade500.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 6),
          Text(value,
              style: TextStyle(color: Colors.red.shade100, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyInfo = bloodGroup.isNotEmpty ||
        allergies.isNotEmpty ||
        conditions.isNotEmpty ||
        medications.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildMedicalCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFirstAidInfoCard()),
                  ],
                )
              : Column(
                  children: [
                    _buildMedicalCard(),
                    const SizedBox(height: 16),
                    _buildFirstAidInfoCard(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMedicalCard() {
    final hasAnyInfo = bloodGroup.isNotEmpty ||
        allergies.isNotEmpty ||
        conditions.isNotEmpty ||
        medications.isNotEmpty;

    return Card(
      color: Colors.red.shade900.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.favorite, color: Colors.red.shade300, size: 32),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medical Information',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade100)),
                Row(
                  children: [
                    IconButton(
                      onPressed: _shareWhatsApp,
                      icon: Icon(Icons.message, color: Colors.green.shade400),
                    ),
                    if (!isEditing)
                      IconButton(
                        onPressed: () => setState(() => isEditing = true),
                        icon: Icon(Icons.edit, color: Colors.red.shade100),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            isEditing ? _buildEditForm() : _buildMedicalInfoDisplay(hasAnyInfo)
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextInput("Blood Group", bloodGroup, (val) => bloodGroup = val),
        _buildTextArea("Allergies", allergies, (val) => allergies = val),
        _buildTextArea(
            "Medical Conditions", conditions, (val) => conditions = val),
        _buildTextArea(
            "Current Medications", medications, (val) => medications = val),
        _buildTextArea("Emergency Message", emergencyMessage,
            (val) => emergencyMessage = val),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveMedicalInfo,
                icon: Icon(Icons.save),
                label: Text("Save"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() => isEditing = false),
              icon: Icon(Icons.close),
              label: Text("Cancel"),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade100),
            )
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickFile(
                    (file) => setState(() => firstAidKitPhoto = file)),
                icon: Icon(Icons.photo),
                label: Text("Upload First Aid Kit"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickFile(
                    (file) => setState(() => insuranceDocument = file)),
                icon: Icon(Icons.upload_file),
                label: Text("Upload Insurance Doc"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalInfoDisplay(bool hasAnyInfo) {
    if (!hasAnyInfo) {
      return Column(
        children: [
          Icon(Icons.favorite_border, color: Colors.red.shade400, size: 48),
          SizedBox(height: 8),
          Text("No medical information added yet",
              style: TextStyle(color: Colors.red.shade300)),
        ],
      );
    }

    return Column(
      children: [
        if (bloodGroup.isNotEmpty)
          _buildInfoCard(label: "Blood Group", value: bloodGroup),
        if (allergies.isNotEmpty)
          _buildInfoCard(label: "Allergies", value: allergies),
        if (conditions.isNotEmpty)
          _buildInfoCard(label: "Medical Conditions", value: conditions),
        if (medications.isNotEmpty)
          _buildInfoCard(label: "Current Medications", value: medications),
        if (firstAidKitPhoto != null)
          _buildInfoCard(
              label: "First Aid Kit Photo", value: firstAidKitPhoto!.name),
        if (insuranceDocument != null)
          _buildInfoCard(
              label: "Insurance Document", value: insuranceDocument!.name),
      ],
    );
  }

  Widget _buildTextInput(
      String label, String initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.red.shade200),
        ),
        style: TextStyle(color: Colors.red.shade100),
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextArea(
      String label, String initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.red.shade200),
        ),
        style: TextStyle(color: Colors.red.shade100),
        controller: TextEditingController(text: initialValue),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFirstAidInfoCard() {
    return Card(
      color: Colors.red.shade900.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "📦 First Aid Instructions:\n\n• Bandage small cuts\n• Use antiseptic\n• Carry aspirin\n• Emergency helpline: 112",
          style: TextStyle(color: Colors.red.shade100),
        ),
      ),
    );
  }
}
