#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/merge_coverage.sh [DERIVED_DATA_DIR] [OUTPUT_XML]
# Examples:
#   scripts/merge_coverage.sh
#   scripts/merge_coverage.sh "./DerivedData" sonarqube-generic-coverage.xml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

DERIVED_DATA_DIR="$PROJECT_ROOT/DerivedData"
COVERAGE_DIR="$PROJECT_ROOT/coverage-reports"
mkdir -p "$COVERAGE_DIR"

OUT_XML="$COVERAGE_DIR/sonarqube-generic-coverage.xml"

CONVERTER="$SCRIPT_DIR/xccov-to-sonarqube-generic.sh"
if [[ ! -x "$CONVERTER" ]]; then
  echo "❌ Missing or non-executable converter script: $CONVERTER" >&2
  exit 1
fi

XCRESULT_FILES=()
if [ -d "$DERIVED_DATA_DIR" ]; then
    echo -e "🔍 Searching for all test results..."
    while IFS= read -r -d '' file; do
        XCRESULT_FILES+=("$file")
        echo -e "   📁 Found: $(basename "$file")"
    done < <(find "$DERIVED_DATA_DIR" -name "*.xcresult" -type d -print0 2>/dev/null)
fi

if [[ ${#XCRESULT_FILES[@]} -eq 0 ]]; then
  echo "❌ No .xcresult bundles found under: $DERIVED_DATA_DIR" >&2
  exit 1
fi

echo "📁 DerivedData: $DERIVED_DATA_DIR"
echo "📦 Found xcresult bundles:"
printf '  - %s\n' "${XCRESULT_FILES[@]}"

# Merge all individual coverage XMLs into a single generic one for SonarCloud
echo '<coverage version="1">' > "$OUT_XML"
for R in "${XCRESULT_FILES[@]}"; do
  echo "➕ Merging coverage from: $R"
  # The converter emits <coverage>...</coverage>
  # Remove the header and footer lines before concatenating
  "$CONVERTER" "$R" | sed '1d;$d' >> "$OUT_XML"
done
echo '</coverage>' >> "$OUT_XML"

echo "✅ Combined coverage written to: $OUT_XML"

