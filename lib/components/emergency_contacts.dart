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
  List<EmergencyContact> contacts = [];
  bool isAdding = false;
  String name = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void loadContacts() async {
    final savedContacts = await StorageUtils.getEmergencyContacts();
    setState(() => contacts = savedContacts);
  }

  void saveContacts(List<EmergencyContact> updated) {
    setState(() => contacts = updated);
    StorageUtils.saveEmergencyContacts(updated);
  }

  void addContact() {
    if (name.trim().isEmpty || phone.trim().isEmpty) return;

    if (contacts.length >= 3) {
      showToast(context,
          title: "Maximum Contacts",
          description: "You can only save up to 3 emergency contacts",
          isError: true);
      return;
    }

    final contact = EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: phone.trim(),
    );

    saveContacts([...contacts, contact]);
    showToast(context,
        title: "Contact Added",
        description: "${contact.name} has been added to emergency contacts");

    setState(() {
      name = '';
      phone = '';
      isAdding = false;
    });
  }

  void removeContact(String id) {
    final updated = contacts.where((c) => c.id != id).toList();
    saveContacts(updated);
    showToast(context,
        title: "Contact Removed",
        description: "Emergency contact has been removed");
  }

  void callContact(EmergencyContact contact) {
    CommunicationUtils.makePhoneCall(contact.phone);
    showToast(context,
        title: "Calling", description: "Calling ${contact.name}...");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF6B21A8).withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
              ),
              child: const Icon(LucideIcons.phone,
                  color: Color(0xFFE9D5FF), size: 32),
            ),
            const SizedBox(height: 12),

            // Heading
            Text(
              "Emergency Contacts (${contacts.length}/3)",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE9D5FF)),
            ),
            const SizedBox(height: 16),

            // Contact List
            ...contacts.map(
              (contact) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E22CE).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Contact Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(contact.phone,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    // Action Buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => callContact(contact),
                          icon: const Icon(LucideIcons.phoneCall,
                              color: Colors.greenAccent),
                        ),
                        IconButton(
                          onPressed: () => removeContact(contact.id),
                          icon: const Icon(LucideIcons.trash2,
                              color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(LucideIcons.userPlus,
                        size: 40, color: Color(0xFFD8B4FE)),
                    SizedBox(height: 8),
                    Text("No emergency contacts added yet",
                        style: TextStyle(color: Color(0xFFE9D5FF))),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Add contact form
            if (isAdding)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E22CE).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => phone = val,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: addContact,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple),
                            child: const Text("Save Contact"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isAdding = false;
                              name = '';
                              phone = '';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade900),
                          child: const Text("Cancel"),
                        ),
                      ],
                    )
                  ],
                ),
              )
            else if (contacts.length < 3)
              ElevatedButton.icon(
                onPressed: () => setState(() => isAdding = true),
                icon: const Icon(LucideIcons.plus),
                label: const Text("Add Emergency Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
