#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   🎭 VERA Maestro UI Test Runner${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check if Maestro is installed
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}❌ Maestro is not installed${NC}"
    echo -e "${YELLOW}📥 Install with: curl -Ls \"https://get.maestro.mobile.dev\" | bash${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Maestro $(maestro --version) installed${NC}\n"

# Configuration
DEVICE=${SIMULATOR_DEVICE:-"iPhone 17"}
APP_SCHEME=${APP_SCHEME:-"VERA"}
WORKSPACE="VERA/VERA.xcworkspace"
BUILD_DIR="DerivedData"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Device:  ${GREEN}$DEVICE${NC}"
echo -e "  Scheme:  ${GREEN}$APP_SCHEME${NC}"
echo ""

# Check if app is already built
APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "VERA.app" -print -quit 2>/dev/null || echo "")

if [ -z "$APP_PATH" ]; then
    echo -e "${YELLOW}🔨 Building VERA app...${NC}"
    
    cd VERA
    
    # Generate project if needed
    if [ ! -f "VERA.xcworkspace/contents.xcworkspacedata" ]; then
        echo -e "${YELLOW}📦 Generating Xcode workspace with Tuist...${NC}"
        tuist generate
    fi
    
    cd ..
    
    # Build
    xcodebuild clean build \
      -workspace "$WORKSPACE" \
      -scheme "$APP_SCHEME" \
      -destination "platform=iOS Simulator,name=$DEVICE" \
      -derivedDataPath "$BUILD_DIR" \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      COMPILER_INDEX_STORE_ENABLE=NO \
      -quiet
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
    
    APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "VERA.app" -print -quit)
fi

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ VERA.app not found in build output${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App found at: $APP_PATH${NC}\n"

# Boot simulator
echo -e "${YELLOW}🚀 Booting simulator '$DEVICE'...${NC}"
xcrun simctl boot "$DEVICE" 2>/dev/null || echo -e "${BLUE}Simulator already booted${NC}"
sleep 2

# Install app
echo -e "${YELLOW}📲 Installing VERA app...${NC}"
xcrun simctl install "$DEVICE" "$APP_PATH"
echo -e "${GREEN}✓ App installed${NC}\n"

# Run Maestro tests
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   🧪 Running Maestro UI Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

maestro test .maestro/flows

TEST_RESULT=$?

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ All Maestro tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed (exit code: $TEST_RESULT)${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Screenshots location
if [ -d "$HOME/.maestro/tests" ]; then
    LATEST_TEST=$(ls -t "$HOME/.maestro/tests" | head -n 1)
    if [ -n "$LATEST_TEST" ]; then
        echo -e "${BLUE}📸 Screenshots: $HOME/.maestro/tests/$LATEST_TEST${NC}\n"
    fi
fi

exit $TEST_RESULT
