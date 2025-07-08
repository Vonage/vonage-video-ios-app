#!/bin/bash

# Combined Swift Code Quality Runner
# This script runs both swift-format and SwiftLint on the VERA iOS App

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help function
show_help() {
    echo -e "${BLUE}Swift Code Quality Runner for VERA iOS App${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -f, --fix         Auto-fix violations where possible"
    echo "  -s, --strict      Treat warnings as errors (SwiftLint only)"
    echo "  -v, --verbose     Verbose output"
    echo "  --format-only     Run only swift-format"
    echo "  --lint-only       Run only SwiftLint"
    echo ""
    echo "Examples:"
    echo "  $0                # Run both swift-format and SwiftLint"
    echo "  $0 --fix          # Run both tools and auto-fix violations"
    echo "  $0 --format-only  # Run only swift-format"
    echo "  $0 --lint-only    # Run only SwiftLint"
    echo ""
}

# Parse arguments
AUTO_FIX=false
STRICT=false
VERBOSE=false
FORMAT_ONLY=false
LINT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--fix)
            AUTO_FIX=true
            shift
            ;;
        -s|--strict)
            STRICT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --format-only)
            FORMAT_ONLY=true
            shift
            ;;
        --lint-only)
            LINT_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Navigate to project root
cd "$PROJECT_ROOT"

echo -e "${BLUE}🔍 Running Swift Code Quality Tools${NC}"
echo -e "${BLUE}===================================${NC}"

OVERALL_SUCCESS=true

# Run swift-format if not lint-only
if [ "$LINT_ONLY" = false ]; then
    echo -e "${BLUE}📝 Running swift-format...${NC}"
    
    # Check if swift-format is installed
    if ! command -v swift-format >/dev/null 2>&1; then
        echo -e "${RED}❌ swift-format not installed${NC}"
        echo -e "${YELLOW}   Install with: brew install swift-format${NC}"
        OVERALL_SUCCESS=false
    else
        # Build swift-format command
        FORMAT_CMD="find ./VERA -name '*.swift' -not -path '*/DerivedData/*' -not -path '*/.build/*'"
        
        if [ "$AUTO_FIX" = true ]; then
            FORMAT_CMD="$FORMAT_CMD | xargs swift-format format --in-place --configuration .swift-format"
            echo -e "${YELLOW}🔧 Auto-fixing format violations...${NC}"
        else
            FORMAT_CMD="$FORMAT_CMD | xargs swift-format format --configuration .swift-format | diff -q - /dev/null"
        fi
        
        if [ "$VERBOSE" = true ]; then
            echo -e "${BLUE}Running: $FORMAT_CMD${NC}"
        fi
        
        # Run swift-format
        if eval "$FORMAT_CMD" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ swift-format completed successfully${NC}"
        else
            if [ "$AUTO_FIX" = true ]; then
                echo -e "${GREEN}✅ swift-format auto-fixed violations${NC}"
            else
                echo -e "${RED}❌ swift-format found violations${NC}"
                echo -e "${YELLOW}   Fix with: find ./VERA -name '*.swift' | xargs swift-format format --in-place --configuration .swift-format${NC}"
                OVERALL_SUCCESS=false
            fi
        fi
    fi
    
    echo ""
fi

# Run SwiftLint if not format-only
if [ "$FORMAT_ONLY" = false ]; then
    echo -e "${BLUE}🔍 Running SwiftLint...${NC}"
    
    # Check if SwiftLint is installed
    if ! command -v swiftlint >/dev/null 2>&1; then
        echo -e "${RED}❌ SwiftLint not installed${NC}"
        echo -e "${YELLOW}   Install with: brew install swiftlint${NC}"
        OVERALL_SUCCESS=false
    else
        # Build SwiftLint arguments
        LINT_ARGS=""
        
        if [ "$AUTO_FIX" = true ]; then
            LINT_ARGS="$LINT_ARGS --fix"
            echo -e "${YELLOW}🔧 Auto-fixing lint violations...${NC}"
        fi
        
        if [ "$STRICT" = true ]; then
            LINT_ARGS="$LINT_ARGS --strict"
            echo -e "${YELLOW}⚠️  Strict mode: treating warnings as errors${NC}"
        fi
        
        if [ "$VERBOSE" = true ]; then
            LINT_ARGS="$LINT_ARGS --verbose"
            echo -e "${BLUE}Running: swiftlint$LINT_ARGS${NC}"
        fi
        
        # Run SwiftLint
        if eval "swiftlint$LINT_ARGS"; then
            echo -e "${GREEN}✅ SwiftLint completed successfully${NC}"
        else
            echo -e "${RED}❌ SwiftLint found violations${NC}"
            echo -e "${YELLOW}   Fix violations manually or run with --fix flag${NC}"
            OVERALL_SUCCESS=false
        fi
    fi
fi

echo ""
echo -e "${BLUE}📊 Code Quality Summary${NC}"
echo -e "${BLUE}======================${NC}"

if [ "$OVERALL_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ All code quality checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some code quality checks failed${NC}"
    exit 1
fi
