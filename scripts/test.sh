#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d "${TMPDIR:-/tmp}/tally-checks.XXXXXX")
trap 'rm -rf "$check_dir"' EXIT
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$check_dir/modules}"
swiftc Sources/TallyCore/Core.swift Tests/CoreChecks.swift -o "$check_dir/core-checks"
"$check_dir/core-checks"
./scripts/build.sh
bridge_bin="${TALLY_BUILD_DIR:-$PWD/.build}/bin/tally"
export TALLY_DATA_DIR="$check_dir/data"
"$bridge_bin" status --id smoke --title "Integration smoke test" --state working --progress 0.5 --tokens 42
"$bridge_bin" list | python3 -c 'import json,sys; a=json.load(sys.stdin); assert len(a)==1 and a[0]["tokens"]==42 and a[0]["progress"]==0.5'
if "$bridge_bin" status --id bad --title Bad --progress nope; then echo 'Invalid CLI input was accepted'; exit 1; fi
if "$bridge_bin" status --id ../bad --title Bad; then echo 'Unsafe ID was accepted'; exit 1; fi
"$bridge_bin" remove smoke
"$bridge_bin" list | python3 -c 'import json,sys; assert json.load(sys.stdin)==[]'
echo 'CLI integration checks passed.'
