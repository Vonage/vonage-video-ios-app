#!/bin/bash

# This script is a wrapper for the centralized format.sh script
# Navigate to project root
cd "$(dirname "$0")/.."

# Make sure the format script is executable
chmod +x scripts/format.sh

# Run the format check
./scripts/format.sh --check
