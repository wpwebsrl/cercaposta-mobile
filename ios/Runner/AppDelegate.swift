import Flutter
import UIKit
import Speech
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "cercaposta/offline_speech", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        guard call.method == "locales" else { result(FlutterMethodNotImplemented); return }
        if #available(iOS 13.0, *) {
          result(SFSpeechRecognizer.supportedLocales().filter { locale in
            SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition == true
          }.map { $0.identifier }.sorted())
        } else { result([String]()) }
      }
    }

    // OS notifications (docs/notifiche.md): the notification poll runs in a background isolate via
    // workmanager → BGAppRefreshTask. The isolate must be able to register the same Flutter plugins
    // (secure storage / prefs / local notifications), and the BGTask identifier must be registered
    // here at launch. iOS runs the task OPPORTUNISTICALLY — verify on device / TestFlight.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "it.cercaposta.app.notifyfetch",
      frequency: NSNumber(value: 15 * 60)
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
