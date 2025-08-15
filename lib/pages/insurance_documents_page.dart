import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:medsafe/widgets/toast.dart';
import 'package:medsafe/services/insurance_services.dart';

// NEW: local file handling
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

// NEW: persistence
import 'package:hive_flutter/hive_flutter.dart';

class InsuranceDocument {
  final String id;
  final String name;
  final String? url; // external link
  final bool isFile; // true if stored locally
  final String? localPath; // absolute path for local files

  InsuranceDocument({
    required this.id,
    required this.name,
    this.url,
    this.isFile = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'isFile': isFile,
        'localPath': localPath,
      };

  factory InsuranceDocument.fromJson(Map<String, dynamic> m) =>
      InsuranceDocument(
        id: m['id'] as String,
        name: m['name'] as String,
        url: m['url'] as String?,
        isFile: m['isFile'] as bool? ?? false,
        localPath: m['localPath'] as String?,
      );
}

class InsuranceDocumentsPage extends StatefulWidget {
  const InsuranceDocumentsPage({super.key});

  @override
  State<InsuranceDocumentsPage> createState() => _InsuranceDocumentsPageState();
}

class _InsuranceDocumentsPageState extends State<InsuranceDocumentsPage> {
  // Header (provider/policy/hotline)
  final _providerCtrl = TextEditingController();
  final _policyCtrl = TextEditingController();
  final _hotlineCtrl = TextEditingController();
  bool _savingHeader = false;

  // Snapshot for compact tile preview
  String _savedProvider = '';
  String _savedPolicy = '';
  String _savedHotline = '';

  // Docs (links + files)
  final List<InsuranceDocument> _documents = [];

  // NEW: Hive box (lazy)
  static const _kDocsBoxName = 'insurance_docs';
  static const _kDocsKey = 'docs';
  Box<dynamic>? _docsBox;

  @override
  void initState() {
    super.initState();
    _loadHeader();
    _loadDocs();
  }

  // ---------- PERSISTENCE ----------
  Future<Box> _getDocsBox() async {
    _docsBox ??= await Hive.openBox(_kDocsBoxName);
    return _docsBox!;
  }

  Future<void> _loadDocs() async {
    try {
      final box = await _getDocsBox();
      final raw = (box.get(_kDocsKey) as List?) ?? const [];
      final docs = <InsuranceDocument>[];
      for (final item in raw) {
        try {
          docs.add(InsuranceDocument.fromJson(
              Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          // skip bad entries
        }
      }
      if (!mounted) return;
      setState(() {
        _documents
          ..clear()
          ..addAll(docs);
      });
    } catch (e) {
      // ignore: keep empty list
    }
  }

  Future<void> _saveDocs() async {
    final box = await _getDocsBox();
    await box.put(
      _kDocsKey,
      _documents.map((d) => d.toJson()).toList(),
    );
  }
  // ----------------------------------

  Future<void> _loadHeader() async {
    final data = await InsuranceService.get();
    if (!mounted) return;
    setState(() {
      _providerCtrl.text = (data['provider'] ?? '');
      _policyCtrl.text = (data['policy'] ?? '');
      _hotlineCtrl.text = (data['hotline'] ?? '');

      _savedProvider = _providerCtrl.text;
      _savedPolicy = _policyCtrl.text;
      _savedHotline = _hotlineCtrl.text;
    });
  }

  Future<void> _saveHeader() async {
    final provider = _providerCtrl.text.trim();
    final policy = _policyCtrl.text.trim();
    final hotline = _hotlineCtrl.text.trim();

    setState(() => _savingHeader = true);
    await InsuranceService.save(
      provider: provider,
      policy: policy,
      hotline: hotline.isEmpty ? null : hotline,
    );
    if (!mounted) return;

    setState(() {
      _savedProvider = provider;
      _savedPolicy = policy;
      _savedHotline = hotline;
      _savingHeader = false;
    });

    showToast(context,
        title: 'Saved', description: 'Insurance details updated.');
  }

  // ----- ADD LINK -----
  Future<void> _openAddLinkSheet() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + inset),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add link',
                      style: Theme.of(ctx).textTheme.titleLarge),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Document name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Document URL',
                    hintText: 'https://example.com/policy.pdf',
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    final uri = Uri.tryParse(s);
                    if (s.isEmpty) return 'Required';
                    if (uri == null ||
                        !(uri.isScheme('http') || uri.isScheme('https'))) {
                      return 'Enter a valid http/https URL';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        _documents.add(InsuranceDocument(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          url: urlCtrl.text.trim(),
                          isFile: false,
                        ));
                      });
                      await _saveDocs(); // NEW
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      showToast(context,
                          title: 'Link added',
                          description: nameCtrl.text.trim());
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

  // ----- UPLOAD FILE -----
  Future<void> _pickAndAddFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;

      final picked = res.files.single;
      if (picked.path == null) {
        showToast(context,
            title: 'Unsupported',
            description: 'This platform returns no file path.',
            isError: true);
        return;
      }

      final src = File(picked.path!);
      if (!await src.exists()) {
        showToast(context,
            title: 'File not found', description: picked.name, isError: true);
        return;
      }

      // Copy to app documents: /Documents/insurance/<uuid>_<originalName>
      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(docsDir.path, 'insurance'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final newName = '${const Uuid().v4()}_${picked.name}';
      final dest = File(p.join(targetDir.path, newName));
      await src.copy(dest.path);

      setState(() {
        _documents.add(InsuranceDocument(
          id: const Uuid().v4(),
          name: p.basenameWithoutExtension(picked.name),
          isFile: true,
          localPath: dest.path,
        ));
      });

      await _saveDocs(); // NEW
      showToast(context, title: 'Uploaded', description: picked.name);
    } catch (e) {
      showToast(context,
          title: 'Upload failed', description: '$e', isError: true);
    }
  }

  void _removeDocument(String id) async {
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    final doc = _documents[idx];

    if (doc.isFile && doc.localPath != null) {
      try {
        final f = File(doc.localPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    setState(() => _documents.removeAt(idx));
    await _saveDocs(); // NEW
    showToast(context, title: 'Removed', description: 'Document deleted.');
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast(context,
          title: 'Cannot open link', description: url, isError: true);
    }
  }

  Future<void> _openLocalDocument(String path) async {
    try {
      final res = await OpenFilex.open(path); // from open_filex
      if (res.type != ResultType.done) {
        // Fallback: let user pick an app
        await Share.shareXFiles([XFile(path)], text: 'Open with…');
      }
    } catch (e) {
      await Share.shareXFiles([XFile(path)], text: 'Open with…');
    }
  }

  Future<void> _callHotline() async {
    if (_savedHotline.isEmpty) {
      showToast(context,
          title: 'No hotline saved',
          description: 'Add an insurer hotline first.',
          isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: _savedHotline);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast(context,
          title: 'Could not place call',
          description: _savedHotline,
          isError: true);
    }
  }

  Future<void> _shareAll() async {
    final provider =
        _providerCtrl.text.trim().isEmpty ? 'N/A' : _providerCtrl.text.trim();
    final policy =
        _policyCtrl.text.trim().isEmpty ? 'N/A' : _policyCtrl.text.trim();
    final hotline =
        _hotlineCtrl.text.trim().isEmpty ? 'N/A' : _hotlineCtrl.text.trim();

    final b = StringBuffer('📋 My Insurance Details\n');
    b.writeln('• Provider: $provider');
    b.writeln('• Policy: $policy');
    b.writeln('• Hotline: $hotline\n');

    final localFiles =
        _documents.where((d) => d.isFile && d.localPath != null).toList();

    if (_documents.isEmpty) {
      b.writeln('No insurance documents added yet.');
    } else {
      b.writeln('Documents:');
      for (var i = 0; i < _documents.length; i++) {
        final d = _documents[i];
        if (d.isFile) {
          b.writeln('${i + 1}. ${d.name} (file)');
        } else {
          b.writeln('${i + 1}. ${d.name}');
          if (d.url != null) b.writeln('   ${d.url}');
        }
      }
    }
    b.writeln('\nShared via Medsafe');

    final text = b.toString();

    if (localFiles.isEmpty) {
      final wa = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(wa)) {
        await launchUrl(wa, mode: LaunchMode.externalApplication);
      } else {
        await Share.share(text);
      }
    } else {
      final files = localFiles.map((d) => XFile(d.localPath!)).toList();
      await Share.shareXFiles(
        files,
        text: text,
        subject: 'My Insurance Details',
      );
    }
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _policyCtrl.dispose();
    _hotlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Documents'),
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: _shareAll,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment_turned_in,
                              color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('My Insurance',
                              style: t.textTheme.titleMedium),
                        ),
                        if (_savedHotline.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _callHotline,
                            icon: const Icon(Icons.phone),
                            label: const Text('Call hotline'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _providerCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Provider'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _policyCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Policy no.'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hotlineCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: 'Insurer hotline'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _savingHeader ? null : _saveHeader,
                        icon: _savingHeader
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ),
                    if (_savedProvider.isNotEmpty ||
                        _savedPolicy.isNotEmpty ||
                        _savedHotline.isNotEmpty) ...[
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.badge, color: cs.primary),
                        title: Text(
                          _savedProvider.isEmpty
                              ? 'Provider: —'
                              : 'Provider: $_savedProvider',
                          style: t.textTheme.bodyLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_savedPolicy.isEmpty
                                ? 'Policy: —'
                                : 'Policy: $_savedPolicy'),
                            const SizedBox(height: 2),
                            Text(_savedHotline.isEmpty
                                ? 'Hotline: —'
                                : 'Hotline: $_savedHotline'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Actions row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAddLinkSheet,
                    icon: const Icon(Icons.link),
                    label: const Text('Add link'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickAndAddFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload file'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Documents list
            Expanded(
              child: _documents.isEmpty
                  ? Center(
                      child: Text(
                        'No insurance documents added.',
                        style: t.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _documents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final d = _documents[i];
                        return ListTile(
                          leading: Icon(
                            d.isFile ? Icons.insert_drive_file : Icons.link,
                            color: cs.primary,
                          ),
                          title: Text(d.name),
                          subtitle: Text(
                              d.isFile ? 'Uploaded file' : 'External link'),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Open',
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => d.isFile
                                    ? _openLocalDocument(d.localPath!)
                                    : _openDocument(d.url!),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeDocument(d.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
