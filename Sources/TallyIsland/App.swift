import AppKit
import SwiftUI
import Carbon

final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: IslandPanel!
    var model: IslandModel!
    var statusItem: NSStatusItem!
    var hotKey: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    var selectedScreen: NSScreen { NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main ?? NSScreen.screens[0] }
    let isPreview = CommandLine.arguments.contains("--preview")
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let renderMode = CommandLine.arguments.contains("--render-preview")
        model = IslandModel(demo: renderMode)
        if renderMode { renderPreviews(); NSApp.terminate(nil); return }
        panel = IslandPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.level = .statusBar; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false
        let top = max(34, selectedScreen.safeAreaInsets.top)
        let notch = hardwareNotchWidth()
        panel.contentView = NSHostingView(rootView: IslandView(model: model, topHeight: top, notchWidth: notch))
        model.resize = { [weak self] in self?.layout() }
        model.expanded = isPreview; model.pinned = isPreview
        layout(); panel.orderFrontRegardless()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: "Tally Island")
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Tally Island", action: #selector(openIsland), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Focus timer", action: #selector(openFocus), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings", action: #selector(openSettings), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Tally Island", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        registerShortcut()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    func hardwareNotchWidth() -> CGFloat {
        let screen = selectedScreen
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea { return max(180, screen.frame.width - left.width - right.width) }
        return 150
    }
    func layout() {
        guard let panel else { return }
        let screen = selectedScreen
        let top = max(34, screen.safeAreaInsets.top)
        let width: CGFloat = model.expanded ? 620 : hardwareNotchWidth() + 190
        let height: CGFloat = model.expanded ? 540 : top
        let y = isPreview ? screen.visibleFrame.midY - height / 2 : screen.frame.maxY - height - (screen.safeAreaInsets.top == 0 ? 6 : 0)
        let frame = NSRect(x: screen.frame.midX - width / 2, y: y, width: width, height: height)
        panel.setFrame(frame, display: true)
        if model.expanded { panel.makeKeyAndOrderFront(nil) }
    }
    @objc func screenChanged() {
        panel.contentView = NSHostingView(rootView: IslandView(model: model, topHeight: max(34, selectedScreen.safeAreaInsets.top), notchWidth: hardwareNotchWidth()))
        layout()
    }
    @objc func openIsland() { model.open(.overview) }
    @objc func openFocus() { model.open(.focus) }
    @objc func openSettings() { model.open(.settings) }
    @objc func quit() { NSApp.terminate(nil) }
    func registerShortcut() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, data in
            guard let data else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(data).takeUnretainedValue()
            Task { @MainActor in delegate.model.toggle() }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        let result = RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x54414C59, id: 1), GetApplicationEventTarget(), 0, &hotKey)
        if result != noErr { model.showNotice("Shortcut unavailable. Use the menu bar icon.") }
    }
    func application(_ application: NSApplication, open urls: [URL]) { model.addFiles(urls); model.open(.shelf) }
    func applicationWillTerminate(_ notification: Notification) {
        if let hotKey { UnregisterEventHotKey(hotKey) }; if let eventHandler { RemoveEventHandler(eventHandler) }
    }
    func renderPreviews() {
        guard let index = CommandLine.arguments.firstIndex(of: "--render-preview"), CommandLine.arguments.count > index + 1 else { return }
        let destination = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        model.expanded = true
        for tab in [IslandTab.overview, .focus, .prompt, .activity] {
            model.tab = tab
            let view = IslandView(model: model).frame(width: 620, height: 540)
            let renderer = ImageRenderer(content: view); renderer.scale = 2
            guard let image = renderer.nsImage, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) else { continue }
            try? png.write(to: destination.appendingPathComponent("\(tab.rawValue.lowercased()).png"))
        }
    }
}
@main enum TallyApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate(); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
