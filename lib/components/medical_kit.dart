// lib/widgets/medical_kit.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:medsafe/widgets/toast.dart';

class MedicalItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String injuryType; // Bleeding / Burn / Fracture / Other
  final XFile? photo;

  MedicalItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.injuryType,
    this.photo,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;
}

class MedicalKit extends StatefulWidget {
  const MedicalKit({super.key});

  @override
  State<MedicalKit> createState() => _MedicalKitState();
}

class _MedicalKitState extends State<MedicalKit> {
  final List<MedicalItem> _items = [];

  final _nameCtrl = TextEditingController();
  DateTime? _expiry;
  String _injuryType = 'Bleeding';
  XFile? _pickedPhoto;

  final _injuryTypes = const ['Bleeding', 'Burn', 'Fracture', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _expiry = d);
  }

  Future<void> _pickPhoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _pickedPhoto = img);
  }

  void _resetComposer() {
    _nameCtrl.clear();
    _expiry = null;
    _pickedPhoto = null;
    _injuryType = _injuryTypes.first;
  }

  Future<void> _addItem() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _expiry == null) {
      showToast(
        context,
        title: 'Missing info',
        description: 'Enter an item name and choose an expiry date.',
        isError: true,
      );
      return;
    }

    final item = MedicalItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      expiryDate: _expiry!,
      injuryType: _injuryType,
      photo: _pickedPhoto,
    );

    setState(() => _items.add(item));
    _resetComposer();

    showToast(context, title: 'Item added', description: item.name);
    // If you have an ExpiryNotifier, schedule here.
  }

  Future<void> _shareItem(MedicalItem item) async {
    final caption =
        'Medical Kit • ${item.injuryType}\nItem: ${item.name}\nExpiry: ${DateFormat.yMMMd().format(item.expiryDate)}';

    if (item.photo != null) {
      await Share.shareXFiles([XFile(item.photo!.path)],
          text: caption, subject: 'Medical Kit');
    } else {
      await Share.share(caption, subject: 'Medical Kit');
    }
  }

  void _deleteItem(MedicalItem item) {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    // If you have an ExpiryNotifier.cancel(item.id), call it here.
    showToast(context, title: 'Removed', description: item.name);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

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
                  child:
                      Icon(Icons.medical_services_outlined, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Medical Kit', style: t.textTheme.titleLarge),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Composer
            _Composer(
              nameCtrl: _nameCtrl,
              injuryType: _injuryType,
              injuryTypes: _injuryTypes,
              expiry: _expiry,
              photo: _pickedPhoto,
              onInjuryChanged: (v) => setState(() => _injuryType = v),
              onPickExpiry: _pickExpiry,
              onPickPhoto: _pickPhoto,
              onAdd: _addItem,
            ),

            const SizedBox(height: 16),

            // List
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                    Text('No items added yet.', style: t.textTheme.bodyMedium),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return _MedicalItemTile(
                    item: item,
                    onShare: () => _shareItem(item),
                    onDelete: () => _deleteItem(item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController nameCtrl;
  final String injuryType;
  final List<String> injuryTypes;
  final DateTime? expiry;
  final XFile? photo;

  final ValueChanged<String> onInjuryChanged;
  final VoidCallback onPickExpiry;
  final VoidCallback onPickPhoto;
  final VoidCallback onAdd;

  const _Composer({
    required this.nameCtrl,
    required this.injuryType,
    required this.injuryTypes,
    required this.expiry,
    required this.photo,
    required this.onInjuryChanged,
    required this.onPickExpiry,
    required this.onPickPhoto,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Column(
      children: [
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Item name',
            suffixIcon: IconButton(
              tooltip: 'Add item',
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ),
          onSubmitted: (_) => onAdd(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: injuryType,
                decoration: const InputDecoration(labelText: 'Use for'),
                items: injuryTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onInjuryChanged(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickExpiry,
                icon: const Icon(Icons.event),
                label: Text(
                  expiry == null
                      ? 'Pick expiry'
                      : DateFormat.yMMMd().format(expiry!),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Photo
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickPhoto,
                icon: const Icon(Icons.photo),
                label: Text(photo == null ? 'Add photo' : 'Change photo'),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _MedicalItemTile extends StatelessWidget {
  final MedicalItem item;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _MedicalItemTile({
    required this.item,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final chipColor = item.isExpired
        ? cs.error.withOpacity(0.12)
        : cs.primary.withOpacity(0.12);
    final chipTextColor = item.isExpired ? cs.error : cs.primary;

    final expiryText = item.isExpired
        ? 'Expired'
        : (item.daysLeft == 0 ? 'Expires today' : 'in ${item.daysLeft}d');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: item.photo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(item.photo!.path),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.medical_services_outlined),
      title: Text(item.name, style: t.textTheme.bodyLarge),
      subtitle: Text(
        '${item.injuryType} • Expires ${DateFormat.yMMMd().format(item.expiryDate)}',
        style: t.textTheme.bodySmall,
      ),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Expiry chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              expiryText,
              style: t.textTheme.labelSmall?.copyWith(color: chipTextColor),
            ),
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: onShare,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
