#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/merge_coverage.sh [DERIVED_DATA_DIR] [OUTPUT_XML]
# Examples:
#   scripts/merge_coverage.sh
#   scripts/merge_coverage.sh "./DerivedData" sonarqube-generic-coverage.xml
#
# Walks every `*.xcresult` under DERIVED_DATA_DIR, converts each to the
# SonarQube Generic Test Data XML format, and merges them into a single
# document. The merge is union-by-line: when the same source file appears
# in multiple xcresult bundles (the normal case when each test scheme runs
# separately in CI), a line is reported as covered if *any* bundle saw it
# executed. Naively concatenating per-bundle XMLs would produce duplicated
# `<file path="…">` blocks that some parsers conflate, dropping coverage.

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

# Stage each xcresult's converted XML in a temp dir, then union-merge them.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for R in "${XCRESULT_FILES[@]}"; do
  echo "➕ Converting coverage from: $R"
  "$CONVERTER" "$R" > "$TMP_DIR/$(basename "$R").xml"
done

# Union-merge by (file path, line number). A line is covered if any input
# bundle reports it covered. Output is a single well-formed SonarQube
# Generic Coverage XML.
python3 - "$OUT_XML" "$TMP_DIR"/*.xml <<'PY'
import re
import sys
import xml.etree.ElementTree as ET

out_path = sys.argv[1]
inputs = sys.argv[2:]

# files: path -> { line_number(int): covered(bool) }
files = {}

for path in inputs:
    tree = ET.parse(path)
    root = tree.getroot()
    for file_elem in root.findall("file"):
        fpath = file_elem.get("path")
        if not fpath:
            continue
        bucket = files.setdefault(fpath, {})
        for line in file_elem.findall("lineToCover"):
            try:
                ln = int(line.get("lineNumber"))
            except (TypeError, ValueError):
                continue
            covered = line.get("covered") == "true"
            # Union: covered wins.
            bucket[ln] = bucket.get(ln, False) or covered

# Emit one <file> block per source, with deduplicated <lineToCover> lines.
out = ['<?xml version="1.0" encoding="UTF-8"?>', '<coverage version="1">']
for fpath in sorted(files):
    out.append(f'  <file path="{fpath}">')
    for ln in sorted(files[fpath]):
        covered = "true" if files[fpath][ln] else "false"
        out.append(f'    <lineToCover lineNumber="{ln}" covered="{covered}"/>')
    out.append("  </file>")
out.append("</coverage>")

with open(out_path, "w") as f:
    f.write("\n".join(out) + "\n")
PY

echo "✅ Combined coverage written to: $OUT_XML"
