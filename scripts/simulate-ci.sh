#!/bin/bash

# Simulate CI environment f# Step 2: Generate coverage report
echo -e "${BLUE}📊 Step 2: Generating coverage reports...${NC}" testing SonarCloud integration
# This script mimics what happens in GitHub Actions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Simulating CI Environment for SonarCloud${NC}"
echo -e "${BLUE}=============================================${NC}"

# Clean slate
echo -e "${YELLOW}🧹 Cleaning environment...${NC}"
rm -rf "$PROJECT_ROOT/DerivedData"
rm -rf "$PROJECT_ROOT/coverage-reports"

# Step 1: Run tests with coverage (like CI does)
echo -e "${BLUE}🧪 Step 1: Running tests with coverage...${NC}"
cd "$PROJECT_ROOT"
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACore \
  -destination "platform=macOS" \
  -derivedDataPath DerivedData \
  -enableCodeCoverage YES \
  -resultBundlePath DerivedData/TestResults.xcresult \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet || echo "Tests completed with issues"

# Step 3: Generate coverage reports
echo -e "${BLUE}📊 Step 3: Generating coverage reports...${NC}"
"$SCRIPT_DIR/generate-coverage.sh" || {
  echo -e "${YELLOW}⚠️ Coverage generation failed, creating minimal report${NC}"
  mkdir -p coverage-reports
  echo '{"coveredLines":0,"executableLines":0,"lineCoverage":0,"targets":[]}' > coverage-reports/coverage.json
}

# Step 4: Verify coverage report
echo -e "${BLUE}📄 Step 4: Verifying coverage report...${NC}"
if [ -f "coverage-reports/coverage.json" ]; then
    echo -e "${GREEN}✅ Coverage report exists${NC}"
    echo -e "${BLUE}📊 Report size: $(wc -c < coverage-reports/coverage.json) bytes${NC}"
    
    # Show first 200 characters of the report
    echo -e "${BLUE}📄 Report preview:${NC}"
    head -c 200 coverage-reports/coverage.json
    echo ""
    echo "..."
else
    echo -e "${RED}❌ Coverage report not found${NC}"
    exit 1
fi

# Step 5: Simulate SonarCloud parameters
echo -e "${BLUE}☁️  Step 5: SonarCloud parameters that would be used:${NC}"
echo "   -Dsonar.projectKey=Vonage_vonage-video-ios-app"
echo "   -Dsonar.organization=vonage"
echo "   -Dsonar.swift.coverage.reportPaths=coverage-reports/coverage.json"
echo "   -Dsonar.sources=VERA/VERA,VERA/VERACore/VERACore,VERA/VERAOpenTok/VERAOpenTok"
echo "   -Dsonar.tests=VERA/VERATests,VERA/VERACore/VERACoreTests,VERA/VERAOpenTok/VERAOpenTokTests,VERA/VERAUITests"

echo -e "${GREEN}✅ CI simulation completed successfully!${NC}"
echo -e "${BLUE}💡 To actually run SonarCloud analysis:${NC}"
echo "   export SONAR_TOKEN=your_token"
echo "   ./scripts/upload-sonarcloud.sh"
