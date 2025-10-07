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

# Check if slather is installed
SLATHER_CMD=""
if command -v slather &> /dev/null; then
    SLATHER_CMD="slather"
    USE_SLATHER=true
elif [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
    # Test if bundle exec slather works
    if bundle exec slather version &> /dev/null; then
        SLATHER_CMD="bundle exec slather"
        USE_SLATHER=true
    else
        echo -e "${YELLOW}⚠️  Slather via bundler has issues (nokogiri dependency). Falling back to xccov...${NC}"
        USE_SLATHER=false
    fi
else
    echo -e "${YELLOW}⚠️  slather not found. Falling back to xccov...${NC}"
    USE_SLATHER=false
fi

# Find ALL test results
DERIVED_DATA_PATH="$PROJECT_ROOT/DerivedData"
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
mkdir -p "$COVERAGE_DIR"

# ✅ Find ALL .xcresult files
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
    echo '{"coveredLines":0,"executableLines":0,"lineCoverage":0,"targets":[]}' > "$COVERAGE_DIR/coverage.json"
    echo -e "${GREEN}✅ Minimal coverage report created${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Found ${#XCRESULT_FILES[@]} test result(s)${NC}"

# Process coverage with Slather (preferred - can handle multiple targets)
if [ "$USE_SLATHER" = true ]; then
    echo -e "${BLUE}🔄 Generating combined coverage with Slather...${NC}"
    cd "$PROJECT_ROOT"
    
    # ✅ Slather can process all targets at once from the workspace
    if $SLATHER_CMD coverage \
        --sonarqube-xml \
        --output-directory "$COVERAGE_DIR" \
        --workspace VERA/VERA.xcworkspace \
        --scheme VERA \
        --binary-basename VERA \
        --source-directory . \
        VERA/VERA.xcodeproj 2>/dev/null; then
        echo -e "${GREEN}✅ Generated SonarQube XML with Slather${NC}"
        
        # Also generate cobertura format as backup
        $SLATHER_CMD coverage \
            --cobertura-xml \
            --output-directory "$COVERAGE_DIR" \
            --workspace VERA/VERA.xcworkspace \
            --scheme VERA \
            --binary-basename VERA \
            --source-directory . \
            VERA/VERA.xcodeproj 2>/dev/null || echo -e "${YELLOW}⚠️  Cobertura generation failed${NC}"
            
        echo -e "${GREEN}✅ Slather coverage generation completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Slather failed, falling back to xccov...${NC}"
        USE_SLATHER=false
    fi
fi

# ✅ Fallback: Process each .xcresult individually and combine
if [ "$USE_SLATHER" = false ]; then
    echo -e "${BLUE}📊 Generating coverage with xccov...${NC}"
    
    COMBINED_COVERAGE="$COVERAGE_DIR/combined_coverage.json"
    echo '{"targets": []}' > "$COMBINED_COVERAGE"
    
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
    
    # ✅ Combine all individual coverage files
    if command -v python3 &> /dev/null; then
        echo -e "${BLUE}🔄 Combining coverage data...${NC}"
        python3 -c "
import json
import glob
import os

coverage_dir = '$COVERAGE_DIR'
combined_data = {'targets': [], 'lineCoverage': 0, 'coveredLines': 0, 'executableLines': 0}

# Process all individual coverage files
for coverage_file in glob.glob(os.path.join(coverage_dir, 'coverage_*.json')):
    try:
        with open(coverage_file, 'r') as f:
            data = json.load(f)
            if 'targets' in data:
                combined_data['targets'].extend(data['targets'])
            elif 'data' in data:  # Alternative format
                combined_data['targets'].extend(data['data'])
        print(f'   ✅ Processed {os.path.basename(coverage_file)}')
    except Exception as e:
        print(f'   ⚠️  Failed to process {os.path.basename(coverage_file)}: {e}')

# Calculate totals
total_executable = 0
total_covered = 0
for target in combined_data['targets']:
    if 'executableLines' in target:
        total_executable += target['executableLines']
    if 'coveredLines' in target:
        total_covered += target['coveredLines']

combined_data['executableLines'] = total_executable
combined_data['coveredLines'] = total_covered
combined_data['lineCoverage'] = (total_covered / total_executable) if total_executable > 0 else 0

# Save combined coverage
with open('$COMBINED_COVERAGE', 'w') as f:
    json.dump(combined_data, f, indent=2)

print(f'📊 Combined Coverage Summary:')
print(f'   Targets: {len(combined_data[\"targets\"])}')
print(f'   Line Coverage: {combined_data[\"lineCoverage\"]:.1%}')
print(f'   Lines: {total_covered}/{total_executable}')
"
        # Copy combined as main coverage
        cp "$COMBINED_COVERAGE" "$COVERAGE_DIR/coverage.json"
        echo -e "${GREEN}✅ Combined coverage data from ${#XCRESULT_FILES[@]} test results${NC}"
    else
        # Fallback: just use the first valid coverage file
        FIRST_VALID=$(find "$COVERAGE_DIR" -name "coverage_*.json" | head -1)
        if [ -n "$FIRST_VALID" ]; then
            cp "$FIRST_VALID" "$COVERAGE_DIR/coverage.json"
            echo -e "${YELLOW}⚠️  Python3 not available, using single coverage file${NC}"
        fi
    fi
fi

# Generate summary
echo -e "${BLUE}📊 Generating coverage summary...${NC}"

if command -v python3 &> /dev/null && [ -f "$COVERAGE_DIR/coverage.json" ]; then
    python3 -c "
import json
import os

coverage_file = '$COVERAGE_DIR/coverage.json'
formats_found = []

if os.path.exists('$COVERAGE_DIR/sonarqube-generic-coverage.xml'):
    formats_found.append('SonarQube XML')
if os.path.exists('$COVERAGE_DIR/cobertura.xml'):
    formats_found.append('Cobertura XML')
if os.path.exists(coverage_file):
    formats_found.append('JSON')
    
    try:
        with open(coverage_file, 'r') as f:
            data = json.load(f)
        
        targets = len(data.get('targets', []))
        coverage = data.get('lineCoverage', 0)
        covered = data.get('coveredLines', 0)
        executable = data.get('executableLines', 0)
        
        print('📊 Final Coverage Summary:')
        print(f'   Test Targets Processed: ${#XCRESULT_FILES[@]}')
        print(f'   Coverage Targets: {targets}')
        print(f'   Line Coverage: {coverage:.1%}')
        print(f'   Lines Covered: {covered:,}/{executable:,}')
        print(f'   Formats: {', '.join(formats_found)}')
    except Exception as e:
        print('📊 Coverage files generated (details unavailable)')
        print(f'   Test Results Processed: ${#XCRESULT_FILES[@]}')
        print(f'   Formats: {', '.join(formats_found)}')
" 2>/dev/null || echo -e "${BLUE}📊 Coverage reports generated from ${#XCRESULT_FILES[@]} test results${NC}"
fi

echo -e "${GREEN}✅ Coverage reports generated in: $COVERAGE_DIR${NC}"
echo -e "${BLUE}📄 Files created:${NC}"
ls -la "$COVERAGE_DIR/" 2>/dev/null || echo "Coverage directory created"

echo -e "${BLUE}💡 Processed test results:${NC}"
for xcresult in "${XCRESULT_FILES[@]}"; do
    echo "   • $(basename "$xcresult")"
done