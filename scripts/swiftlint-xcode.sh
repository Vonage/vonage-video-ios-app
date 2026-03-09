#!/bin/bash

# SwiftLint Xcode Run Script Phase (Target-Specific)
# 
# This script lints only Swift files belonging to a specific Xcode target,
# avoiding permission errors and unnecessary linting of unrelated files.
#
# Usage in Xcode Run Script Phase:
# ${SRCROOT}/scripts/swiftlint-xcode-target-specific.sh
#
# The script uses Xcode environment variables:
# - SRCROOT: Path to the target's source directory 
# - TARGET_NAME: Name of the current target
# - PROJECT_DIR: Project root directory (fallback for SRCROOT if needed)
#
# Or run manually with:
# SRCROOT=/path/to/target TARGET_NAME=MyTarget ./scripts/swiftlint-xcode-target-specific.sh

echo "🚀 SwiftLint Xcode Run Script Phase (Target-Specific)"

# Check if SwiftLint is disabled via environment variable
if [ "${RUN_SWIFTLINT}" = "NO" ]; then
  echo "⏭️  SwiftLint skipped (RUN_SWIFTLINT=NO)"
  exit 0
fi

# Ensure we have Homebrew in PATH for Xcode Run Script Phases
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Check if SwiftLint is installed
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
    echo "warning: SwiftLint not found. Install it via Homebrew, Mint, or add it to your PATH."
    echo "  brew install swiftlint"
    echo "  mint install realm/SwiftLint"
    exit 0  # Don't fail the build, just warn
fi

echo "✅ Found SwiftLint at: ${SWIFTLINT_CMD}"

# Find project root by looking for .swiftlint.yml
CURRENT_DIR="${SRCROOT}"
PROJECT_ROOT=""

while [ "$CURRENT_DIR" != "/" ] && [ -n "$CURRENT_DIR" ]; do
    if [ -f "$CURRENT_DIR/.swiftlint.yml" ]; then
        PROJECT_ROOT="$CURRENT_DIR"
        break
    fi
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

# Fallback: try common relative paths
if [ -z "$PROJECT_ROOT" ]; then
    for path in "${SRCROOT}" "${SRCROOT}/.." "${SRCROOT}/../.."; do
        if [ -f "$path/.swiftlint.yml" ]; then
            PROJECT_ROOT="$path"
            break
        fi
    done
fi

if [ -z "$PROJECT_ROOT" ]; then
    echo "warning: Could not find .swiftlint.yml config file"
    echo "Running SwiftLint with default configuration on current target only"
    cd "${SRCROOT}"
    $SWIFTLINT_CMD lint "${SRCROOT}"
    exit $?
fi

echo "📁 Project root: ${PROJECT_ROOT}"
echo "🔍 Config: ${PROJECT_ROOT}/.swiftlint.yml"
echo "🎯 Target: ${TARGET_NAME}"
echo "📂 Target source: ${SRCROOT}"

# Change to project root but only lint the specific target directory
cd "${PROJECT_ROOT}"

# Determine the relative path from project root to the target source
RELATIVE_TARGET_PATH=$(realpath --relative-to="${PROJECT_ROOT}" "${SRCROOT}" 2>/dev/null || python3 -c "import os.path; print(os.path.relpath('${SRCROOT}', '${PROJECT_ROOT}'))")

echo "🔍 Linting target-specific path: ${RELATIVE_TARGET_PATH}"

# Find Swift files in the target directory only, excluding problematic paths
SWIFT_FILES_COUNT=$(find "${SRCROOT}" -maxdepth 10 -name "*.swift" -not -path "*/.*" -not -path "*/*.xcodeproj/*" -not -path "*/build/*" -not -path "*/Build/*" -not -path "*/DerivedData/*" -not -path "*/__Snapshots__/*" | wc -l | tr -d ' ')
echo "📊 Found ${SWIFT_FILES_COUNT} Swift files in target directory"

if [ "$SWIFT_FILES_COUNT" -eq 0 ]; then
    echo "⚠️  No Swift files found in target directory, skipping SwiftLint"
    exit 0
fi

# Run SwiftLint on the specific target directory only with explicit file finding
echo "🔍 Running SwiftLint on target-specific Swift files..."

# Create a temporary file list of Swift files to lint (only from SRCROOT, not entire project)
TEMP_FILE_LIST=$(mktemp)
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
    > "${TEMP_FILE_LIST}"

# Check if we have files to lint
if [ ! -s "${TEMP_FILE_LIST}" ]; then
    echo "⚠️  No Swift files found in target directory after filtering, skipping SwiftLint"
    rm -f "${TEMP_FILE_LIST}"
    exit 0
fi

echo "📊 Linting $(wc -l < "${TEMP_FILE_LIST}") Swift files from target directory"

# Run SwiftLint with the file list - only pass files explicitly to avoid directory traversal
cd "${PROJECT_ROOT}"
if [ -s "${TEMP_FILE_LIST}" ]; then
    echo "🔍 Running SwiftLint on $(wc -l < "${TEMP_FILE_LIST}" | tr -d ' ') target-specific files..."
    
    # Pass files directly to SwiftLint to avoid directory traversal issues
    cat "${TEMP_FILE_LIST}" | xargs $SWIFTLINT_CMD lint --quiet
    exit_code=$?
else
    echo "⚠️  No files to lint after filtering"
    exit_code=0
fi

# Clean up temporary file
rm -f "${TEMP_FILE_LIST}"

if [ $exit_code -eq 0 ]; then
    echo "✅ SwiftLint passed for target ${TARGET_NAME}"
else
    echo "❌ SwiftLint found violations in target ${TARGET_NAME}"
fi

exit $exit_code
