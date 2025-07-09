#!/bin/bash

# Swift Format Script for VERA iOS App
# This script runs swift-format on all Swift files in the project

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default options
IN_PLACE=false
VERBOSE=false
CHECK_MODE=false

# Function to show help
show_help() {
    echo -e "${BLUE}Swift Format Runner for VERA iOS App${NC}"
    echo "===================================="
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -i, --in-place  Format files in place (modifies files)"
    echo "  -c, --check     Check if files are formatted without modifying"
    echo "  -v, --verbose   Verbose output"
    echo
    echo "Examples:"
    echo "  $0              # Check formatting without modifying files"
    echo "  $0 --in-place   # Format files in place"
    echo "  $0 --check      # Check formatting and report differences"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--in-place)
            IN_PLACE=true
            shift
            ;;
        -c|--check)
            CHECK_MODE=true
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

# Check if swift-format is available
if ! command -v swift-format &> /dev/null; then
    echo -e "${RED}❌ swift-format is not installed or not in PATH${NC}"
    echo "Install it with: brew install swift-format"
    exit 1
fi

# Navigate to project root
cd "$PROJECT_ROOT"

echo -e "${BLUE}🔍 Running swift-format on VERA iOS App${NC}"
echo "======================================"

# Find all Swift files
SWIFT_FILES=$(find . -name "*.swift" -type f | grep -v ".build" | grep -v "DerivedData" | sort)

if [ -z "$SWIFT_FILES" ]; then
    echo -e "${YELLOW}⚠️  No Swift files found${NC}"
    exit 0
fi

# Count files
FILE_COUNT=$(echo "$SWIFT_FILES" | wc -l | tr -d ' ')
echo -e "${GREEN}Found $FILE_COUNT Swift files${NC}"

# Build swift-format command
SWIFT_FORMAT_CMD="swift-format"

if [ "$CHECK_MODE" = true ]; then
    SWIFT_FORMAT_CMD="$SWIFT_FORMAT_CMD --diff"
    echo -e "${YELLOW}🔍 Checking formatting (no changes will be made)...${NC}"
elif [ "$IN_PLACE" = true ]; then
    SWIFT_FORMAT_CMD="$SWIFT_FORMAT_CMD --in-place"
    echo -e "${YELLOW}🔧 Formatting files in place...${NC}"
else
    echo -e "${YELLOW}📋 Checking formatting (use --in-place to modify files)...${NC}"
fi

if [ "$VERBOSE" = true ]; then
    echo "Running: $SWIFT_FORMAT_CMD"
fi

# Run swift-format
EXIT_CODE=0
FORMATTED_COUNT=0

for file in $SWIFT_FILES; do
    if [ "$VERBOSE" = true ]; then
        echo "Processing: $file"
    fi
    
    if [ "$CHECK_MODE" = true ]; then
        # Check mode - show diff if file is not formatted
        if ! swift-format --diff "$file" > /dev/null 2>&1; then
            echo -e "${RED}❌ $file needs formatting${NC}"
            if [ "$VERBOSE" = true ]; then
                swift-format --diff "$file"
            fi
            ((FORMATTED_COUNT++))
            EXIT_CODE=1
        else
            if [ "$VERBOSE" = true ]; then
                echo -e "${GREEN}✅ $file is properly formatted${NC}"
            fi
        fi
    elif [ "$IN_PLACE" = true ]; then
        # In-place mode - format the file
        if swift-format --in-place "$file"; then
            if [ "$VERBOSE" = true ]; then
                echo -e "${GREEN}✅ Formatted $file${NC}"
            fi
            ((FORMATTED_COUNT++))
        else
            echo -e "${RED}❌ Failed to format $file${NC}"
            EXIT_CODE=1
        fi
    else
        # Default mode - just check if formatting is needed
        if ! swift-format --diff "$file" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  $file needs formatting${NC}"
            ((FORMATTED_COUNT++))
        fi
    fi
done

# Summary
echo
if [ "$IN_PLACE" = true ]; then
    if [ $FORMATTED_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ All files were already properly formatted!${NC}"
    else
        echo -e "${GREEN}✅ Successfully formatted $FORMATTED_COUNT files${NC}"
    fi
elif [ "$CHECK_MODE" = true ]; then
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✅ All files are properly formatted!${NC}"
    else
        echo -e "${RED}❌ $FORMATTED_COUNT files need formatting${NC}"
    fi
else
    if [ $FORMATTED_COUNT -eq 0 ]; then
        echo -e "${GREEN}✅ All files are properly formatted!${NC}"
    else
        echo -e "${YELLOW}⚠️  $FORMATTED_COUNT files need formatting (use --in-place to fix)${NC}"
    fi
fi

exit $EXIT_CODE
