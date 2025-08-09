import 'package:home_widget/home_widget.dart';

class WidgetBridge {
  static const String appGroupId = 'group.medsafe.app'; // set in Xcode
  static Future<void> update() async {
    await HomeWidget.saveWidgetData<String>('deeplink', 'medsafe://sos');
    await HomeWidget.updateWidget(
      name: 'MedsafeWidget',
      iOSName: 'MedsafeWidget', // must match WidgetKit target
    );
  }
}
