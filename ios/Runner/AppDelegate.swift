import Flutter
import UIKit
import FirebaseCore
import FirebaseAnalytics
// import flutter_web_auth_2

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🔥 AppDelegate: Configuring Firebase")
    FirebaseApp.configure() // Инициализация Firebase
    Analytics.setAnalyticsCollectionEnabled(true)
    print("🔥 AppDelegate: Firebase configured successfully")
    
    #if DEBUG
    // Явно включаем режим отладки для физических устройств
    let arguments = ProcessInfo.processInfo.arguments
    if !arguments.contains("-FIRDebugEnabled") && !arguments.contains("-FIRAnalyticsDebugEnabled") {
      Analytics.setAnalyticsCollectionEnabled(true)
      UserDefaults.standard.set(true, forKey: "FIREBASE_ANALYTICS_DEBUG_MODE_ENABLED")
      print("🔥 Firebase Analytics debug mode enabled programmatically")
      
      // Отправляем тестовое событие из iOS кода напрямую
      Analytics.logEvent("ios_native_test_event", parameters: [
        "timestamp": NSDate().timeIntervalSince1970,
        "platform": "iOS Native"
      ])
      print("🔥 Sent test iOS native Firebase analytics event")
    }
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    //  FlutterWebAuth2Plugin.register(with: self.registrar(forPlugin: "FlutterWebAuth2Plugin")!)
     if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
