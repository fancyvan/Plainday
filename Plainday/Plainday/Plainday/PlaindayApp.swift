import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        return true
    }

    // Show reminder banners even while Plainday is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}

@main
struct PlaindayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let band = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.09, blue: 0.15, alpha: 1)
            : UIColor(red: 0.85, green: 0.82, blue: 1.0, alpha: 1)
    })

    var body: some Scene {
        WindowGroup {
            PlaindayWebView()
                .ignoresSafeArea()
                .background(band.ignoresSafeArea())
        }
    }
}
