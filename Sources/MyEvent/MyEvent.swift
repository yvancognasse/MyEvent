import SwiftUI
import Combine
import AppKit
import EventKit

@main
@MainActor
enum MyEventApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}

@MainActor
final class AppModel: ObservableObject {
    let store = EKEventStore()
    let hotKey = HotKey()
    @Published var language = AppLanguage.saved {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "interfaceLanguage")
            error = ""
            NotificationCenter.default.post(name: .myEventLanguageChanged, object: nil)
        }
    }
    @Published var calendars: [EKCalendar] = []
    @Published var selected: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "calendars") ?? [])
    @Published var shortcut = (UserDefaults.standard.data(forKey: "shortcut").flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }) ?? Shortcut()
    @Published var error = ""
    @Published var accessibilityGranted = AXIsProcessTrusted()
    private var lastCapture = Date.distantPast
    @Published var recording = false
    @Published var busy = false
    @Published var authorized = false
    @Published var tab = 0
    private var observation: NSObjectProtocol?
    private var keyMonitor: Any?
    init() {
        hotKey.action = { [weak self] in Task { @MainActor in await self?.capture() } }
        if !hotKey.register(shortcut) { error = tr("This shortcut is already in use. Choose another combination in General.") }
        refresh()
        observation = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
    func refreshPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        authorized = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }
    func refresh() {
        refreshPermissions()
        calendars = authorized ? store.calendars(for: .event).sorted { ($0.source.title, $0.title) < ($1.source.title, $1.title) } : []
    }
    func requestCalendars() async {
        do {
            authorized = try await store.requestFullAccessToEvents()
            refresh()
            if !authorized { error = tr("Calendar access denied. Allow full calendar access in System Settings.") }
        } catch { self.error = error.localizedDescription }
    }
    func toggle(_ calendar: EKCalendar, enabled: Bool) {
        if enabled { selected.insert(calendar.calendarIdentifier) } else { selected.remove(calendar.calendarIdentifier) }
        UserDefaults.standard.set(Array(selected), forKey: "calendars")
    }
    var destinations: [EKCalendar] { calendars.filter { selected.contains($0.calendarIdentifier) && $0.allowsContentModifications } }
    var missingDestinations: Bool { authorized && selected.count != destinations.count }
    func capture() async {
        guard !busy, !recording, Date().timeIntervalSince(lastCapture) > 1.2 else { return }
        lastCapture = Date()
        busy = true
        DockFeedback.begin()
        defer { busy = false; DockFeedback.finish() }
        do {
            refresh()
            guard authorized, !destinations.isEmpty, !missingDestinations else {
                throw CaptureError.destinations
            }
            let calendarIDs = destinations.map(\.calendarIdentifier)
            let names = destinations.map { "\($0.source.title) / \($0.title)" }
            let text = try await SelectionReader.read()
            let selectedLanguage = language
            let capturedAt = Date()
            let translated = try await EventTextTranslator.translate(text, to: selectedLanguage)
            let draft = EventContentBuilder.build(source: text, translated: translated, language: selectedLanguage, now: capturedAt)
            error = ""
            EventPopup.review(EventReceipt(draft: draft, destinations: names, language: selectedLanguage)) { [weak self] edited in
                guard let self else { throw CaptureError.destinations }
                do {
                    try self.save(edited, to: calendarIDs)
                    self.error = ""
                } catch {
                    self.error = error.localizedDescription
                    throw error
                }
            }
        } catch is CancellationError {
            error = ""
        } catch {
            self.error = error.localizedDescription
            EventPopup.failed(error.localizedDescription)
        }
    }
    enum CaptureError: LocalizedError {
        case destinations, invalidEvent
        var errorDescription: String? {
            switch self {
            case .destinations: return tr("Allow calendar access and select at least one available destination in Accounts.")
            case .invalidEvent: return tr("The selected text could not be turned into a valid event.")
            }
        }
    }
    func save(_ draft: EventDraft, to calendarIDs: [String]) throws {
        refreshPermissions()
        let reviewedCalendars = calendarIDs.compactMap { store.calendar(withIdentifier: $0) }
        guard authorized, !calendarIDs.isEmpty,
              Set(calendarIDs).count == calendarIDs.count,
              reviewedCalendars.count == calendarIDs.count,
              reviewedCalendars.allSatisfy(\.allowsContentModifications) else {
            throw CaptureError.destinations
        }
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, draft.end > draft.start else {
            throw CaptureError.invalidEvent
        }
        do {
            for calendar in reviewedCalendars {
                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                event.title = draft.title
                event.startDate = draft.start
                event.endDate = draft.end
                event.location = draft.location
                event.notes = draft.notes
                event.url = draft.url
                try store.save(event, span: .thisEvent, commit: false)
            }
            try store.commit()
        } catch {
            store.reset()
            refresh()
            throw error
        }
    }
    func startRecording() {
        guard !recording else { return }
        recording = true
        error = ""
        hotKey.suspend()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { self.stopRecording(); return nil }
            guard let value = Shortcut.from(event) else {
                self.error = tr("Use ⌘, ⌥ or ⌃ with a key (⇧ alone is not enough)."); return nil
            }
            if self.hotKey.register(value) {
                self.shortcut = value
                UserDefaults.standard.set(try? JSONEncoder().encode(value), forKey: "shortcut")
                self.finishRecording()
                self.error = ""
            } else {
                self.error = tr("This combination is already in use. Try another, or press Escape to cancel.")
            }
            return nil
        }
    }
    func finishRecording() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        recording = false
    }
    func stopRecording() {
        guard recording else { return }
        finishRecording()
        if !hotKey.register(shortcut) { error = tr("Shortcut unavailable. Choose another combination.") }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var model: AppModel!
    private var languageObserver: NSObjectProtocol?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        PreferencesMigration.run()
        model = AppModel()
        languageObserver = NotificationCenter.default.addObserver(forName: .myEventLanguageChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.window?.title = "MyEvent — \(tr("Settings"))"
                self?.installMenus()
            }
        }
        let settingsStyle: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        // Match the reference's outer size, including the native title bar.
        let settingsFrame = NSRect(x: 0, y: 0, width: 512, height: 471)
        let settingsContent = NSWindow.contentRect(forFrameRect: settingsFrame, styleMask: settingsStyle)
        window = NSWindow(contentRect: settingsContent, styleMask: settingsStyle, backing: .buffered, defer: false)
        window.title = "MyEvent — \(tr("Settings"))"
        window.minSize = settingsFrame.size
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: MainView(model: model))
        window.center()
        DispatchQueue.main.async { self.installMenus() }
        show()
    }
    func show() {
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    func installMenus() {
        let bar = NSMenu()
        func group(_ title: String) -> NSMenu {
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: title)
            item.submenu = submenu
            bar.addItem(item)
            return submenu
        }
        func add(_ menu: NSMenu, _ key: String, action: Selector, shortcut: String = "", target: AnyObject? = nil) {
            let item = NSMenuItem(title: tr(key), action: action, keyEquivalent: shortcut)
            item.target = target
            menu.addItem(item)
        }
        let application = group("MyEvent")
        add(application, "Settings…", action: #selector(openWindow), shortcut: ",", target: self)
        application.addItem(.separator())
        add(application, "Hide MyEvent", action: #selector(NSApplication.hide(_:)), shortcut: "h", target: NSApp)
        add(application, "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), target: NSApp)
        application.addItem(.separator())
        add(application, "Quit MyEvent", action: #selector(quit), shortcut: "q", target: self)
        let windows = group(tr("Window"))
        add(windows, "Minimize", action: #selector(NSWindow.miniaturize(_:)), shortcut: "m")
        add(windows, "Close", action: #selector(NSWindow.performClose(_:)), shortcut: "w")
        add(windows, "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), target: NSApp)
        NSApp.windowsMenu = windows
        let help = group(tr("Help"))
        add(help, "Help (English)", action: #selector(openHelp), shortcut: "?", target: self)
        NSApp.helpMenu = help
        NSApp.mainMenu = bar
    }
    @objc func openHelp() { HelpGuide.open() }
    @objc func openWindow() { show() }
    @objc func quit() { NSApp.terminate(nil) }
    func windowWillClose(_ notification: Notification) {
        model.stopRecording()
        if let closingWindow = notification.object as? NSWindow, closingWindow === window {
            NSApp.terminate(nil)
        }
    }
    func windowDidResignKey(_ notification: Notification) { model.stopRecording() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { show(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

struct MainView: View {
    @ObservedObject var model: AppModel
    private let permissionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let tabs = [("General", "gearshape"), ("Accounts", "at"), ("Permissions", "hand.raised")]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button {
                        model.stopRecording()
                        model.tab = index
                        model.refreshPermissions()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tabs[index].1).font(.system(size: 21, weight: .regular))
                            Text(tr(tabs[index].0)).font(.system(size: 11))
                        }
                        .foregroundStyle(model.tab == index ? Color.accentColor : .secondary)
                        .frame(width: index == 2 ? 92 : 76, height: 56)
                        .background(model.tab == index ? Color(nsColor: .controlBackgroundColor) : .clear, in: RoundedRectangle(cornerRadius: 7))
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityAddTraits(model.tab == index ? .isSelected : [])
                }
            }.frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 10)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if model.tab == 0 { general.disabled(model.busy) }
                    else if model.tab == 1 { accounts.disabled(model.busy) }
                    else { permissions }
                    if !model.error.isEmpty {
                        Label(model.error, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.orange).textSelection(.enabled)
                    }
                }.padding(.horizontal, 36).padding(.vertical, 24).frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider().padding(.horizontal, 24)
            HStack(spacing: 10) {
                if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"), let icon = NSImage(contentsOf: url) {
                    Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.busy ? tr("Preparing event…") : "MyEvent")
                        .lineLimit(2).font(.caption)
                    Text(BuildInfo.label).font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Spacer(minLength: 0)
                Button { HelpGuide.open() } label: { Image(systemName: "questionmark.circle") }
                    .buttonStyle(.plain).font(.system(size: 20)).help(tr("Help (English)"))
                    .accessibilityLabel(tr("Help (English)"))
                Button(tr("Quit")) {
                    model.stopRecording()
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .help(tr("Quit MyEvent"))
                Button(tr("Hide")) {
                    model.stopRecording()
                    NSApp.hide(nil)
                }
                .buttonStyle(.borderedProminent)
                .help(tr("Hide MyEvent"))
            }
            // Keep the actions at the physical bottom right in every language.
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 24).padding(.vertical, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, Locale(identifier: model.language.rawValue))
        .environment(\.layoutDirection, model.language.isRightToLeft ? .rightToLeft : .leftToRight)
        .onReceive(permissionTimer) { _ in
            if model.tab == 2, NSApp.isActive { model.refreshPermissions() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in model.refresh() }
    }
    private var general: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(tr("Language:")).font(.callout.weight(.medium))
                Spacer()
                Picker(tr("Language"), selection: $model.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }.labelsHidden().frame(width: 230)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(tr("Global shortcut:")).font(.callout.weight(.medium))
                    Spacer()
                    Button(model.recording ? tr("Press your shortcut…") : model.shortcut.label) { model.startRecording() }
                    if model.recording { Button(tr("Cancel")) { model.stopRecording() } }
                }
                Text(tr("Select text and press the shortcut. Review the details before creating the event."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Text(tr("The chosen language is used for the event title and detailed notes.")).font(.caption).foregroundStyle(.secondary)
            Divider()
            Text(tr("The red button quits MyEvent and disables the shortcut. The yellow button minimizes the window and keeps MyEvent running."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private var accounts: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tr("Add events to:")).font(.callout)
            Text(tr("A copy is created in each selected calendar.")).font(.caption).foregroundStyle(.secondary)
            if !model.authorized {
                Button(tr("Allow calendar access…")) { Task { await model.requestCalendars() } }
            } else if model.calendars.isEmpty {
                Text(tr("No calendars available. Add an account in Calendar on this Mac.")).foregroundStyle(.secondary)
            } else {
                ForEach(Array(Set(model.calendars.map { $0.source.sourceIdentifier })).sorted(), id: \.self) { source in
                    let entries = model.calendars.filter { $0.source.sourceIdentifier == source }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entries.first?.source.title ?? tr("Account")).font(.callout.weight(.semibold)).foregroundStyle(.secondary)
                        ForEach(entries, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: Binding(get: { model.selected.contains(calendar.calendarIdentifier) }, set: { model.toggle(calendar, enabled: $0) })) {
                                HStack(spacing: 7) {
                                    Circle().fill(Color(cgColor: calendar.cgColor)).frame(width: 8, height: 8)
                                    Text(calendar.title)
                                    if !calendar.allowsContentModifications { Text(tr("Read only")).foregroundStyle(.secondary).font(.caption) }
                                }
                            }.disabled(!calendar.allowsContentModifications)
                        }
                    }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            if model.missingDestinations {
                Text(tr("Some selected destinations are no longer available.")).font(.caption).foregroundStyle(.orange)
                Button(tr("Remove unavailable destinations")) {
                    model.selected = Set(model.destinations.map(\.calendarIdentifier))
                    UserDefaults.standard.set(Array(model.selected), forKey: "calendars")
                }
            }
            Divider()
            HStack {
                Button(tr("Manage accounts…")) { open("x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension") }
                Spacer()
                Button(tr("Refresh")) { model.refresh() }
            }
            Text(tr("Only accounts synced with macOS Calendar are available.")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var permissions: some View {
        VStack(alignment: .leading, spacing: 20) {
            permissionRow(tr("Calendars"), detail: tr("Show calendar destinations and add events."), granted: model.authorized) {
                if model.authorized { open("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") }
                else { Task { await model.requestCalendars() } }
            }
            Divider()
            permissionRow(tr("Accessibility"), detail: tr("Read selected text in the source application."), granted: model.accessibilityGranted) {
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
                open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            }
            if !model.accessibilityGranted {
                Text(tr("If MyEvent is already enabled in macOS, remove the old entry, add this app again, then quit and reopen MyEvent.")).font(.caption).foregroundStyle(.secondary)
                Text(Bundle.main.bundlePath).font(.caption2.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
            }
            Button(tr("Refresh")) { model.refreshPermissions() }
            Divider()
            Text(tr("No external services. If selected text is not directly accessible, MyEvent uses Copy and restores the clipboard."))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func permissionRow(_ title: String, detail: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
                Label(granted ? tr("Allowed") : tr("Not allowed"), systemImage: granted ? "checkmark.circle.fill" : "circle")
                    .font(.caption).foregroundStyle(granted ? .green : .secondary)
            }
            Spacer()
            Button(granted ? tr("Settings…") : tr("Allow…"), action: action)
        }
    }
    private func open(_ address: String) { NSWorkspace.shared.open(URL(string: address)!) }
}
