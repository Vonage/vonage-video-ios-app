#!/bin/bash

set -e

echo "🧪 Running VERA Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    echo -e "${RED}❌ swift-format is not installed. Please install it first:${NC}"
    echo "   brew install swift-format"
    exit 1
fi

# Check code formatting
echo -e "${YELLOW}🔍 Checking code formatting...${NC}"
FORMAT_ISSUES=""
FORMAT_DETAILS=""
while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        # Check if the file would be changed by swift-format
        DIFF_OUTPUT=$(swift-format format --configuration .swift-format "$file" | diff -u "$file" - 2>/dev/null)
        if [ $? -ne 0 ]; then
            FORMAT_ISSUES="$FORMAT_ISSUES$file needs formatting\n"
            FORMAT_DETAILS="$FORMAT_DETAILS\n📄 $file:\n$DIFF_OUTPUT\n"
        fi
    fi
done < <(find ./VERA -name "*.swift" \
    -not -path "./build/*" \
    -not -path "./.build/*" \
    -not -path "./DerivedData/*" \
    -not -path "./Pods/*" \
    -not -path "./Carthage/*" \
    -not -path "./vendor/*" -print0)

if [ -n "$FORMAT_ISSUES" ]; then
    echo -e "${RED}❌ Format issues found:${NC}"
    echo -e "$FORMAT_ISSUES"
    echo ""
    echo -e "${YELLOW}🔍 Detailed differences:${NC}"
    echo -e "$FORMAT_DETAILS"
    echo ""
    echo -e "${YELLOW}💡 To fix formatting issues, run:${NC}"
    echo "   find ./VERA -name '*.swift' | xargs swift-format format --in-place --configuration .swift-format"
    exit 1
fi

echo -e "${GREEN}✅ Code formatting is correct${NC}"

# Clean build folder
echo -e "${YELLOW}🧹 Cleaning build folder...${NC}"
rm -rf ./DerivedData

# Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
xcodebuild test \
    -scheme VERA \
    -project VERA/VERA.xcodeproj \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
    -enableCodeCoverage YES \
    -derivedDataPath ./DerivedData \
    -quiet

echo -e "${GREEN}✅ All tests passed!${NC}"

# Generate simple coverage report
if [ -d "./DerivedData/Build/ProfileData" ]; then
    echo -e "${YELLOW}📊 Generating coverage report...${NC}"
    xcrun xccov view --report --json ./DerivedData/Build/ProfileData/*/Coverage.profdata > coverage.json 2>/dev/null || true
    echo -e "${GREEN}✅ Coverage report generated in coverage.json${NC}"
fi

echo -e "${GREEN}🎉 All checks passed successfully!${NC}"
