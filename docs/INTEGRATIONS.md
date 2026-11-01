# Bring your workflow to the island

The `tally` command writes small JSON files to `~/Library/Application Support/TallyIsland/Activities`. The app refreshes every two seconds. This is an original file-based protocol, not the Atoll SDK or an Atoll-compatible API. It requires no server, network listener, credentials, or changes to agent settings.

The packaged command is at `Tally Island.app/Contents/MacOS/tally`. You can invoke it there, or copy it to a directory already on your PATH. From source, run `./scripts/build.sh` and use `.build/bin/tally`.

```bash
TALLY='/Applications/Tally Island.app/Contents/MacOS/tally'
"$TALLY" status --id build --title 'Building the website' --state working --progress 0.25
"$TALLY" status --id build --title 'Ready for review' --state waiting --detail 'Preview is ready'
"$TALLY" status --id build --title 'Build complete' --state done --progress 1 --tokens 12400
"$TALLY" list
"$TALLY" remove build
```

IDs accept letters, digits, hyphens, and underscores only. Titles are limited to 120 characters and detail to 500. Progress is optional, between 0 and 1. Tokens are optional, nonnegative integers reported by the caller. Omit unavailable values: unknown usage is never estimated from progress or elapsed time.

## Wrap a build

```bash
TALLY='/Applications/Tally Island.app/Contents/MacOS/tally'
"$TALLY" status --id my-build --title 'Compiling' --state working
if make; then
  "$TALLY" status --id my-build --title 'Build passed' --state done --progress 1
else
  "$TALLY" status --id my-build --title 'Build failed' --state failed
fi
```

## JSON contract

```json
{
  "id": "example",
  "title": "Review ready",
  "detail": "A tool supplied this status",
  "state": "waiting",
  "progress": 0.8,
  "tokens": 2400,
  "updatedAt": "2026-11-01T04:00:00Z"
}
```

Write atomically to `example.json`, with a current ISO-8601 timestamp. The filename and ID must agree. Files larger than 8 KiB, symlinks, malformed data, invalid fields, and timestamps more than one minute in the future are ignored. The app scans at most the 100 most recently modified JSON files. Waiting states sort first, then failures, working, and completed states. Working/waiting entries expire from view after 24 hours, completed/failed entries after one hour. Expiry hides entries; it does not delete source files. Dismiss or `tally remove` deletes that one activity file.

This channel is trusted **only to display text and numbers**. It cannot execute commands, approve tool actions, open URLs, or run HTML. Other processes running as the same user can write to it; it is not an authenticated boundary between local apps. Avoid putting secrets in titles or details.

For tests, set `TALLY_DATA_DIR` for both the app and CLI to a temporary directory. Activities are then read from its `Activities` subdirectory. Preference storage is still separate and follows the app's usual UserDefaults domain.

## Agent integration

Any agent or build runner can call the same command at lifecycle boundaries. No automatic Claude/Codex hook installation or account usage retrieval is included in v0.1. Report only what your integration actually knows. Token counts are caller-supplied per activity, not provider billing totals or plan limits.
