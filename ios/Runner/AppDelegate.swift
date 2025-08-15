import Flutter
import UIKit

GMSServices.provideAPIKey("AIzaSyCFT2bpuZamzvz49My7QVc0trVrZHmqLaY")
GMSPlacesClient.provideAPIKey("AIzaSyCFT2bpuZamzvz49My7QVc0trVrZHmqLaY")
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
