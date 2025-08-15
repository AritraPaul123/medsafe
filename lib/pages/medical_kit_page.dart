// lib/pages/medical_kit_page.dart
import 'package:flutter/material.dart';
import 'package:medsafe/components/medical_kit.dart'; // or widgets/medical_kit.dart if you moved it

class MedicalKitPage extends StatelessWidget {
  const MedicalKitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Kit')),
      body: const SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: MedicalKit(),
        ),
      ),
    );
  }
}
