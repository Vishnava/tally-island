import Foundation
import TallyCore

let help = """
Tally Island · local activity bridge

  tally status --id build --title "Building" --state working [--detail "Tests"] [--progress 0.5] [--tokens 1200]
  tally remove ID
  tally list
  tally path

States: working, waiting, done, failed. Progress: 0…1. No shell commands are executed.
Point TALLY_DATA_DIR at a temporary directory to isolate development/testing data.
"""
func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else { print(help); return }
    switch command {
    case "--help", "-h", "help": print(help)
    case "path": print(ActivityStore.directory.path)
    case "list":
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601; enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(decoding: try enc.encode(ActivityStore.read()), as: UTF8.self))
    case "remove":
        guard args.count == 2 else { throw TallyError.invalid("Use: tally remove ID") }; try ActivityStore.remove(id: args[1])
    case "status":
        var values: [String: String] = [:]; var i = 1
        let known: Set<String> = ["--id", "--title", "--state", "--detail", "--progress", "--tokens"]
        while i < args.count {
            guard known.contains(args[i]), i + 1 < args.count, values[args[i]] == nil else { throw TallyError.invalid("Unknown, repeated, or incomplete option: \(args[i])") }
            values[args[i]] = args[i+1]; i += 2
        }
        guard let id = values["--id"], let title = values["--title"], let state = ActivityState(rawValue: values["--state"] ?? "working") else { throw TallyError.invalid("Provide --id, --title, and a valid --state.") }
        let progress = values["--progress"].flatMap(Double.init)
        let tokens = values["--tokens"].flatMap(Int.init)
        if values["--progress"] != nil && progress == nil { throw TallyError.invalid("Progress must be a number.") }
        if values["--tokens"] != nil && tokens == nil { throw TallyError.invalid("Tokens must be an integer.") }
        try ActivityStore.write(Activity(id: id, title: title, detail: values["--detail"] ?? "", state: state, progress: progress, tokens: tokens))
        print("Updated \(id).")
    default: throw TallyError.invalid("Unknown command: \(command). Use tally --help.")
    }
}
do { try run() } catch { FileHandle.standardError.write(Data("tally: \(error.localizedDescription)\n".utf8)); exit(1) }
