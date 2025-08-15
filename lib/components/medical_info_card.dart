// lib/widgets/medical_info_card.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' show log, pow;
import 'package:medsafe/widgets/toast.dart';

class MedicalInfoCard extends StatefulWidget {
  const MedicalInfoCard({super.key});

  @override
  State<MedicalInfoCard> createState() => _MedicalInfoCardState();
}

class _MedicalInfoCardState extends State<MedicalInfoCard> {
  // Stored values
  String _bloodGroup = '';
  String _allergies = '';
  String _conditions = '';
  String _medications = '';
  String _emergencyMessage = '';

  // Optional uploads (kept as PlatformFile for metadata)
  PlatformFile? _firstAidKitPhoto;
  PlatformFile? _insuranceDocument;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalInfo();
  }

  Future<void> _loadMedicalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bloodGroup = prefs.getString('bloodGroup') ?? '';
      _allergies = prefs.getString('allergies') ?? '';
      _conditions = prefs.getString('conditions') ?? '';
      _medications = prefs.getString('medications') ?? '';
      _emergencyMessage = prefs.getString('emergencyMessage') ?? '';
      _loading = false;
    });
  }

  Future<void> _saveMedicalInfo({
    required String bloodGroup,
    required String allergies,
    required String conditions,
    required String medications,
    required String emergencyMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloodGroup', bloodGroup.trim());
    await prefs.setString('allergies', allergies.trim());
    await prefs.setString('conditions', conditions.trim());
    await prefs.setString('medications', medications.trim());
    await prefs.setString('emergencyMessage', emergencyMessage.trim());

    setState(() {
      _bloodGroup = bloodGroup.trim();
      _allergies = allergies.trim();
      _conditions = conditions.trim();
      _medications = medications.trim();
      _emergencyMessage = emergencyMessage.trim();
    });

    showToast(context,
        title: 'Saved', description: 'Medical information updated.');
  }

  Future<void> _pickPlatformFile(void Function(PlatformFile file) onSelected,
      {List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      onSelected(result.files.first);
    }
  }

  Future<void> _shareWhatsApp() async {
    final message = '''
EMERGENCY MEDICAL INFO
• Blood group: $_bloodGroup
• Allergies: $_allergies
• Conditions: $_conditions
• Medications: $_medications
• Note: $_emergencyMessage
''';
    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast(context,
          title: 'WhatsApp not available', isError: true, description: '');
    }
  }

  // --- UI helpers ---

  bool get _hasAnyInfo =>
      _bloodGroup.isNotEmpty ||
      _allergies.isNotEmpty ||
      _conditions.isNotEmpty ||
      _medications.isNotEmpty ||
      _emergencyMessage.isNotEmpty ||
      _firstAidKitPhoto != null ||
      _insuranceDocument != null;

  String _formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(k)).floor();
    final value = bytes / pow(k, i);
    return '${value.toStringAsFixed(decimals)} ${sizes[i]}';
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
                  child: Icon(Icons.favorite, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Medical Information',
                      style: t.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Share via WhatsApp',
                  onPressed: _shareWhatsApp,
                  icon: const Icon(Icons.message),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditSheet(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (!_hasAnyInfo)
              Column(
                children: [
                  Icon(Icons.favorite_border, color: cs.secondary, size: 48),
                  const SizedBox(height: 8),
                  Text('No medical information yet',
                      style: t.textTheme.bodyMedium),
                ],
              )
            else
              Column(
                children: [
                  if (_bloodGroup.isNotEmpty)
                    _InfoRow(label: 'Blood group', value: _bloodGroup),
                  if (_allergies.isNotEmpty)
                    _InfoRow(label: 'Allergies', value: _allergies),
                  if (_conditions.isNotEmpty)
                    _InfoRow(label: 'Medical conditions', value: _conditions),
                  if (_medications.isNotEmpty)
                    _InfoRow(label: 'Current medications', value: _medications),
                  if (_emergencyMessage.isNotEmpty)
                    _InfoRow(label: 'Emergency note', value: _emergencyMessage),
                  if (_firstAidKitPhoto != null) ...[
                    const SizedBox(height: 8),
                    _FileBadge(
                      icon: Icons.photo,
                      label: 'First-aid kit photo',
                      name: _firstAidKitPhoto!.name,
                      sizeText: _firstAidKitPhoto!.size != null
                          ? _formatBytes(_firstAidKitPhoto!.size!)
                          : '',
                    ),
                  ],
                  if (_insuranceDocument != null) ...[
                    const SizedBox(height: 8),
                    _FileBadge(
                      icon: Icons.description,
                      label: 'Insurance document',
                      name: _insuranceDocument!.name,
                      sizeText: _insuranceDocument!.size != null
                          ? _formatBytes(_insuranceDocument!.size!)
                          : '',
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final t = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    // Persistent controllers inside sheet scope; initialized with current values
    final bgCtrl = TextEditingController(text: _bloodGroup);
    final alCtrl = TextEditingController(text: _allergies);
    final condCtrl = TextEditingController(text: _conditions);
    final medCtrl = TextEditingController(text: _medications);
    final msgCtrl = TextEditingController(text: _emergencyMessage);

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
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('Edit Medical Info', style: t.textTheme.titleLarge),
                const SizedBox(height: 12),

                // Fields
                TextFormField(
                  controller: bgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Blood group',
                    hintText: 'e.g. O+, A-, B+',
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: alCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Allergies',
                    hintText: 'e.g. Penicillin, peanuts',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: condCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medical conditions',
                    hintText: 'e.g. Asthma, diabetes',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: medCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Current medications',
                    hintText: 'e.g. Metformin 500mg',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: msgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Emergency note',
                    hintText: 'One line responders should see first',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Uploads
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPlatformFile(
                          (f) => setState(() => _firstAidKitPhoto = f),
                          allowedExtensions: const [
                            'jpg',
                            'jpeg',
                            'png',
                            'heic'
                          ],
                        ),
                        icon: const Icon(Icons.photo),
                        label: const Text('Add first-aid photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPlatformFile(
                          (f) => setState(() => _insuranceDocument = f),
                          allowedExtensions: const ['pdf', 'jpg', 'png'],
                        ),
                        icon: const Icon(Icons.description),
                        label: const Text('Add insurance doc'),
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
                      // no strict validation; empty fields are allowed
                      await _saveMedicalInfo(
                        bloodGroup: bgCtrl.text,
                        allergies: alCtrl.text,
                        conditions: condCtrl.text,
                        medications: medCtrl.text,
                        emergencyMessage: msgCtrl.text,
                      );
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
}

// ---- Small, reusable UI bits ----

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
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

class _FileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String name;
  final String sizeText;

  const _FileBadge({
    required this.icon,
    required this.label,
    required this.name,
    required this.sizeText,
  });

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  name + (sizeText.isNotEmpty ? ' • $sizeText' : ''),
                  style: t.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// math helpers
