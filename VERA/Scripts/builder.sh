#!/bin/bash

# Ensure we run under real bash (not sh/dash or bash's POSIX mode). When invoked as
# `sh builder.sh`, macOS runs bash in POSIX mode where `echo -e` prints a literal
# "-e"; re-exec / disable POSIX so the colored output and bashisms behave correctly.
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi
set +o posix 2>/dev/null || true
shopt -u xpg_echo 2>/dev/null || true

set -euo pipefail

# Starter Kit Builder Script
#
# Owns code generation and workspace generation for the iOS Starter Kit.
#
# Usage:
#   ./Scripts/builder.sh            First-time setup: prerequisites, full codegen,
#                                   workspace generation, and optional Xcode launch.
#   ./Scripts/builder.sh --update   Fast path: regenerate JSON-driven files
#                                   (AppConfig.swift + theme assets) and the workspace.
#                                   No prerequisite checks, no Xcode launch.
#
# Code generation lives HERE (not in Project.swift): editing Config/app-config.json or
# Config/theme.json requires running this script (a plain `tuist generate` won't
# regenerate the generated files).

# Color codes for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Get script directory, VERA root, and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$VERA_DIR/.." && pwd)"

# Mode: setup (default) or update
MODE="setup"

# Phase tracking (set TOTAL_PHASES per mode before the first `phase` call)
TOTAL_PHASES=0
CURRENT_PHASE=0

# ----------------------------------------------------------------------------
# Output helpers
# ----------------------------------------------------------------------------
print_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║             Starter Kit · Builder            ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo -e "  ${DIM}mode:${NC} ${BOLD}$MODE${NC}"
}

# phase "Title" — prints a numbered section header framed by divider lines
readonly PHASE_RULE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
phase() {
    CURRENT_PHASE=$((CURRENT_PHASE + 1))
    echo ""
    echo -e "${BLUE}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${BLUE}${BOLD} Phase ${CURRENT_PHASE}/${TOTAL_PHASES} · $1${NC}"
    echo -e "${BLUE}${BOLD}${PHASE_RULE}${NC}"
}

# step "message" — an in-progress sub-step
step() {
    echo -e "  ${YELLOW}▸${NC} $1"
}

# ok "message" — a completed sub-step
ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

# warn "message"
warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

# fail "message" and exit — framed error banner
error_exit() {
    echo ""
    echo -e "${RED}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${RED}${BOLD} ✗ FAILED${NC}"
    echo -e "${RED} $1${NC}"
    echo -e "${RED}${BOLD}${PHASE_RULE}${NC}"
    echo ""
    exit 1
}

# print_done "message" — framed success banner
print_done() {
    echo ""
    echo -e "${GREEN}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${GREEN}${BOLD} ✓ $1${NC}"
    echo -e "${GREEN}${BOLD}${PHASE_RULE}${NC}"
    echo ""
}

# warn_unsaved_config — prominent reminder shown right before code generation.
# Code generation reads Config/app-config.json and Config/theme.json FROM DISK, so
# any edits still held in the editor's memory (unsaved) are invisible here and will
# NOT be picked up. This can't be detected from a shell, so we make the reminder
# impossible to miss and (when interactive) pause until the user confirms.
warn_unsaved_config() {
    echo ""
    echo -e "${YELLOW}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${YELLOW}${BOLD} ⚠  Save your config/theme edits first${NC}"
    echo -e "${YELLOW}${BOLD}${PHASE_RULE}${NC}"
    echo -e "  Code generation reads ${BOLD}app-config.json${NC} and ${BOLD}theme.json${NC} from disk,"
    echo -e "  so ${BOLD}unsaved${NC} editor changes won't be applied. Save now with ${BOLD}⌘S / Save All${NC}."
    echo ""
    if [ -t 0 ]; then
        local remaining=15
        while [ "$remaining" -gt 0 ]; do
            printf "\r  ${YELLOW}▸${NC} Continuing in ${BOLD}%2ds${NC} — press Enter to go now (Ctrl-C to abort) " "$remaining"
            # -t 1: wait up to 1s for a keypress; returns non-zero on timeout.
            if read -t 1 -n 1 -r _key 2>/dev/null; then
                break
            fi
            remaining=$((remaining - 1))
        done
        printf "\r\033[K"  # clear the countdown line
    fi
    echo ""
}

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --update)
            MODE="update"
            ;;
        -h|--help)
            grep '^#' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            error_exit "Unknown option: $arg (use --update, or no flag for full setup)"
            ;;
    esac
done

# Change to VERA directory (all paths below are relative to it)
cd "$VERA_DIR"

# ----------------------------------------------------------------------------
# Shared: JSON-driven code generation (AppConfig.swift + theme assets)
# ----------------------------------------------------------------------------
run_config_codegen() {
    step "generate-app-config.py → AppConfig.swift"
    if python3 Scripts/generate-app-config.py >/dev/null; then
        ok "AppConfig.swift generated"
    else
        error_exit "Failed to generate AppConfig.swift. Re-run without >/dev/null to see details."
    fi

    # Normalizes theme.json first (backfills any missing color/radius/typography
    # tokens with defaults, persisting them into the file) and then regenerates the
    # theme assets.
    step "generate-app-theme.py → normalize theme.json + theme assets"
    if theme_out=$(python3 Scripts/generate-app-theme.py 2>&1); then
        echo "$theme_out" | grep -q "Added missing" && ok "theme.json normalized (missing tokens added)"
        ok "Theme assets generated"
    else
        echo "$theme_out" | tail -3
        error_exit "Failed to generate theme assets."
    fi
}

# ----------------------------------------------------------------------------
# Shared: resolve API base URL and (re)generate EnvironmentConstants.swift
# ----------------------------------------------------------------------------
# The API base URL has a SINGLE entry point: EnvironmentConstants.swift. This
# helper resolves the URL and regenerates that file so both first-time setup and
# the --update fast path stay in sync.
#
# Requirement: when using builder.sh, a VALID baseApiUrl MUST resolve from
# app-config.json. It is the single source for the API base URL and always
# overrides EnvironmentConstants. The value supports ${VAR} placeholders, which
# are expanded from the environment (e.g. "${BASE_API_URL}" picks up an exported
# BASE_API_URL). If the resolved value is missing or invalid, the build stops
# with an error.
#
# "Valid" means a non-empty absolute URL with an http/https scheme and a host.
resolve_and_generate_env_constants() {
    local json_base_url
    json_base_url=$(python3 -c "
import json, os
from urllib.parse import urlparse
try:
    val = (json.load(open('Config/app-config.json')).get('baseApiUrl', '') or '').strip()
    val = os.path.expandvars(val)
    parsed = urlparse(val)
    print(val if parsed.scheme in ('http', 'https') and parsed.netloc else '')
except Exception:
    print('')
")

    if [ -z "$json_base_url" ]; then
        error_exit "A valid baseApiUrl is required in Config/app-config.json (absolute http/https URL with a host)."
    fi

    export BASE_API_URL="$json_base_url"
    ok "Base URL from app-config.json: $BASE_API_URL"

    step "generateEnvironmentConstants.sh → EnvironmentConstants.swift"
    if ./Scripts/generateEnvironmentConstants.sh >/dev/null; then
        ok "EnvironmentConstants.swift generated"
    else
        error_exit "Failed to generate EnvironmentConstants.swift."
    fi
}

# ----------------------------------------------------------------------------
# Shared: root-level config/theme overrides
# ----------------------------------------------------------------------------
# The template ships default Config/app-config.json and Config/theme.json that
# work out of the box. Developers can customise the build by dropping an
# app-config.json and/or theme.json at the repository root: when present, each
# is MOVED into Config/, overwriting the default and removing it from the root,
# before codegen runs. If neither override exists, the Config/ defaults are used
# unchanged.
apply_root_overrides() {
    local applied=0

    # $1 = filename to look for at the repo root; moved into Config/ if present
    _override_one() {
        local filename="$1"
        local src="$REPO_ROOT/$filename"
        local dst="./Config/$filename"

        if [ -f "$src" ]; then
            if mv -f "$src" "$dst"; then
                ok "Root override applied: ${filename} → Config/${filename}"
                applied=1
            else
                error_exit "Failed to move root override ${src} → ${dst}"
            fi
        fi
    }

    _override_one "app-config.json"
    _override_one "theme.json"

    if [ "$applied" -eq 0 ]; then
        ok "No root-level overrides found; using Config/ defaults"
    fi
}

run_tuist_generate() {
    # Fetch Tuist-managed SPM dependencies (Tuist/Package.swift) before generate.
    step "tuist install (SPM dependencies)"
    if tuist install; then
        ok "Dependencies installed"
    else
        error_exit "Failed to install dependencies with tuist. Check the error above."
    fi

    step "tuist generate (workspace)"
    local workspace_file="VERA.xcworkspace"
    if tuist generate --no-open; then
        if [ -d "$workspace_file" ]; then
            ok "Workspace generated → ${workspace_file}"
        else
            warn "tuist generate ran but ${workspace_file} was not found."
        fi
    else
        error_exit "Failed to generate workspace with tuist. Check the error above."
    fi
}

# Regenerates the SPM-only asset accessors from the Tuist-generated
# TuistAssets+VERACommonUI.swift so the SPM build never drifts from the asset
# catalog. MUST run after `tuist generate` (it reads the Derived/ output).
run_spm_assets_codegen() {
    step "generate-spm-assets.py → SPMAssets+VERACommonUI.swift"
    if python3 Scripts/generate-spm-assets.py; then
        ok "SPM asset accessors generated"
    else
        error_exit "Failed to generate SPM asset accessors."
    fi
}

open_xcode() {
    step "Opening Xcode..."
    if open VERA.xcworkspace; then
        ok "Xcode launched"
    else
        warn "Failed to open Xcode. Open VERA.xcworkspace manually."
    fi
}

# Framed "Launch App" section header, printed before the build-&-run prompt.
launch_app_header() {
    echo ""
    echo -e "${CYAN}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${CYAN}${BOLD} ▶  Launch App${NC}"
    echo -e "${CYAN}${BOLD}${PHASE_RULE}${NC}"
}

# Echoes currently CONNECTED physical iOS devices as "UDID<TAB>Name" lines (via
# devicectl, which reports live connection state). Empty output = none connected.
list_connected_devices() {
    xcrun devicectl --version >/dev/null 2>&1 || return 0
    local json="$VERA_DIR/build/.devicectl-devices.json"
    mkdir -p "$(dirname "$json")"
    xcrun devicectl list devices --json-output "$json" >/dev/null 2>&1 || return 0
    python3 -c "
import json, sys
try:
    data = json.load(open('$json'))
except Exception:
    sys.exit()
for dev in data.get('result', {}).get('devices', []):
    conn = dev.get('connectionProperties', {})
    if conn.get('tunnelState') == 'connected':
        name = dev.get('deviceProperties', {}).get('name', 'device')
        udid = dev.get('hardwareProperties', {}).get('udid') or dev.get('identifier', '')
        if udid:
            print(f'{udid}\t{name}')
" 2>/dev/null
}

# Echoes available iPhone simulators as "UDID<TAB>Label" lines (booted ones first).
list_available_simulators() {
    xcrun simctl list devices available -j 2>/dev/null | python3 -c "
import json, sys
try:
    devices = json.load(sys.stdin)['devices']
except Exception:
    sys.exit()
rows = []
for runtime, devs in devices.items():
    rt = runtime.split('.')[-1].replace('-', ' ')
    for x in devs:
        if not x.get('isAvailable') or 'iPhone' not in x.get('name', ''):
            continue
        booted = ' [booted]' if x.get('state') == 'Booted' else ''
        rows.append((x['udid'], f\"{x['name']} — {rt}{booted}\"))
rows.sort(key=lambda r: ('[booted]' not in r[1], r[1]))
for udid, label in rows:
    print(f'{udid}\t{label}')
" 2>/dev/null
}

# Arrow-key menu. $1 = prompt, $2 = newline-separated "value<TAB>label" options.
# Sets MENU_RESULT (value) and MENU_LABEL (label). With a single option it selects
# it directly. Non-interactive (no TTY) picks the first option.
menu_select() {
    local prompt="$1" options="$2"
    local -a values=() labels=()
    local v l
    while IFS=$'\t' read -r v l; do
        [ -z "$v" ] && continue
        values+=("$v")
        labels+=("$l")
    done <<<"$options"

    local n=${#values[@]}
    [ "$n" -eq 0 ] && return 1
    if [ "$n" -eq 1 ] || [ ! -t 0 ] || [ ! -r /dev/tty ]; then
        MENU_RESULT="${values[0]}"
        MENU_LABEL="${labels[0]}"
        return 0
    fi

    local sel=0 key rest i
    printf "  %s ${DIM}(↑/↓ to move, Enter to select)${NC}:\n" "$prompt"
    tput civis 2>/dev/null || true
    while true; do
        for i in $(seq 0 $((n - 1))); do
            if [ "$i" -eq "$sel" ]; then
                printf "  ${CYAN}${BOLD}❯ %s${NC}\033[K\n" "${labels[$i]}"
            else
                printf "    ${DIM}%s${NC}\033[K\n" "${labels[$i]}"
            fi
        done
        IFS= read -rsn1 key </dev/tty || true
        if [ "$key" = $'\x1b' ]; then
            # Arrow keys arrive as ESC [ A/B. macOS ships bash 3.2, whose `read -t`
            # only accepts INTEGER timeouts, so use 1 (not a fractional value).
            IFS= read -rsn2 -t 1 rest </dev/tty || true
            case "$rest" in
                '[A' | 'OA') sel=$(((sel - 1 + n) % n)) ;;
                '[B' | 'OB') sel=$(((sel + 1) % n)) ;;
            esac
        elif [ -z "$key" ]; then
            break
        fi
        printf "\033[%dA" "$n" # move cursor back up to redraw
    done
    tput cnorm 2>/dev/null || true
    MENU_RESULT="${values[$sel]}"
    MENU_LABEL="${labels[$sel]}"
    return 0
}

# Yes/No arrow selector. Returns 0 for Yes, 1 for No. Non-interactive → No.
confirm_menu() {
    local prompt="$1"
    if [ ! -t 0 ] || [ ! -r /dev/tty ]; then
        return 1
    fi
    menu_select "$prompt" "yes"$'\t'"Yes"$'\n'"no"$'\t'"No" || return 1
    [ "$MENU_RESULT" = "yes" ]
}

# Runs "$@" (output discarded) with a spinner animation on the line below, so long
# steps like xcodebuild show progress. Returns the command's exit code. On a
# non-TTY it runs synchronously without animation.
spin() {
    if [ ! -t 1 ]; then
        "$@" >/dev/null 2>&1
        return $?
    fi
    "$@" >/dev/null 2>&1 &
    local pid=$! i=0 idx
    local frames='|/-\'
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        idx=$((i % ${#frames}))
        printf "\r    ${CYAN}%s${NC} working...  " "${frames:idx:1}"
        i=$((i + 1))
        sleep 0.2
    done
    local rc=0
    wait "$pid" || rc=$?
    printf "\r\033[K"
    tput cnorm 2>/dev/null || true
    return "$rc"
}

# Builds the VERA app for an iOS Simulator, installs and launches it. This is the
# heavy path (a full xcodebuild) and is always optional. Any failure is non-fatal:
# it warns and returns so the script still finishes cleanly.
# $1 = simulator UDID (required; chosen by the caller).
run_on_simulator() {
    local udid="${1:-}"
    if ! xcrun simctl help >/dev/null 2>&1; then
        warn "Simulator tools (xcrun simctl) not available. Skipping."
        return 0
    fi
    if [ -z "$udid" ]; then
        warn "No iPhone simulator selected. Skipping run."
        return 0
    fi
    ok "Simulator: $udid"

    open -a Simulator >/dev/null 2>&1 || true

    # If the simulator is already running, close the app first (cold start). Otherwise
    # boot it. Either way we do NOT print "Booting..." for an already-running sim.
    if xcrun simctl list devices booted 2>/dev/null | grep -q "$udid"; then
        local app_bundle_id
        app_bundle_id=$(grep -m1 -E 'bundleId:' VERAApp/Project.swift 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/')
        if [ -n "$app_bundle_id" ]; then
            step "Simulator already running — closing the app..."
            xcrun simctl terminate "$udid" "$app_bundle_id" >/dev/null 2>&1 || true
        fi
    else
        step "Booting simulator..."
        xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    fi

    step "Building VERA for the simulator (this can take a few minutes)..."
    local derived="$VERA_DIR/build/BuilderRun"
    if spin xcodebuild build \
        -workspace VERA.xcworkspace \
        -scheme VERA \
        -configuration Debug \
        -destination "id=$udid" \
        -derivedDataPath "$derived" \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO; then
        ok "Build succeeded"
    else
        warn "Build failed. Open VERA.xcworkspace and run from Xcode to see the error."
        return 0
    fi

    local app_path
    app_path=$(find "$derived/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" 2>/dev/null | head -1)
    if [ -z "$app_path" ]; then
        warn "Could not locate the built .app. Run from Xcode instead."
        return 0
    fi

    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null || echo "")
    if [ -z "$bundle_id" ]; then
        warn "Could not read the app bundle id. Run from Xcode instead."
        return 0
    fi

    step "Installing and launching $bundle_id..."
    if xcrun simctl install "$udid" "$app_path" >/dev/null 2>&1 &&
        xcrun simctl launch "$udid" "$bundle_id" >/dev/null 2>&1; then
        ok "App launched on the simulator"
    else
        warn "Install/launch failed. Run from Xcode instead."
    fi
}

# Prominent reminder: Xcode must be signed in to the team so the development
# provisioning profiles can be downloaded for a physical-device install.
notice_xcode_login_for_device() {
    echo ""
    echo -e "${YELLOW}${BOLD}${PHASE_RULE}${NC}"
    echo -e "${YELLOW}${BOLD} ⚠  Xcode sign-in required to install on a physical device${NC}"
    echo -e "${YELLOW}${BOLD}${PHASE_RULE}${NC}"
    echo -e "  You must be signed in to this team in Xcode (${BOLD}Settings → Accounts${NC})"
    echo -e "  so the development provisioning profiles can be downloaded."
    echo -e "  ${DIM}Not needed for the Simulator.${NC}"
    echo ""
}

# Persists DEVELOPMENT_TEAM to Config/Signing.xcconfig via the canonical
# regenerateSigningConfig.sh (single source of truth). $1 = team id.
write_development_team() {
    # Canonical writer for Signing.xcconfig; creates it with the given team.
    DEVELOPMENT_TEAM="$1" ./Scripts/regenerateSigningConfig.sh >/dev/null
}

# Guarantees Config/Signing.xcconfig exists before `tuist generate`, which fails
# without it (Project.swift references it as an xcconfig). If missing, it's created
# via regenerateSigningConfig.sh using the current DEVELOPMENT_TEAM env (may be empty,
# which is fine for generation and the simulator; the device flow prompts for a real
# team later).
ensure_signing_config() {
    local xcconfig="./Config/Signing.xcconfig"
    if [ -f "$xcconfig" ]; then
        ok "Config/Signing.xcconfig already present"
        notice_xcode_login_for_device
        return 0
    fi

    warn "Config/Signing.xcconfig not found."
    echo -e "  ${DIM}It's needed to generate the project and to install the app.${NC}"
    echo -e "  ${DIM}Without a valid Apple Development Team you can still run on the"
    echo -e "  Simulator, but you won't be able to install on a physical device.${NC}"

    local team=""
    if [ -n "${DEVELOPMENT_TEAM:-}" ]; then
        team="$DEVELOPMENT_TEAM"
    elif [ -t 0 ] && [ -r /dev/tty ]; then
        printf "  Enter your Apple Development Team ID (blank to continue without it): "
        read -r team </dev/tty || true
        team=$(printf '%s' "$team" | tr -d '[:space:]')
    fi

    DEVELOPMENT_TEAM="$team" ./Scripts/regenerateSigningConfig.sh >/dev/null
    if [ -n "$team" ]; then
        ok "Config/Signing.xcconfig created (team: $team)"
        notice_xcode_login_for_device
    else
        warn "Config/Signing.xcconfig created WITHOUT a team — device installs will fail until you set one."
    fi
}

# Ensures a Development Team is configured before a device build. Reads it from the
# DEVELOPMENT_TEAM env var (wins) or Config/Signing.xcconfig. If missing and running
# interactively, offers to enter a Team ID and persists it to the xcconfig (which
# survives regeneration, unlike the Xcode "Signing & Capabilities" UI). Returns
# non-zero when no team could be resolved.
ensure_development_team() {
    local xcconfig="./Config/Signing.xcconfig"
    local team=""
    if [ -f "$xcconfig" ]; then
        team=$(grep -E '^DEVELOPMENT_TEAM' "$xcconfig" | sed -E 's/^DEVELOPMENT_TEAM[[:space:]]*=[[:space:]]*//' | tr -d '[:space:]')
    fi
    [ -n "${DEVELOPMENT_TEAM:-}" ] && team="$DEVELOPMENT_TEAM"

    if [ -n "$team" ]; then
        ok "Development Team: $team"
        return 0
    fi

    warn "No Development Team configured — required to run on a physical device."
    warn "Set it in Config/Signing.xcconfig (persists across builder.sh / tuist generate);"
    warn "the Xcode 'Signing & Capabilities' UI is reset whenever the project is regenerated."

    if [ ! -t 0 ] || [ ! -r /dev/tty ]; then
        return 1
    fi

    printf "  Enter your Apple Development Team ID (blank to skip): "
    local input=""
    read -r input </dev/tty || true
    input=$(printf '%s' "$input" | tr -d '[:space:]')
    if [ -z "$input" ]; then
        warn "No Team ID entered. Skipping device run."
        return 1
    fi

    write_development_team "$input"
    ok "Development Team saved to Config/Signing.xcconfig"
    notice_xcode_login_for_device
    return 0
}

# Builds the VERA app for a connected physical device and installs/launches it via
# devicectl. Requires valid code signing (team + provisioning); non-fatal on failure.
# $1 = device UDID, $2 = device name (for display).
run_on_device() {
    local udid="$1" name="$2"
    ok "Device: ${name:-unknown} ($udid)"

    # A device build needs a Development Team. Offer to configure it persistently.
    # If none is provided, a physical device can't be used — fall back to the simulator.
    if ! ensure_development_team; then
        warn "Without a Development Team the app can't run on a physical device."
        if confirm_menu "Run on the iOS Simulator instead?"; then
            launch_on_simulator_flow
        fi
        return 0
    fi

    # Close the app on the device (if running) right after selecting it, for a cold
    # start. Best-effort: find the app's process by its bundle path and terminate it.
    step "Closing the app on the device (if running)..."
    local proc_json="$VERA_DIR/build/.device-procs.json"
    mkdir -p "$(dirname "$proc_json")"
    if xcrun devicectl device info processes --device "$udid" --json-output "$proc_json" >/dev/null 2>&1; then
        local pid
        pid=$(python3 -c "
import json, sys
try:
    d = json.load(open('$proc_json'))
except Exception:
    sys.exit()
for p in d.get('result', {}).get('runningProcesses', []):
    path = (p.get('executable') or p.get('executablePath') or '') or ''
    if '/VERA.app/' in path or path.endswith('/VERA'):
        print(p.get('processIdentifier') or p.get('pid') or '')
        break
" 2>/dev/null)
        if [ -n "$pid" ]; then
            xcrun devicectl device process terminate --device "$udid" --pid "$pid" >/dev/null 2>&1 || true
        fi
    fi

    step "Building VERA for the device (requires valid signing; this can take a few minutes)..."
    local derived="$VERA_DIR/build/BuilderRunDevice"
    if spin xcodebuild build \
        -workspace VERA.xcworkspace \
        -scheme VERA \
        -configuration Debug \
        -destination "id=$udid" \
        -derivedDataPath "$derived" \
        -allowProvisioningUpdates; then
        ok "Build succeeded"
    else
        warn "Device build failed — usually code signing (team/provisioning)."
        warn "Make sure you're signed in to this team in Xcode (Settings → Accounts)."
        warn "Tip: set DEVELOPMENT_TEAM in Config/Signing.xcconfig so it survives regeneration."
        return 0
    fi

    local app_path
    app_path=$(find "$derived/Build/Products/Debug-iphoneos" -maxdepth 1 -name "*.app" 2>/dev/null | head -1)
    if [ -z "$app_path" ]; then
        warn "Could not locate the built .app. Run from Xcode instead."
        return 0
    fi

    local bundle_id
    bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Info.plist" 2>/dev/null || echo "")

    step "Installing and launching on ${name:-device}..."
    # --terminate-existing kills any running instance first for a visible cold start.
    if xcrun devicectl device install app --device "$udid" "$app_path" >/dev/null 2>&1 &&
        [ -n "$bundle_id" ] &&
        xcrun devicectl device process launch --terminate-existing --device "$udid" "$bundle_id" >/dev/null 2>&1; then
        ok "App launched on ${name:-the device}"
    else
        warn "Install/launch on device failed. Run from Xcode instead."
    fi
}

# Prints the Launch App header, detects connected physical devices, and asks where
# to run. With a device connected: (s)imulator / (d)evice / (n)o. Otherwise a simple
# simulator y/n.
launch_on_simulator_flow() {
    local sims
    sims=$(list_available_simulators)
    if [ -z "$sims" ]; then
        warn "No iPhone simulators available. Skipping."
        return 0
    fi
    if menu_select "Select a simulator" "$sims"; then
        ok "Selected: $MENU_LABEL"
        run_on_simulator "$MENU_RESULT"
    fi
}

launch_on_device_flow() {
    local devices
    devices=$(list_connected_devices)
    if [ -z "$devices" ]; then
        warn "No connected devices found."
        return 0
    fi
    if menu_select "Select a device" "$devices"; then
        run_on_device "$MENU_RESULT" "$MENU_LABEL"
    fi
}

# Prints the Launch App header, detects connected physical devices, and asks where
# to run. With a device connected: (s)imulator / (d)evice / (n)o. Otherwise a simple
# simulator y/n. Each path lists the targets and lets you arrow-select (or launches
# directly when there is only one).
offer_launch() {
    launch_app_header

    # Only offer to launch when running interactively (skip in CI / piped runs).
    if [ ! -t 0 ] || [ ! -r /dev/tty ]; then
        return 0
    fi

    # Top-level target menu: Simulator, Physical device (only if connected), or none.
    local connected options
    connected=$(list_connected_devices)
    options="sim"$'\t'"iOS Simulator"
    if [ -n "$connected" ]; then
        options+=$'\n'"device"$'\t'"Physical device (requires Xcode sign-in + a valid Development Team)"
    fi
    options+=$'\n'"none"$'\t'"Don't launch"

    menu_select "Where do you want to run the app?" "$options" || return 0
    case "$MENU_RESULT" in
        sim) launch_on_simulator_flow ;;
        device) launch_on_device_flow ;;
        *) : ;;
    esac
}

print_banner

# ============================================================================
# UPDATE mode: regenerate config-driven files + workspace, then exit
# ============================================================================
if [ "$MODE" = "update" ]; then
    TOTAL_PHASES=5

    phase "Validate configuration"
    apply_root_overrides
    if [ ! -f "./Config/app-config.json" ]; then
        error_exit "Configuration file not found at ./Config/app-config.json"
    fi
    ok "app-config.json found"

    phase "Regenerate code from config and theme"
    warn_unsaved_config
    run_config_codegen
    # A valid baseApiUrl in app-config.json is required and always overrides
    # EnvironmentConstants, so `--update` picks up URL changes too.
    resolve_and_generate_env_constants

    phase "Configure code signing"
    ensure_signing_config

    phase "Generate workspace"
    run_tuist_generate

    phase "Generate SPM assets"
    run_spm_assets_codegen

    offer_launch

    print_done "Update complete"
    echo -e "  ${DIM}If Xcode is already open, let it reload the project and Build"
    echo -e "  (Clean Build Folder if you toggled a feature flag).${NC}"
    echo ""

    if confirm_menu "Open VERA.xcworkspace in Xcode now?"; then
        open_xcode
    fi
    echo ""
    exit 0
fi

# ============================================================================
# SETUP mode: full first-time setup
# ============================================================================
TOTAL_PHASES=7

# ----------------------------------------------------------------------------
phase "Check prerequisites"
# ----------------------------------------------------------------------------

# Check Xcode
if ! xcode-select -p >/dev/null 2>&1; then
    error_exit "Xcode not installed. Please install Xcode from the App Store."
fi
ok "Xcode found"

# Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
    echo ""
    read -p "  Homebrew not found. Install it now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        step "Installing Homebrew..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            ok "Homebrew installed successfully"

            # Load Homebrew into PATH for current session
            # Apple Silicon
            if [ -x /opt/homebrew/bin/brew ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            # Intel
            if [ -x /usr/local/bin/brew ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi

            # Verify brew is now available
            if ! command -v brew >/dev/null 2>&1; then
                error_exit "Homebrew was installed but brew is not available in PATH. Restart the terminal and rerun this script."
            fi
        else
            error_exit "Failed to install Homebrew"
        fi
    else
        error_exit "Homebrew is required. Visit https://brew.sh to install it."
    fi
fi
ok "Homebrew found"

# Check Python 3
if ! command -v python3 >/dev/null 2>&1; then
    step "Installing Python 3 via Homebrew..."
    if brew install python3; then
        ok "Python 3 installed successfully"
    else
        error_exit "Failed to install Python 3"
    fi
fi
ok "Python 3 found"

# Tuist
if ! command -v tuist >/dev/null 2>&1; then
    echo ""
    read -p "  Tuist not found. Install via Homebrew? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        step "Installing Tuist..."
        if brew install tuist; then
            ok "Tuist installed successfully"
        else
            error_exit "Failed to install Tuist via Homebrew"
        fi
    else
        error_exit "Tuist is required to generate the workspace. Exiting."
    fi
else
    ok "Tuist found"
fi

# ----------------------------------------------------------------------------
phase "Validate configuration"
# ----------------------------------------------------------------------------
apply_root_overrides
if [ ! -f "./Config/app-config.json" ]; then
    error_exit "Configuration file not found at ./Config/app-config.json"
fi
ok "app-config.json found"

if [ ! -f "./Config/theme.json" ]; then
    error_exit "Theme file not found at ./Config/theme.json"
fi
ok "theme.json found"

# ----------------------------------------------------------------------------
phase "Resolve base URL & environment constants"
# ----------------------------------------------------------------------------
# SINGLE entry point for the API base URL: a valid baseApiUrl in app-config.json
# is required and is injected into EnvironmentConstants.swift.
resolve_and_generate_env_constants

# ----------------------------------------------------------------------------
phase "Generate code from config and theme"
# ----------------------------------------------------------------------------
warn_unsaved_config
step "generate-app-config.py → AppConfig.swift"
if python3 Scripts/generate-app-config.py >/dev/null; then
    ok "AppConfig.swift generated"
else
    error_exit "Failed to generate AppConfig.swift."
fi

# Normalizes theme.json first (backfills any missing color/radius/typography
# tokens with defaults, persisting them into the file) and then regenerates assets.
step "generate-app-theme.py → normalize theme.json + theme assets"
if theme_out=$(python3 Scripts/generate-app-theme.py 2>&1); then
    echo "$theme_out" | grep -q "Added missing" && ok "theme.json normalized (missing tokens added)"
    ok "Theme assets generated"
else
    echo "$theme_out" | tail -3
    error_exit "Failed to generate theme assets."
fi

# ----------------------------------------------------------------------------
phase "Configure code signing"
# ----------------------------------------------------------------------------
ensure_signing_config

# ----------------------------------------------------------------------------
phase "Generate workspace"
# ----------------------------------------------------------------------------
run_tuist_generate

# ----------------------------------------------------------------------------
phase "Generate SPM assets"
# ----------------------------------------------------------------------------
run_spm_assets_codegen

# ----------------------------------------------------------------------------
# Launch, completion banner, then the Xcode-opening prompt
# ----------------------------------------------------------------------------
offer_launch

print_done "Setup complete"

if confirm_menu "Open VERA.xcworkspace in Xcode now?"; then
    open_xcode
fi
echo ""
