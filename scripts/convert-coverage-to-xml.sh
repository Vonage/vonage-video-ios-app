#!/bin/bash

# Convert xccov JSON coverage to SonarQube XML format
# This script provides a fallback when Slather is not available

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Converting xccov JSON to SonarQube XML format...${NC}"

COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
JSON_FILE="$COVERAGE_DIR/coverage.json"
XML_FILE="$COVERAGE_DIR/sonarqube-generic-coverage.xml"

if [ ! -f "$JSON_FILE" ]; then
    echo -e "${YELLOW}⚠️  Coverage JSON file not found: $JSON_FILE${NC}"
    exit 1
fi

# Create SonarQube XML header
cat > "$XML_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1">
EOF

# Parse JSON and convert to XML (simplified version)
python3 -c "
import json
import sys

try:
    with open('$JSON_FILE', 'r') as f:
        data = json.load(f)
    
    print('  <!-- Generated from xccov JSON by convert-coverage-to-xml.sh -->')
    
    for target in data.get('targets', []):
        target_name = target.get('name', 'Unknown')
        if 'files' in target and target['files']:
            for file_info in target['files']:
                file_path = file_info.get('path', '')
                if file_path and not file_path.endswith('Tests.swift'):
                    # Convert absolute path to relative
                    if file_path.startswith('$PROJECT_ROOT/'):
                        file_path = file_path[len('$PROJECT_ROOT/') + 1:]
                    elif '/vonage-video-ios-app/' in file_path:
                        file_path = file_path.split('/vonage-video-ios-app/')[-1]
                    
                    covered_lines = file_info.get('coveredLines', 0)
                    executable_lines = file_info.get('executableLines', 0)
                    
                    print(f'  <file path=\"{file_path}\">')
                    
                    # Add line coverage info (simplified)
                    if 'functions' in file_info:
                        line_number = 1
                        for func in file_info['functions']:
                            func_line = func.get('lineNumber', line_number)
                            func_covered = func.get('coveredLines', 0)
                            func_executable = func.get('executableLines', 1)
                            hits = 1 if func_covered > 0 else 0
                            
                            print(f'    <lineToCover lineNumber=\"{func_line}\" covered=\"{\"true\" if hits > 0 else \"false\"}\"/>')
                            line_number = func_line + func_executable
                    
                    print('  </file>')

except Exception as e:
    print(f'<!-- Error processing coverage data: {e} -->', file=sys.stderr)
    
" >> "$XML_FILE"

# Close XML
echo '</coverage>' >> "$XML_FILE"

echo -e "${GREEN}✅ Generated SonarQube XML coverage: $XML_FILE${NC}"

# Validate XML (basic check)
if command -v xmllint >/dev/null 2>&1; then
    if xmllint --noout "$XML_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ XML validation passed${NC}"
    else
        echo -e "${YELLOW}⚠️  XML validation failed, but file was created${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  xmllint not available, skipping validation${NC}"
fi

echo -e "${BLUE}📊 Coverage files available:${NC}"
ls -la "$COVERAGE_DIR"/ | grep -E '\.(json|xml)$' || echo "No coverage files found"
