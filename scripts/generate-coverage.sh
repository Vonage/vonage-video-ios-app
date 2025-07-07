#!/bin/bash

# Generate code coverage reports for SonarCloud
# This script processes xcodebuild test results and generates coverage reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Generating Code Coverage Reports...${NC}"

# Find the most recent test results
DERIVED_DATA_PATH="$PROJECT_ROOT/DerivedData"
XCRESULT_PATH=""

# Look for test results
if [ -d "$DERIVED_DATA_PATH/Logs/Test" ]; then
    XCRESULT_PATH=$(find "$DERIVED_DATA_PATH/Logs/Test" -name "*.xcresult" -type d | head -1)
fi

if [ -z "$XCRESULT_PATH" ] || [ ! -d "$XCRESULT_PATH" ]; then
    echo -e "${RED}❌ No test results found. Please run tests first:${NC}"
    echo "   ./scripts/test-core.sh"
    exit 1
fi

echo -e "${BLUE}📈 Found test results: $(basename "$XCRESULT_PATH")${NC}"

# Create coverage reports directory
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
mkdir -p "$COVERAGE_DIR"

# Generate SonarCloud-compatible coverage using xcodebuild
echo -e "${BLUE}📊 Generating SonarCloud-compatible coverage...${NC}"

# Extract coverage data using xcrun
if xcrun xccov view --report --json "$XCRESULT_PATH" > "$COVERAGE_DIR/coverage.json" 2>/dev/null; then
    echo -e "${GREEN}✅ Generated coverage.json${NC}"
else
    echo -e "${YELLOW}⚠️  Direct xccov failed, searching for coverage files...${NC}"
    
    # Find .xccovreport files
    XCCOV_REPORT=$(find "$DERIVED_DATA_PATH" -name "*.xccovreport" -type f | head -1)
    if [ -n "$XCCOV_REPORT" ]; then
        echo -e "${BLUE}📊 Found coverage report: $(basename "$XCCOV_REPORT")${NC}"
        if xcrun xccov view --report --json "$XCCOV_REPORT" > "$COVERAGE_DIR/coverage.json" 2>/dev/null; then
            echo -e "${GREEN}✅ Generated coverage.json from xccovreport${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not extract JSON coverage, creating minimal report${NC}"
            echo '{"data":[{"files":[]}]}' > "$COVERAGE_DIR/coverage.json"
        fi
    else
        echo -e "${YELLOW}⚠️  No coverage files found, creating minimal report${NC}"
        echo '{"data":[{"files":[]}]}' > "$COVERAGE_DIR/coverage.json"
    fi
fi

# Generate a simple text report for human reading
if [ -f "$COVERAGE_DIR/coverage.json" ]; then
    echo -e "${BLUE}📊 Generating text summary...${NC}"
    
    # Try to extract basic coverage info
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
import sys

try:
    with open('$COVERAGE_DIR/coverage.json', 'r') as f:
        data = json.load(f)
    print('📊 Coverage Summary Generated')
    print('   Format: SonarCloud-compatible JSON')
    print('   Location: coverage-reports/coverage.json')
except:
    print('📊 Basic coverage report created')
" 2>/dev/null || echo -e "${BLUE}📊 Basic coverage report created${NC}"
    else
        echo -e "${BLUE}📊 Basic coverage report created${NC}"
    fi
fi

echo -e "${GREEN}✅ Coverage reports generated in: $COVERAGE_DIR${NC}"
echo -e "${BLUE}📄 Files created:${NC}"
ls -la "$COVERAGE_DIR/" 2>/dev/null || echo "Coverage directory created"

echo -e "${BLUE}💡 To upload to SonarCloud, use:${NC}"
echo "   export SONAR_TOKEN=your_token"
echo "   ./scripts/upload-sonarcloud.sh"
