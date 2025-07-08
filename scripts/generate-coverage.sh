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

# Check if slather is installed
SLATHER_CMD=""
if command -v slather &> /dev/null; then
    SLATHER_CMD="slather"
    USE_SLATHER=true
elif [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
    # Test if bundle exec slather works
    if bundle exec slather version &> /dev/null; then
        SLATHER_CMD="bundle exec slather"
        USE_SLATHER=true
    else
        echo -e "${YELLOW}⚠️  Slather via bundler has issues (nokogiri dependency). Falling back to xccov...${NC}"
        USE_SLATHER=false
    fi
else
    echo -e "${YELLOW}⚠️  slather not found. Falling back to xccov...${NC}"
    USE_SLATHER=false
fi

# Find the most recent test results
DERIVED_DATA_PATH="$PROJECT_ROOT/DerivedData"
XCRESULT_PATH=""

# Create coverage reports directory first
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
mkdir -p "$COVERAGE_DIR"

# Look for test results in multiple locations
if [ -d "$DERIVED_DATA_PATH/Logs/Test" ]; then
    XCRESULT_PATH=$(find "$DERIVED_DATA_PATH/Logs/Test" -name "*.xcresult" -type d | head -1)
fi

# Check for TestResults.xcresult (specific from CI)
if [ -z "$XCRESULT_PATH" ] && [ -d "$DERIVED_DATA_PATH/TestResults.xcresult" ]; then
    XCRESULT_PATH="$DERIVED_DATA_PATH/TestResults.xcresult"
fi

# Check for any .xcresult in DerivedData
if [ -z "$XCRESULT_PATH" ] && [ -d "$DERIVED_DATA_PATH" ]; then
    XCRESULT_PATH=$(find "$DERIVED_DATA_PATH" -name "*.xcresult" -type d 2>/dev/null | head -1)
fi

if [ -z "$XCRESULT_PATH" ] || [ ! -d "$XCRESULT_PATH" ]; then
    echo -e "${YELLOW}⚠️  No test results found in expected locations${NC}"
    if [ -d "$DERIVED_DATA_PATH" ]; then
        echo -e "${BLUE}🔍 Available test results:${NC}"
        find "$DERIVED_DATA_PATH" -name "*.xcresult" -type d 2>/dev/null || echo "   No .xcresult files found"
    else
        echo -e "${BLUE}🔍 DerivedData directory does not exist${NC}"
    fi
    
    echo -e "${YELLOW}⚠️  Creating minimal coverage report...${NC}"
    echo '{"coveredLines":0,"executableLines":0,"lineCoverage":0,"targets":[]}' > "$COVERAGE_DIR/coverage.json"
    echo -e "${GREEN}✅ Minimal coverage report created${NC}"
    exit 0
fi

echo -e "${BLUE}📈 Found test results: $(basename "$XCRESULT_PATH")${NC}"

# Try to generate coverage with Slather first (preferred for SonarCloud)
if [ "$USE_SLATHER" = true ]; then
    echo -e "${BLUE}🔄 Generating coverage with Slather (SonarCloud-optimized)...${NC}"
    cd "$PROJECT_ROOT"
    
    # Generate SonarQube XML format
    if $SLATHER_CMD coverage \
        --sonarqube-xml \
        --output-directory "$COVERAGE_DIR" \
        --workspace VERA/VERA.xcworkspace \
        --scheme VERA \
        --binary-basename VERA \
        --source-directory . \
        VERA/VERA.xcodeproj 2>/dev/null; then
        echo -e "${GREEN}✅ Generated SonarQube XML with Slather${NC}"
        
        # Also generate cobertura format as backup
        $SLATHER_CMD coverage \
            --cobertura-xml \
            --output-directory "$COVERAGE_DIR" \
            --workspace VERA/VERA.xcworkspace \
            --scheme VERA \
            --binary-basename VERA \
            --source-directory . \
            VERA/VERA.xcodeproj 2>/dev/null || echo -e "${YELLOW}⚠️  Cobertura generation failed${NC}"
            
        echo -e "${GREEN}✅ Slather coverage generation completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Slather failed, falling back to xccov...${NC}"
        USE_SLATHER=false
    fi
fi

# Fallback to xccov if Slather failed or is not available
if [ "$USE_SLATHER" = false ]; then
    echo -e "${BLUE}📊 Generating coverage with xccov...${NC}"
    
    # Extract coverage data using xcrun
    if xcrun xccov view --report --json "$XCRESULT_PATH" > "$COVERAGE_DIR/coverage.json" 2>/dev/null; then
        echo -e "${GREEN}✅ Generated coverage.json with xccov${NC}"
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
fi

# Generate a simple text report for human reading
if [ -f "$COVERAGE_DIR/coverage.json" ] || [ -f "$COVERAGE_DIR/sonarqube-generic-coverage.xml" ]; then
    echo -e "${BLUE}📊 Generating text summary...${NC}"
    
    # Try to extract basic coverage info
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
import sys
import os

coverage_dir = '$COVERAGE_DIR'

# Check for different coverage formats
formats_found = []
if os.path.exists(os.path.join(coverage_dir, 'sonarqube-generic-coverage.xml')):
    formats_found.append('SonarQube XML')
if os.path.exists(os.path.join(coverage_dir, 'cobertura.xml')):
    formats_found.append('Cobertura XML')
if os.path.exists(os.path.join(coverage_dir, 'coverage.json')):
    formats_found.append('JSON')

print('📊 Coverage Summary Generated')
print('   Formats: ' + ', '.join(formats_found) if formats_found else 'Basic coverage')
print('   Location: coverage-reports/')
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
echo ""
echo -e "${BLUE}💡 To install Slather for better SonarCloud integration:${NC}"
echo "   gem install slather"
