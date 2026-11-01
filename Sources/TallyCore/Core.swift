import Foundation

public enum NumberFormat {
    public static func clock(_ seconds: TimeInterval) -> String {
        let n = max(0, Int(ceil(seconds)))
        return String(format: "%02d:%02d", n / 60, n % 60)
    }
    public static func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 10_000 { return String(format: "%.0fK", Double(n) / 1000) }
        if n >= 1000 { return String(format: "%.1fK", Double(n) / 1000) }
        return String(max(0, n))
    }
}

public struct FocusTimer: Codable, Equatable {
    public var duration: TimeInterval = 1500
    public var deadline: Date?
    public var pausedRemaining: TimeInterval = 1500
    public var completed = false
    public init() {}
    public var isRunning: Bool { deadline != nil }
    public func remaining(at now: Date) -> TimeInterval { max(0, deadline?.timeIntervalSince(now) ?? pausedRemaining) }
    public func progress(at now: Date) -> Double { min(1, max(0, 1 - remaining(at: now) / max(1, duration))) }
    public mutating func start(seconds: TimeInterval, at now: Date) {
        duration = min(7200, max(1, seconds)); pausedRemaining = duration
        deadline = now.addingTimeInterval(duration); completed = false
    }
    public mutating func pause(at now: Date) { pausedRemaining = remaining(at: now); deadline = nil }
    public mutating func resume(at now: Date) {
        guard pausedRemaining > 0, !completed else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
    }
    @discardableResult public mutating func tick(at now: Date) -> Bool {
        guard deadline != nil, remaining(at: now) <= 0 else { return false }
        deadline = nil; pausedRemaining = 0; completed = true; return true
    }
    public mutating func reset() { deadline = nil; pausedRemaining = duration; completed = false }
}

public enum ActivityState: String, Codable, CaseIterable { case working, waiting, done, failed }
public struct Activity: Codable, Equatable, Identifiable {
    public let id: String
    public var title: String
    public var detail: String
    public var state: ActivityState
    public var progress: Double?
    public var tokens: Int?
    public var updatedAt: Date
    public init(id: String, title: String, detail: String = "", state: ActivityState = .working, progress: Double? = nil, tokens: Int? = nil, updatedAt: Date = Date()) {
        self.id = id; self.title = title; self.detail = detail; self.state = state
        self.progress = progress; self.tokens = tokens; self.updatedAt = updatedAt
    }
    public func validate() throws {
        guard !id.isEmpty, id.count <= 64, id.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_").contains($0) }) else { throw TallyError.invalid("ID must contain 1–64 letters, numbers, hyphens or underscores.") }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, title.count <= 120, detail.count <= 500 else { throw TallyError.invalid("Title must be 1–120 characters; detail at most 500.") }
        if let progress, !progress.isFinite || !(0...1).contains(progress) { throw TallyError.invalid("Progress must be between 0 and 1.") }
        if let tokens, tokens < 0 { throw TallyError.invalid("Tokens cannot be negative.") }
    }
    public func isVisible(at now: Date) -> Bool {
        let age = now.timeIntervalSince(updatedAt)
        return age >= -60 && age < ((state == .done || state == .failed) ? 3600 : 86400)
    }
    public var priority: Int { switch state { case .waiting: return 3; case .failed: return 2; case .working: return 1; case .done: return 0 } }
}
public enum TallyError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { switch self { case .invalid(let reason): return reason } }
}

public enum ActivityStore {
    public static var directory: URL {
        if let path = ProcessInfo.processInfo.environment["TALLY_DATA_DIR"] { return URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent("Activities", isDirectory: true) }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/TallyIsland/Activities", isDirectory: true)
    }
    public static func write(_ activity: Activity, to folder: URL = directory) throws {
        try activity.validate()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = folder.appendingPathComponent(activity.id + ".json")
        // Atomic replacement avoids partially read files and replaces, rather than follows, a file symlink.
        try encoder.encode(activity).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    public static func read(from folder: URL = directory, at now: Date = Date()) -> [Activity] {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let urls = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey, .isSymbolicLinkKey, .contentModificationDateKey])) ?? []
        return urls.filter { $0.pathExtension == "json" }.sorted {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) > ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }.prefix(100).compactMap { url -> Activity? in
            guard let info = try? url.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]), info.isSymbolicLink != true,
                  (info.fileSize ?? Int.max) <= 8192, let data = try? Data(contentsOf: url), let item = try? decoder.decode(Activity.self, from: data),
                  (try? item.validate()) != nil, item.id + ".json" == url.lastPathComponent, item.isVisible(at: now) else { return nil }
            return item
        }.sorted { $0.priority == $1.priority ? $0.updatedAt > $1.updatedAt : $0.priority > $1.priority }
    }
    public static func remove(id: String, from folder: URL = directory) throws {
        try Activity(id: id, title: "Remove").validate()
        let url = folder.appendingPathComponent(id + ".json")
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}

public enum ClipboardGuard {
    public static func accepts(_ text: String, types: [String] = []) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.utf8.count <= 16_384 else { return false }
        let privateTypes = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType", "org.nspasteboard.AutoGeneratedType", "com.agilebits.onepassword"]
        guard !types.contains(where: { t in privateTypes.contains(where: { t.hasPrefix($0) }) }) else { return false }
        let patterns = ["-----BEGIN .*PRIVATE KEY-----", "(?i)\\b(?:sk-(?:proj-)?|gh[pousr]_|github_pat_|xox[baprs]-)[A-Za-z0-9_-]{12,}", "\\bAKIA[A-Z0-9]{16}\\b", "(?i)(?:password|secret|api[_-]?key|authorization)\\s*[:=]\\s*\\S+", "\\beyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+"]
        return !patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }
}

public enum PromptWords {
    public static func words(in text: String) -> [String] { text.split(whereSeparator: \.isWhitespace).map(String.init) }
    public static func index(elapsed: TimeInterval, wordsPerMinute: Double, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(count - 1, max(0, Int(max(0, elapsed) * min(300, max(30, wordsPerMinute)) / 60)))
    }
}
