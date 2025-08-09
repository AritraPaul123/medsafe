import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FirstAidInfoPage extends StatelessWidget {
  const FirstAidInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firstAidSteps = [
      {
        "title": "Check for Consciousness",
        "description": "Gently shake shoulders and shout 'Are you okay?'",
      },
      {
        "title": "Call for Help",
        "description": "Call emergency services immediately (911/112)",
      },
      {
        "title": "Check Breathing",
        "description": "Look, listen, and feel for normal breathing",
      },
      {
        "title": "Control Bleeding",
        "description": "Apply direct pressure with clean cloth",
      },
      {
        "title": "Treat for Shock",
        "description": "Keep person warm and elevate legs if possible",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("First Aid Info"),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text(
                  "Basic First Aid Steps",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...firstAidSteps.asMap().entries.map((entry) {
              int index = entry.key;
              var step = entry.value;
              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    radius: 14,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    step['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                  ),
                  subtitle: Text(
                    step['description']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.phone,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          "Emergency Numbers",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...[
                      {"label": "General Emergency", "number": "911"},
                      {"label": "Poison Control", "number": "1-800-222-1222"},
                      {"label": "Crisis Hotline", "number": "988"},
                    ].map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "• ${e['label']}: ${e['number']}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
