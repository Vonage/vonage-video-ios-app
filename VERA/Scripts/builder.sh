#!/bin/bash
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

# Get script directory and VERA root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

    step "generate-app-theme.py → theme assets"
    if python3 Scripts/generate-app-theme.py >/dev/null; then
        ok "Theme assets generated"
    else
        error_exit "Failed to generate theme assets. Re-run without >/dev/null to see details."
    fi
}

run_tuist_generate() {
    step "tuist generate (workspace)"
    if tuist generate --no-open; then
        ok "VERA.xcworkspace generated"
    else
        error_exit "Failed to generate workspace with tuist. Check the error above."
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

print_banner

# ============================================================================
# UPDATE mode: regenerate config-driven files + workspace, then exit
# ============================================================================
if [ "$MODE" = "update" ]; then
    TOTAL_PHASES=3

    phase "Validate configuration"
    if [ ! -f "./Config/app-config.json" ]; then
        error_exit "Configuration file not found at ./Config/app-config.json"
    fi
    ok "app-config.json found"

    phase "Regenerate code from config and theme"
    run_config_codegen

    phase "Generate workspace"
    run_tuist_generate

    print_done "Update complete"
    echo -e "  ${DIM}If Xcode is already open, let it reload the project and Build"
    echo -e "  (Clean Build Folder if you toggled a feature flag).${NC}"
    echo ""

    read -p "  Open VERA.xcworkspace in Xcode now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open_xcode
    fi
    echo ""
    exit 0
fi

# ============================================================================
# SETUP mode: full first-time setup
# ============================================================================
TOTAL_PHASES=6

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
if [ ! -f "./Config/app-config.json" ]; then
    error_exit "Configuration file not found at ./Config/app-config.json"
fi
ok "app-config.json found"

if [ ! -f "./Config/theme.json" ]; then
    error_exit "Theme file not found at ./Config/theme.json"
fi
ok "theme.json found"

# ----------------------------------------------------------------------------
phase "Resolve BASE_API_URL"
# ----------------------------------------------------------------------------
# Priority 1: baseApiUrl from app-config.json (Starter Kit)
# Priority 2: $BASE_API_URL from environment (VERA internal)
JSON_BASE_URL=$(python3 -c "
import json
try:
    val = json.load(open('Config/app-config.json')).get('baseApiUrl', '')
    print(val.strip())
except:
    print('')
")

if [ -n "$JSON_BASE_URL" ]; then
    export BASE_API_URL="$JSON_BASE_URL"
    ok "From app-config.json: $BASE_API_URL"
elif [ -n "${BASE_API_URL:-}" ]; then
    ok "From environment: $BASE_API_URL"
else
    error_exit "baseApiUrl not found in Config/app-config.json and BASE_API_URL env var is not set."
fi

# ----------------------------------------------------------------------------
phase "Generate code from config and theme"
# ----------------------------------------------------------------------------
step "generate-app-config.py → AppConfig.swift"
if python3 Scripts/generate-app-config.py >/dev/null; then
    ok "AppConfig.swift generated"
else
    error_exit "Failed to generate AppConfig.swift."
fi

step "generateEnvironmentConstants.sh → EnvironmentConstants.swift"
if ./Scripts/generateEnvironmentConstants.sh >/dev/null; then
    ok "EnvironmentConstants.swift generated"
else
    error_exit "Failed to generate EnvironmentConstants.swift."
fi

step "generate-app-theme.py → theme assets"
if python3 Scripts/generate-app-theme.py >/dev/null; then
    ok "Theme assets generated"
else
    error_exit "Failed to generate theme assets."
fi

# ----------------------------------------------------------------------------
phase "Generate workspace"
# ----------------------------------------------------------------------------
run_tuist_generate

# ----------------------------------------------------------------------------
# Xcode opening prompt
# ----------------------------------------------------------------------------
print_done "Setup complete"

# On first-time setup we open Xcode automatically.
open_xcode
echo ""
