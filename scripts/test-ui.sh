#!/bin/bash

# UI Tests only script for VERA workspace
# This script only runs UI tests (slow)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🎮 Running UI Tests (This will take several minutes)...${NC}"
echo -e "${YELLOW}⚠️  UI tests are slow and will launch simulators.${NC}"
echo -e "${YELLOW}💡 For fast development, use ./scripts/test-core.sh instead.${NC}"
echo ""

# Skip confirmation if running in CI
if [[ -z "${CI}" ]]; then
    read -p "Do you want to continue with UI tests? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}UI tests cancelled. Use ./scripts/test-core.sh for fast testing.${NC}"
        exit 0
    fi
fi

# Clean build folder
echo -e "${YELLOW}🧹 Cleaning build folder...${NC}"
rm -rf ./DerivedData

# Build first
echo -e "${YELLOW}🔨 Building project...${NC}"
xcodebuild build \
    -workspace VERA/VERA.xcworkspace \
    -scheme VERA \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -derivedDataPath ./DerivedData \
    -skipPackagePluginValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

echo -e "${GREEN}✅ Build completed${NC}"

# Run UI tests with fallback strategy
echo -e "${YELLOW}🧪 Running UI tests (this will take several minutes)...${NC}"
echo -e "${YELLOW}☕ Good time for a coffee break!${NC}"

if xcodebuild test \
    -workspace VERA/VERA.xcworkspace \
    -scheme VERA \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:VERAUITests \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -derivedDataPath ./DerivedData \
    -skipPackagePluginValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO; then
    echo -e "${GREEN}✅ UI tests completed successfully with iPhone 16${NC}"
elif xcodebuild test \
    -workspace VERA/VERA.xcworkspace \
    -scheme VERA \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:VERAUITests \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -derivedDataPath ./DerivedData \
    -skipPackagePluginValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO; then
    echo -e "${GREEN}✅ UI tests completed successfully with iPhone 16 Pro${NC}"
elif xcodebuild test \
    -workspace VERA/VERA.xcworkspace \
    -scheme VERA \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:VERAUITests \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -derivedDataPath ./DerivedData \
    -skipPackagePluginValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO; then
    echo -e "${GREEN}✅ UI tests completed successfully with iPhone 15${NC}"
else
    echo -e "${RED}❌ UI tests failed${NC}"
    echo -e "${YELLOW}Available destinations:${NC}"
    xcodebuild -workspace VERA/VERA.xcworkspace -scheme VERA -showdestinations | grep "iOS Simulator" | head -5
    exit 1
fi

echo -e "${GREEN}🎉 UI tests completed successfully!${NC}"
echo -e "${YELLOW}💡 For faster day-to-day development, use ./scripts/test-core.sh${NC}"
