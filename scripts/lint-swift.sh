#!/bin/bash

# SwiftLint runner for VERA iOS App
# This script runs SwiftLint on the entire workspace

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
    echo -e "${BLUE}SwiftLint Runner for VERA iOS App${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -f, --fix      Auto-fix violations where possible"
    echo "  -s, --strict   Treat warnings as errors"
    echo "  -v, --verbose  Verbose output"
    echo ""
    echo "Examples:"
    echo "  $0              # Run SwiftLint with default settings"
    echo "  $0 --fix        # Run SwiftLint and auto-fix violations"
    echo "  $0 --strict     # Run SwiftLint treating warnings as errors"
    echo ""
}

# Check if SwiftLint is installed
check_swiftlint() {
    if ! command -v swiftlint >/dev/null 2>&1; then
        echo -e "${RED}❌ SwiftLint not installed${NC}"
        echo -e "${YELLOW}   Install with: brew install swiftlint${NC}"
        exit 1
    fi
}

# Parse arguments
AUTO_FIX=false
STRICT=false
VERBOSE=false

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
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Navigate to project root
cd "$PROJECT_ROOT"

echo -e "${BLUE}🔍 Running SwiftLint on VERA iOS App${NC}"
echo -e "${BLUE}====================================${NC}"

# Check if SwiftLint is installed
check_swiftlint

# Check if configuration exists
if [ ! -f ".swiftlint.yml" ]; then
    echo -e "${RED}❌ SwiftLint configuration file (.swiftlint.yml) not found${NC}"
    exit 1
fi

# Build SwiftLint command
SWIFTLINT_CMD="swiftlint"

if [ "$AUTO_FIX" = true ]; then
    SWIFTLINT_CMD="$SWIFTLINT_CMD --fix"
    echo -e "${YELLOW}🔧 Auto-fixing violations where possible...${NC}"
fi

if [ "$STRICT" = true ]; then
    SWIFTLINT_CMD="$SWIFTLINT_CMD --strict"
    echo -e "${YELLOW}⚠️  Strict mode: treating warnings as errors${NC}"
fi

if [ "$VERBOSE" = true ]; then
    SWIFTLINT_CMD="$SWIFTLINT_CMD --verbose"
fi

# Run SwiftLint
echo -e "${BLUE}Running: $SWIFTLINT_CMD${NC}"
echo ""

if eval "$SWIFTLINT_CMD"; then
    echo ""
    echo -e "${GREEN}✅ SwiftLint completed successfully!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ SwiftLint found violations${NC}"
    echo -e "${YELLOW}   Fix violations manually or run with --fix flag${NC}"
    exit 1
fi
