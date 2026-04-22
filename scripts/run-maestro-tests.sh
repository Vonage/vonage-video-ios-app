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

# ============================================================================
# 1. Check Prerequisites
# ============================================================================

echo -e "${BLUE}🔍 Checking prerequisites...${NC}\n"

# Check Maestro installation
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}❌ Maestro is not installed${NC}"
    echo -e "${YELLOW}📥 Install with: curl -Ls \"https://get.maestro.mobile.dev\" | bash${NC}"
    echo -e "${YELLOW}   Then add to PATH: export PATH=\"\$HOME/.maestro/bin:\$PATH\"${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Maestro $(maestro --version) installed${NC}"

# Check Java installation (required by Maestro)
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ Java is not installed (required by Maestro)${NC}"
    echo -e "${YELLOW}📥 Install with: brew install openjdk@17${NC}"
    echo -e "${YELLOW}   Then set JAVA_HOME: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)${NC}"
    exit 1
fi

# Validate JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠️  JAVA_HOME not set, attempting to auto-detect Java 17...${NC}"
    if /usr/libexec/java_home -v 17 &> /dev/null; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo -e "${GREEN}✓ Auto-detected JAVA_HOME: $JAVA_HOME${NC}"
    else
        echo -e "${RED}❌ Java 17 not found${NC}"
        echo -e "${YELLOW}📥 Install with: brew install openjdk@17${NC}"
        exit 1
    fi
elif [ ! -d "$JAVA_HOME" ]; then
    echo -e "${RED}❌ JAVA_HOME points to invalid directory: $JAVA_HOME${NC}"
    echo -e "${YELLOW}Fix with: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Java $(java -version 2>&1 | grep version | cut -d'"' -f2) detected${NC}"

# Check if .maestro/flows directory exists
if [ ! -d ".maestro/flows" ]; then
    echo -e "${RED}❌ .maestro/flows directory not found${NC}"
    echo -e "${YELLOW}📁 Create it with: mkdir -p .maestro/flows${NC}"
    echo -e "${YELLOW}   Then add test flows (YAML files)${NC}"
    exit 1
fi

# Check if there are any test flows
FLOW_COUNT=$(find .maestro/flows -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
if [ "$FLOW_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No test flows found in .maestro/flows${NC}"
    echo -e "${YELLOW}📝 Add at least one .yaml or .yml file in .maestro/flows/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found $FLOW_COUNT test flow(s)${NC}"

# Check Tuist installation
if ! command -v tuist &> /dev/null; then
    echo -e "${RED}❌ Tuist is not installed${NC}"
    echo -e "${YELLOW}📥 Install with: curl -Ls https://install.tuist.io | bash${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tuist $(tuist version 2>/dev/null || echo 'installed') detected${NC}"

echo ""

# ============================================================================
# 2. Configuration
# ============================================================================

DEVICE=${SIMULATOR_DEVICE:-"iPhone 17"}
APP_SCHEME=${APP_SCHEME:-"VERA"}
WORKSPACE="VERA/VERA.xcworkspace"
BUILD_DIR="DerivedData"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Device:     ${GREEN}$DEVICE${NC}"
echo -e "  Scheme:     ${GREEN}$APP_SCHEME${NC}"
echo -e "  Workspace:  ${GREEN}$WORKSPACE${NC}"
echo ""

# ============================================================================
# 3. Check Required Environment Variables
# ============================================================================

echo -e "${BLUE}🔍 Checking environment variables...${NC}\n"

MISSING_VARS=()

if [ -z "$BASE_API_URL" ]; then
    MISSING_VARS+=("BASE_API_URL")
fi

if [ -z "$DEVELOPMENT_TEAM" ]; then
    MISSING_VARS+=("DEVELOPMENT_TEAM")
fi

if [ -z "$MARKETING_VERSION" ]; then
    MISSING_VARS+=("MARKETING_VERSION")
fi

if [ -z "$CURRENT_PROJECT_VERSION" ]; then
    MISSING_VARS+=("CURRENT_PROJECT_VERSION")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Missing environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "   ${RED}✗${NC} $var"
    done
    echo ""
    echo -e "${YELLOW}Set them with:${NC}"
    echo -e "  export BASE_API_URL=https://api.example.net/"
    echo -e "  export DEVELOPMENT_TEAM=AB0C12DE34"
    echo -e "  export MARKETING_VERSION=1.1"
    echo -e "  export CURRENT_PROJECT_VERSION=1"
    echo ""
    echo -e "${BLUE}ℹ️  Continuing anyway (using existing generated files if available)...${NC}\n"
else
    echo -e "${GREEN}✓ All required environment variables set${NC}\n"
fi

# ============================================================================
# 4. Check/Generate Workspace
# ============================================================================

if [ ! -f "$WORKSPACE/contents.xcworkspacedata" ]; then
    echo -e "${YELLOW}📦 Workspace not found, generating with Tuist...${NC}\n"
    
    cd VERA
    
    # Generate environment constants if env vars are set
    if [ ${#MISSING_VARS[@]} -eq 0 ]; then
        echo -e "${BLUE}🔧 Generating environment constants...${NC}"
        ./Scripts/generateEnvironmentConstants.sh
        
        echo -e "${BLUE}🔧 Generating signing configuration...${NC}"
        ./Scripts/regenerateSigningConfig.sh
        
        if [ -f "./Scripts/generate-app-config.py" ]; then
            echo -e "${BLUE}🔧 Generating app config...${NC}"
            python3 ./Scripts/generate-app-config.py
        fi
        
        if [ -f "./Scripts/generate-app-theme.py" ]; then
            echo -e "${BLUE}🔧 Generating theme assets...${NC}"
            python3 ./Scripts/generate-app-theme.py
        fi
        
        echo ""
    fi
    
    echo -e "${BLUE}🏗️  Running tuist generate...${NC}"
    tuist generate
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Tuist generate failed${NC}"
        cd ..
        exit 1
    fi
    
    cd ..
    echo -e "${GREEN}✓ Workspace generated successfully${NC}\n"
else
    echo -e "${GREEN}✓ Workspace exists${NC}\n"
fi

# ============================================================================
# 5. Build or Find App
# ============================================================================

APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "VERA.app" -print -quit 2>/dev/null || echo "")

if [ -z "$APP_PATH" ]; then
    echo -e "${YELLOW}🔨 Building VERA app (this may take a few minutes)...${NC}\n"
    
    # Verify workspace exists before building
    if [ ! -f "$WORKSPACE/contents.xcworkspacedata" ]; then
        echo -e "${RED}❌ Workspace still not found at $WORKSPACE${NC}"
        exit 1
    fi
    
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
    
    BUILD_RESULT=$?
    
    if [ $BUILD_RESULT -ne 0 ]; then
        echo -e "${RED}❌ Build failed (exit code: $BUILD_RESULT)${NC}"
        echo -e "${YELLOW}💡 Try cleaning and regenerating:${NC}"
        echo -e "   cd VERA && tuist clean && tuist generate && cd .."
        echo -e "   rm -rf $BUILD_DIR"
        exit 1
    fi
    
    APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "VERA.app" -print -quit)
    
    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}❌ VERA.app not found after build${NC}"
        echo -e "${YELLOW}Expected location: $BUILD_DIR/Build/Products/Debug-iphonesimulator/VERA.app${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${GREEN}✓ Using existing app build${NC}"
fi

echo -e "${BLUE}📱 App path: $APP_PATH${NC}\n"

# ============================================================================
# 6. Simulator Management
# ============================================================================

echo -e "${YELLOW}🚀 Managing simulator '$DEVICE'...${NC}"

# Check if simulator exists
if ! xcrun simctl list devices | grep -q "$DEVICE"; then
    echo -e "${RED}❌ Simulator '$DEVICE' not found${NC}"
    echo -e "${YELLOW}Available simulators:${NC}"
    xcrun simctl list devices | grep "iPhone"
    echo ""
    echo -e "${YELLOW}💡 Use a different device with: SIMULATOR_DEVICE=\"iPhone 15\" ./scripts/run-maestro-tests.sh${NC}"
    exit 1
fi

# Boot simulator
BOOT_OUTPUT=$(xcrun simctl boot "$DEVICE" 2>&1 || true)
if echo "$BOOT_OUTPUT" | grep -q "Unable to boot device in current state: Booted"; then
    echo -e "${BLUE}ℹ️  Simulator already booted${NC}"
elif echo "$BOOT_OUTPUT" | grep -q "Unable to boot"; then
    echo -e "${RED}❌ Failed to boot simulator: $BOOT_OUTPUT${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Simulator booted${NC}"
    sleep 3  # Give simulator time to fully boot
fi

# Install app
echo -e "${YELLOW}📲 Installing VERA app on simulator...${NC}"
INSTALL_OUTPUT=$(xcrun simctl install "$DEVICE" "$APP_PATH" 2>&1)
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
    echo -e "${RED}❌ Failed to install app: $INSTALL_OUTPUT${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App installed successfully${NC}\n"

# ============================================================================
# 7. Run Maestro Tests
# ============================================================================

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

# ============================================================================
# 8. Test Results & Artifacts
# ============================================================================

if [ -d "$HOME/.maestro/tests" ]; then
    LATEST_TEST=$(ls -t "$HOME/.maestro/tests" 2>/dev/null | head -n 1)
    if [ -n "$LATEST_TEST" ]; then
        TEST_DIR="$HOME/.maestro/tests/$LATEST_TEST"
        echo -e "${BLUE}📊 Test Results:${NC}"
        echo -e "   📸 Screenshots: ${GREEN}$TEST_DIR${NC}"
        
        # Check for HTML report
        if [ -f "$TEST_DIR/report.html" ]; then
            echo -e "   📄 HTML Report: ${GREEN}$TEST_DIR/report.html${NC}"
            
            # Offer to open report
            if [ $TEST_RESULT -ne 0 ]; then
                echo -e "\n${YELLOW}💡 Open HTML report to see failure details:${NC}"
                echo -e "   open \"$TEST_DIR/report.html\""
            fi
        fi
        
        echo ""
    fi
fi

# ============================================================================
# 9. Cleanup & Exit
# ============================================================================

if [ $TEST_RESULT -ne 0 ]; then
    echo -e "${YELLOW}🔧 Troubleshooting tips:${NC}"
    echo -e "   1. Check the HTML report for detailed logs and screenshots"
    echo -e "   2. Run with debug: ${BLUE}maestro test .maestro/flows/ --debug${NC}"
    echo -e "   3. Clean build: ${BLUE}rm -rf $BUILD_DIR && cd VERA && tuist clean && tuist generate && cd ..${NC}"
    echo -e "   4. Check simulator logs: ${BLUE}xcrun simctl spawn booted log stream --level=debug${NC}"
    echo ""
fi

exit $TEST_RESULT
