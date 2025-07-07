#!/bin/bash

# Test script for VERA workspace
# By default, only runs fast core tests
# Use -ui flag to also run UI tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

RUN_UI_TESTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -ui|--ui-tests)
      RUN_UI_TESTS=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -ui, --ui-tests   Run UI tests (slow)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo "🧪 Starting VERA Tests..."
echo "=========================================="

# Always run core tests first (fast)
echo "📱 Running Core Tests (Fast)..."
"$SCRIPT_DIR/test-core.sh"

if [ "$RUN_UI_TESTS" = true ]; then
  echo ""
  echo "🎮 Running UI Tests (Slow)..."
  echo "⚠️  This may take several minutes..."
  "$SCRIPT_DIR/test-ui.sh"
else
  echo ""
  echo "⏭️  Skipping UI Tests (use -ui flag to run them)"
  echo "   UI tests are disabled by default for faster CI"
fi

echo ""
echo "✅ All requested tests completed!"
echo "=========================================="
