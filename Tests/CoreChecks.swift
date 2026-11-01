import Foundation

@main enum CoreChecks {
    static var passed = 0
    static func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        guard condition() else { fputs("FAIL: \(label)\n", stderr); exit(1) }
        passed += 1; print("PASS: \(label)")
    }
    static func rejects(_ label: String, _ block: () throws -> Void) { do { try block(); check(false, label) } catch { check(true, label) } }
    static func main() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        var timer = FocusTimer()
        timer.start(seconds: 1500, at: start)
        check(timer.remaining(at: start.addingTimeInterval(60)) == 1440, "timer follows wall time")
        timer.pause(at: start.addingTimeInterval(60))
        check(timer.remaining(at: start.addingTimeInterval(500)) == 1440, "pause holds remaining time")
        timer.resume(at: start.addingTimeInterval(500))
        check(timer.remaining(at: start.addingTimeInterval(560)) == 1380, "resume preserves elapsed work")
        let data = try JSONEncoder().encode(timer)
        var restored = try JSONDecoder().decode(FocusTimer.self, from: data)
        check(restored == timer, "timer persistence round-trip")
        check(restored.tick(at: start.addingTimeInterval(10000)), "completion after sleep or relaunch")
        check(!restored.tick(at: start.addingTimeInterval(10001)), "completion fires only once")
        check(restored.completed && !restored.isRunning && restored.remaining(at: start) == 0, "completion final state")
        restored.reset(); check(!restored.completed && restored.remaining(at: start) == 1500, "reset restores duration")
        check(NumberFormat.clock(59.1) == "01:00", "display rounds partial seconds up")
        check(NumberFormat.clock(-1) == "00:00", "display never shows negative time")
        check(NumberFormat.compact(12400) == "12K", "compact token formatting")
        check(ClipboardGuard.accepts("A useful note"), "ordinary text accepted")
        check(!ClipboardGuard.accepts("   \n"), "blank clipboard ignored")
        check(!ClipboardGuard.accepts(String(repeating: "x", count: 16385)), "large clipboard rejected")
        check(!ClipboardGuard.accepts("a secret", types: ["org.nspasteboard.ConcealedType"]), "password-manager concealed marker")
        check(!ClipboardGuard.accepts("sk-proj-1234567890abcdefghijklmnop"), "API key pattern rejected")
        check(!ClipboardGuard.accepts("-----BEGIN RSA PRIVATE KEY-----"), "private key rejected")
        check(!ClipboardGuard.accepts("password=secret123"), "named secret rejected")
        check(!ClipboardGuard.accepts("eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature"), "JWT rejected")
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("TallyChecks-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        let item = Activity(id: "build_1", title: "Build", state: .working, progress: 0.5, tokens: 1200, updatedAt: start)
        try ActivityStore.write(item, to: folder)
        check(ActivityStore.read(from: folder, at: start) == [item], "activity round-trip")
        rejects("path traversal rejected") { try ActivityStore.write(Activity(id: "../escape", title: "Bad"), to: folder) }
        rejects("nonfinite progress rejected") { try Activity(id: "bad", title: "Bad", progress: .nan).validate() }
        rejects("out of range progress rejected") { try Activity(id: "bad", title: "Bad", progress: 1.1).validate() }
        rejects("negative tokens rejected") { try Activity(id: "bad", title: "Bad", tokens: -1).validate() }
        rejects("empty title rejected") { try Activity(id: "bad", title: " ").validate() }
        try Data("{broken".utf8).write(to: folder.appendingPathComponent("broken.json"))
        try Data(repeating: 65, count: 9000).write(to: folder.appendingPathComponent("large.json"))
        check(ActivityStore.read(from: folder, at: start).count == 1, "malformed and oversized files ignored")
        try ActivityStore.write(Activity(id: "wait", title: "Approval", state: .waiting, updatedAt: start), to: folder)
        check(ActivityStore.read(from: folder, at: start).first?.id == "wait", "waiting gets priority")
        check(ActivityStore.read(from: folder, at: start.addingTimeInterval(86401)).isEmpty, "stale activities expire")
        check(!item.isVisible(at: start.addingTimeInterval(-120)), "far-future activity rejected")
        let external = folder.appendingPathComponent("external")
        try JSONEncoder().encode(item).write(to: external)
        try FileManager.default.createSymbolicLink(at: folder.appendingPathComponent("link.json"), withDestinationURL: external)
        check(ActivityStore.read(from: folder, at: start).count == 2, "symlink activity ignored")
        try ActivityStore.remove(id: "build_1", from: folder)
        check(ActivityStore.read(from: folder, at: start).map(\.id) == ["wait"], "remove only requested activity")
        rejects("remove path traversal rejected") { try ActivityStore.remove(id: "../../oops", from: folder) }
        check(PromptWords.words(in: " One\n two\tthree ") == ["One", "two", "three"], "prompt handles whitespace")
        check(PromptWords.index(elapsed: 2, wordsPerMinute: 120, count: 100) == 4, "prompt pace")
        check(PromptWords.index(elapsed: 100, wordsPerMinute: 120, count: 3) == 2, "prompt clamps at end")
        check(PromptWords.index(elapsed: 10, wordsPerMinute: 120, count: 0) == 0, "empty prompt safe")
        print("\(passed) checks passed.")
    }
}
