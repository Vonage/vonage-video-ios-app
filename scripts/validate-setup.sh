#!/bin/bash

# Validate SonarCloud integration setup
# This script checks all components are working correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating SonarCloud Integration Setup${NC}"
echo -e "${BLUE}===========================================${NC}"

ERRORS=0

# Check 1: Required scripts exist
echo -e "${BLUE}📄 Checking required scripts...${NC}"
REQUIRED_SCRIPTS=(
    "scripts/test-core.sh"
    "scripts/test.sh" 
    "scripts/generate-coverage.sh"
    "scripts/upload-sonarcloud.sh"
    "scripts/configure-veracore-testing.sh"
    "scripts/simulate-ci.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -x "$PROJECT_ROOT/$script" ]; then
        echo -e "${GREEN}✅ $script${NC}"
    else
        echo -e "${RED}❌ $script (missing or not executable)${NC}"
        ((ERRORS++))
    fi
done

# Check 2: Configuration files exist
echo -e "${BLUE}⚙️  Checking configuration files...${NC}"
CONFIG_FILES=(
    "sonar-project.properties"
    ".github/workflows/ci.yml"
)

for config in "${CONFIG_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$config" ]; then
        echo -e "${GREEN}✅ $config${NC}"
    else
        echo -e "${RED}❌ $config (missing)${NC}"
        ((ERRORS++))
    fi
done

# Check 3: VERACore project structure
echo -e "${BLUE}🏗️  Checking project structure...${NC}"
PROJECT_DIRS=(
    "VERA/VERA"
    "VERA/VERACore"
    "VERA/VERACore/VERACoreTests"
)

for dir in "${PROJECT_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo -e "${GREEN}✅ $dir${NC}"
    else
        echo -e "${RED}❌ $dir (missing)${NC}"
        ((ERRORS++))
    fi
done

# Check 4: Test basic functionality
echo -e "${BLUE}🧪 Testing basic functionality...${NC}"

# Test coverage generation with minimal setup
cd "$PROJECT_ROOT"
rm -rf DerivedData coverage-reports

echo -e "${YELLOW}   Testing coverage generation without tests...${NC}"
if "$SCRIPT_DIR/generate-coverage.sh" >/dev/null 2>&1; then
    if [ -f "coverage-reports/coverage.json" ]; then
        echo -e "${GREEN}✅ Coverage generation (fallback)${NC}"
    else
        echo -e "${RED}❌ Coverage generation failed to create report${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}❌ Coverage generation script failed${NC}"
    ((ERRORS++))
fi

# Check 5: Test help functions
echo -e "${BLUE}📚 Testing help functions...${NC}"
if "$SCRIPT_DIR/test.sh" --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ test.sh help${NC}"
else
    echo -e "${RED}❌ test.sh help${NC}"
    ((ERRORS++))
fi

# Summary
echo -e "${BLUE}📊 Validation Summary${NC}"
echo -e "${BLUE}====================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! SonarCloud integration is ready.${NC}"
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "   1. Set up your SonarCloud project at https://sonarcloud.io"
    echo "   2. Add SONAR_TOKEN to your GitHub repository secrets"
    echo "   3. Adjust project key in sonar-project.properties if needed"
    echo "   4. Test with: ./scripts/test.sh -coverage"
else
    echo -e "${RED}❌ $ERRORS errors found. Please fix them before proceeding.${NC}"
    exit 1
fi
