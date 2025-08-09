import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medsafe/components/hometown_address.dart';
import 'package:medsafe/controllers/sos_controller.dart';
import 'pages/index_page.dart';
import 'pages/live_location_page.dart';
import 'pages/emergency_instructions_page.dart';
import 'pages/medical_kit_page.dart';
import 'pages/emergency_contacts_page.dart';
import 'pages/insurance_documents_page.dart';
import 'pages/hometown_address_page.dart';
import 'pages/manual_location_page.dart';
import 'pages/not_found_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      errorBuilder: (context, state) => const NotFoundPage(),
      routes: [
        // wherever you configure GoRouter:
        GoRoute(
          path: '/sos',
          builder: (ctx, state) {
            // Fire SOS immediately, then show a minimal screen or pop.
            Future.microtask(() => SosController.activateSOS(ctx));
            return const SizedBox.shrink();
          },
        ),

        GoRoute(path: '/', builder: (context, state) => const IndexPage()),
        GoRoute(
            path: '/location',
            builder: (context, state) => const LiveLocationPage()),
        GoRoute(
            path: '/instructions',
            builder: (context, state) => EmergencyInstructionsPage()),
        GoRoute(
            path: '/medical-kit',
            builder: (context, state) => const MedicalKitPage()),
        GoRoute(
            path: '/contacts',
            builder: (context, state) => const EmergencyContactsPage()),
        GoRoute(
            path: '/insurance',
            builder: (context, state) => const InsuranceDocumentsPage()),
        GoRoute(
            path: '/hometown-address',
            builder: (context, state) => const HometownAddressPage()),
        GoRoute(
            path: '/current-location',
            builder: (context, state) => const ManualLocationPage()),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Medsafe Rescue Beacon',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      routerConfig: _router,
    );
  }
}
