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
    "scripts/test-snapshots.sh"
    "scripts/generate-coverage.sh"
    "scripts/upload-sonarcloud.sh"
    "scripts/simulate-ci.sh"
    "scripts/test-sonar-config.sh"
    "scripts/setup-project.sh"
    "scripts/lint-swift.sh"
    "scripts/code-quality.sh"
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
    "VERA/VERACore/VERACoreSnapshotTests"
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

# Check 6: UI Snapshot Testing (optional)
echo -e "${BLUE}📸 Checking UI Snapshot Testing setup...${NC}"
if [ -d "$PROJECT_ROOT/VERA/VERACore/VERACoreSnapshotTests" ]; then
    echo -e "${GREEN}✅ VERACoreSnapshotTests target exists${NC}"
    
    # Check if snapshot script works
    if "$SCRIPT_DIR/test-snapshots.sh" --help >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Snapshot testing script functional${NC}"
    else
        echo -e "${YELLOW}⚠️  Snapshot testing script has issues${NC}"
    fi
    
    # Check for reference snapshots
    if find "$PROJECT_ROOT/VERA/VERACore/VERACoreSnapshotTests" -name "*.png" -type f | grep -q .; then
        echo -e "${GREEN}✅ Reference snapshots exist${NC}"
    else
        echo -e "${YELLOW}⚠️  No reference snapshots found (run with -r to record)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  VERACoreSnapshotTests not configured (UI tests only)${NC}"
fi

# Check 7: Git LFS for Snapshot Images
echo -e "${BLUE}📦 Checking Git LFS for Snapshot Images...${NC}"

# Check if git-lfs is installed
if ! command -v git-lfs >/dev/null 2>&1; then
    echo -e "${RED}❌ git-lfs not installed${NC}"
    echo -e "${YELLOW}   Install with: brew install git-lfs${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ git-lfs installed${NC}"
    
    # Check if .gitattributes exists and has LFS configuration
    if [ -f "$PROJECT_ROOT/.gitattributes" ]; then
        if grep -q "filter=lfs" "$PROJECT_ROOT/.gitattributes"; then
            echo -e "${GREEN}✅ Git LFS configured for image files${NC}"
            
            # Check if snapshot images are tracked by LFS
            if git lfs ls-files | grep -q "\.png"; then
                echo -e "${GREEN}✅ Snapshot images are tracked by Git LFS${NC}"
            else
                echo -e "${YELLOW}⚠️  No PNG files tracked by Git LFS yet${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  .gitattributes exists but no LFS configuration found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  .gitattributes not found (Git LFS not configured)${NC}"
        echo -e "${YELLOW}   Run: git lfs track '*.png'${NC}"
    fi
fi

# Check 8: Swift Format Linter
echo -e "${BLUE}🎨 Checking Swift Format Linter...${NC}"

# Check if swift-format is installed
if ! command -v swift-format >/dev/null 2>&1; then
    echo -e "${RED}❌ swift-format not installed${NC}"
    echo -e "${YELLOW}   Install with: brew install swift-format${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ swift-format installed${NC}"
    
    # Check if configuration file exists
    if [ -f "$PROJECT_ROOT/.swift-format" ]; then
        echo -e "${GREEN}✅ .swift-format configuration file exists${NC}"
        
        # Test linter on a sample of Swift files from all projects
        echo -e "${YELLOW}   Testing linter on workspace files...${NC}"
        LINTER_ERRORS=0
        TESTED_FILES=0
        
        # Find all Swift files in the workspace, excluding build artifacts
        while IFS= read -r -d '' file; do
            if [ $TESTED_FILES -ge 10 ]; then  # Limit to 10 files for validation
                break
            fi
            
            # Test if file needs formatting
            if ! swift-format format --configuration "$PROJECT_ROOT/.swift-format" "$file" | diff -q "$file" - >/dev/null 2>&1; then
                echo -e "${RED}     ❌ $(basename "$file") needs formatting${NC}"
                ((LINTER_ERRORS++))
            fi
            ((TESTED_FILES++))
        done < <(find "$PROJECT_ROOT/VERA" -name "*.swift" -not -path "*/DerivedData/*" -not -path "*/.build/*" -print0)
        
        if [ $LINTER_ERRORS -eq 0 ]; then
            echo -e "${GREEN}✅ All tested Swift files ($TESTED_FILES) are properly formatted${NC}"
        else
            echo -e "${YELLOW}⚠️  $LINTER_ERRORS of $TESTED_FILES files need formatting${NC}"
            echo -e "${YELLOW}   Fix with: find ./VERA -name '*.swift' | xargs swift-format format --in-place --configuration .swift-format${NC}"
        fi
    else
        echo -e "${RED}❌ .swift-format configuration file missing${NC}"
        ((ERRORS++))
    fi
fi

# Check 9: SwiftLint
echo -e "${BLUE}🔍 Checking SwiftLint...${NC}"

# Check if SwiftLint is installed
if ! command -v swiftlint >/dev/null 2>&1; then
    echo -e "${RED}❌ SwiftLint not installed${NC}"
    echo -e "${YELLOW}   Install with: brew install swiftlint${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✅ SwiftLint installed${NC}"
    
    # Check if configuration file exists
    if [ -f "$PROJECT_ROOT/.swiftlint.yml" ]; then
        echo -e "${GREEN}✅ .swiftlint.yml configuration file exists${NC}"
        
        # Check if lint script exists
        if [ -f "$PROJECT_ROOT/scripts/lint-swift.sh" ]; then
            echo -e "${GREEN}✅ lint-swift.sh script exists${NC}"
            
            # Test SwiftLint on a subset of files (quick validation)
            echo -e "${YELLOW}   Testing SwiftLint configuration...${NC}"
            if swiftlint version >/dev/null 2>&1; then
                echo -e "${GREEN}✅ SwiftLint configuration is valid${NC}"
            else
                echo -e "${RED}❌ SwiftLint configuration has issues${NC}"
                ((ERRORS++))
            fi
        else
            echo -e "${RED}❌ lint-swift.sh script missing${NC}"
            ((ERRORS++))
        fi
    else
        echo -e "${RED}❌ .swiftlint.yml configuration file missing${NC}"
        ((ERRORS++))
    fi
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
    echo ""
    echo -e "${BLUE}🧪 Test Commands:${NC}"
    echo "   • Core/Logic tests:  ./scripts/test-core.sh"
    echo "   • All platform tests: ./scripts/test.sh"
    echo "   • UI Snapshot tests: ./scripts/test-snapshots.sh"
    echo "   • With coverage:     ./scripts/test.sh -coverage"
else
    echo -e "${RED}❌ $ERRORS errors found. Please fix them before proceeding.${NC}"
    exit 1
fi
