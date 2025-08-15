// lib/pages/not_found_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  final String? attemptedRoute;

  const NotFoundPage({super.key, this.attemptedRoute});

  @override
  Widget build(BuildContext context) {
    if (attemptedRoute != null) {
      debugPrint('404: attempted route => $attemptedRoute');
    }

    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Page not found'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.search_off, color: cs.primary),
                    ),
                    const SizedBox(height: 12),

                    // Headline
                    Text('Oops — page not found',
                        style: t.textTheme.titleLarge),
                    const SizedBox(height: 8),

                    // Details
                    if (attemptedRoute != null && attemptedRoute!.isNotEmpty)
                      Text(
                        '“$attemptedRoute” doesn’t exist.',
                        style: t.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'The page you’re looking for doesn’t exist or has moved.',
                        style: t.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),

                    // Action
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Go to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
