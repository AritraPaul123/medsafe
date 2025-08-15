// lib/widgets/emergency_contacts_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medsafe/services/assistant_services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

typedef SetAssistantCallback = Future<void> Function(String name, String phone);
typedef DeleteContactCallback = Future<void> Function(dynamic id);
typedef EditContactCallback = Future<void> Function(
  dynamic id,
  dynamic name,
  dynamic phone,
);

class EmergencyContactsWidget extends StatefulWidget {
  final SetAssistantCallback onSetAsAssistant;
  final DeleteContactCallback onDeleteContact;
  final EditContactCallback onEditContact;

  const EmergencyContactsWidget({
    super.key,
    required this.onSetAsAssistant,
    required this.onDeleteContact,
    required this.onEditContact,
  });

  @override
  State<EmergencyContactsWidget> createState() =>
      _EmergencyContactsWidgetState();
}

class _EmergencyContactsWidgetState extends State<EmergencyContactsWidget> {
  // Normalize Hive map -> sorted list
  List<Map<String, String>> _contactsFromRaw(Map<String, dynamic> raw) {
    final list = <Map<String, String>>[];
    raw.forEach((id, value) {
      final m = (value as Map).cast<String, dynamic>();
      list.add({
        'id': id.toString(),
        'name': (m['name'] ?? '').toString(),
        'phone': (m['phone'] ?? '').toString(),
      });
    });
    list.sort(
      (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
    );
    return list;
  }

  // ---- Add / Edit Sheets ----
  Future<void> _openContactSheet(
    BuildContext context, {
    String? id,
    String initialName = '',
    String initialPhone = '',
    required EditContactCallback onSave, // re-use for add/edit
  }) async {
    final t = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController();

    // Parse existing phone for dial
    final dialPattern = RegExp(r'^\+(\d{1,3})\s*[- ]?\s*');
    String selectedDial = '+91';
    String localNumber = initialPhone;
    final m = dialPattern.firstMatch(initialPhone.trim());
    if (m != null) {
      selectedDial = '+${m.group(1)!}';
      localNumber = initialPhone.trim().replaceFirst(m.group(0)!, '').trim();
    }
    phoneCtrl.text = localNumber;

    // Unique keys for dropdown (avoid +1 duplicates)
    final countryOptions = [
      {'key': 'IN', 'label': '🇮🇳 India', 'dial': '+91'},
      {'key': 'US', 'label': '🇺🇸 United States', 'dial': '+1'},
      {'key': 'CA', 'label': '🇨🇦 Canada', 'dial': '+1'},
      {'key': 'GB', 'label': '🇬🇧 United Kingdom', 'dial': '+44'},
      {'key': 'AU', 'label': '🇦🇺 Australia', 'dial': '+61'},
      {'key': 'DE', 'label': '🇩🇪 Germany', 'dial': '+49'},
      {'key': 'FR', 'label': '🇫🇷 France', 'dial': '+33'},
      {'key': 'AE', 'label': '🇦🇪 UAE', 'dial': '+971'},
      {'key': 'SG', 'label': '🇸🇬 Singapore', 'dial': '+65'},
    ];

    String selectedKey = (countryOptions.firstWhere(
      (e) => e['dial'] == selectedDial,
      orElse: () => countryOptions.first,
    ))['key']!;

    // per-sheet flag so geodetect runs once
    var sheetGeoStarted = false;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: t.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: StatefulBuilder(
            builder: (sheetCtx, setState) {
              // ---- geolocate -> reverse geocode -> set default country code
              Future<void> _tryGeoDetectAndSet() async {
                try {
                  if (initialPhone.trim().isNotEmpty) return; // editing, skip
                  final serviceOn = await Geolocator.isLocationServiceEnabled();
                  if (!serviceOn) return;

                  var perm = await Geolocator.checkPermission();
                  if (perm == LocationPermission.denied) {
                    perm = await Geolocator.requestPermission();
                  }
                  if (perm == LocationPermission.denied ||
                      perm == LocationPermission.deniedForever) return;

                  final pos = await Geolocator.getCurrentPosition();
                  final placemarks = await geocoding.placemarkFromCoordinates(
                    pos.latitude,
                    pos.longitude,
                  );
                  if (placemarks.isEmpty) return;
                  final iso = placemarks.first.isoCountryCode?.toUpperCase();
                  if (iso == null) return;

                  final idx = countryOptions.indexWhere((e) => e['key'] == iso);
                  if (idx == -1) return;
                  final match = countryOptions[idx];

                  setState(() {
                    selectedKey = match['key']!;
                    selectedDial = match['dial']!;
                  });
                } catch (_) {
                  // silent fallback
                }
              }

              // run once after first build
              if (!sheetGeoStarted) {
                sheetGeoStarted = true;
                Future.microtask(_tryGeoDetectAndSet);
              }

              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id == null ? 'Add Contact' : 'Modify Contact',
                      style: t.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Full name',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Dial dropdown + Phone field
                    Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedKey,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                            ),
                            items: countryOptions.map((e) {
                              return DropdownMenuItem<String>(
                                value: e['key']!,
                                child: Text(
                                  '${e['label']}   ${e['dial']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                selectedKey = v;
                                selectedDial = countryOptions
                                    .firstWhere((e) => e['key'] == v)['dial']!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: '$selectedDial 9876543210',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\s\-]+')),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            validator: (v) {
                              final raw =
                                  (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');
                              if (raw.isEmpty) return 'Required';
                              if (raw.length < 7 || raw.length > 15) {
                                return 'Invalid phone';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                _submitIfValid(formKey, () async {
                              final composed = _composePhone(
                                selectedDial,
                                phoneCtrl.text.trim(),
                              );
                              await onSave(
                                  id ?? '', nameCtrl.text.trim(), composed);
                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(id == null
                                        ? 'Contact added'
                                        : 'Contact updated'),
                                  ),
                                );
                              }
                            }),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label:
                            Text(id == null ? 'Save Contact' : 'Save Changes'),
                        onPressed: () => _submitIfValid(formKey, () async {
                          final composed = _composePhone(
                            selectedDial,
                            phoneCtrl.text.trim(),
                          );
                          await onSave(
                              id ?? '', nameCtrl.text.trim(), composed);
                          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(id == null
                                    ? 'Contact added'
                                    : 'Contact updated'),
                              ),
                            );
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Confirm delete (dialog only, never pops the page)
  Future<bool> _confirmDelete(
      BuildContext context, String name, String phone) async {
    final t = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove $name ($phone) from your contacts.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(true),
            style: FilledButton.styleFrom(backgroundColor: t.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return FutureBuilder(
      future: AssistantService.box(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final box = snapshot.data!;

        return Column(
          children: [
            // Header + Add button
            Row(
              children: [
                Expanded(
                  child:
                      Text('Emergency Contacts', style: t.textTheme.titleLarge),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => _openContactSheet(
                    context,
                    onSave: (id, name, phone) async {
                      await AssistantService.upsertContact(
                        name: name,
                        phone: phone,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live list
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(keys: const ['contacts']),
                builder: (context, _, __) {
                  final raw =
                      (box.get('contacts') as Map?)?.cast<String, dynamic>() ??
                          <String, dynamic>{};
                  final contacts = _contactsFromRaw(raw);

                  if (contacts.isEmpty) {
                    return Center(
                      child: Text(
                        'No contacts yet.',
                        style: t.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      final id = c['id']!;
                      final name = c['name']!;
                      final phone = c['phone']!;

                      return Dismissible(
                        key: Key('contact_$id'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final ok = await _confirmDelete(context, name, phone);
                          if (ok) await widget.onDeleteContact(id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact deleted')),
                            );
                          }
                          return ok;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: t.colorScheme.error.withOpacity(0.12),
                          child: Icon(Icons.delete, color: t.colorScheme.error),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(name, style: t.textTheme.bodyLarge),
                          subtitle: Text(phone, style: t.textTheme.bodySmall),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'assistant':
                                  await widget.onSetAsAssistant(name, phone);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Set as assistant'),
                                      ),
                                    );
                                  }
                                  break;
                                case 'modify':
                                  await _openContactSheet(
                                    context,
                                    id: id,
                                    initialName: name,
                                    initialPhone: phone,
                                    onSave: (id, newName, newPhone) => widget
                                        .onEditContact(id, newName, newPhone),
                                  );
                                  break;
                                case 'delete':
                                  final ok = await _confirmDelete(
                                      context, name, phone);
                                  if (ok) {
                                    await widget.onDeleteContact(id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Contact deleted'),
                                        ),
                                      );
                                    }
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'assistant',
                                child: _MenuRow(
                                  icon: Icons.verified_user,
                                  label: 'Set as Assistant',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'modify',
                                child: _MenuRow(
                                  icon: Icons.edit,
                                  label: 'Modify Contact',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: _MenuRow(
                                  icon: Icons.delete,
                                  label: 'Delete',
                                  danger: true,
                                  color: t.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final Color? color;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = color ?? t.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: danger ? c : t.colorScheme.onSurface)),
      ],
    );
  }
}

// Helper to validate + run
void _submitIfValid(GlobalKey<FormState> key, Future<void> Function() run) {
  final ok = key.currentState?.validate() ?? false;
  if (!ok) return;
  run();
}

String _composePhone(String dial, String local) {
  if (local.startsWith('+')) return local.trim();
  return '$dial ${local.trim()}'.trim();
}
