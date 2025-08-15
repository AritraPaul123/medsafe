// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:app_links/app_links.dart';

import 'package:medsafe/controllers/sos_controller.dart';
import 'package:medsafe/services/notification_services.dart';
import 'package:medsafe/utils/theme.dart'; // must provide buildMinimalTheme()
import 'app.dart'; // ensure this exposes your real root widget (e.g., App())

// Native channel for deep links from iOS/Android (cold start + warm)
const MethodChannel _deepLinkChannel = MethodChannel('medsafe/deeplink');

// Global navigator key so SOS can run without rebuilding routes
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep status/navigation bars tidy and high-contrast
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await NotificationService.init(navigatorKey);
  await Hive.initFlutter();

  // Optional quick action (kept where it was)
  NotificationService.showSosQuickAction();
  NotificationService.showSosFullScreen();

  // Safety net for any uncaught errors
  runZonedGuarded(
    () => runApp(const MedSafeRoot()),
    (error, stack) => debugPrint('Uncaught: $error\n$stack'),
  );
}

class MedSafeRoot extends StatefulWidget {
  const MedSafeRoot({super.key});
  @override
  State<MedSafeRoot> createState() => _MedSafeRootState();
}

class _MedSafeRootState extends State<MedSafeRoot> {
  StreamSubscription<Uri>? _linkSub;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('group.medsafe.app');

    _setupDeepLinks(); // Native method channel (cold + warm)
    _setupAppLinks(); // app_links (cold + warm)
  }

  // --- Deep links via native MethodChannel (iOS/Android) ---
  Future<void> _setupDeepLinks() async {
    // Cold start
    try {
      final initialLink =
          await _deepLinkChannel.invokeMethod<String>('getInitialLink');
      if (initialLink != null) _handleUri(Uri.parse(initialLink));
    } catch (e) {
      debugPrint('DeepLink initial (native) error: $e');
    }

    // Warm start
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final link = call.arguments as String?;
        if (link != null) _handleUri(Uri.parse(link));
      }
    });
  }

  // --- Deep links via app_links package (universal/app links) ---
  Future<void> _setupAppLinks() async {
    _appLinks = AppLinks();

    // Cold start
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      debugPrint('AppLinks initial error: $e');
    }

    // Warm start
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) => debugPrint('AppLinks stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    // Normalize and route
    if (uri.scheme == 'medsafe' && uri.host == 'sos') {
      final ctx = navigatorKey.currentState?.context;
      if (ctx != null) SosController.activateSOS(ctx);
    } else if (uri.scheme == 'medsafe' && uri.host == 'end-sos') {
      SosController.endLiveActivity();
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Medsafe',
      // Minimal, high-contrast theme (implement in medsafe/utils/theme.dart)
      theme: buildMinimalTheme(),
      darkTheme: buildMinimalDarkTheme(),
      themeMode: ThemeMode.system,
      // If you have a dark theme helper, uncomment:
      // darkTheme: buildMinimalDarkTheme(),
      // Respect system theme:

      // Clamp text scale for layout safety but still accessible.
      builder: (context, child) {
        final scale = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.4);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // IMPORTANT: Do NOT put MyApp here if MyApp builds MedSafeRoot.
      // Use your actual app shell/root from app.dart to avoid recursion.
      // Example: if app.dart exposes `App()` as the real root, keep this:
      home: const App(),
      // If your root is named differently (e.g., HomeShell or RootRouter),
      // change `App()` to that widget.
    );
  }
}
