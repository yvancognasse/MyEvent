import AppKit
import WebKit

/// One retained native help window. No browser is launched for the guide or its links.
@MainActor
enum HelpGuide {
    private static var controller: HelpWindowController?
    static func open() {
        if controller == nil { controller = HelpWindowController() }
        controller?.open()
    }
    static func openOffline() { open() }
}

@MainActor
private final class HelpWindowController: NSWindowController, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero)
    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 880, height: 720), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "MyEvent Help (English)"
        window.minSize = NSSize(width: 560, height: 440)
        window.isReleasedWhenClosed = false
        window.contentView = webView
        window.setFrameAutosaveName("MyEventHelp")
        window.center()
        super.init(window: window)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func open() {
        guard let url = Bundle.main.url(forResource: "help", withExtension: "html") else {
            let alert = NSAlert()
            alert.messageText = "MyEvent Help"
            alert.informativeText = "The bundled English guide is missing. Please rebuild MyEvent."
            alert.runModal()
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        let allowed = ["file", "https", "http", "about"].contains(url.scheme?.lowercased() ?? "")
        guard allowed else { decisionHandler(.cancel); return }
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
        } else { decisionHandler(.allow) }
    }
}
