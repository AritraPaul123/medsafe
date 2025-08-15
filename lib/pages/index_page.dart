// lib/pages/index_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/services/assistant_services.dart';
import 'package:medsafe/widgets/toast.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    // Simple menu model (theme handles colors; no per-item color)
    final items = <_MenuItem>[
      _MenuItem('Live Location', 'Track and share your current location',
          Icons.location_on_outlined, '/location'),
      _MenuItem('Current Location', 'Manually set your current location',
          Icons.navigation_outlined, '/current-location'),
      _MenuItem('Hometown Location', 'Save your hometown location',
          Icons.home_outlined, '/hometown-address'),
      _MenuItem('Emergency Instructions', 'Step-by-step emergency guidance',
          Icons.favorite_border, '/instructions'),
      _MenuItem('My Medical Kit', 'Manage your medical supplies',
          Icons.medical_services_outlined, '/medical-kit'),
      _MenuItem('Emergency Contacts', 'Manage your emergency contacts',
          Icons.phone_outlined, '/contacts'),
      _MenuItem('Insurance Documents', 'Store and share insurance info',
          Icons.description_outlined, '/insurance'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medsafe'),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Header + SOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.warning_amber_rounded,
                              color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Emergency tools at your fingertips',
                              style: t.textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSOS(context),
                        icon: const Icon(Icons.sos),
                        label: const Text('Activate SOS'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sends your location to emergency contacts and initiates a call.',
                      style: t.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick actions
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickAction(
                      icon: Icons.phone,
                      label: 'Assistant',
                      onTap: () => AssistantService.callAssistant(context),
                    ),
                    _QuickAction(
                      icon: Icons.chat_bubble_outline,
                      label: 'WA Help',
                      onTap: () =>
                          AssistantService.whatsappAssistantWithLocation(
                              context),
                    ),
                    _QuickAction(
                      icon: Icons.local_hospital_outlined,
                      label: 'Hospitals',
                      onTap: AssistantService.callNearestHospital,
                    ),
                    _QuickAction(
                      icon: Icons.local_taxi_outlined,
                      label: 'Book Ride',
                      onTap: () => AssistantService.bookRideToHospital(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Navigation grid
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final isWide = c.maxWidth > 700;
                    final crossAxisCount = isWide ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (_, i) => _MenuCard(item: items[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSOS(BuildContext context) async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await SosController.startLiveActivity(pos.latitude, pos.longitude);

      // If you also send a WhatsApp deep link, do it here.

      await SosController.activateSOS(context);
      showToast(context,
          title: 'SOS activated',
          description: 'Location sent to your contacts.');
    } catch (e) {
      showToast(context,
          title: 'SOS failed', description: e.toString(), isError: true);
    } finally {
      await SosController.endLiveActivity();
    }
  }
}

// --- Small UI bits ---

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String description;
  final IconData icon;
  final String path;
  const _MenuItem(this.title, this.description, this.icon, this.path);
}

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final borderRadius = BorderRadius.circular(14);
    final borderColor = cs.outline.withOpacity(0.35);

    // Background subtly reacts to hover/press (web/desktop) and tap (mobile).
    final baseBg = cs.surface;
    final hoverBg = cs.surfaceVariant.withOpacity(0.08);
    final pressBg = cs.surfaceVariant.withOpacity(0.14);
    final bg = _pressed ? pressBg : (_hover ? hoverBg : baseBg);

    return Semantics(
      button: true,
      label: widget.item.title,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.98 : 1.0,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: borderColor, width: 2),
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => context.push(widget.item.path),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            onHover: (v) => setState(() => _hover = v),
            child: Padding(
              // Tight padding = minimal look
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon chip
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.item.icon, color: cs.primary),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    widget.item.title,
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    widget.item.description,
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.textTheme.bodySmall?.color?.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
