// lib/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/utils/theme.dart';

import 'pages/index_page.dart';
import 'pages/live_location_page.dart';
import 'pages/emergency_instructions_page.dart';
import 'pages/medical_kit_page.dart';
import 'pages/emergency_contacts_page.dart';
import 'pages/insurance_documents_page.dart';
import 'pages/hometown_address_page.dart';
import 'pages/manual_location_page.dart';
import 'pages/not_found_page.dart';

/// Keep router at file scope so it doesn't rebuild on every frame.
final GoRouter _router = GoRouter(
  routes: [
    // Trigger SOS immediately, then render nothing.
    GoRoute(
      path: '/sos',
      builder: (ctx, state) {
        // Fire-and-forget so we don't block the build.
        Future.microtask(() => SosController.activateSOS(ctx));
        return const SizedBox.shrink();
      },
    ),
    GoRoute(path: '/', builder: (_, __) => const IndexPage()),
    GoRoute(path: '/location', builder: (_, __) => const LiveLocationPage()),
    GoRoute(
        path: '/instructions', builder: (_, __) => EmergencyInstructionsPage()),
    GoRoute(path: '/medical-kit', builder: (_, __) => const MedicalKitPage()),
    GoRoute(
        path: '/contacts', builder: (_, __) => const EmergencyContactsPage()),
    GoRoute(
        path: '/insurance', builder: (_, __) => const InsuranceDocumentsPage()),
    GoRoute(
        path: '/hometown-address',
        builder: (_, __) => const HometownAddressPage()),
    GoRoute(
        path: '/current-location',
        builder: (_, __) => const ManualLocationPage()),
  ],
  errorBuilder: (_, __) => const NotFoundPage(),
);

/// Expose a single app widget. `main.dart` should do:
///   runApp(const App());
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Medsafe',
      theme: buildMinimalTheme(),
      darkTheme: buildMinimalDarkTheme(),
      themeMode: ThemeMode.system,

      // Respect large text while protecting layout
      builder: (context, child) {
        final scale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.4);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },

      routerConfig: _router,
    );
  }
}
