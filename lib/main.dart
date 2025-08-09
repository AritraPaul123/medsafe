import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:app_links/app_links.dart';
import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/services/notification_services.dart';
import 'app.dart';

// MethodChannel for native deep link communication
const MethodChannel _deepLinkChannel = MethodChannel('medsafe/deeplink');

// Global navigator key so SOS can run without rebuilding routes
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Hive.initFlutter();
  NotificationService.showSosQuickAction(); // <- here
  runApp(const MedSafeRoot()); // NOT MyApp inside MyApp
}

class MedSafeRoot extends StatefulWidget {
  const MedSafeRoot({super.key});

  @override
  State<MedSafeRoot> createState() => _MedSafeRootState();
}

class _MedSafeRootState extends State<MedSafeRoot> {
  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('group.medsafe.app');
    _listenForDeepLinks();
  }

  Future<void> _listenForDeepLinks() async {
    // Cold start: get the initial link if the app was launched via deep link
    try {
      final initialLink =
          await _deepLinkChannel.invokeMethod<String>('getInitialLink');
      if (initialLink != null) _handleUri(Uri.parse(initialLink));
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    // Warm start: listen for incoming links while the app is running
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final link = call.arguments as String?;
        if (link != null) _handleUri(Uri.parse(link));
      }
    });
  }

  void initLinks() async {
    final _appLinks = AppLinks();

    // Initial link (app opened via deep link)
    final Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) _handleUri(initialLink);

    // Listen for incoming links (while app is running)
    _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == 'medsafe' && uri.host == 'sos') {
      SosController.activateSOS(navigatorKey.currentContext!);
    } else if (uri.scheme == 'medsafe' && uri.host == 'end-sos') {
      SosController.endLiveActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Medsafe',
      theme: ThemeData.dark(),
      home:
          const MyApp(), // ⛔ this rebuilds MyApp inside itself -> recursion & duplicate keys
    );
  }
}
