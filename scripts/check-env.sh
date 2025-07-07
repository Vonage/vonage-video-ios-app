#!/bin/bash

# 🔧 Quick Development Environment Check
# Fast verification for developers

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔧 Quick Environment Check"
echo "=========================="

MISSING=0

# Check essentials
check_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        ((MISSING++))
    fi
}

check_cmd "xcodebuild" "Xcode"
check_cmd "git-lfs" "Git LFS"
check_cmd "swift-format" "Swift Format"

# Check Git LFS files
if [ -d "VERA/VERACore/VERACoreSnapshotTests/__Snapshots__" ]; then
    echo -e "${GREEN}✅ Snapshot images${NC}"
else
    echo -e "${YELLOW}⚠️  No snapshot images (run: git lfs pull)${NC}"
fi

echo ""
if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}🎉 Environment ready for development!${NC}"
    echo "Run: ./scripts/test-core.sh"
else
    echo -e "${YELLOW}⚠️  $MISSING missing dependencies${NC}"
    echo "Run: ./scripts/setup-project.sh"
fi
