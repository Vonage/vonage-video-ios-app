#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the root directory (parent of scripts/)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root to ensure paths are correct
cd "$PROJECT_ROOT"

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

# Check & install SwiftLint
if ! command -v swiftlint &> /dev/null; then
    echo -e "${YELLOW}📦 SwiftLint not found, installing...${NC}"
    brew install swiftlint
fi
echo -e "${GREEN}✓ SwiftLint $(swiftlint --version 2>/dev/null | head -n 1) installed${NC}"

# Check Maestro installation
if ! command -v maestro &> /dev/null; then
    echo -e "${YELLOW}📦 Maestro not found, installing...${NC}"
    curl -Ls "https://get.maestro.mobile.dev" | bash
    export PATH="$HOME/.maestro/bin:$PATH"
    echo -e "${GREEN}✓ Maestro installed${NC}"
else
    echo -e "${GREEN}✓ Maestro $(maestro --version) installed${NC}"
fi

# Check and install Java 17 (required by Maestro)
echo -e "${BLUE}🔍 Checking Java 17...${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}⚠️  Java is not installed, attempting to install Java 17...${NC}"
    if command -v brew &> /dev/null; then
        brew install openjdk@17
    else
        echo -e "${RED}❌ Homebrew not found. Cannot install Java 17 automatically.${NC}"
        echo -e "${YELLOW}📥 Install manually with: brew install openjdk@17${NC}"
        exit 1
    fi
fi

# Validate and auto-detect JAVA_HOME
if [ -n "$JAVA_HOME" ] && [ ! -d "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠️  JAVA_HOME is set but invalid ($JAVA_HOME), auto-detecting...${NC}"
    unset JAVA_HOME
fi

if [ -z "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠️  JAVA_HOME not set, attempting to auto-detect Java 17...${NC}"
    if /usr/libexec/java_home -v 17 &> /dev/null; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo -e "${GREEN}✓ Auto-detected JAVA_HOME: $JAVA_HOME${NC}"
    else
        echo -e "${RED}❌ Java 17 not found${NC}"
        echo -e "${YELLOW}📥 Installing Java 17...${NC}"
        brew install openjdk@17
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo -e "${GREEN}✓ Installed and set JAVA_HOME: $JAVA_HOME${NC}"
    fi
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
    echo -e "${YELLOW}📦 Tuist not found, installing...${NC}"
    brew install tuist
    echo -e "${GREEN}✓ Tuist installed${NC}"
else
    echo -e "${GREEN}✓ Tuist installed${NC}"
fi

echo -e "${GREEN}✓ Tuist $(tuist version 2>/dev/null || echo 'installed') detected${NC}"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed${NC}"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✓ $XCODE_VERSION detected${NC}"

echo ""

# ============================================================================
# 2. Configuration & Simulator Detection
# ============================================================================

APP_SCHEME=${APP_SCHEME:-"VERA"}
WORKSPACE="VERA/VERA.xcworkspace"
BUILD_DIR="DerivedData"

# Auto-detect simulator: use env var, or find best available iPhone
if [ -n "$SIMULATOR_DEVICE" ]; then
    DEVICE="$SIMULATOR_DEVICE"
else
    echo -e "${BLUE}🔍 Auto-detecting simulator...${NC}"
    
    if xcrun simctl list devices available | grep -q "iPhone 17"; then
        DEVICE="iPhone 17"
    elif xcrun simctl list devices available | grep -q "iPhone 16 Pro"; then
        DEVICE="iPhone 16 Pro"
    elif xcrun simctl list devices available | grep -q "iPhone 16"; then
        DEVICE="iPhone 16"
    elif xcrun simctl list devices available | grep -q "iPhone 15 Pro"; then
        DEVICE="iPhone 15 Pro"
    elif xcrun simctl list devices available | grep -q "iPhone 15"; then
        DEVICE="iPhone 15"
    else
        DEVICE=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed 's/^ *//' | sed 's/ (.*//')
    fi
    
    if [ -z "$DEVICE" ]; then
        echo -e "${RED}❌ No iPhone simulator found${NC}"
        echo -e "${YELLOW}Available devices:${NC}"
        xcrun simctl list devices available
        exit 1
    fi
fi

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Xcode:      ${GREEN}$XCODE_VERSION${NC}"
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

if [ -f "$WORKSPACE/contents.xcworkspacedata" ]; then
    echo -e "${GREEN}✓ Workspace exists at $WORKSPACE${NC}\n"
else
    echo -e "${YELLOW}📦 Workspace not found, generating...${NC}\n"
    
    echo -e "${BLUE}🔧 Running project generation scripts...${NC}"
    cd VERA
    
    # Generate environment constants (always required)
    if [ -f "./Scripts/generateEnvironmentConstants.sh" ]; then
        chmod +x ./Scripts/generateEnvironmentConstants.sh
        ./Scripts/generateEnvironmentConstants.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to generate environment constants${NC}"
            cd ..
            exit 1
        fi
    fi
    
    # Generate signing configuration (always required)
    if [ -f "./Scripts/regenerateSigningConfig.sh" ]; then
        chmod +x ./Scripts/regenerateSigningConfig.sh
        ./Scripts/regenerateSigningConfig.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to generate signing configuration${NC}"
            cd ..
            exit 1
        fi
    fi
    
    # Generate app config if available
    if [ -f "./Scripts/generate-app-config.py" ]; then
        echo -e "${BLUE}🔧 Generating app config...${NC}"
        python3 ./Scripts/generate-app-config.py
    fi
    
    # Generate theme assets if available
    if [ -f "./Scripts/generate-app-theme.py" ]; then
        echo -e "${BLUE}🔧 Generating theme assets...${NC}"
        python3 ./Scripts/generate-app-theme.py
    fi
    
    echo -e "${GREEN}✓ Generation scripts completed${NC}\n"
    
    # Generate workspace with Tuist
    echo -e "${BLUE}🏗️  Generating Xcode workspace with Tuist...${NC}"
    tuist generate --no-open
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Tuist generate failed${NC}"
        cd ..
        exit 1
    fi
    
    cd ..
    echo -e "${GREEN}✓ Workspace generated successfully${NC}\n"
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
      RUN_SWIFTLINT=NO \
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

# Validate simulator exists
if ! xcrun simctl list devices available | grep -q "$DEVICE"; then
    echo -e "${RED}❌ Simulator '$DEVICE' not available${NC}"
    echo -e "${YELLOW}Available simulators:${NC}"
    xcrun simctl list devices available | grep "iPhone"
    echo ""
    echo -e "${YELLOW}💡 Use: SIMULATOR_DEVICE=\"iPhone 16\" ./scripts/run-maestro-tests.sh${NC}"
    exit 1
fi

# Get simulator UUID for reliable operations
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$DEVICE" | head -n 1 | grep -oE '\([A-F0-9-]+\)' | tr -d '()')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Could not get simulator ID for '$DEVICE'${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found simulator: $DEVICE ($SIMULATOR_ID)${NC}"

# Boot simulator using UUID
BOOT_OUTPUT=$(xcrun simctl boot "$SIMULATOR_ID" 2>&1 || true)
if echo "$BOOT_OUTPUT" | grep -q "Unable to boot device in current state: Booted"; then
    echo -e "${BLUE}ℹ️  Simulator already booted${NC}"
elif echo "$BOOT_OUTPUT" | grep -q "Unable to boot"; then
    echo -e "${RED}❌ Failed to boot simulator: $BOOT_OUTPUT${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Simulator booted${NC}"
    # Wait for simulator to be fully ready
    echo -e "${BLUE}⏳ Waiting for simulator to be ready...${NC}"
    xcrun simctl bootstatus "$SIMULATOR_ID" -b 2>/dev/null || sleep 5
    echo -e "${GREEN}✓ Simulator ready${NC}"
fi

# Terminate app if running
echo -e "${YELLOW}⏹️  Closing app if running...${NC}"
xcrun simctl terminate "$SIMULATOR_ID" "com.vonage.VERA" 2>/dev/null || true

# Install app using UUID
echo -e "${YELLOW}📲 Installing VERA app on simulator...${NC}"
INSTALL_OUTPUT=$(xcrun simctl install "$SIMULATOR_ID" "$APP_PATH" 2>&1)
INSTALL_RESULT=$?

if [ $INSTALL_RESULT -ne 0 ]; then
    echo -e "${RED}❌ Failed to install app: $INSTALL_OUTPUT${NC}"
    echo -e "${YELLOW}💡 Try: xcrun simctl shutdown \"$SIMULATOR_ID\" && xcrun simctl erase \"$SIMULATOR_ID\"${NC}"
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
    echo -e "   3. Run single flow: ${BLUE}maestro test .maestro/flows/<flow-name>.yaml${NC}"
    echo -e "   4. Clean build: ${BLUE}rm -rf $BUILD_DIR && cd VERA && tuist clean && tuist generate && cd ..${NC}"
    echo -e "   5. Check simulator logs: ${BLUE}xcrun simctl spawn booted log stream --level=debug${NC}"
    echo ""
fi

exit $TEST_RESULT
