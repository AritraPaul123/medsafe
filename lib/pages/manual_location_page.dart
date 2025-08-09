import 'package:flutter/material.dart';
import 'package:medsafe/components/manual_location_entry.dart';

class ManualLocationPage extends StatelessWidget {
  const ManualLocationPage({super.key});

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade300,
                    backgroundColor: Colors.red.shade900.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 24),

                // Heading and subtitle
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manually set your current location for emergency reference',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Manual Location Entry Widget
                ManualLocationEntry(), // Your actual widget goes here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
