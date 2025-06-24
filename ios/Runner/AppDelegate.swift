import Flutter
import UIKit
import FirebaseCore
import FirebaseAnalytics
import BranchSDK
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
    
    // --- Branch SDK initialization ---
    // Инициализация Branch для обработки диплинков и универсальных ссылок
    Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
      // params содержит данные диплинка, если приложение открыто по ссылке
      print("[AppDelegate] Branch params: \(String(describing: params))")
    }
    // --- End Branch SDK initialization ---
    
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

  // --- Обработка Universal Links (Branch) ---
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    Branch.getInstance().continue(userActivity)
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  // --- Обработка URI Scheme (Branch) ---
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    Branch.getInstance().application(app, open: url, options: options)
    return super.application(app, open: url, options: options)
  }
}
