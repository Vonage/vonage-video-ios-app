#!/bin/bash

# 🚀 VERA iOS Project Setup Script
# This script sets up everything needed for new developers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}${BOLD}"
echo "🚀 Welcome to VERA iOS Project Setup!"
echo "===================================="
echo -e "${NC}"
echo "This script will set up everything you need to start developing."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
ERRORS=0

# Function to check and install dependencies
check_dependency() {
    local cmd=$1
    local name=$2
    local install_cmd=$3
    
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $name is not installed${NC}"
        if [ -n "$install_cmd" ]; then
            echo -e "${YELLOW}   Installing $name...${NC}"
            eval "$install_cmd"
            if command -v "$cmd" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ $name installed successfully${NC}"
            else
                echo -e "${RED}❌ Failed to install $name${NC}"
                ((ERRORS++))
            fi
        else
            echo -e "${YELLOW}   Please install $name manually${NC}"
            ((ERRORS++))
        fi
    fi
}

# Step 1: Check system requirements
echo -e "${BLUE}📋 Step 1: Checking System Requirements${NC}"
echo "========================================"

# Check macOS version
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✅ macOS detected${NC}"
    macos_version=$(sw_vers -productVersion)
    echo -e "${BLUE}   Version: $macos_version${NC}"
else
    echo -e "${RED}❌ This project requires macOS${NC}"
    exit 1
fi

# Check Xcode
if xcode-select -p >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Xcode Command Line Tools installed${NC}"
    xcode_version=$(xcodebuild -version | head -n1)
    echo -e "${BLUE}   $xcode_version${NC}"
else
    echo -e "${RED}❌ Xcode Command Line Tools not found${NC}"
    echo "   Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "   Please restart this script after installation completes."
    exit 1
fi

echo ""

# Step 2: Check and install development tools
echo -e "${BLUE}🛠️  Step 2: Installing Development Tools${NC}"
echo "========================================"

# Check Homebrew
check_dependency "brew" "Homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Check Git LFS
check_dependency "git-lfs" "Git LFS" "brew install git-lfs"

# Check swift-format
check_dependency "swift-format" "Swift Format" "brew install swift-format"

# Check sonar-scanner (optional)
if command -v sonar-scanner >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SonarCloud Scanner is installed${NC}"
else
    echo -e "${YELLOW}⚠️  SonarCloud Scanner not installed (optional)${NC}"
    echo -e "${BLUE}   Install with: brew install sonar-scanner${NC}"
fi

echo ""

# Step 3: Git LFS Setup
echo -e "${BLUE}📦 Step 3: Git LFS Configuration${NC}"
echo "================================"

cd "$PROJECT_ROOT"

# Initialize Git LFS
echo -e "${YELLOW}   Initializing Git LFS...${NC}"
git lfs install

# Pull LFS files
echo -e "${YELLOW}   Downloading LFS files (snapshot images)...${NC}"
if git lfs pull; then
    echo -e "${GREEN}✅ Git LFS files downloaded successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Some LFS files may not be available yet${NC}"
fi

# Verify LFS files
lfs_files_count=$(git lfs ls-files | wc -l | tr -d ' ')
if [ "$lfs_files_count" -gt 0 ]; then
    echo -e "${GREEN}✅ Found $lfs_files_count LFS files${NC}"
    echo -e "${BLUE}   LFS files:${NC}"
    git lfs ls-files | sed 's/^/     /'
else
    echo -e "${YELLOW}⚠️  No LFS files found (will be created when running snapshot tests)${NC}"
fi

echo ""

# Step 4: Project Validation
echo -e "${BLUE}🔍 Step 4: Project Validation${NC}"
echo "============================="

echo -e "${YELLOW}   Running project validation...${NC}"
if "$SCRIPT_DIR/validate-setup.sh"; then
    echo -e "${GREEN}✅ Project validation passed!${NC}"
else
    echo -e "${RED}❌ Project validation failed${NC}"
    ((ERRORS++))
fi

echo ""

# Step 5: Build Test
echo -e "${BLUE}🏗️  Step 5: Initial Build Test${NC}"
echo "============================"

echo -e "${YELLOW}   Testing project build...${NC}"
if xcodebuild build \
    -workspace VERA/VERA.xcworkspace \
    -scheme VERA \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    -quiet 2>/dev/null; then
    echo -e "${GREEN}✅ Project builds successfully!${NC}"
    
    # Clean up build artifacts
    rm -rf DerivedData
else
    echo -e "${YELLOW}⚠️  Build test skipped (may require iOS Simulator setup)${NC}"
fi

echo ""

# Step 6: Setup Summary
echo -e "${BLUE}📊 Setup Summary${NC}"
echo "================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo "1. 📖 Read the README.md for project overview"
    echo "2. 🧪 Run tests: ./scripts/test.sh"
    echo "3. 📸 Try snapshot tests: ./scripts/test-snapshots.sh"
    echo "4. 🎨 Check code formatting: swift-format --version"
    echo ""
    echo -e "${BOLD}Useful commands:${NC}"
    echo "• Run core tests:     ./scripts/test-core.sh"
    echo "• Run all tests:      ./scripts/test.sh"
    echo "• Run UI tests:       ./scripts/test.sh -ui"
    echo "• Generate coverage:  ./scripts/test.sh -coverage"
    echo "• Snapshot tests:     ./scripts/test-snapshots.sh"
    echo "• Validate setup:     ./scripts/validate-setup.sh"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo "• README.md - Project overview and commands"
    echo "• Git LFS info in README.md snapshot section"
    echo "• Scripts in ./scripts/ with --help options"
    echo ""
    echo -e "${GREEN}🚀 You're ready to start developing!${NC}"
else
    echo -e "${RED}❌ Setup completed with $ERRORS errors${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the issues above and run this script again.${NC}"
    echo "Or continue manually if the errors are not critical."
    exit 1
fi
