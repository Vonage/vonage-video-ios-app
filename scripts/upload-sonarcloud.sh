#!/bin/bash

# Upload coverage and analysis results to SonarCloud
# This script can be used for local analysis or manual uploads

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}☁️  SonarCloud Upload Script${NC}"
echo -e "${BLUE}================================${NC}"

# Check if sonar-scanner is installed
if ! command -v sonar-scanner &> /dev/null; then
    echo -e "${RED}❌ sonar-scanner not found. Please install it first:${NC}"
    echo ""
    echo "   # Using Homebrew (macOS)"
    echo "   brew install sonar-scanner"
    echo ""
    echo "   # Using NPM"
    echo "   npm install -g sonar-scanner"
    echo ""
    echo "   # Manual installation"
    echo "   https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/"
    exit 1
fi

# Check if slather is installed
SLATHER_CMD=""
SLATHER_AVAILABLE=false

if command -v slather &> /dev/null; then
    SLATHER_CMD="slather"
    SLATHER_AVAILABLE=true
elif [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
    # Test if bundle exec slather works
    if bundle exec slather version &> /dev/null; then
        SLATHER_CMD="bundle exec slather"
        SLATHER_AVAILABLE=true
    else
        echo -e "${YELLOW}⚠️  Slather via bundler has issues (nokogiri dependency).${NC}"
        SLATHER_CMD=""
        SLATHER_AVAILABLE=false
    fi
fi

if [ "$SLATHER_AVAILABLE" = false ]; then
    echo -e "${YELLOW}⚠️  Slather not available, will use existing coverage reports or skip coverage${NC}"
    echo -e "${BLUE}💡 To enable XML coverage reports, install Slather:${NC}"
    echo "   sudo gem install slather"
    echo ""
    echo "Continuing with available coverage reports..."
fi

# Check if SONAR_TOKEN is set
if [ -z "$SONAR_TOKEN" ]; then
    echo -e "${RED}❌ SONAR_TOKEN environment variable not set${NC}"
    echo ""
    echo "Please set your SonarCloud token:"
    echo "   export SONAR_TOKEN=your_token_here"
    echo ""
    echo "You can get your token from: https://sonarcloud.io/account/security"
    exit 1
fi

# Check if coverage reports exist and generate with Slather
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
DERIVED_DATA_PATH="$PROJECT_ROOT/DerivedData"

echo -e "${BLUE}📊 Generating SonarCloud-compatible coverage reports...${NC}"

# Create coverage directory if it doesn't exist
mkdir -p "$COVERAGE_DIR"

# Look for coverage data in DerivedData
COVERAGE_DATA_FOUND=false
if [ -d "$DERIVED_DATA_PATH" ]; then
    XCRESULT_FILES=$(find "$DERIVED_DATA_PATH" -name "*.xcresult" 2>/dev/null || true)
    if [ -n "$XCRESULT_FILES" ]; then
        echo -e "${GREEN}✅ Found xcresult files for coverage analysis${NC}"
        COVERAGE_DATA_FOUND=true
    fi
fi

# If no coverage data found, try to generate it
if [ "$COVERAGE_DATA_FOUND" = false ]; then
    echo -e "${YELLOW}⚠️  No coverage data found. Running tests to generate coverage...${NC}"
    if ! "$SCRIPT_DIR/test-core.sh"; then
        echo -e "${RED}❌ Test execution failed${NC}"
        exit 1
    fi
fi

# Generate SonarCloud-compatible coverage reports
cd "$PROJECT_ROOT"

if [ "$SLATHER_AVAILABLE" = true ]; then
    echo -e "${BLUE}🔄 Converting coverage data with Slather...${NC}"
    
    # Generate SonarQube XML format
    $SLATHER_CMD coverage \
        --sonarqube-xml \
        --output-directory "$COVERAGE_DIR" \
        --workspace VERA/VERA.xcworkspace \
        --scheme VERA \
        --binary-basename VERA \
        --source-directory . \
        VERA/VERA.xcodeproj
    
    # Also generate cobertura format as backup
    $SLATHER_CMD coverage \
        --cobertura-xml \
        --output-directory "$COVERAGE_DIR" \
        --workspace VERA/VERA.xcworkspace \
        --scheme VERA \
        --binary-basename VERA \
        --source-directory . \
        VERA/VERA.xcodeproj
else
    echo -e "${YELLOW}⚠️  Slather not available, using existing coverage reports${NC}"
    # Check if we need to generate coverage with xccov as fallback
    if [ ! -f "$COVERAGE_DIR/coverage.json" ]; then
        echo -e "${BLUE}📊 Generating coverage with xccov fallback...${NC}"
        "$SCRIPT_DIR/generate-coverage.sh"
    fi
fi

echo -e "${BLUE}📊 Found coverage reports:${NC}"
ls -la "$COVERAGE_DIR/" 2>/dev/null || echo "No coverage files found"

# Change to project root for sonar-scanner
cd "$PROJECT_ROOT"

# Run SonarCloud analysis
echo -e "${BLUE}☁️  Running SonarCloud analysis...${NC}"

# Determine which coverage format to use based on available files
COVERAGE_PARAM=""
if [ -f "$COVERAGE_DIR/sonarqube-generic-coverage.xml" ]; then
    COVERAGE_PARAM="-Dsonar.coverageReportPaths=coverage-reports/sonarqube-generic-coverage.xml"
    echo -e "${GREEN}✅ Using SonarQube XML coverage format${NC}"
elif [ -f "$COVERAGE_DIR/coverage.json" ]; then
    COVERAGE_PARAM="-Dsonar.swift.coverage.reportPaths=coverage-reports/coverage.json"
    echo -e "${YELLOW}⚠️  Using fallback JSON coverage format${NC}"
else
    echo -e "${YELLOW}⚠️  No coverage reports found, running analysis without coverage${NC}"
fi

sonar-scanner \
    -Dsonar.projectKey=Vonage_vonage-video-ios-app \
    -Dsonar.organization=vonage \
    -Dsonar.sources=VERA/VERA,VERA/VERACore/VERACore,VERA/VERAOpenTok/VERAOpenTok \
    -Dsonar.tests=VERA/VERATests,VERA/VERACore/VERACoreTests,VERA/VERAOpenTok/VERAOpenTokTests,VERA/VERAUITests \
    $COVERAGE_PARAM \
    -Dsonar.host.url=https://sonarcloud.io \
    -Dsonar.token=$SONAR_TOKEN \
    -Dsonar.verbose=false

echo -e "${GREEN}✅ SonarCloud analysis completed!${NC}"
echo -e "${BLUE}📊 View results at: https://sonarcloud.io/project/overview?id=vonage-video-ios-app${NC}"
