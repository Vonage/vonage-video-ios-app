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
    echo "  -h, --help           Show this help message"
    echo "  -f, --fix            Auto-fix violations where possible"
    echo "  -s, --strict         Treat warnings as errors"
    echo "  -v, --verbose        Verbose output"
    echo "  --format             Also run swift-format after SwiftLint"
    echo "  --format-only        Only run swift-format (skip SwiftLint)"
    echo ""
    echo "Examples:"
    echo "  $0                   # Run SwiftLint with default settings"
    echo "  $0 --fix             # Run SwiftLint and auto-fix violations"
    echo "  $0 --strict          # Run SwiftLint treating warnings as errors"
    echo "  $0 --fix --format    # Run SwiftLint with auto-fix and then format"
    echo "  $0 --format-only     # Only run swift-format"
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

# Check if swift-format is installed
check_swift_format() {
    if ! command -v swift-format >/dev/null 2>&1; then
        echo -e "${RED}❌ swift-format not installed${NC}"
        echo -e "${YELLOW}   Install with: brew install swift-format${NC}"
        exit 1
    fi
}

# Run swift-format on VERACore files
run_swift_format() {
    echo -e "${BLUE}🔧 Running swift-format on VERACore files...${NC}"
    
    # Format VERACore files with the project's configuration
    local formatted_count=0
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            if swift-format format --configuration .swift-format --in-place "$file"; then
                if [ "$VERBOSE" = true ]; then
                    echo -e "${GREEN}✅ Formatted $file${NC}"
                fi
                ((formatted_count++))
            else
                echo -e "${RED}❌ Failed to format $file${NC}"
            fi
        fi
    done < <(find ./VERA/VERACore -name "*.swift" \
        -not -path "./build/*" \
        -not -path "./.build/*" \
        -not -path "./DerivedData/*" \
        -not -path "./VERA/VERACore/VERACoreSnapshotTests/*" -print0 2>/dev/null)
    
    echo -e "${GREEN}✅ Formatted $formatted_count VERACore files${NC}"
}

# Parse arguments
AUTO_FIX=false
STRICT=false
VERBOSE=false
RUN_FORMAT=false
FORMAT_ONLY=false

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
        --format)
            RUN_FORMAT=true
            shift
            ;;
        --format-only)
            FORMAT_ONLY=true
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

# Check if swift-format is needed
if [ "$RUN_FORMAT" = true ] || [ "$FORMAT_ONLY" = true ]; then
    check_swift_format
fi

# Only run swift-format if format-only is requested
if [ "$FORMAT_ONLY" = true ]; then
    run_swift_format
    exit 0
fi

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

SWIFTLINT_EXIT_CODE=0
if ! eval "$SWIFTLINT_CMD"; then
    SWIFTLINT_EXIT_CODE=1
fi

# Run swift-format if requested
if [ "$RUN_FORMAT" = true ]; then
    echo ""
    run_swift_format
fi

# Final result
if [ $SWIFTLINT_EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Swift code quality checks completed successfully!${NC}"
    if [ "$RUN_FORMAT" = true ]; then
        echo -e "${GREEN}✅ Code formatting applied${NC}"
    fi
    exit 0
else
    echo ""
    echo -e "${RED}❌ SwiftLint found violations${NC}"
    if [ "$AUTO_FIX" = false ]; then
        echo -e "${YELLOW}   Fix violations manually or run with --fix flag${NC}"
    fi
    if [ "$RUN_FORMAT" = false ]; then
        echo -e "${YELLOW}   Consider running with --format to apply formatting${NC}"
    fi
    exit 1
fi
