#!/bin/bash

# Generate SPM Assets — Xcode Run Script Phase (VERACommonUI)
#
# Regenerates VERACommonUI/VERACommonUI/Generated/SPMAssets+VERACommonUI.swift
# from the Tuist-generated Derived/Sources/TuistAssets+VERACommonUI.swift so the
# SPM build never drifts from the asset catalog.
#
# This runs as a `.pre` build phase on the VERACommonUI target, keeping the SPM
# accessors up to date on every Xcode build — without relying on anyone running
# `Scripts/generate-spm-assets.py` by hand after `tuist generate`. It complements
# (does not replace) the same step in `Scripts/builder.sh`.
#
# Uses Xcode environment variables:
# - SRCROOT: the VERACommonUI target source dir (…/VERA/VERACommonUI)
#
# The Python script resolves its paths relative to the VERA/ directory, so we
# run it from there (SRCROOT's parent).

set -euo pipefail

echo "🎨 Generate SPM Assets (VERACommonUI)"

# Allow opting out (mirrors RUN_SWIFTLINT).
if [ "${RUN_SPM_ASSETS_CODEGEN:-YES}" = "NO" ]; then
  echo "⏭️  SPM asset codegen skipped (RUN_SPM_ASSETS_CODEGEN=NO)"
  exit 0
fi

# Ensure Homebrew Python is reachable from Xcode's minimal PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Locate python3.
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif [ -x "/opt/homebrew/bin/python3" ]; then
  PYTHON_CMD="/opt/homebrew/bin/python3"
elif [ -x "/usr/local/bin/python3" ]; then
  PYTHON_CMD="/usr/local/bin/python3"
else
  echo "warning: python3 not found; skipping SPM asset codegen."
  exit 0
fi

# SRCROOT is …/VERA/VERACommonUI. The script must run from …/VERA.
if [ -z "${SRCROOT:-}" ] || [ ! -d "${SRCROOT}/.." ]; then
  echo "warning: SRCROOT not set or invalid; skipping SPM asset codegen."
  exit 0
fi
VERA_DIR="$(cd "${SRCROOT}/.." && pwd)"
SCRIPT="${VERA_DIR}/Scripts/generate-spm-assets.py"

if [ ! -f "$SCRIPT" ]; then
  echo "warning: ${SCRIPT} not found; skipping SPM asset codegen."
  exit 0
fi

# If the Tuist assets aren't generated yet (e.g. first configure), skip quietly.
if [ ! -f "${VERA_DIR}/VERACommonUI/Derived/Sources/TuistAssets+VERACommonUI.swift" ]; then
  echo "⏭️  TuistAssets not generated yet; skipping (will run on next build)."
  exit 0
fi

cd "${VERA_DIR}"
"$PYTHON_CMD" "Scripts/generate-spm-assets.py"

SPM_ASSETS_FILE="${VERA_DIR}/VERACommonUI/VERACommonUI/Generated/SPMAssets+VERACommonUI.swift"
if [ -f "$SPM_ASSETS_FILE" ]; then
  echo "✅ SPM assets generated → ${SPM_ASSETS_FILE}"
else
  echo "warning: generate-spm-assets.py ran but ${SPM_ASSETS_FILE} was not found."
fi
