#!/bin/bash
#
# Self-check for scripts/vera-verify. Needs no simulator and never boots one:
# it only runs help, dry-run and validation paths with isolated state directories.
# Usage: ./scripts/vera-verify-test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$SCRIPT_DIR/vera-verify"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/vera-verify-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

export VERA_VERIFY_STATE_DIR="$SANDBOX/state"
export VERA_VERIFY_ARTIFACTS_DIR="$SANDBOX/artifacts"
export VERA_VERIFY_DERIVED_DATA="$SANDBOX/DerivedData"
export VERA_VERIFY_RUN_ID="self-check"
unset VERA_VERIFY_DEVICE

PASSED=0
FAILED=0

# expect NAME EXPECTED_EXIT PYTHON_ASSERTION -- CLI ARGS...
# The assertion sees the parsed JSON as `d` and the raw stdout as `raw`.
expect() {
    local name="$1" expected_exit="$2" assertion="$3"
    shift 4
    local output exit_code
    output="$("$CLI" "$@" 2>/dev/null)"
    exit_code=$?
    if [ "$exit_code" -ne "$expected_exit" ]; then
        echo "FAIL $name: exit $exit_code, expected $expected_exit"
        echo "$output" | head -20
        FAILED=$((FAILED + 1))
        return
    fi
    if echo "$output" | python3 -c '
import json, sys
raw = sys.stdin.read()
d = json.loads(raw)
assert '"$assertion"', "assertion failed"
' 2>/dev/null; then
        PASSED=$((PASSED + 1))
    else
        echo "FAIL $name: assertion '$assertion' on:"
        echo "$output" | head -20
        FAILED=$((FAILED + 1))
    fi
}

expect "help" 0 'd["ok"] and "doctor" in d["help"]' -- help
expect "unknown command" 1 'not d["ok"] and d["next_action"]' -- frobnicate
for command in doctor build launch drive screenshot logs record-video deep-link hierarchy online-url cleanup map-check; do
    expect "$command --help" 0 'd["ok"] and d["help"]' -- "$command" --help
done

expect "build dry-run uses isolated DerivedData" 0 \
    'd["dry_run"] and any("xcodebuild build" in s and "'"$SANDBOX"'/DerivedData" in s for s in d["would_run"]) and not any("rm -rf" in s for s in d["would_run"])' \
    -- build --dry-run
expect "build rejects http base URL" 1 'not d["ok"] and "https" in d["error"]' -- build --base-url http://example.net/ --dry-run
expect "build dry-run with base URL restores generated files" 0 \
    'any("restore" in s for s in d["would_run"]) and not any("example.net" in s for s in d["would_run"])' \
    -- build --base-url https://example.net/ --dry-run
expect "launch needs a build" 1 'not d["ok"] and "build" in d["next_action"]' -- launch --dry-run

mkdir -p "$VERA_VERIFY_DERIVED_DATA/Build/Products/Debug-iphonesimulator/VERA.app"
expect "launch dry-run uses mocks" 0 \
    'any("VERA_E2E_MOCKS=1" in s and "simctl launch" in s for s in d["would_run"])' \
    -- launch --scenario force-mute --dry-run
expect "launch dry-run online disables mocks" 0 \
    'any("VERA_E2E_MOCKS=0" in s for s in d["would_run"]) and not any("SCENARIO" in s for s in d["would_run"])' \
    -- launch --online --dry-run
expect "launch pins English by default" 0 \
    'd["would_run"].index(next(s for s in d["would_run"] if "AppleLanguages=(en)" in s)) < d["would_run"].index(next(s for s in d["would_run"] if "simctl launch" in s))' \
    -- launch --dry-run
expect "launch --language system keeps the simulator language" 0 \
    'not any("AppleLanguages" in s for s in d["would_run"])' -- launch --language system --dry-run
expect "launch rejects a bad language" 1 'not d["ok"]' -- launch --language 'en;rm' --dry-run
mkdir -p "$VERA_VERIFY_STATE_DIR/runs"
printf 'build_failed=1\n' > "$VERA_VERIFY_STATE_DIR/runs/self-check.env"
expect "launch refuses a stale app after a failed build" 1 'not d["ok"] and "stale" in d["error"]' -- launch --dry-run
rm -f "$VERA_VERIFY_STATE_DIR/runs/self-check.env"

expect "drive unknown feature" 1 'not d["ok"] and "README" in d["next_action"]' -- drive --feature no-such-feature
expect "drive unknown flow" 1 'not d["ok"]' -- drive --flow no-such-flow.yaml
expect "drive feature dry-run lists its flows" 0 \
    'len(d["would_run"]) == 2 and all("force-mute" in s for s in d["would_run"])' \
    -- drive --feature moderation-force-mute --dry-run

expect "deep-link redacts query and fragment" 0 \
    '"<redacted>" in raw and "secret" not in raw and "frag" not in raw' \
    -- deep-link 'vera://example.net/room/demo?token=secret#frag' --dry-run
expect "deep-link rejects other schemes" 1 'not d["ok"]' -- deep-link 'ftp://example.net/room/demo' --dry-run
expect "screenshot rejects unsafe names" 1 'not d["ok"]' -- screenshot --name '../escape'
expect "logs rejects bad --since" 1 'not d["ok"]' -- logs --since soon
expect "online-url needs a PR number" 1 'not d["ok"]' -- online-url --react-pr abc

expect "cleanup without state touches nothing" 0 \
    'not any("simctl" in s for s in d["would_run"])' -- cleanup --dry-run
mkdir -p "$VERA_VERIFY_STATE_DIR/runs"
printf 'udid=FAKE-UDID\nlaunched_by_run=1\n' > "$VERA_VERIFY_STATE_DIR/runs/self-check.env"
expect "cleanup leaves a simulator it did not boot" 0 \
    'any("terminate FAKE-UDID" in s for s in d["would_run"]) and not any("shutdown" in s for s in d["would_run"])' \
    -- cleanup --dry-run
printf 'udid=FAKE-UDID\nbooted_by_run=1\n' > "$VERA_VERIFY_STATE_DIR/runs/self-check.env"
expect "cleanup shuts down a simulator it booted" 0 \
    'any("shutdown FAKE-UDID" in s for s in d["would_run"])' -- cleanup --dry-run
rm -f "$VERA_VERIFY_STATE_DIR/runs/self-check.env"

expect "map-check passes on the Feature Map" 0 'd["ok"] and d["features"] > 0' -- map-check
BROKEN="$SANDBOX/broken-map"
cp -R "$REPO_ROOT/.claude/skills/verify/features" "$BROKEN"
printf -- '---\nstatus: developed\nverification: maestro\nparity_rows:\n  - X\n---\n\n## Gotchas\n' > "$BROKEN/orphan.md"
expect "map-check catches unlinked files, missing flows and sections" 1 \
    'not d["ok"] and any("not linked" in e for e in d["errors"]) and any("maestro_flows is empty" in e for e in d["errors"]) and any("H2 sections" in e for e in d["errors"])' \
    -- map-check --features "$BROKEN"

if [ -d "$VERA_VERIFY_ARTIFACTS_DIR" ]; then
    echo "FAIL dry runs created an artifacts directory"
    FAILED=$((FAILED + 1))
else
    PASSED=$((PASSED + 1))
fi

echo "vera-verify self-check: $PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
