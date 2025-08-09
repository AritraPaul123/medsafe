// emergency_contacts_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medsafe/services/assistant_services.dart';
import '../widgets/emergency_contacts_widget.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  String? _assistantName;
  String? _assistantPhone;

  @override
  void initState() {
    super.initState();
    _loadAssistant();
  }

  Future<void> _loadAssistant() async {
    final name = await AssistantService.getName();
    final phone = await AssistantService.getPhone();
    if (!mounted) return;
    setState(() {
      _assistantName = name;
      _assistantPhone = phone;
    });
  }

  Future<void> _clearAssistant() async {
    // simple clear (keep the keys tidy)
    final box = await AssistantService.box(); // already defined in service
    await box.delete('name');
    await box.delete('phone');
    await _loadAssistant();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal Assistant cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), Colors.black, Color(0xFF7F1D1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                TextButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.redAccent, size: 20),
                  label: const Text("Back to Home",
                      style: TextStyle(color: Colors.redAccent)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor: Colors.red.shade900.withOpacity(0.2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                const Center(
                  child: Column(
                    children: [
                      Text(
                        "Emergency Contacts",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Manage contacts who will be notified during emergencies",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Assistant banner (shows current / lets clear)
                _AssistantBanner(
                  name: _assistantName,
                  phone: _assistantPhone,
                  onCleared: _clearAssistant,
                ),
                const SizedBox(height: 16),

                // Manual entry field
                const SizedBox(height: 16),
                _AssistantNumberEntry(onSaved: () async {
                  await _loadAssistant();
                }),

                // Contacts list with "Set as Assistant" action
                Expanded(
                  child: EmergencyContactsWidget(
                    onSetAsAssistant: (name, phone) async {
                      await AssistantService.setAssistant(
                          phone: phone, name: name);
                      await _loadAssistant();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('$name set as Personal Assistant')),
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

// Small UI chip card
class _AssistantBanner extends StatelessWidget {
  final String? name;
  final String? phone;
  final VoidCallback onCleared;

  const _AssistantBanner({
    required this.name,
    required this.phone,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    final hasAssistant = (phone != null && phone!.isNotEmpty);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: hasAssistant
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name?.isNotEmpty == true ? name! : 'Personal Assistant',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  )
                : const Text(
                    'No Personal Assistant set',
                    style: TextStyle(color: Colors.white70),
                  ),
          ),
          if (hasAssistant)
            TextButton(
              onPressed: onCleared,
              child: const Text('Clear',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }
}

class _AssistantNumberEntry extends StatefulWidget {
  final VoidCallback onSaved;
  const _AssistantNumberEntry({required this.onSaved});

  @override
  State<_AssistantNumberEntry> createState() => _AssistantNumberEntryState();
}

class _AssistantNumberEntryState extends State<_AssistantNumberEntry> {
  final _controller = TextEditingController();

  Future<void> _save() async {
    final phone = _controller.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a phone number')),
      );
      return;
    }
    await AssistantService.setAssistant(phone: phone);
    widget.onSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal Assistant number saved')),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set Personal Assistant Manually',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '+911234567890',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
