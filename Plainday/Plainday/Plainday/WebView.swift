import SwiftUI
import WebKit

/// Hosts the bundled Plainday page (index.html) full-screen.
struct PlaindayWebView: UIViewRepresentable {
    func makeCoordinator() -> Bridge { Bridge() }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "plainday")

        // Hand the page whatever was saved last time, before its script runs.
        let boot = """
        window.__PLAINDAY_STATE__ = \(Storage.jsString(Storage.read("state.json")));
        window.__PLAINDAY_IMGS__ = \(Storage.jsString(Storage.read("stickers.json")));
        """
        controller.addUserScript(WKUserScript(source: boot, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.websiteDataStore = .default()

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.contentInsetAdjustmentBehavior = .never   // the page pads for the notch itself
        web.navigationDelegate = context.coordinator
        if #available(iOS 16.4, *) { web.isInspectable = true }   // lets you debug with Safari on a Mac

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
