// lib/pages/hometown_address_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medsafe/components/hometown_address.dart';

class HometownAddressPage extends StatelessWidget {
  const HometownAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hometown Address'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: const SafeArea(
        minimum: EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: HometownAddressWidget(),
        ),
      ),
    );
  }
}
