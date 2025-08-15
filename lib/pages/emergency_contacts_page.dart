// lib/pages/emergency_contacts_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medsafe/services/assistant_services.dart';
import 'package:medsafe/widgets/toast.dart';
import 'package:medsafe/widgets/emergency_contacts_widget.dart';

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
    final box = await AssistantService.box();
    await box.delete('name');
    await box.delete('phone');
    await _loadAssistant();
    if (!mounted) return;
    showToast(context,
        title: 'Assistant cleared', description: 'Personal Assistant removed.');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            // Contacts list
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: EmergencyContactsWidget(
                    onSetAsAssistant: (name, phone) async {
                      await AssistantService.setAssistant(
                          phone: phone, name: name);
                      await _loadAssistant();
                      if (!mounted) return;
                      showToast(
                        context,
                        title: 'Assistant set',
                        description:
                            '$name will be used as Personal Assistant.',
                      );
                    },
                    onEditContact: (id, name, phone) async {
                      await AssistantService.updateContact(
                          id: id, name: name, phone: phone);
                      if (!mounted) return;
                      showToast(context,
                          title: 'Contact updated',
                          description: name.toString());
                    },
                    onDeleteContact: (id) async {
                      await AssistantService.deleteContact(id);
                      if (!mounted) return;
                      showToast(context,
                          title: 'Contact deleted', description: '');
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),
            // Assistant banner
            _AssistantBanner(
              name: _assistantName,
              phone: _assistantPhone,
              onCleared: _clearAssistant,
            ),

            const SizedBox(height: 12),

            // Manual Assistant phone entry
            _AssistantNumberEntry(
              onSaved: _loadAssistant,
            ),

            const SizedBox(height: 12),

            // Helpful note
            const SizedBox(height: 8),
            Text(
              'Tip: Set one contact as your Personal Assistant to prioritize calls during SOS.',
              style: t.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- UI bits ----

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
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final hasAssistant = (phone != null && phone!.isNotEmpty);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.verified_user, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasAssistant
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (name?.isNotEmpty ?? false)
                              ? name!
                              : 'Personal Assistant',
                          style: t.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(phone!, style: t.textTheme.bodySmall),
                      ],
                    )
                  : Text('No Personal Assistant set',
                      style: t.textTheme.bodyMedium),
            ),
            if (hasAssistant)
              TextButton(
                onPressed: onCleared,
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssistantNumberEntry extends StatefulWidget {
  final Future<void> Function() onSaved;
  const _AssistantNumberEntry({required this.onSaved});

  @override
  State<_AssistantNumberEntry> createState() => _AssistantNumberEntryState();
}

class _AssistantNumberEntryState extends State<_AssistantNumberEntry> {
  final _controller = TextEditingController();

  Future<void> _save() async {
    final phone = _controller.text.trim();
    if (phone.isEmpty) {
      showToast(
        context,
        title: 'Enter a phone number',
        description: 'Add a number with country code if possible.',
        isError: true,
      );
      return;
    }

    // Optional light validation: allow +, digits, spaces, dashes
    final reg = RegExp(r'^[+\d][\d \-()]{5,}$');
    if (!reg.hasMatch(phone)) {
      showToast(
        context,
        title: 'Invalid number',
        description: 'Use digits and optional +, spaces, or dashes.',
        isError: true,
      );
      return;
    }

    await AssistantService.setAssistant(phone: phone);
    await widget.onSaved();
    if (!mounted) return;
    _controller.clear();
    showToast(context, title: 'Assistant saved', description: phone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Personal Assistant manually',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '+91 12345 67890',
                      labelText: 'Phone number',
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
