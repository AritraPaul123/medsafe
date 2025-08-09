import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class EmergencyInstructionsPage extends StatefulWidget {
  @override
  _EmergencyInstructionsPageState createState() =>
      _EmergencyInstructionsPageState();
}

class _EmergencyInstructionsPageState extends State<EmergencyInstructionsPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isReading = false;

  EmergencyType? selectedEmergency;

  final List<EmergencyType> emergencyTypes = [
    EmergencyType(
      id: 'bleeding',
      title: 'Severe Bleeding',
      icon: Icons.bloodtype,
      color: Colors.red,
      instructions: [
        'Apply direct pressure to the wound with a clean cloth or bandage',
        'Elevate the injured area above the heart if possible',
        'Do not remove objects stuck in the wound',
        'Apply additional bandages over the first if blood soaks through',
        'Call 911 immediately for severe bleeding',
        'Keep the person calm and lying down'
      ],
    ),
    // Add other emergencies similarly...
  ];

  void readInstructions(List<String> instructions) async {
    await flutterTts.stop();
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.speak(instructions.join('. '));
    setState(() => isReading = true);
    flutterTts.setCompletionHandler(() {
      setState(() => isReading = false);
    });
  }

  void stopReading() async {
    await flutterTts.stop();
    setState(() => isReading = false);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), Colors.black, Color(0xFF7F1D1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: selectedEmergency == null
                ? Column(
                    children: [
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[200],
                              backgroundColor:
                                  Colors.red[800]!.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Back to Home"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Emergency Instructions',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[200]),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: emergencyTypes.map((emergency) {
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedEmergency = emergency),
                              child: Card(
                                color: emergency.color.withOpacity(0.3),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(emergency.icon,
                                          color: Colors.red[300], size: 40),
                                      const SizedBox(height: 8),
                                      Text(emergency.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.red[200],
                                              fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => selectedEmergency = null),
                            icon: Icon(Icons.arrow_back),
                            label: Text("Back"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900,
                            ),
                          ),
                          const Spacer(),
                          if (isReading)
                            ElevatedButton.icon(
                              onPressed: stopReading,
                              icon: Icon(Icons.volume_off),
                              label: Text("Stop Voice"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedEmergency!.title,
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.red[200],
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: isReading
                            ? null
                            : () => readInstructions(
                                selectedEmergency!.instructions),
                        icon: Icon(Icons.volume_up),
                        label: Text("Read Aloud"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                      const SizedBox(height: 16),
                      ...selectedEmergency!.instructions
                          .asMap()
                          .entries
                          .map((entry) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.shade300.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Text("${entry.key + 1}",
                                    style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry.value,
                                    style: TextStyle(color: Colors.red[100])),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class EmergencyType {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> instructions;

  EmergencyType({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.instructions,
  });
}
