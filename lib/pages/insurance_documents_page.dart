import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/insurance_services.dart'; // <- tiny helper we added earlier

class InsuranceDocument {
  final String id;
  final String name;
  final String? url;
  final bool isFile;

  InsuranceDocument({
    required this.id,
    required this.name,
    this.url,
    this.isFile = false,
  });
}

class InsuranceDocumentsPage extends StatefulWidget {
  const InsuranceDocumentsPage({super.key});

  @override
  State<InsuranceDocumentsPage> createState() => _InsuranceDocumentsPageState();
}

class _InsuranceDocumentsPageState extends State<InsuranceDocumentsPage> {
  // Saved insurance details (used in SOS)
  // add to _InsuranceDocumentsPageState fields
  String _savedProvider = '';
  String _savedPolicy = '';
  String _savedHotline = '';

  final _providerCtrl = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _hotlineCtrl = TextEditingController();
  bool _savingHeader = false;

  // Link list
  final List<InsuranceDocument> _documents = [];
  bool isAdding = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  // update _loadHeader()
  Future<void> _loadHeader() async {
    final data = await InsuranceService.get();
    if (!mounted) return;
    setState(() {
      _providerCtrl.text = (data['provider'] ?? '');
      _policyCtrl.text = (data['policy'] ?? '');
      _hotlineCtrl.text = (data['hotline'] ?? '');

      // also reflect as "saved" snapshot for the tile
      _savedProvider = _providerCtrl.text;
      _savedPolicy = _policyCtrl.text;
      _savedHotline = _hotlineCtrl.text;
    });
  }

// update _saveHeader()
  Future<void> _saveHeader() async {
    final provider = _providerCtrl.text.trim();
    final policy = _policyCtrl.text.trim();
    final hotline = _hotlineCtrl.text.trim();

    await InsuranceService.save(
      provider: provider,
      policy: policy,
      hotline: hotline.isEmpty ? null : hotline,
    );

    if (!mounted) return;
    setState(() {
      // snapshot for the ListTile
      _savedProvider = provider;
      _savedPolicy = policy;
      _savedHotline = hotline;

      // clear fields after save
      _providerCtrl.clear();
      _policyCtrl.clear();
      _hotlineCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Insurance details saved')),
    );
  }

  void _addLinkDocument() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both name and URL')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid http/https URL')),
      );
      return;
    }

    setState(() {
      _documents.add(InsuranceDocument(
        id: const Uuid().v4(),
        name: name,
        url: url,
        isFile: false,
      ));
      _nameController.clear();
      _urlController.clear();
      isAdding = false;
    });
  }

  void _removeDocument(String id) {
    setState(() {
      _documents.removeWhere((doc) => doc.id == id);
    });
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open this link')),
      );
    }
  }

  Future<void> _shareDocuments() async {
    final b = StringBuffer("📋 *My Insurance Details*\n");
    final provider =
        _providerCtrl.text.trim().isEmpty ? 'N/A' : _providerCtrl.text.trim();
    final policy =
        _policyCtrl.text.trim().isEmpty ? 'N/A' : _policyCtrl.text.trim();
    final hotline =
        _hotlineCtrl.text.trim().isEmpty ? 'N/A' : _hotlineCtrl.text.trim();

    b.writeln("• Provider: $provider");
    b.writeln("• Policy: $policy");
    b.writeln("• Hotline: $hotline\n");

    if (_documents.isEmpty) {
      b.writeln("_No insurance documents added yet._");
    } else {
      b.writeln("*Documents:*");
      for (var i = 0; i < _documents.length; i++) {
        final d = _documents[i];
        b.writeln("${i + 1}. ${d.name}");
        if (!d.isFile && d.url != null) b.writeln("   🔗 ${d.url}");
      }
    }
    b.writeln("\nShared via Medsafe Emergency");

    final text = b.toString();

    // Try WhatsApp deep link first
    final wa = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to system share sheet
    await Share.share(text);
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _policyCtrl.dispose();
    _hotlineCtrl.dispose();
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
    Clipboard.setData(const ClipboardData(text: '')); // small privacy tidy
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), Colors.black, Color(0xFF7F1D1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.redAccent),
                      label: const Text("Back to Home",
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _shareDocuments,
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    )
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  "Insurance Documents",
                  style: TextStyle(
                    color: Color(0xFFFFCCCC),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Store your insurance details and links",
                  style: TextStyle(color: Colors.redAccent),
                ),

                const SizedBox(height: 16),

                // ---- Saved Insurance Details (used in SOS) ----
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Insurance',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _providerCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "Provider",
                                labelStyle: TextStyle(color: Colors.redAccent),
                                filled: true,
                                fillColor: Colors.black26,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _policyCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "Policy No.",
                                labelStyle: TextStyle(color: Colors.redAccent),
                                filled: true,
                                fillColor: Colors.black26,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _hotlineCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Insurer Hotline",
                          labelStyle: TextStyle(color: Colors.redAccent),
                          filled: true,
                          fillColor: Colors.black26,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _savingHeader ? null : _saveHeader,
                          icon: _savingHeader
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ---- Add Link ----
                if (!isAdding)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => isAdding = true),
                    icon: const Icon(Icons.link),
                    label: const Text("Add Link"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                // in build(), right BELOW the Save button of the insurance header section, show the tile
                if (_savedProvider.isNotEmpty ||
                    _savedPolicy.isNotEmpty ||
                    _savedHotline.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Card(
                      color: Colors.black26,
                      child: ListTile(
                        leading: const Icon(Icons.assignment_turned_in,
                            color: Colors.redAccent),
                        title: Text(
                          _savedProvider.isEmpty
                              ? 'Provider: —'
                              : 'Provider: $_savedProvider',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _savedPolicy.isEmpty
                                  ? 'Policy: —'
                                  : 'Policy: $_savedPolicy',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _savedHotline.isEmpty
                                  ? 'Hotline: —'
                                  : 'Hotline: $_savedHotline',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        trailing: _savedHotline.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.phone,
                                    color: Colors.greenAccent),
                                onPressed: () async {
                                  final uri =
                                      Uri(scheme: 'tel', path: _savedHotline);
                                  await launchUrl(uri);
                                },
                              ),
                      ),
                    ),
                  ),

                if (isAdding)
                  Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Document Name",
                          labelStyle: TextStyle(color: Colors.redAccent),
                          filled: true,
                          fillColor: Colors.black26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Document URL (https://…)",
                          labelStyle: TextStyle(color: Colors.redAccent),
                          filled: true,
                          fillColor: Colors.black26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _addLinkDocument,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: const Text("Save"),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isAdding = false;
                                _nameController.clear();
                                _urlController.clear();
                              });
                            },
                            child: const Text("Cancel",
                                style: TextStyle(color: Colors.redAccent)),
                          )
                        ],
                      )
                    ],
                  ),

                const SizedBox(height: 12),

                // ---- List ----
                Expanded(
                  child: _documents.isEmpty
                      ? const Center(
                          child: Text(
                            "No insurance documents added.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return Card(
                              color: Colors.black26,
                              child: ListTile(
                                title: Text(doc.name,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  doc.isFile
                                      ? "Uploaded file"
                                      : "External link",
                                  style: const TextStyle(color: Colors.white60),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!doc.isFile && doc.url != null)
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new,
                                            color: Colors.blueAccent),
                                        onPressed: () =>
                                            _openDocument(doc.url!),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      onPressed: () => _removeDocument(doc.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
