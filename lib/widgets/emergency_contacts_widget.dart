import 'package:flutter/material.dart';

typedef SetAssistantCallback = Future<void> Function(String name, String phone);

class EmergencyContactsWidget extends StatelessWidget {
  final SetAssistantCallback onSetAsAssistant;

  const EmergencyContactsWidget({
    super.key,
    required this.onSetAsAssistant,
  });

  @override
  Widget build(BuildContext context) {
    // Replace with your actual contacts list source
    final contacts = [
      {"name": "Dad", "phone": "+911111111111"},
      {"name": "Mom", "phone": "+922222222222"},
      {"name": "Doctor", "phone": "+933333333333"},
    ];

    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.redAccent),
      itemBuilder: (context, index) {
        final name = contacts[index]["name"]!;
        final phone = contacts[index]["phone"]!;

        return ListTile(
          leading: const Icon(Icons.person, color: Colors.redAccent),
          title: Text(
            name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            phone,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.redAccent),
            onSelected: (value) async {
              if (value == 'assistant') {
                await onSetAsAssistant(name, phone);
              }
              // you could add other actions like 'call', 'delete', etc. here
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assistant',
                child: Row(
                  children: [
                    Icon(Icons.verified_user,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Set as Assistant'),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            // Optional: make tap call this contact directly
          },
        );
      },
    );
  }
}
