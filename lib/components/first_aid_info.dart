// lib/pages/first_aid_info.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FirstAidInfoPage extends StatelessWidget {
  const FirstAidInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final firstAidSteps = const [
      {
        "title": "Check for consciousness",
        "description": "Gently tap the shoulders and ask, Are you okay?",
      },
      {
        "title": "Call for help",
        "description": "Contact local emergency services immediately.",
      },
      {
        "title": "Check breathing",
        "description": "Look, listen, and feel for normal breathing.",
      },
      {
        "title": "Control bleeding",
        "description": "Apply firm, direct pressure with a clean cloth.",
      },
      {
        "title": "Treat for shock",
        "description": "Keep them warm and elevate legs if safe to do so.",
      },
    ];

    final emergencyNumbers = const [
      {"label": "General Emergency", "number": "911 / 112"},
      {"label": "Poison Control", "number": "1-800-222-1222"},
      {"label": "Crisis Hotline", "number": "988"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Info'),
        // AppBar colors come from theme; no overrides = cleaner + consistent
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.alertTriangle, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Basic First Aid Steps',
                    style: t.textTheme.titleLarge,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Steps
            ...firstAidSteps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    step['title']!,
                    style: t.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    step['description']!,
                    style: t.textTheme.bodySmall,
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Emergency numbers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.phone, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('Emergency Numbers',
                            style: t.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...emergencyNumbers.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '• ${e['label']}: ${e['number']}',
                            style: t.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: Save these numbers in your contacts.',
                      style: t.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Footer note
            Text(
              'This information is for guidance only. If someone is in danger, call your local emergency number immediately.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
