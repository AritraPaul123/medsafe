// lib/widgets/emergency_contacts.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:medsafe/utils/communication_service.dart';
import 'package:medsafe/utils/models.dart';
import 'package:medsafe/utils/storage_utils.dart';
import 'package:medsafe/widgets/toast.dart';

class EmergencyContacts extends StatefulWidget {
  const EmergencyContacts({super.key});

  @override
  State<EmergencyContacts> createState() => _EmergencyContactsState();
}

class _EmergencyContactsState extends State<EmergencyContacts> {
  static const int _maxContacts = 3;

  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final saved = await StorageUtils.getEmergencyContacts();
    if (!mounted) return;
    setState(() {
      _contacts = saved;
      _loading = false;
    });
  }

  Future<void> _saveContacts(List<EmergencyContact> updated) async {
    setState(() => _contacts = updated);
    await StorageUtils.saveEmergencyContacts(updated);
  }

  Future<void> _addContactTap() async {
    if (_contacts.length >= _maxContacts) {
      showToast(
        context,
        title: 'Maximum contacts',
        description: 'You can save up to $_maxContacts emergency contacts.',
        isError: true,
      );
      return;
    }
    await _openAddEditSheet();
  }

  Future<void> _openAddEditSheet({EmergencyContact? existing}) async {
    final t = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');

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
                  child: Text(
                    existing == null ? 'Add Emergency Contact' : 'Edit Contact',
                    style: t.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Full name',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. +91 98xxxxxx',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(
                        existing == null ? 'Save Contact' : 'Save Changes'),
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;

                      final newContact = EmergencyContact(
                        id: existing?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );

                      final updated = [..._contacts];
                      final idx =
                          updated.indexWhere((c) => c.id == newContact.id);
                      if (idx >= 0) {
                        updated[idx] = newContact;
                      } else {
                        updated.add(newContact);
                      }
                      await _saveContacts(updated);
                      if (mounted) Navigator.of(sheetCtx).pop();
                      if (mounted) {
                        showToast(
                          context,
                          title: existing == null
                              ? 'Contact added'
                              : 'Contact updated',
                          description: newContact.name,
                        );
                      }
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

  Future<void> _removeContact(String id) async {
    final c = _contacts.firstWhere((e) => e.id == id);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${c.name} (${c.phone}) from your contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok ?? false) {
      final updated = _contacts.where((e) => e.id != id).toList();
      await _saveContacts(updated);
      if (mounted) {
        showToast(context, title: 'Contact removed', description: c.name);
      }
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    CommunicationUtils.makePhoneCall(contact.phone);
    showToast(context, title: 'Calling', description: contact.name);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
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
                        child: Icon(LucideIcons.phone, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emergency Contacts (${_contacts.length}/$_maxContacts)',
                          style: t.textTheme.titleLarge,
                        ),
                      ),
                      if (_contacts.length < _maxContacts)
                        FilledButton.icon(
                          onPressed: _addContactTap,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(LucideIcons.userPlus,
                              size: 40, color: cs.secondary),
                          const SizedBox(height: 8),
                          Text('No emergency contacts yet',
                              style: t.textTheme.bodyMedium),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contacts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final c = _contacts[i];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(c.name, style: t.textTheme.bodyLarge),
                          subtitle: Text(c.phone, style: t.textTheme.bodySmall),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'call':
                                  _callContact(c);
                                  break;
                                case 'edit':
                                  _openAddEditSheet(existing: c);
                                  break;
                                case 'delete':
                                  _removeContact(c.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'call',
                                child: _MenuRow(
                                    icon: LucideIcons.phoneCall, label: 'Call'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: _MenuRow(
                                    icon: LucideIcons.edit, label: 'Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: _MenuRow(
                                  icon: LucideIcons.trash2,
                                  label: 'Delete',
                                  danger: true,
                                  color: cs.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  if (_contacts.length >= _maxContacts) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline.withOpacity(0.6)),
                      ),
                      child: Text(
                        'You’ve reached the maximum of $_maxContacts contacts.',
                        style: t.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
      ),
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
