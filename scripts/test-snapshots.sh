#!/bin/bash

# Run snapshot tests for VERACore (iOS specific)
# This script handles iOS snapshot testing workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RECORD_SNAPSHOTS=false
COMPARE_SNAPSHOTS=false
CLEAN_SNAPSHOTS=false
DEVICE="iPhone 16"
SCHEME="VERACoreSnapshotTests"

# Function to show usage
show_usage() {
    echo -e "${BLUE}📸 VERACore iOS Snapshot Testing Script${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --record      Record new reference snapshots"
    echo "  -c, --compare     Compare against existing snapshots (default)"
    echo "  -clean           Clean all existing snapshots"
    echo "  -d, --device      Specify device for testing (default: iPhone 13)"
    echo "  -s, --scheme      Specify test scheme (default: VERACoreSnapshotTests)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run snapshot tests (compare mode)"
    echo "  $0 -r                 # Record new reference snapshots"
    echo "  $0 -d 'iPhone 16 Pro' # Run tests on iPhone 16 Pro"
    echo "  $0 -clean             # Clean all existing snapshots"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--record)
            RECORD_SNAPSHOTS=true
            shift
            ;;
        -c|--compare)
            COMPARE_SNAPSHOTS=true
            shift
            ;;
        -clean)
            CLEAN_SNAPSHOTS=true
            shift
            ;;
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -s|--scheme)
            SCHEME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Default to compare mode if no mode specified
if [[ "$RECORD_SNAPSHOTS" == false && "$COMPARE_SNAPSHOTS" == false && "$CLEAN_SNAPSHOTS" == false ]]; then
    COMPARE_SNAPSHOTS=true
fi

echo -e "${BLUE}📸 VERACore iOS Snapshot Testing${NC}"
echo -e "${BLUE}=================================${NC}"

# Clean snapshots if requested
if [[ "$CLEAN_SNAPSHOTS" == true ]]; then
    echo -e "${YELLOW}🧹 Cleaning existing snapshots...${NC}"
    find "$PROJECT_ROOT" -name "__Snapshots__" -type d -exec rm -rf {} + 2>/dev/null || true
    echo -e "${GREEN}✅ Snapshots cleaned${NC}"
    exit 0
fi

# Change to project directory
cd "$PROJECT_ROOT"

# Check if the snapshot testing target exists
if ! (cd "$PROJECT_ROOT/VERA/VERACore" && xcodebuild -list | grep -q "$SCHEME"); then
    echo -e "${RED}❌ $SCHEME scheme not found in VERACore project.${NC}"
    echo -e "${YELLOW}💡 Available schemes in VERACore:${NC}"
    (cd "$PROJECT_ROOT/VERA/VERACore" && xcodebuild -list)
    exit 1
fi

# Configure environment for snapshot testing
export RECORD_SNAPSHOTS=$RECORD_SNAPSHOTS

# Set up environment variables for snapshot testing
if [[ "$RECORD_SNAPSHOTS" == true ]]; then
    echo -e "${YELLOW}📸 Recording mode: Creating new reference snapshots${NC}"
    echo -e "${YELLOW}⚠️  New reference images will be saved to version control${NC}"
    export SNAPSHOT_RECORD=true
else
    echo -e "${BLUE}🔍 Compare mode: Comparing against existing snapshots${NC}"
    export SNAPSHOT_RECORD=false
fi

# Run VERACore snapshot tests
echo -e "${BLUE}🧪 Running VERACore iOS snapshot tests...${NC}"
echo -e "${BLUE}Device: $DEVICE${NC}"
echo -e "${BLUE}Scheme: $SCHEME${NC}"

# Run the tests
(cd "$PROJECT_ROOT/VERA/VERACore" && xcodebuild test \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -enableCodeCoverage NO \
    -quiet)

# Check results
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Snapshot tests completed successfully${NC}"
    
    if [[ "$RECORD_SNAPSHOTS" == true ]]; then
        echo -e "${YELLOW}📸 New reference snapshots recorded${NC}"
        echo -e "${YELLOW}⚠️  Don't forget to commit the new snapshots to version control${NC}"
        
        # Show what was created
        echo -e "${BLUE}📄 New snapshot files:${NC}"
        find "$PROJECT_ROOT" -name "__Snapshots__" -type d -exec find {} -name "*.png" \; 2>/dev/null | head -20
    else
        echo -e "${GREEN}🔍 All snapshots match existing references${NC}"
    fi
else
    echo -e "${RED}❌ Snapshot tests failed${NC}"
    
    if [[ "$RECORD_SNAPSHOTS" == false ]]; then
        echo -e "${YELLOW}💡 Snapshot mismatches found. Check the failure artifacts:${NC}"
        find "$PROJECT_ROOT" -name "__Snapshots__" -type d -exec find {} -name "Failure_*.png" \; 2>/dev/null | head -10
        echo ""
        echo -e "${YELLOW}To update snapshots, run: $0 -r${NC}"
    fi
    
    exit 1
fi

echo -e "${GREEN}🎉 iOS snapshot testing completed!${NC}"
