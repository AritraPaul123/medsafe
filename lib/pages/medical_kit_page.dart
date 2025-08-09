import 'package:flutter/material.dart';
import 'package:medsafe/components/medical_kit.dart'; // Replace with your actual import

class MedicalKitPage extends StatelessWidget {
  const MedicalKitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7F1D1D), Colors.black, Color(0xFF7F1D1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[200],
                          backgroundColor: Colors.red[800]!.withOpacity(0.3),
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

                  // Title and subtitle
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "Medical Kit",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE4E1),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Add essential medical items to your emergency kit",
                          style: TextStyle(color: Color(0xFFFCA5A5)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Component: MedicalKit (create separately)
                  const MedicalKit(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
