#!/bin/bash

echo "🔍 Checking Swift format..."

# Navigate to project root
cd "$(dirname "$0")/.."

FORMAT_ISSUES=""
FILE_COUNT=0

echo "📁 Searching for Swift files in VERA directory..."

while IFS= read -r -d '' file; do
  if [ -f "$file" ]; then
    FILE_COUNT=$((FILE_COUNT + 1))
    echo "🔍 Checking format: $file"
    
    if ! swift-format format --configuration .swift-format "$file" | diff -q "$file" - > /dev/null 2>&1; then
      FORMAT_ISSUES="$FORMAT_ISSUES$file needs formatting\n"
      echo "❌ Format issue: $file"
    else
      echo "✅ Format OK: $file"
    fi
  fi
done < <(find ./VERA -name "*.swift" \
  -not -path "./build/*" \
  -not -path "./.build/*" \
  -not -path "./DerivedData/*" \
  -not -path "./Pods/*" \
  -not -path "./Carthage/*" \
  -not -path "./vendor/*" \
  -not -path "*/project.xcworkspace/*" -print0)

echo ""
echo "📊 Checked $FILE_COUNT Swift files"

if [ -n "$FORMAT_ISSUES" ]; then
  echo ""
  echo "❌ Format issues found:"
  echo -e "$FORMAT_ISSUES"
  echo ""
  echo "💡 To fix format issues:"
  echo "   swift-format format --in-place --configuration .swift-format VERA/**/*.swift"
  echo "   scripts/format-swift.sh"
  exit 1
else
  echo ""
  echo "✅ All Swift files are properly formatted!"
  exit 0
fi
