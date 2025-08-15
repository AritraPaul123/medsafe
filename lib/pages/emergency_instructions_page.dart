// lib/pages/emergency_instructions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyInstructionsPage extends StatefulWidget {
  const EmergencyInstructionsPage({super.key});

  @override
  State<EmergencyInstructionsPage> createState() =>
      _EmergencyInstructionsPageState();
}

class _EmergencyInstructionsPageState extends State<EmergencyInstructionsPage> {
  final FlutterTts _tts = FlutterTts();
  bool _isReading = false;
  EmergencyType? _selected;

  final List<EmergencyType> _types = [
    EmergencyType(
      id: 'bleeding',
      title: 'Severe bleeding',
      icon: Icons.bloodtype,
      instructions: const [
        'Call your local emergency number now.',
        'Apply firm, direct pressure with a clean cloth/bandage.',
        'Keep pressing—do NOT lift to “check” the wound.',
        'If blood soaks through, add more cloth on top and keep pressing.',
        'Do not remove objects stuck in the wound; pad around them.',
        'If trained and available, use a tourniquet above the wound.',
        'Keep the person warm and lying down; watch breathing.',
      ],
    ),
    EmergencyType(
      id: 'burns',
      title: 'Burns (moderate/severe)',
      icon: Icons.local_fire_department,
      instructions: const [
        'Turn off the heat source / ensure scene is safe.',
        'Cool the burn with cool running water for 20 minutes.',
        'Remove rings/jewelry/clothing not stuck to the skin.',
        'Do not use ice, creams, or home remedies.',
        'Cover loosely with a sterile, non-stick dressing.',
        'Electrical or chemical burn? Call emergency services.',
      ],
    ),
    EmergencyType(
      id: 'fracture',
      title: 'Suspected fracture or sprain',
      icon: Icons.healing,
      instructions: const [
        'Call emergency services for major deformity/open wound/head/neck/back injury.',
        'Do not straighten; immobilize the area as found.',
        'Apply a cold pack wrapped in cloth for 20 minutes on/off.',
        'Check feeling, warmth, and color beyond the injury.',
        'Avoid food or drink in case surgery is needed.',
      ],
    ),
    EmergencyType(
      id: 'choking_adult',
      title: 'Choking (adult/child > 1 yr)',
      icon: Icons.priority_high,
      instructions: const [
        'Ask “Are you choking?” If they can’t speak/cough, act.',
        'Give 5 back blows between shoulder blades.',
        'Then 5 abdominal thrusts (Heimlich).',
        'Repeat 5 back blows + 5 thrusts until relief or they collapse.',
        'If unresponsive: call emergency services and start CPR.',
      ],
    ),
    EmergencyType(
      id: 'cpr_adult',
      title: 'CPR (adult)',
      icon: Icons.favorite,
      instructions: const [
        'Call emergency services; get an AED if available.',
        'Check responsiveness and breathing (no more than 10 seconds).',
        'Start compressions: 100–120/min, at least 5–6 cm deep, full recoil.',
        'If trained: 30 compressions : 2 breaths. Otherwise hands-only CPR.',
        'Use AED asap; follow its prompts. Do not stop until help takes over.',
      ],
    ),
    EmergencyType(
      id: 'heart_attack',
      title: 'Heart attack (possible)',
      icon: Icons.monitor_heart,
      instructions: const [
        'Call emergency services now.',
        'Have them rest; loosen tight clothing; keep calm.',
        'If not allergic and no contraindication, consider chewing 160–325 mg aspirin (per dispatcher/doctor advice).',
        'Be ready to start CPR if they become unresponsive and not breathing normally.',
      ],
    ),
    EmergencyType(
      id: 'stroke',
      title: 'Stroke (FAST)',
      icon: Icons.psychology_alt,
      instructions: const [
        'Face drooping? Arm weakness? Speech slurred? Time to call emergency services.',
        'Note the time symptoms started (critical for treatment).',
        'Keep them comfortable; do not give food or drink.',
        'Monitor breathing and responsiveness.',
      ],
    ),
    EmergencyType(
      id: 'anaphylaxis',
      title: 'Severe allergic reaction',
      icon: Icons.medical_services,
      instructions: const [
        'Call emergency services.',
        'Use epinephrine auto-injector in the outer thigh immediately.',
        'Have them lie flat; raise legs if possible (unless breathing is hard—then sit up).',
        'If symptoms persist after 5–10 minutes and a second injector is available, give the second dose.',
        'Keep monitoring breathing; be ready for CPR.',
      ],
    ),
    EmergencyType(
      id: 'seizure',
      title: 'Seizure',
      icon: Icons.psychology,
      instructions: const [
        'Protect from injury; pad the head; move objects away.',
        'Do NOT restrain; do NOT put anything in the mouth.',
        'Time the seizure. When it stops, place on their side (recovery position).',
        'Call emergency services if seizure > 5 minutes, repeats, first seizure, pregnant, injured, or breathing trouble.',
      ],
    ),
    EmergencyType(
      id: 'heatstroke',
      title: 'Heatstroke',
      icon: Icons.wb_sunny_outlined,
      instructions: const [
        'Call emergency services.',
        'Move to a cool place; remove excess clothing.',
        'Cool rapidly: cold water immersion if possible OR apply cold, wet cloths/ice packs to neck, armpits, groin—fan them.',
        'Continue aggressive cooling until better or help arrives.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Make TTS await completion so we can track state cleanly.
    _tts.awaitSpeakCompletion(true);
    // Fallback completion handler (some platforms still use this callback).
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _read(List<String> steps) async {
    try {
      setState(() => _isReading = true);
      await _tts.stop();
      await _tts.setSpeechRate(0.5); // slow and clear
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.speak(steps.join('. '));
      // With awaitSpeakCompletion(true), speak resolves after completion on most platforms.
      if (mounted) setState(() => _isReading = false);
    } catch (_) {
      if (mounted) setState(() => _isReading = false);
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _isReading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return PopScope(
      canPop: _selected == null, // when detail is open, consume back
      onPopInvoked: (didPop) {
        if (!didPop && _selected != null) {
          setState(() => _selected = null); // go back to grid, stay on page
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Instructions'),
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: _selected == null
              ? GridView.builder(
                  itemCount: _types.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, i) {
                    final e = _types[i];
                    return _EmergencyTile(
                      title: e.title,
                      icon: e.icon,
                      onTap: () => setState(() => _selected = e),
                    );
                  },
                )
              : ListView(
                  children: [
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => setState(() => _selected = null),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                        const Spacer(),
                        if (_isReading)
                          FilledButton.tonalIcon(
                            onPressed: _stop,
                            icon: const Icon(Icons.volume_off),
                            label: const Text('Stop'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(_selected!.title, style: t.textTheme.headlineSmall),

                    const SizedBox(height: 8),

                    // Read / Stop
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReading
                            ? null
                            : () => _read(_selected!.instructions),
                        icon: const Icon(Icons.volume_up),
                        label: Text(_isReading ? 'Reading…' : 'Read aloud'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Steps
                    ..._selected!.instructions.asMap().entries.map(
                          (entry) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _NumberBadge(number: entry.key + 1),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(entry.value,
                                        style: t.textTheme.bodyLarge),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ——— UI bits ———

class _EmergencyTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _EmergencyTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Card(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: cs.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: cs.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ——— Data model ———

class EmergencyType {
  final String id;
  final String title;
  final IconData icon;
  final List<String> instructions;

  const EmergencyType({
    required this.id,
    required this.title,
    required this.icon,
    required this.instructions,
  });
}
