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

# Check if coverage reports exist
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
if [ ! -d "$COVERAGE_DIR" ]; then
    echo -e "${YELLOW}⚠️  No coverage reports found. Generating them first...${NC}"
    if ! "$SCRIPT_DIR/generate-coverage.sh"; then
        echo -e "${YELLOW}⚠️  Coverage generation failed, creating minimal report...${NC}"
        mkdir -p "$COVERAGE_DIR"
        echo '{"coveredLines":0,"executableLines":0,"lineCoverage":0,"targets":[]}' > "$COVERAGE_DIR/coverage.json"
    fi
fi

# Ensure we have a coverage file
if [ ! -f "$COVERAGE_DIR/coverage.json" ]; then
    echo -e "${YELLOW}⚠️  No coverage data found. Trying to run tests...${NC}"
    if "$SCRIPT_DIR/test-core.sh" && "$SCRIPT_DIR/generate-coverage.sh"; then
        echo -e "${GREEN}✅ Coverage generated successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Test execution failed, creating minimal coverage report...${NC}"
        mkdir -p "$COVERAGE_DIR"
        echo '{"coveredLines":0,"executableLines":0,"lineCoverage":0,"targets":[]}' > "$COVERAGE_DIR/coverage.json"
    fi
fi

echo -e "${BLUE}📊 Found coverage reports:${NC}"
ls -la "$COVERAGE_DIR/" 2>/dev/null || echo "No coverage files found"

# Change to project root for sonar-scanner
cd "$PROJECT_ROOT"

# Run SonarCloud analysis
echo -e "${BLUE}☁️  Running SonarCloud analysis...${NC}"
sonar-scanner \
    -Dsonar.projectKey=Dsonar.projectKey=Vonage_vonage-video-ios-app \
    -Dsonar.organization=vonage \
    -Dsonar.sources=VERA/VERA,VERA/VERACore/VERACore,VERA/VERAOpenTok/VERAOpenTok \
    -Dsonar.tests=VERA/VERATests,VERA/VERACore/VERACoreTests,VERA/VERAOpenTok/VERAOpenTokTests,VERA/VERAUITests \
    -Dsonar.swift.coverage.reportPaths=coverage-reports/coverage.json \
    -Dsonar.host.url=https://sonarcloud.io \
    -Dsonar.token=$SONAR_TOKEN \
    -Dsonar.verbose=false

echo -e "${GREEN}✅ SonarCloud analysis completed!${NC}"
echo -e "${BLUE}📊 View results at: https://sonarcloud.io/project/overview?id=vonage-video-ios-app${NC}"
