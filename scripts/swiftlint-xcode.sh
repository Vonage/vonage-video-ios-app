#!/bin/bash

# SwiftLint Xcode Run Script Phase (Target-Specific)
#
# Optimized for speed:
#   1. Uses --use-script-input-files (reads Xcode's file list via env vars instead of find)
#   2. Uses --cache-path (skips unchanged files across builds — survives clean builds)
#   3. Falls back to find + xargs when env vars are not available (CLI / manual runs)
#
# Usage in Xcode Run Script Phase (via Tuist Scripts+SwiftLint.swift):
#   ${SRCROOT}/../../scripts/swiftlint-xcode.sh
#
# Xcode environment variables used:
#   - SRCROOT             : Path to the target's source directory
#   - TARGET_NAME         : Name of the current target
#   - SCRIPT_INPUT_FILE_COUNT / SCRIPT_INPUT_FILE_N : Populated by Xcode when inputPaths are set
#   - BUILD_DIR           : Xcode build products dir (used for per-workspace cache)

echo "🚀 SwiftLint Xcode Run Script Phase (Target-Specific)"

# ── Skip guard ────────────────────────────────────────────────────────────────
if [ "${RUN_SWIFTLINT}" = "NO" ]; then
  echo "⏭️  SwiftLint skipped (RUN_SWIFTLINT=NO)"
  exit 0
fi

# ── Find SwiftLint ────────────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SWIFTLINT_CMD=""
if command -v swiftlint >/dev/null 2>&1; then
    SWIFTLINT_CMD="swiftlint"
elif [ -f "/opt/homebrew/bin/swiftlint" ]; then
    SWIFTLINT_CMD="/opt/homebrew/bin/swiftlint"
elif [ -f "/usr/local/bin/swiftlint" ]; then
    SWIFTLINT_CMD="/usr/local/bin/swiftlint"
elif [ -f "/usr/bin/swiftlint" ]; then
    SWIFTLINT_CMD="/usr/bin/swiftlint"
else
    echo "warning: SwiftLint not found. Install it via Homebrew: brew install swiftlint"
    exit 0
fi

echo "✅ Found SwiftLint at: ${SWIFTLINT_CMD}"

# ── Locate project root (.swiftlint.yml) ─────────────────────────────────────
CURRENT_DIR="${SRCROOT}"
PROJECT_ROOT=""

while [ "$CURRENT_DIR" != "/" ] && [ -n "$CURRENT_DIR" ]; do
    if [ -f "$CURRENT_DIR/.swiftlint.yml" ]; then
        PROJECT_ROOT="$CURRENT_DIR"
        break
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

if [ -z "$PROJECT_ROOT" ]; then
    for path in "${SRCROOT}" "${SRCROOT}/.." "${SRCROOT}/../.."; do
        if [ -f "$path/.swiftlint.yml" ]; then
            PROJECT_ROOT="$path"
            break
        fi
    done
fi

if [ -z "$PROJECT_ROOT" ]; then
    echo "warning: Could not find .swiftlint.yml — running with defaults on SRCROOT"
    cd "${SRCROOT}"
    $SWIFTLINT_CMD lint "${SRCROOT}"
    exit $?
fi

echo "📁 Project root : ${PROJECT_ROOT}"
echo "🔍 Config       : ${PROJECT_ROOT}/.swiftlint.yml"
echo "🎯 Target       : ${TARGET_NAME:-<unknown>}"
echo "📂 Source dir   : ${SRCROOT}"

cd "${PROJECT_ROOT}"

# ── Persistent cache (survives clean builds) ─────────────────────────────────
# Per-workspace cache so multiple projects don't collide.
WORKSPACE_HASH=$(echo "${PROJECT_ROOT}" | shasum -a 256 | cut -c1-8)
CACHE_DIR="${HOME}/.swiftlint_cache/${WORKSPACE_HASH}"
mkdir -p "${CACHE_DIR}"
echo "💾 Cache path   : ${CACHE_DIR}"

# ── Build the concrete list of Swift files to lint ───────────────────────────
# IMPORTANT: Xcode populates SCRIPT_INPUT_FILE_* verbatim from the build phase's
# inputPaths and does NOT expand globs. The Tuist helper declares a config path
# plus "<target>/**/*.swift", so Xcode hands SwiftLint a .yml and a literal
# "…/**/*.swift" that matches no file. Feeding that straight to
# --use-script-input-files lints nothing while reporting success.
#
# So: accept Xcode's inputs only when they are concrete, existing .swift files
# with no unexpanded glob; otherwise discover the target's sources with find.
# Either way we feed a concrete list back through --use-script-input-files, which
# lints EXACTLY those files (it ignores the config's `included:`, so we don't
# fall into a whole-tree union scan) while --cache-path skips unchanged files.
LINT_LIST=$(mktemp)

collect_xcode_inputs() {
    [ -n "${SCRIPT_INPUT_FILE_COUNT:-}" ] || return 1
    [ "${SCRIPT_INPUT_FILE_COUNT}" -gt 0 ] 2>/dev/null || return 1
    : > "${LINT_LIST}"
    local i=0 f unresolved=0
    while [ "$i" -lt "${SCRIPT_INPUT_FILE_COUNT}" ]; do
        eval "f=\${SCRIPT_INPUT_FILE_${i}:-}"
        case "$f" in
            *'*'*)   unresolved=1 ;;                               # glob Xcode left literal
            *.swift) [ -f "$f" ] && printf '%s\n' "$f" >> "${LINT_LIST}" ;;
            *) : ;;                                                # ignore .yml and non-swift
        esac
        i=$((i + 1))
    done
    [ "$unresolved" -eq 0 ] && [ -s "${LINT_LIST}" ]
}

if collect_xcode_inputs; then
    echo "⚡ Incremental mode: $(wc -l < "${LINT_LIST}" | tr -d ' ') concrete Swift input(s) from Xcode"
else
    echo "🔍 Full-scan mode (Xcode inputs are a glob/config, not concrete files) — discovering target sources"
    find "${SRCROOT}" -maxdepth 10 -name "*.swift" \
        -not -path "*/.*" \
        -not -path "*/*.xcodeproj/*" \
        -not -path "*/*.xcworkspace/*" \
        -not -path "*/build/*" \
        -not -path "*/Build/*" \
        -not -path "*/DerivedData/*" \
        -not -path "*/__Snapshots__/*" \
        -not -path "*/Pods/*" \
        -not -path "*/Carthage/*" \
        > "${LINT_LIST}"
    echo "📊 Discovered $(wc -l < "${LINT_LIST}" | tr -d ' ') Swift file(s) under ${SRCROOT}"
fi

if [ ! -s "${LINT_LIST}" ]; then
    echo "⚠️  No Swift files to lint — skipping"
    rm -f "${LINT_LIST}"
    exit 0
fi

# Re-expose the concrete list as SCRIPT_INPUT_FILE_* and lint with
# --use-script-input-files so SwiftLint lints exactly these files.
export SCRIPT_INPUT_FILE_COUNT
SCRIPT_INPUT_FILE_COUNT=$(wc -l < "${LINT_LIST}" | tr -d ' ')
idx=0
while IFS= read -r f; do
    export "SCRIPT_INPUT_FILE_${idx}=$f"
    idx=$((idx + 1))
done < "${LINT_LIST}"
rm -f "${LINT_LIST}"

$SWIFTLINT_CMD lint \
    --use-script-input-files \
    --quiet \
    --cache-path "${CACHE_DIR}"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✅ SwiftLint passed for target ${TARGET_NAME:-<unknown>}"
else
    echo "❌ SwiftLint found violations in target ${TARGET_NAME:-<unknown>}"
fi

exit $exit_code
