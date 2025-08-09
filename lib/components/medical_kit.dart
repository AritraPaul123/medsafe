import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class MedicalItem {
  final String name;
  final DateTime expiryDate;
  final String injuryType; // Bleeding / Burn / Fracture / Other
  final XFile? photo;

  MedicalItem({
    required this.name,
    required this.expiryDate,
    required this.injuryType,
    this.photo,
  });
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

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
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

  Future<void> _addItem() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _expiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter name and pick an expiry date')),
      );
      return;
    }

    final item = MedicalItem(
      name: name,
      expiryDate: _expiry!,
      injuryType: _injuryType,
      photo: _pickedPhoto,
    );
    setState(() {
      _items.add(item);
      _nameCtrl.clear();
      _expiry = null;
      _pickedPhoto = null;
      _injuryType = 'Bleeding';
    });

    // If you already have ExpiryNotifier.schedule(), call it here:
    // await ExpiryNotifier.schedule(name.hashCode, itemName: item.name, expiryDate: item.expiryDate);
  }

  Future<void> _shareItem(MedicalItem item) async {
    final caption =
        "Medical Kit • ${item.injuryType}\nItem: ${item.name}\nExpiry: ${DateFormat.yMMMd().format(item.expiryDate)}";

    if (item.photo != null) {
      await Share.shareXFiles([XFile(item.photo!.path)],
          text: caption, subject: 'Medical Kit');
    } else {
      await Share.share(caption, subject: 'Medical Kit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelStyle: TextStyle(color: Colors.lightBlueAccent),
            labelText: 'Item name',
            suffixIcon:
                IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
          ),
          onSubmitted: (_) => _addItem(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DropdownButton<String>(
              value: _injuryType,
              onChanged: (v) => setState(() => _injuryType = v!),
              items: _injuryTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: TextStyle(color: Colors.lightBlueAccent),
                      )))
                  .toList(),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
                onPressed: _pickExpiry,
                child: Text(_expiry == null
                    ? 'Pick expiry'
                    : DateFormat.yMMMd().format(_expiry!))),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo),
              label: Text(_pickedPhoto == null ? 'Add photo' : 'Change photo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._items.map((i) => Card(
              child: ListTile(
                title: Text(i.name),
                subtitle: Text(
                    "${i.injuryType} • Expires ${DateFormat.yMMMd().format(i.expiryDate)}"),
                leading: i.photo != null
                    ? Image.file(
                        File(i.photo!.path),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.medical_services_outlined),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.ios_share),
                        onPressed: () => _shareItem(i)),
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() => _items.remove(i));
                          // If you have ExpiryNotifier.cancel(i.id), call it here.
                        }),
                  ],
                ),
              ),
            )),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('No items added yet.',
                style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}
