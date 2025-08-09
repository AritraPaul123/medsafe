import 'package:flutter/material.dart';
import 'package:medsafe/utils/location_service.dart'; // Replace with actual import

class LiveLocationPage extends StatelessWidget {
  const LiveLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height, // Add this line
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
                // Back button
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(
                        context); // or use Navigator.pushNamed(context, '/');
                  },
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

                // Title and subtitle
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Live Location',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Get your current location and share it with emergency contacts',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Actual component
                const LocationService(), // Replace with your actual widget
              ],
            ),
          ),
        ),
      ),
    );
  }
}
