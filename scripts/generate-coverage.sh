#!/bin/bash

# Generate code coverage reports for SonarCloud
# This script processes xcodebuild test results and generates coverage reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Generating Code Coverage Reports...${NC}"

# Find ALL test results
DERIVED_DATA_PATH="$PROJECT_ROOT/DerivedData"
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
mkdir -p "$COVERAGE_DIR"

# Find ALL .xcresult files
XCRESULT_FILES=()
if [ -d "$DERIVED_DATA_PATH" ]; then
    echo -e "${BLUE}🔍 Searching for all test results...${NC}"
    while IFS= read -r -d '' file; do
        XCRESULT_FILES+=("$file")
        echo -e "${BLUE}   📁 Found: $(basename "$file")${NC}"
    done < <(find "$DERIVED_DATA_PATH" -name "*.xcresult" -type d -print0 2>/dev/null)
fi

if [ ${#XCRESULT_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No test results found${NC}"
    echo -e "${YELLOW}⚠️  Creating minimal coverage report...${NC}"
    
    # Create valid JSON for SonarCloud (array format)
    echo '[]' > "$COVERAGE_DIR/coverage.json"
    
    # Create valid XML for SonarCloud
    cat > "$COVERAGE_DIR/sonarqube-generic-coverage.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1">
  <!-- Empty coverage report -->
</coverage>
EOF
    
    echo -e "${GREEN}✅ Minimal coverage reports created${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Found ${#XCRESULT_FILES[@]} test result(s)${NC}"

# Process coverage with xccov and convert to SonarCloud XML
echo -e "${BLUE}📊 Generating coverage with xccov...${NC}"

COMBINED_COVERAGE="$COVERAGE_DIR/combined_coverage.json"
# Initialize with empty array for SonarCloud JSON
echo '[]' > "$COMBINED_COVERAGE"

# Process each .xcresult individually
for i in "${!XCRESULT_FILES[@]}"; do
    XCRESULT_PATH="${XCRESULT_FILES[$i]}"
    echo -e "${BLUE}   📊 Processing $(basename "$XCRESULT_PATH") ($(($i + 1))/${#XCRESULT_FILES[@]})...${NC}"
    
    INDIVIDUAL_COVERAGE="$COVERAGE_DIR/coverage_$(basename "$XCRESULT_PATH" .xcresult).json"
    
    if xcrun xccov view --report --json "$XCRESULT_PATH" > "$INDIVIDUAL_COVERAGE" 2>/dev/null; then
        echo -e "${GREEN}      ✅ Generated coverage for $(basename "$XCRESULT_PATH")${NC}"
    else
        echo -e "${YELLOW}      ⚠️  Failed to extract coverage from $(basename "$XCRESULT_PATH")${NC}"
    fi
done

# Convert xccov JSON to SonarCloud XML format
echo -e "${BLUE}🔄 Converting to SonarCloud XML format...${NC}"

if command -v python3 &> /dev/null; then
    python3 -c "
import json
import glob
import os
import xml.etree.ElementTree as ET

coverage_dir = '$COVERAGE_DIR'
project_root = '$PROJECT_ROOT'

# Create root XML element
root = ET.Element('coverage')
root.set('version', '1')

combined_targets = []
all_files = {}

# Process all individual coverage files
for coverage_file in glob.glob(os.path.join(coverage_dir, 'coverage_*.json')):
    try:
        with open(coverage_file, 'r') as f:
            data = json.load(f)
            
            if 'targets' in data:
                for target in data['targets']:
                    if 'files' in target:
                        for file_data in target['files']:
                            file_path = file_data.get('path', '')
                            # Make path relative to project root
                            if file_path.startswith(project_root + '/'):
                                file_path = file_path[len(project_root) + 1:]
                            elif file_path.startswith('/'):
                                # Try to make relative if it's an absolute path within project
                                for prefix in ['VERA/VERAApp/VERA/', 'VERA/VERACore/VERACore/', 'VERA/VERAChat/VERAChat/', 'VERA/VERAOpenTok/VERAOpenTok/', 'VERA/VERAOpenTokChatPlugin/VERAOpenTokChatPlugin/']:
                                    if prefix in file_path:
                                        file_path = prefix + file_path.split(prefix)[-1]
                                        break
                            
                            # Skip if not a Swift file or in project
                            if not file_path.endswith('.swift') or 'VERA/' not in file_path:
                                continue
                                
                            if file_path not in all_files:
                                all_files[file_path] = {
                                    'lines': {},
                                    'executable_lines': 0,
                                    'covered_lines': 0
                                }
                            
                            # Process line coverage
                            if 'functions' in file_data:
                                for func in file_data['functions']:
                                    if 'executableLines' in func:
                                        for line_info in func['executableLines']:
                                            line_num = line_info.get('line', 0)
                                            is_covered = line_info.get('executionCount', 0) > 0
                                            
                                            if line_num > 0:
                                                all_files[file_path]['lines'][line_num] = is_covered
                                                if line_num not in [l for l in all_files[file_path]['lines'].keys() if l < line_num]:
                                                    all_files[file_path]['executable_lines'] += 1
                                                    if is_covered:
                                                        all_files[file_path]['covered_lines'] += 1
                
        print(f'   ✅ Processed {os.path.basename(coverage_file)}')
    except Exception as e:
        print(f'   ⚠️  Failed to process {os.path.basename(coverage_file)}: {e}')

# Generate XML for each file
for file_path, file_info in all_files.items():
    file_elem = ET.SubElement(root, 'file')
    file_elem.set('path', file_path)
    
    # Add line coverage
    for line_num, is_covered in sorted(file_info['lines'].items()):
        line_elem = ET.SubElement(file_elem, 'lineToCover')
        line_elem.set('lineNumber', str(line_num))
        line_elem.set('covered', 'true' if is_covered else 'false')

# Save XML
xml_path = os.path.join(coverage_dir, 'sonarqube-generic-coverage.xml')
tree = ET.ElementTree(root)
ET.indent(tree, space='  ', level=0)  # Pretty print
tree.write(xml_path, encoding='UTF-8', xml_declaration=True)

# Also create JSON array format for other tools
json_targets = []
for file_path, file_info in all_files.items():
    json_targets.append({
        'name': os.path.basename(file_path),
        'path': file_path,
        'executableLines': file_info['executable_lines'],
        'coveredLines': file_info['covered_lines'],
        'lineCoverage': file_info['covered_lines'] / file_info['executable_lines'] if file_info['executable_lines'] > 0 else 0
    })

with open('$COMBINED_COVERAGE', 'w') as f:
    json.dump(json_targets, f, indent=2)

# Copy as main coverage file
with open(os.path.join(coverage_dir, 'coverage.json'), 'w') as f:
    json.dump(json_targets, f, indent=2)

print(f'📊 Coverage Summary:')
print(f'   Files processed: {len(all_files)}')
total_executable = sum(f['executable_lines'] for f in all_files.values())
total_covered = sum(f['covered_lines'] for f in all_files.values())
line_coverage = (total_covered / total_executable) if total_executable > 0 else 0
print(f'   Line Coverage: {line_coverage:.1%}')
print(f'   Lines: {total_covered}/{total_executable}')
print(f'   XML saved to: sonarqube-generic-coverage.xml')
"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully converted to SonarCloud XML format${NC}"
    else
        echo -e "${YELLOW}⚠️  Python conversion failed, creating minimal XML...${NC}"
        cat > "$COVERAGE_DIR/sonarqube-generic-coverage.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1">
  <!-- Minimal coverage report -->
</coverage>
EOF
        echo '[]' > "$COVERAGE_DIR/coverage.json"
    fi
else
    echo -e "${YELLOW}⚠️  Python3 not available, creating minimal reports...${NC}"
    cat > "$COVERAGE_DIR/sonarqube-generic-coverage.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<coverage version="1">
  <!-- Python3 not available -->
</coverage>
EOF
    echo '[]' > "$COVERAGE_DIR/coverage.json"
fi

# Generate summary
echo -e "${BLUE}📊 Coverage reports generated${NC}"

echo -e "${GREEN}✅ Coverage reports generated in: $COVERAGE_DIR${NC}"
echo -e "${BLUE}📄 Files created:${NC}"
ls -la "$COVERAGE_DIR/" 2>/dev/null || echo "Coverage directory created"

echo -e "${BLUE}💡 Processed test results:${NC}"
for xcresult in "${XCRESULT_FILES[@]}"; do
    echo "   • $(basename "$xcresult")"
done