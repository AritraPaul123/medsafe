import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Use if you're using go_router for routing
import 'package:medsafe/components/hometown_address.dart'; // <-- Ensure this is the correct import for your widget

class HometownAddressPage extends StatelessWidget {
  const HometownAddressPage({super.key});

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[200],
                      backgroundColor: Colors.red[800]!.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      context
                          .pop(); // Requires GoRouter. Replace with Navigator.pop(context) if not using GoRouter
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Back to Home"),
                  ),
                  const SizedBox(height: 24),

                  // Title and subtitle
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "Hometown Address",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE4E1),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Save your hometown address for emergency reference",
                          style: TextStyle(color: Color(0xFFFCA5A5)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // HometownAddressWidget
                  const HometownAddressWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
