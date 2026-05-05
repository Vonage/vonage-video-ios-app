#!/bin/bash

# ============================================================================
# Maestro Installation Script
# ============================================================================
# Installs Maestro and its dependencies (Java 17).
# Can be run standalone or sourced from other scripts.
#
# Usage:
#   ./scripts/install-maestro.sh          # Standalone installation
#   source ./scripts/install-maestro.sh   # Sourced from another script
# ============================================================================

set -e

# Colors for output (skip if already defined by parent script)
RED=${RED:-'\033[0;31m'}
GREEN=${GREEN:-'\033[0;32m'}
YELLOW=${YELLOW:-'\033[1;33m'}
BLUE=${BLUE:-'\033[0;34m'}
NC=${NC:-'\033[0m'}

echo -e "${BLUE}🔍 Checking Maestro prerequisites...${NC}\n"

# ── 1. Homebrew ──────────────────────────────────────────────────────────────

if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew not found. Install it from https://brew.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Homebrew installed${NC}"

# ── 2. Java 17 (required by Maestro) ────────────────────────────────────────

echo -e "${BLUE}🔍 Checking Java 17...${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${YELLOW}📦 Java not found, installing OpenJDK 17...${NC}"
    brew install openjdk@17
fi

# Validate and auto-detect JAVA_HOME
if [ -n "$JAVA_HOME" ] && [ ! -d "$JAVA_HOME" ]; then
    echo -e "${YELLOW}⚠️  JAVA_HOME is set but invalid ($JAVA_HOME), auto-detecting...${NC}"
    unset JAVA_HOME
fi

if [ -z "$JAVA_HOME" ]; then
    if /usr/libexec/java_home -v 17 &> /dev/null; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo -e "${GREEN}✓ Auto-detected JAVA_HOME: $JAVA_HOME${NC}"
    else
        echo -e "${YELLOW}📥 Java 17 not detected, installing...${NC}"
        brew install openjdk@17
        export JAVA_HOME=$(/usr/libexec/java_home -v 17)
        echo -e "${GREEN}✓ Installed and set JAVA_HOME: $JAVA_HOME${NC}"
    fi
fi

echo -e "${GREEN}✓ Java $(java -version 2>&1 | grep version | cut -d'"' -f2) detected${NC}"

# ── 3. Maestro ───────────────────────────────────────────────────────────────

echo -e "${BLUE}🔍 Checking Maestro...${NC}"

if ! command -v maestro &> /dev/null; then
    echo -e "${YELLOW}📦 Maestro not found, installing...${NC}"
    curl -Ls "https://get.maestro.mobile.dev" | bash
    export PATH="$HOME/.maestro/bin:$PATH"
    echo -e "${GREEN}✓ Maestro installed${NC}"
else
    echo -e "${GREEN}✓ Maestro $(maestro --version) already installed${NC}"
fi

echo -e "\n${GREEN}✓ Maestro is ready to use${NC}"
echo -e "  Run tests: ${BLUE}./scripts/run-maestro-tests.sh${NC}"
echo -e "  Single flow: ${BLUE}maestro test .maestro/flows/<flow>.yaml${NC}\n"
