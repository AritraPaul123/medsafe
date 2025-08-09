import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/services/assistant_services.dart';
import 'package:icons_plus/icons_plus.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Live Location",
        "description": "Track and share your current location",
        "icon": Icons.location_on_outlined,
        "path": "/location",
        "color": Colors.purple
      },
      {
        "title": "Current Location",
        "description": "Manually set your current location",
        "icon": Icons.navigation_outlined,
        "path": "/current-location",
        "color": Colors.green
      },
      {
        "title": "Hometown Location",
        "description": "Save your hometown location",
        "icon": Icons.home_outlined,
        "path": "/hometown-address",
        "color": Colors.blue
      },
      {
        "title": "Emergency Instructions",
        "description": "Step-by-step emergency guidance",
        "icon": Icons.favorite_border,
        "path": "/instructions",
        "color": Colors.redAccent
      },
      {
        "title": "My Medical Kit",
        "description": "Manage your medical supplies",
        "icon": Icons.medical_services_outlined,
        "path": "/medical-kit",
        "color": Colors.green
      },
      {
        "title": "Emergency Contacts",
        "description": "Manage your emergency contacts",
        "icon": Icons.phone_outlined,
        "path": "/contacts",
        "color": Colors.orange
      },
      {
        "title": "Insurance Documents",
        "description": "Store and share insurance info",
        "icon": Icons.description_outlined,
        "path": "/insurance",
        "color": Colors.indigo
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F1D1D), Colors.black, Color(0xFF7F1D1D)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Colors.red],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.red.shade200.withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(blurRadius: 10, color: Colors.redAccent)
                    ],
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Medsafe Emergency",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your comprehensive medical emergency companion. Quick access to emergency services, medical information, and safety tools.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // SOS Button
                ElevatedButton(
                  onPressed: () async {
                    final pos = await Geolocator.getCurrentPosition();
                    await SosController.startLiveActivity(
                        pos.latitude, pos.longitude);

                    // your WhatsApp deep link sending here...

                    // When SOS is over:
                    await SosController.activateSOS(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("SOS Activated!")),
                    );
                    await SosController.endLiveActivity();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("SOS", style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 16),

// Quick Actions bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        icon: Icons.phone,
                        label: 'Assistant',
                        onTap: () => AssistantService.callAssistant(context),
                      ),
                      _QuickAction(
                        icon: Iconsax.whatsapp_outline,
                        label: 'WA Help',
                        onTap: () =>
                            AssistantService.whatsappAssistantWithLocation(
                                context),
                      ),
                      _QuickAction(
                        icon: Icons.local_hospital,
                        label: 'Hospitals',
                        onTap: AssistantService.callNearestHospital,
                      ),
                      _QuickAction(
                        icon: Icons.local_taxi,
                        label: 'Book Ride',
                        onTap: AssistantService.bookRideToHospital,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Responsive Navigation Grid using Wrap
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: menuItems.map((item) {
                    return GestureDetector(
                      onTap: () => context
                          .push(item['path']), // <-- use push instead of go
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 48) / 2,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item['color'].withOpacity(0.25),
                              item['color'].withOpacity(0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.red.shade100.withOpacity(0.2),
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item['icon'],
                                size: 32, color: Colors.redAccent),
                            const SizedBox(height: 8),
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['description'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.redAccent),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
