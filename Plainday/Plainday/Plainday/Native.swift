import Foundation
import UIKit
import WebKit
import UserNotifications
import WidgetKit

/// Receives messages from the page: saves your lists and schedules notifications.
final class Bridge: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "save":
            if let state = body["state"] as? String { Storage.write("state.json", state) }
        case "imgs":
            if let imgs = body["imgs"] as? String { Storage.write("stickers.json", imgs) }
        case "notify":
            if let items = body["items"] as? [[String: Any]] { Alerts.schedule(items) }
        case "widget":
            if let summary = body["summary"] as? String { WidgetShare.publish(summary) }
        default:
            break
        }
    }

    // Web links open in Safari instead of inside the app.
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           let scheme = url.scheme, scheme.hasPrefix("http") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

/// Saves data as files in the app's private Application Support folder.
enum Storage {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Plainday", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func read(_ name: String) -> String? {
        try? String(contentsOf: folder.appendingPathComponent(name), encoding: .utf8)
    }

    static func write(_ name: String, _ text: String) {
        try? text.write(to: folder.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }

    /// A JavaScript string literal for `text`, or `null`.
    static func jsString(_ text: String?) -> String {
        guard let text = text,
              let data = try? JSONEncoder().encode(text),
              let literal = String(data: data, encoding: .utf8) else { return "null" }
        return literal
    }
}

/// Local notifications for reminders and events (iOS allows 64 pending; we use up to 60).
enum Alerts {
    static func schedule(_ items: [[String: Any]]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = .current
        parser.dateFormat = "yyyy-MM-dd HH:mm"

        let now = Date()
        var scheduled = 0
        for item in items {
            guard scheduled < 60,
                  let id = item["id"] as? String,
                  let title = item["title"] as? String,
                  let when = item["when"] as? String,
                  let date = parser.date(from: when),
                  date > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = (item["body"] as? String) ?? ""
            content.sound = .default

            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            scheduled += 1
        }
    }
}

/// Shares a small summary of today with the Home Screen and Lock Screen widgets.
enum WidgetShare {
    static var group: String {
        Bundle.main.object(forInfoDictionaryKey: "PlaindayAppGroup") as? String ?? ""
    }

    static func publish(_ summary: String) {
        guard !group.isEmpty, let defaults = UserDefaults(suiteName: group) else { return }
        let data = Data(summary.utf8)
        if defaults.data(forKey: "summary") == data { return }   // nothing changed
        defaults.set(data, forKey: "summary")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
