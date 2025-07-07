#!/bin/bash

# Create iOS-specific snapshot testing target for VERACore
# This script guides through creating a new iOS testing target

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Creating iOS Snapshot Testing Target${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if we're in the right directory
if [ ! -f "VERA/VERACore/VERACore.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ VERACore project not found. Make sure you're in the project root.${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Manual steps to create iOS snapshot testing target:${NC}"
echo ""
echo "1. Open VERACore.xcodeproj in Xcode"
echo "2. Select the VERACore project in the navigator"
echo "3. Click '+' at the bottom of the targets list"
echo "4. Choose 'iOS' → 'Unit Testing Bundle'"
echo "5. Configure the new target:"
echo "   - Product Name: VERACoreSnapshotTests"
echo "   - Target to be Tested: VERACore"
echo "   - Language: Swift"
echo "   - Use Core Data: No"
echo ""
echo "6. After creation, select the new target and set:"
echo "   - iOS Deployment Target: 15.0 (or your minimum)"
echo "   - Supported Destinations: iPhone, iPad"
echo ""
echo "7. Add Package Dependencies:"
echo "   - Add swift-snapshot-testing to VERACoreSnapshotTests target"
echo "   - Select only 'SnapshotTesting' library"
echo ""
echo "8. Configure the target settings:"
echo "   - Build Settings → Search 'SWIFT_TREAT_WARNINGS_AS_ERRORS' → Set to NO"
echo "   - Build Settings → Search 'ENABLE_TESTABILITY' → Set to YES"
echo ""
echo -e "${GREEN}✅ After completing these steps, run this script again with -verify flag${NC}"
echo ""
echo "Usage: $0 -verify"
