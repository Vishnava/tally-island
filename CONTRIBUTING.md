# Contributing

Build with `./scripts/build.sh`, run `./scripts/test.sh`, then package with `./scripts/package.sh`.

Keep platform-independent behavior in `Sources/TallyCore`, presentation in `Sources/TallyIsland`, and the CLI in `Sources/tally`. New state transitions or input parsers should include meaningful behavioral cases in `Tests/CoreChecks.swift`.

Before a pull request, check every affected tab at the fixed panel size, keyboard access, empty and unavailable states, persistence, and whether a new background task can be stopped. Do not add hidden telemetry, automatic credential discovery, unsolicited permissions, or unlicensed code/assets. Credit inspirations and preserve upstream notices if a future change incorporates code.

Report bugs with OS version, architecture, display/notch setup, steps and observed behavior. Remove personal paths, script text, clipboard content and activity data before sharing screenshots or logs.
