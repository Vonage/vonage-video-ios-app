#!/bin/bash

# Swift Format Script for VERA iOS App
# Simple and reliable formatting script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default options
FIX_MODE=false
VERBOSE=false

# Help function
show_help() {
    echo -e "${BLUE}Swift Format Script for VERA iOS App${NC}"
    echo "====================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --fix       Format files in place"
    echo "  --check     Check formatting only (default)"
    echo "  --verbose   Verbose output"
    echo "  --help      Show this help"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --check)
            FIX_MODE=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check if swift-format exists
if ! command -v swift-format &> /dev/null; then
    echo -e "${RED}❌ swift-format not found. Install with: brew install swift-format${NC}"
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if .swift-format config exists
CONFIG_FLAG=""
if [ -f ".swift-format" ]; then
    CONFIG_FLAG="--configuration .swift-format"
    echo -e "${GREEN}✅ Using .swift-format configuration${NC}"
else
    echo -e "${YELLOW}⚠️ No .swift-format found, using default configuration${NC}"
fi

echo -e "${BLUE}🔍 Finding Swift files in VERA directory...${NC}"

# Find Swift files, excluding common build directories
SWIFT_FILES=$(find ./VERA -name "*.swift" -type f \
    -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" \
    -not -path "*/build/*" \
    -not -path "*/Pods/*" \
    -not -path "*/Carthage/*" \
    -not -path "*/xcuserdata/*" \
    -not -path "*/project.xcworkspace/*" \
    2>/dev/null | sort)

if [ -z "$SWIFT_FILES" ]; then
    echo -e "${YELLOW}⚠️ No Swift files found${NC}"
    exit 0
fi

FILE_COUNT=$(echo "$SWIFT_FILES" | wc -l | tr -d ' ')
echo -e "${GREEN}Found $FILE_COUNT Swift files${NC}"

if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Files to process:${NC}"
    echo "$SWIFT_FILES"
fi

# Process files
ISSUES_FOUND=0
FILES_FIXED=0

if [ "$FIX_MODE" = true ]; then
    echo -e "${YELLOW}🔧 Formatting files in place...${NC}"
    
    while IFS= read -r file; do
        if [ "$VERBOSE" = true ]; then
            echo "Formatting: $file"
        fi
        
        if swift-format format $CONFIG_FLAG --in-place "$file" 2>/dev/null; then
            ((FILES_FIXED++))
            if [ "$VERBOSE" = true ]; then
                echo -e "${GREEN}✅ Formatted: $file${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to format: $file${NC}"
            ((ISSUES_FOUND++))
        fi
    done <<< "$SWIFT_FILES"
    
    echo ""
    if [ $ISSUES_FOUND -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully formatted $FILES_FIXED files${NC}"
    else
        echo -e "${YELLOW}⚠️ Formatted $FILES_FIXED files, $ISSUES_FOUND files had errors${NC}"
    fi

else
    echo -e "${YELLOW}🔍 Checking formatting...${NC}"
    
    while IFS= read -r file; do
        if [ "$VERBOSE" = true ]; then
            echo "Checking: $file"
        fi
        
        # Get formatted version
        FORMATTED=$(swift-format format $CONFIG_FLAG "$file" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Error processing: $file${NC}"
            ((ISSUES_FOUND++))
            continue
        fi
        
        # Compare with original
        if ! echo "$FORMATTED" | diff -q "$file" - >/dev/null 2>&1; then
            echo -e "${RED}❌ Needs formatting: $file${NC}"
            ((ISSUES_FOUND++))
        elif [ "$VERBOSE" = true ]; then
            echo -e "${GREEN}✅ Properly formatted: $file${NC}"
        fi
    done <<< "$SWIFT_FILES"
    
    echo ""
    if [ $ISSUES_FOUND -eq 0 ]; then
        echo -e "${GREEN}✅ All files are properly formatted!${NC}"
    else
        echo -e "${RED}❌ $ISSUES_FOUND files need formatting${NC}"
        echo -e "${BLUE}💡 Run with --fix to format them${NC}"
    fi
fi

exit $ISSUES_FOUND
