# Validation record — 0.1.0 preview

Local checks performed 2026-11-01 on an Apple silicon Mac running macOS 27.0.1 with Apple Swift 6.4 Command Line Tools.

## Passed

- Optimized native application and CLI compilation using `scripts/build.sh`, targeting macOS 14.
- 36 core behavioral checks: timer pause/resume/relaunch/sleep and single completion; numeric formatting; clipboard marker/size/secret filtering; activity round-trip, validation, expiry, ordering, symlink rejection and scoped removal; teleprompter pace and boundaries.
- CLI integration: create/list/remove in an isolated temporary data directory; invalid numeric input and path traversal return failure.
- Actual SwiftUI screen rendering reviewed at 620 × 540 points: Overview, Focus, Prompt, Activity. Documentation images use explicitly labeled sample data, not measured user metrics.
- App bundle creation, icon generation, ad-hoc code signing and strict signature verification.
- The packaged application launched locally in a centered preview panel.

## Limits

- Native interaction automation was blocked by pending macOS Accessibility/Screen Recording permissions. Clicking, drag/drop, clipboard collection, global shortcut and multi-display interaction have not yet been validated end-to-end through UI automation.
- No claim of runtime testing on macOS 14–26, Intel hardware, multiple displays, lock screen, VoiceOver or reduced-motion configurations.
- No long-duration CPU/energy/memory profiling. A two-second sample interval is a design choice, not a battery-life benchmark.
- No Apple Developer ID signing or notarization. The packaged binary is ad-hoc signed.
- GitHub Actions configuration is included. Its execution status must be checked on GitHub; local success does not imply a passing remote run.

## Manual acceptance checklist

1. Quit another island overlay; open Tally. Check notch alignment, collapsed click target and floating fallback.
2. Expand via hover/menu/Control–Option–T; pin/unpin; collapse with Esc. Move between displays/spaces.
3. Start a timer, pause/resume, quit/relaunch, and sleep/wake. Confirm one completion event.
4. Enable clipboard capture; copy ordinary test text, a secret-pattern fixture, and password-manager text. Search/copy/clear; disable and verify clearing.
5. Add/drop a temporary file, open/reveal/drag it out; remove the reference and verify the original file still exists. Test a moved or deleted file.
6. Edit a script, adjust pace, read/pause, step backward/forward, and restart. Test empty and very long scripts.
7. Submit a live `tally status`, update it, dismiss it; submit malformed/expired input and confirm it is not displayed.
8. Check all three accents, keyboard focus and VoiceOver descriptions; run overnight before promoting to a stable release.
