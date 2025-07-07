#!/bin/bash

# Add swift-snapshot-testing to VERACore project
# This script adds the snapshot testing dependency to your VERACore project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📸 Adding Snapshot Testing to VERACore${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if we're in the right directory
if [ ! -f "VERA/VERACore/VERACore.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ VERACore project not found. Make sure you're in the project root.${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  Manual steps required:${NC}"
echo ""
echo "1. Open VERACore.xcodeproj in Xcode"
echo "2. Select the VERACore project in the navigator"
echo "3. Go to 'Package Dependencies' tab"
echo "4. Click '+' and add: https://github.com/pointfreeco/swift-snapshot-testing"
echo "5. Add 'SnapshotTesting' to VERACoreTests target"
echo ""
echo -e "${GREEN}✅ Once added, you can use snapshot testing in your tests!${NC}"
echo ""
echo "Example usage:"
echo "  import SnapshotTesting"
echo "  import SwiftUI"
echo "  @testable import VERACore"
echo ""
echo "  @Test func testViewSnapshot() {"
echo "    let view = MyView()"
echo "    assertSnapshot(of: view, as: .image)"
echo "  }"
