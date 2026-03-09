#!/bin/bash

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERA_DIR="$SCRIPT_DIR/.."

# Validate VERA directory exists
if [ ! -d "$VERA_DIR/VERAApp" ]; then
    echo "❌ Error: VERA directory structure not found at $VERA_DIR"
    echo "   Expected to find VERAApp/ folder"
    exit 1
fi

cd "$VERA_DIR"

mkdir -p Config
echo "DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM" > Config/Signing.xcconfig
echo "MARKETING_VERSION = 1.0" >> Config/Signing.xcconfig
echo "CURRENT_PROJECT_VERSION = $CURRENT_PROJECT_VERSION" >> Config/Signing.xcconfig

echo "✅ Signing.xcconfig generated"
echo "   Output: Config/Signing.xcconfig"