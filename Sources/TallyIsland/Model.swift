import SwiftUI
import AppKit
import TallyCore
import UniformTypeIdentifiers

struct Clip: Identifiable { let id = UUID(); let text: String; let date = Date() }
enum IslandTab: String, CaseIterable {
    case overview = "Overview", focus = "Focus", clipboard = "Clipboard", shelf = "Shelf", prompt = "Prompt", activity = "Activity", settings = "Settings"
    var symbol: String { switch self { case .overview: return "square.grid.2x2"; case .focus: return "timer"; case .clipboard: return "doc.on.clipboard"; case .shelf: return "tray"; case .prompt: return "text.alignleft"; case .activity: return "waveform.path"; case .settings: return "slider.horizontal.3" } }
}
@MainActor final class IslandModel: ObservableObject {
    @Published var clipSearch = ""
    @Published var editingPrompt = false
    @Published var dropTarget = false
    var collapseTask: DispatchWorkItem?
    @Published var tab: IslandTab = .overview
    @Published var expanded = false
    @Published var pinned = false
    @Published var now = Date()
    @Published var machine = MachineSnapshot()
    @Published var focus = FocusTimer()
    @Published var clips: [Clip] = []
    @Published var files: [URL] = []
    @Published var activities: [Activity] = []
    @Published var notice = ""
    @Published var script: String { didSet { if !demo { defaults.set(script, forKey: "script") }; resetPrompt() } }
    @Published var promptRunning = false
    @Published var promptIndex = 0
    @Published var wordsPerMinute: Double = 120
    @Published var clipboardEnabled: Bool { didSet { if !demo { defaults.set(clipboardEnabled, forKey: "clipboardEnabled") }; pasteboardCount = NSPasteboard.general.changeCount; if !clipboardEnabled { clips = [] } } }
    @Published var hoverEnabled: Bool { didSet { if !demo { defaults.set(hoverEnabled, forKey: "hoverEnabled") } } }
    @Published var accentName: String { didSet { if !demo { defaults.set(accentName, forKey: "accent") } } }
    @Published var completedSessions: Int { didSet { if !demo { defaults.set(completedSessions, forKey: "sessions") } } }
    var accent: Color { switch accentName { case "Mint": return Color(red: 0.50, green: 0.91, blue: 0.76); case "Ice": return Color(red: 0.52, green: 0.76, blue: 1); default: return Color(red: 0.96, green: 0.77, blue: 0.39) } }
    var resize: (() -> Void)?
    private let defaults: UserDefaults
    let demo: Bool
    private let monitor = SystemMonitor()
    private var ticker: Timer?
    private var tickCount = 0
    private var pasteboardCount = NSPasteboard.general.changeCount
    private var promptStarted: Date?
    private var promptStartIndex = 0
    private var noticeUntil = Date.distantPast
    var words: [String] { PromptWords.words(in: script) }
    init(demo: Bool = false) {
        self.demo = demo; defaults = demo ? UserDefaults(suiteName: "TallyIsland.Preview")! : .standard
        script = demo ? "Make space for what matters. One idea, one clear sentence, one focused moment at a time." : (defaults.string(forKey: "script") ?? "Your next great idea starts here. Paste your talking points, set a comfortable pace, and keep your eyes near the camera.")
        clipboardEnabled = !demo && defaults.bool(forKey: "clipboardEnabled")
        hoverEnabled = defaults.object(forKey: "hoverEnabled") == nil ? true : defaults.bool(forKey: "hoverEnabled")
        accentName = defaults.string(forKey: "accent") ?? "Amber"
        completedSessions = demo ? 3 : defaults.integer(forKey: "sessions")
        if demo {
            now = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 9, minute: 41))!
            machine = MachineSnapshot(cpu: 18, memoryGB: 8.4, totalMemoryGB: 24, battery: 86, charging: false, diskFreeGB: 248, cpuHistory: [8,12,10,14,9,22,18,28,15,12,16,18,17,24,19,12,18])
            activities = [Activity(id: "sample", title: "Website build", detail: "24 tests passed", state: .done, tokens: 12400)]
        } else {
            if let data = defaults.data(forKey: "focus"), let saved = try? JSONDecoder().decode(FocusTimer.self, from: data) { focus = saved }
            let bookmarks = defaults.array(forKey: "shelf") as? [Data] ?? []
            files = bookmarks.compactMap { data in var stale = false; return try? URL(resolvingBookmarkData: data, options: [.withoutUI, .withoutMounting], relativeTo: nil, bookmarkDataIsStale: &stale) }
            machine = monitor.sample()
            ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in Task { @MainActor in self?.tick() } }
            ticker?.tolerance = 0.2
        }
    }
    func tick() {
        now = Date(); tickCount += 1
        if focus.tick(at: now) { completedSessions += 1; saveFocus(); showNotice("Focus complete. Take a breath."); NSSound(named: "Glass")?.play(); expanded = true; resize?() }
        if tickCount % 2 == 0 { machine = monitor.sample(); activities = ActivityStore.read() }
        if clipboardEnabled { readClipboard() }
        if promptRunning, let started = promptStarted {
            let count = words.count
            promptIndex = min(max(0, count - 1), promptStartIndex + PromptWords.index(elapsed: now.timeIntervalSince(started), wordsPerMinute: wordsPerMinute, count: count))
            if count == 0 || promptIndex >= count - 1 { promptRunning = false; promptStarted = nil }
        }
        if now > noticeUntil { notice = "" }
    }
    func toggle() { expanded.toggle(); resize?() }
    func open(_ tab: IslandTab) { self.tab = tab; expanded = true; resize?() }
    func showNotice(_ text: String) { notice = text; noticeUntil = Date().addingTimeInterval(4) }
    func startFocus(_ minutes: Int) { focus.start(seconds: Double(minutes * 60), at: Date()); saveFocus() }
    func toggleFocus() {
        if focus.isRunning { focus.pause(at: Date()) } else if focus.completed { focus.start(seconds: focus.duration, at: Date()) } else { focus.resume(at: Date()) }
        saveFocus()
    }
    func resetFocus() { focus.reset(); saveFocus() }
    private func saveFocus() { if !demo, let data = try? JSONEncoder().encode(focus) { defaults.set(data, forKey: "focus") } }
    private func readClipboard() {
        let board = NSPasteboard.general
        guard board.changeCount != pasteboardCount else { return }; pasteboardCount = board.changeCount
        guard let text = board.string(forType: .string), ClipboardGuard.accepts(text, types: (board.types ?? []).map(\.rawValue)) else { return }
        clips.removeAll { $0.text == text }; clips.insert(Clip(text: text), at: 0); clips = Array(clips.prefix(30))
    }
    func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string); pasteboardCount = NSPasteboard.general.changeCount; showNotice("Copied") }
    func addFiles(_ urls: [URL]) {
        for url in urls where url.isFileURL && FileManager.default.fileExists(atPath: url.path) {
            let standard = url.standardizedFileURL
            if !files.contains(standard), files.count < 20 { files.append(standard) }
        }
        saveShelf()
    }
    func chooseFiles() {
        let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.canChooseDirectories = true; panel.prompt = "Add to shelf"
        panel.begin { [weak self] response in if response == .OK { Task { @MainActor in self?.addFiles(panel.urls) } } }
    }
    func removeFile(_ url: URL) { files.removeAll { $0 == url }; saveShelf() }
    private func saveShelf() { if !demo { defaults.set(files.compactMap { try? $0.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) }, forKey: "shelf") } }
    func openFile(_ url: URL) { if !NSWorkspace.shared.open(url) { showNotice("File unavailable. It may have moved or been deleted.") } }
    func resetPrompt() { promptIndex = 0; promptRunning = false; promptStarted = nil }
    func togglePrompt() {
        if promptRunning { promptRunning = false; promptStarted = nil }
        else if !words.isEmpty { if promptIndex >= words.count - 1 { promptIndex = 0 }; promptStartIndex = promptIndex; promptStarted = Date(); promptRunning = true }
    }
    func stepPrompt(_ amount: Int) { promptRunning = false; promptStarted = nil; promptIndex = min(max(0, words.count - 1), max(0, promptIndex + amount)) }
    func dismissActivity(_ item: Activity) {
        do { try ActivityStore.remove(id: item.id); activities.removeAll { $0.id == item.id } } catch { showNotice(error.localizedDescription) }
    }
    func openBridgeFolder() {
        do { try FileManager.default.createDirectory(at: ActivityStore.directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]); NSWorkspace.shared.open(ActivityStore.directory) } catch { showNotice(error.localizedDescription) }
    }
}
