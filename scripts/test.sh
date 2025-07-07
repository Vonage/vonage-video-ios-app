#!/bin/bash

# Test script for VERA workspace
# By default, only runs fast core tests
# Use -ui flag to also run UI tests
# Use -coverage flag to generate coverage reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

RUN_UI_TESTS=false
GENERATE_COVERAGE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -ui|--ui-tests)
      RUN_UI_TESTS=true
      shift
      ;;
    -coverage|--coverage)
      GENERATE_COVERAGE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -ui, --ui-tests   Run UI tests (slow)"
      echo "  -coverage, --coverage   Generate coverage reports"
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
if [ "$GENERATE_COVERAGE" = true ]; then
  "$SCRIPT_DIR/test-core.sh" -coverage
else
  "$SCRIPT_DIR/test-core.sh"
fi

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

if [ "$GENERATE_COVERAGE" = true ]; then
  echo ""
  echo "📊 Coverage reports generated during test execution"
  echo "   To upload to SonarCloud: export SONAR_TOKEN=token && ./scripts/upload-sonarcloud.sh"
else
  echo ""
  echo "📊 To generate coverage reports: ./scripts/test.sh -coverage"
fi

echo ""
echo "✅ All requested tests completed!"
echo "=========================================="
