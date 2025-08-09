import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  final String? attemptedRoute;

  const NotFoundPage({super.key, this.attemptedRoute});

  @override
  Widget build(BuildContext context) {
    if (attemptedRoute != null) {
      debugPrint(
          "404 Error: User attempted to access non-existent route: $attemptedRoute");
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Tailwind's gray-100
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Page not found',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF4B5563), // Tailwind's gray-600
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text(
                'Return to Home',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
