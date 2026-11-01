import SwiftUI
import AppKit
import TallyCore
import UniformTypeIdentifiers

private let soft = Color.white.opacity(0.48)
private let panelColor = Color(red: 0.065, green: 0.068, blue: 0.075)
struct IslandView: View {
    @ObservedObject var model: IslandModel
    var topHeight: CGFloat = 36
    var notchWidth: CGFloat = 190
    var body: some View {
        VStack(spacing: 0) {
            topBar
            if model.expanded {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 6) {
                        ForEach(IslandTab.allCases, id: \.self) { tab in
                            Button { model.tab = tab } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: tab.symbol).font(.system(size: 15, weight: .medium))
                                    Text(tab.rawValue).font(.system(size: 9, weight: .medium))
                                }
                                .foregroundStyle(model.tab == tab ? model.accent : soft)
                                .frame(maxWidth: .infinity).frame(height: 48)
                                .background(model.tab == tab ? model.accent.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain).accessibilityLabel(tab.rawValue)
                        }
                    }
                    .padding(5).background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
                    Group {
                        switch model.tab {
                        case .overview: overview
                        case .focus: focus
                        case .clipboard: clipboard
                        case .shelf: shelf
                        case .prompt: prompt
                        case .activity: activity
                        case .settings: settings
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    footer
                }.padding(.horizontal, 24).padding(.top, 14).padding(.bottom, 17)
            }
        }
        .background(panelColor)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: model.expanded ? 16 : 10, bottomLeadingRadius: model.expanded ? 28 : 15, bottomTrailingRadius: model.expanded ? 28 : 15, topTrailingRadius: model.expanded ? 16 : 10))
        .overlay(alignment: .bottom) { if !model.notice.isEmpty { Text(model.notice).font(.system(size: 12, weight: .medium)).padding(.horizontal, 18).padding(.vertical, 10).background(model.accent).foregroundStyle(.black).clipShape(Capsule()).padding(.bottom, 45).allowsHitTesting(false) } }
        .foregroundStyle(.white).preferredColorScheme(.dark)
        .onHover { inside in
            model.collapseTask?.cancel()
            if inside && model.hoverEnabled && !model.expanded { model.expanded = true; model.resize?() }
            else if !inside && !model.pinned && model.expanded && model.tab == .overview {
                let task = DispatchWorkItem { if !model.pinned { model.expanded = false; model.resize?() } }
                model.collapseTask = task; DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: task)
            }
        }
        .onExitCommand { model.expanded = false; model.resize?() }
    }
    private var topBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "circle.dotted").font(.system(size: 17, weight: .bold)).foregroundStyle(model.accent)
                if model.expanded { Text("TALLY").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2) }
                else { DotNumber(text: model.focus.isRunning ? NumberFormat.clock(model.focus.remaining(at: model.now)) : time, size: 2.2, color: model.accent) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: notchWidth)
            HStack(spacing: 8) {
                if model.expanded {
                    Button { model.pinned.toggle() } label: { Image(systemName: model.pinned ? "pin.fill" : "pin").foregroundStyle(model.pinned ? model.accent : soft) }.buttonStyle(.plain).help("Keep island open").accessibilityLabel("Keep island open")
                    Button { model.expanded = false; model.resize?() } label: { Image(systemName: "chevron.up").foregroundStyle(soft) }.buttonStyle(.plain).help("Collapse island").accessibilityLabel("Collapse island")
                } else {
                    Circle().fill(model.activities.contains(where: { $0.state == .waiting }) ? Color.orange : model.accent).frame(width: 5, height: 5)
                    DotNumber(text: model.machine.battery.map { "\($0)%" } ?? "--", size: 2.2)
                }
            }.frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, model.expanded ? 26 : 14).frame(height: topHeight)
        .background(Color.black)
        .contentShape(Rectangle()).onTapGesture { if !model.expanded { model.toggle() } }
    }
    private var time: String { model.now.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) }
    private func eyebrow(_ text: String) -> some View { Text(text.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.6).foregroundStyle(soft) }
    private func title(_ text: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(text).font(.system(size: 22, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75); Text(subtitle).font(.system(size: 11)).foregroundStyle(soft).fixedSize(horizontal: false, vertical: true) }
    }
    private func action(_ label: String, symbol: String, primary: Bool = false, run: @escaping () -> Void) -> some View {
        Button(action: run) { Label(label, systemImage: symbol).font(.system(size: 11, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 10).background(primary ? model.accent : Color.white.opacity(0.07), in: Capsule()).foregroundStyle(primary ? Color.black : .white) }.buttonStyle(.plain)
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 12) {
                    eyebrow(model.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    DotNumber(text: time, size: 7.8)
                    Text("A little space. A clearer day.").font(.system(size: 12)).foregroundStyle(soft)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 12) {
                    HStack(spacing: 5) { Circle().fill(model.accent).frame(width: 5, height: 5); Text(model.demo ? "PREVIEW DATA" : "LIVE ON YOUR MAC").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(0.8).foregroundStyle(soft) }
                    action(model.focus.isRunning ? "Back to focus" : "Start a focus", symbol: "arrow.up.right", primary: true) { model.open(.focus) }
                }
            }.padding(.top, 6)
            HStack(spacing: 10) {
                metric("CPU", value: model.machine.cpu.map { String(format: "%.0f", $0) } ?? "--", unit: "%", detail: "processor load", color: model.accent, progress: (model.machine.cpu ?? 0) / 100)
                metric("MEMORY", value: String(format: "%.1f", model.machine.memoryGB), unit: "GB", detail: "of \(Int(model.machine.totalMemoryGB)) GB physical", color: Color(red: 0.61, green: 0.72, blue: 1), progress: model.machine.memoryGB / max(1, model.machine.totalMemoryGB))
                metric("BATTERY", value: model.machine.battery.map(String.init) ?? "--", unit: "%", detail: model.machine.battery == nil ? "no internal battery" : (model.machine.charging ? "charging" : model.machine.externalPower ? "external power" : "on battery"), color: Color(red: 0.50, green: 0.91, blue: 0.76), progress: Double(model.machine.battery ?? 0) / 100)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack { eyebrow("Processor · last 80s"); Spacer(); Text("2s samples").font(.system(size: 8)).foregroundStyle(soft) }
                    Sparkline(values: model.machine.cpuHistory, color: model.accent).frame(height: 29)
                }.padding(14).background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
                Button { model.open(.activity) } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        eyebrow("Activity")
                        HStack { Circle().fill(model.accent).frame(width: 5, height: 5); Text(model.activities.first?.title ?? "Nothing needs you").font(.system(size: 11, weight: .medium)).lineLimit(1); Spacer(); Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(soft) }
                    }.padding(14).frame(width: 215, height: 70).background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain)
            }
        }
    }
    private func metric(_ label: String, value: String, unit: String, detail: String, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            eyebrow(label)
            HStack(alignment: .bottom, spacing: 7) { DotNumber(text: value, size: 4.9, color: color); Text(unit).font(.system(size: 10, weight: .medium)).foregroundStyle(soft).padding(.bottom, 2) }
            GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.07)); Capsule().fill(color.opacity(0.8)).frame(width: geo.size.width * min(1, max(0, progress))) } }.frame(height: 3)
            Text(detail).font(.system(size: 9)).foregroundStyle(soft).lineLimit(1)
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
    }
    private func progressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule().fill(model.accent).frame(width: geo.size.width * min(1, max(0, value)))
            }
        }.frame(height: 4).accessibilityLabel("Progress").accessibilityValue("\(Int(value * 100)) percent")
    }
    private var focus: some View {
        VStack(spacing: 19) {
            HStack { title(model.focus.completed ? "Nicely done." : "One thing at a time.", subtitle: "A quiet timer for your next meaningful stretch."); Spacer(); VStack(spacing: 6) { DotNumber(text: String(model.completedSessions), size: 3.5, color: model.accent); eyebrow("completed") } }
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(model.accent.opacity(0.045))
                VStack(spacing: 16) {
                    eyebrow(model.focus.completed ? "Take a break" : model.focus.isRunning ? "Stay with it" : "Ready when you are")
                    DotNumber(text: NumberFormat.clock(model.focus.remaining(at: model.now)), size: 10, color: model.accent)
                    progressBar(model.focus.progress(at: model.now)).frame(width: 270)
                }
            }.frame(height: 155)
            HStack(spacing: 8) { ForEach([5, 15, 25, 50], id: \.self) { minutes in Button { model.startFocus(minutes) } label: { Text("\(minutes) min").font(.system(size: 11, weight: .medium)).padding(.horizontal, 15).padding(.vertical, 8).background(Color.white.opacity(0.06), in: Capsule()) }.buttonStyle(.plain) }; Spacer(); action(model.focus.isRunning ? "Pause" : "Start", symbol: model.focus.isRunning ? "pause.fill" : "play.fill", primary: true) { model.toggleFocus() }; Button { model.resetFocus() } label: { Image(systemName: "arrow.counterclockwise") }.buttonStyle(.plain).help("Reset timer").accessibilityLabel("Reset timer") }
            Text("Keeps time through sleep. Your session survives a restart.").font(.system(size: 10)).foregroundStyle(soft)
        }
    }
    private var clipboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { title("A second chance to paste.", subtitle: "Up to 30 text clips. In memory, until you quit."); Spacer(); Toggle("Capture", isOn: $model.clipboardEnabled).toggleStyle(.switch).font(.system(size: 10)) }
            if !model.clipboardEnabled {
                empty("doc.on.clipboard", "Your clipboard stays yours.", "Enable Capture to collect new text copies. Known secret patterns and password-manager markers are skipped; filtering cannot catch every secret.")
            } else {
                HStack { TextField("Search clips", text: $model.clipSearch).textFieldStyle(.roundedBorder); Button("Clear") { model.clips = [] }.buttonStyle(.plain).foregroundStyle(model.accent) }
                if model.clips.isEmpty { empty("doc.on.doc", "Copy something to begin.", "Only new copies are captured. Nothing is written to disk.") }
                else { ScrollView { LazyVStack(spacing: 7) { ForEach(model.clips.filter { model.clipSearch.isEmpty || $0.text.localizedCaseInsensitiveContains(model.clipSearch) }) { clip in HStack(alignment: .top) { Text(clip.text).font(.system(size: 11)).lineLimit(3).frame(maxWidth: .infinity, alignment: .leading); Button { model.copy(clip.text) } label: { Image(systemName: "doc.on.doc") }.buttonStyle(.plain).foregroundStyle(model.accent).accessibilityLabel("Copy clip") }.padding(12).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 11)) } } } }
            }
        }
    }
    private var shelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { title("Hold that thought. Or file.", subtitle: "Drop up to 20 files here. Originals stay exactly where they are."); Spacer(); action("Add", symbol: "plus", primary: true) { model.chooseFiles() } }
            if model.files.isEmpty { empty("tray.and.arrow.down", "A landing place for files.", "Drag files onto this panel, or choose Add. Open, reveal, or drag them back out whenever you need.") }
            else { ScrollView { LazyVStack(spacing: 7) { ForEach(model.files, id: \.self) { url in HStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().frame(width: 26, height: 26)
                Button { model.openFile(url) } label: { VStack(alignment: .leading, spacing: 3) { Text(url.lastPathComponent).font(.system(size: 11, weight: .medium)).lineLimit(1); Text(url.deletingLastPathComponent().lastPathComponent).font(.system(size: 9)).foregroundStyle(soft) }.frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.plain)
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { Image(systemName: "folder") }.buttonStyle(.plain).accessibilityLabel("Reveal in Finder")
                Button { model.removeFile(url) } label: { Image(systemName: "xmark") }.buttonStyle(.plain).foregroundStyle(soft).accessibilityLabel("Remove from shelf")
            }.padding(11).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 11)).onDrag { NSItemProvider(contentsOf: url) ?? NSItemProvider() } } } } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(model.dropTarget ? model.accent.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $model.dropTarget) { providers in
            for provider in providers { _ = provider.loadObject(ofClass: URL.self) { url, _ in if let url { Task { @MainActor in model.addFiles([url]) } } } }; return !providers.isEmpty
        }
    }
    private var prompt: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { title("Your words. Near the camera.", subtitle: "A paced teleprompter for calls, demos, and recordings."); Spacer(); Button(model.editingPrompt ? "Done" : "Edit script") { model.editingPrompt.toggle(); model.promptRunning = false }.buttonStyle(.plain).foregroundStyle(model.accent) }
            if model.editingPrompt { TextEditor(text: $model.script).font(.system(size: 16)).scrollContentBackground(.hidden).padding(12).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16)) }
            else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { eyebrow("\(model.words.isEmpty ? 0 : model.promptIndex + 1) / \(model.words.count) words"); Spacer(); eyebrow(model.promptRunning ? "Reading" : "Paused") }
                    Text(currentPhrase).font(.system(size: 26, weight: .medium)).foregroundStyle(model.accent).lineSpacing(6).lineLimit(3).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    Text(nextPhrase).font(.system(size: 14)).foregroundStyle(soft).lineLimit(2)
                }.padding(20).frame(height: 170).background(model.accent.opacity(0.045), in: RoundedRectangle(cornerRadius: 18))
            }
            HStack(spacing: 12) {
                action(model.promptRunning ? "Pause" : "Read", symbol: model.promptRunning ? "pause.fill" : "play.fill", primary: true) { model.togglePrompt() }.disabled(model.words.isEmpty)
                Button { model.stepPrompt(-8) } label: { Image(systemName: "backward.end") }.buttonStyle(.plain).accessibilityLabel("Previous words")
                Button { model.stepPrompt(8) } label: { Image(systemName: "forward.end") }.buttonStyle(.plain).accessibilityLabel("Next words")
                Button { model.resetPrompt() } label: { Image(systemName: "arrow.counterclockwise") }.buttonStyle(.plain).accessibilityLabel("Restart script")
                Spacer(); Slider(value: $model.wordsPerMinute, in: 60...240, step: 10).frame(width: 95).disabled(model.promptRunning).accessibilityLabel("Words per minute")
                Text("\(Int(model.wordsPerMinute)) wpm").font(.system(size: 10, design: .monospaced)).foregroundStyle(soft)
            }
            Text("Paced playback · no microphone or speech recording").font(.system(size: 10)).foregroundStyle(soft)
        }
    }
    private var currentPhrase: String { let words = model.words; guard !words.isEmpty else { return "Add a script to begin." }; let start = (model.promptIndex / 8) * 8; return words[start..<min(start + 8, words.count)].joined(separator: " ") }
    private var nextPhrase: String { let words = model.words; let start = ((model.promptIndex / 8) + 1) * 8; guard start < words.count else { return "End of script" }; return words[start..<min(start + 16, words.count)].joined(separator: " ") }
    private var activity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { title("Less checking. More doing.", subtitle: "Builds and agents report here through the local tally command."); Spacer(); DotNumber(text: String(model.activities.count), size: 4, color: model.accent) }
            if model.activities.isEmpty {
                empty("waveform.path", "Ready for your workflow.", "Send working, waiting, done, or failed states from any tool. Token counts appear only when a tool supplies them.")
                Text("tally status --id build --title 'Building' --state working").font(.system(size: 10, design: .monospaced)).textSelection(.enabled).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            } else { ScrollView { LazyVStack(spacing: 8) { ForEach(model.activities) { item in VStack(alignment: .leading, spacing: 9) {
                HStack { Circle().fill(item.state == .failed ? Color.red : item.state == .waiting ? Color.orange : model.accent).frame(width: 6, height: 6); Text(item.title).font(.system(size: 12, weight: .semibold)); Spacer(); Text(item.state.rawValue.uppercased()).font(.system(size: 8, design: .monospaced)).foregroundStyle(soft); Button { model.dismissActivity(item) } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel("Dismiss activity") }
                if !item.detail.isEmpty { Text(item.detail).font(.system(size: 11)).foregroundStyle(soft).lineLimit(2) }
                if let progress = item.progress { progressBar(progress) }
                if let tokens = item.tokens { HStack(alignment: .bottom) { DotNumber(text: NumberFormat.compact(tokens), size: 2.8, color: model.accent); Text("reported tokens").font(.system(size: 9)).foregroundStyle(soft) } }
            }.padding(14).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12)) } } } }
            HStack { Button("Open activity folder") { model.openBridgeFolder() }; Spacer(); Button("Integration guide") { if let url = Bundle.main.url(forResource: "INTEGRATIONS", withExtension: "md") { NSWorkspace.shared.open(url) } } }.buttonStyle(.plain).font(.system(size: 10)).foregroundStyle(model.accent)
        }
    }
    private var settings: some View {
        VStack(alignment: .leading, spacing: 17) {
            title("Make a little space your own.", subtitle: "Tally Island · 0.1.0 preview · native, local, and open source")
            HStack { Text("Accent"); Spacer(); Picker("Accent", selection: $model.accentName) { ForEach(["Amber", "Mint", "Ice"], id: \.self) { Text($0) } }.pickerStyle(.segmented).labelsHidden().frame(width: 245) }
            Divider().overlay(Color.white.opacity(0.05))
            Toggle("Expand on hover", isOn: $model.hoverEnabled).toggleStyle(.switch)
            Toggle("Capture clipboard text", isOn: $model.clipboardEnabled).toggleStyle(.switch)
            Text("Clipboard capture is optional and memory-only. Script, shelf references, timer, and preferences stay on this Mac. No analytics or account required.").font(.system(size: 11)).foregroundStyle(soft).lineSpacing(4)
            HStack { Label("⌃⌥T opens the island", systemImage: "keyboard"); Spacer(); Text("Esc collapses") }.font(.system(size: 10)).foregroundStyle(soft)
            HStack { action("Quit Tally Island", symbol: "power") { NSApp.terminate(nil) }; Spacer(); Text("Made for moments that count.").font(.system(size: 10)).foregroundStyle(soft) }
        }.font(.system(size: 12))
    }
    private func empty(_ symbol: String, _ heading: String, _ detail: String) -> some View {
        VStack(spacing: 12) { Image(systemName: symbol).font(.system(size: 28, weight: .light)).foregroundStyle(model.accent); Text(heading).font(.system(size: 15, weight: .medium)); Text(detail).font(.system(size: 11)).foregroundStyle(soft).multilineTextAlignment(.center).lineSpacing(4).frame(maxWidth: 360) }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(15)
    }
    private var footer: some View {
        HStack(spacing: 6) { Image(systemName: "lock").font(.system(size: 8)); Text("LOCAL BY DESIGN").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1); Spacer(); Text(model.demo ? "DESIGN PREVIEW" : "\(Int(model.machine.diskFreeGB)) GB free").font(.system(size: 9, design: .monospaced)); Text("·"); Text("⌃⌥T").font(.system(size: 10, design: .monospaced)) }.foregroundStyle(Color.white.opacity(0.30))
    }
}
