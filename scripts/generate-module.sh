#!/bin/bash
# ============================================================================
# generate-module.sh — Automates VERA feature module creation
# ============================================================================
# Usage:  ./scripts/generate-module.sh <ModuleName> [options]
# Example: ./scripts/generate-module.sh Reactions --with-plugin --run-tests
#
# Options:
#   --with-plugin              Also create a plugin module (default: VERAVonage<Name>Plugin)
#   --plugin-name <ShortName>  Custom plugin class name (implies --with-plugin).
#                              VERA prefix added automatically for the directory/target.
#                              Example: --plugin-name VonageScreenSharePlugin
#   --no-plugin                Skip plugin creation (default)
#   --build                    Run xcodebuild build after generation (default)
#   --run-tests                Run xcodebuild tests after build (implies --build)
#   --skip-build               Skip xcodebuild build & test steps
#   --run-app                  Build & launch the VERA app in the simulator (default)
#   --no-run-app               Skip building & launching the app
# ============================================================================

set -euo pipefail

# ── Colours & helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { printf "${BLUE}ℹ  %s${NC}\n" "$1"; }
success() { printf "${GREEN}✅ %s${NC}\n" "$1"; }
warn()    { printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
step()    { printf "\n${CYAN}── Step %s ──────────────────────────────────────${NC}\n" "$1"; }
error()   { printf "${RED}❌ %s${NC}\n" "$1"; exit 1; }

# ── Paths (same strategy as format.sh) ───────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERA_DIR="$REPO_ROOT/VERA"
SCRIPT_DIR="$REPO_ROOT/scripts"

# ── Parse arguments ──────────────────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage: $0 <ModuleName> [--with-plugin|--no-plugin|--plugin-name <Name>] [--build] [--run-tests] [--skip-build] [--run-app|--no-run-app]"
  echo "Example: $0 Settings --with-plugin --build --run-tests"
  echo "         $0 ScreenShare --plugin-name VonageScreenSharePlugin"
  exit 1
fi

NAME="$1"; shift

# Validate PascalCase: must start with uppercase letter
if [[ ! "$NAME" =~ ^[A-Z] ]]; then
  error "ModuleName must be PascalCase (start with uppercase). Got: '$NAME'. Example: Settings, Reactions"
fi

WITH_PLUGIN=false; RUN_TESTS=false; SKIP_BUILD=true; RUN_APP=true; PLUGIN_NAME_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-plugin)  WITH_PLUGIN=true;  shift ;;
    --plugin-name)
      [[ $# -lt 2 ]] && error "--plugin-name requires a value (e.g. --plugin-name VonageScreenSharePlugin)"
      PLUGIN_NAME_OVERRIDE="$2"
      [[ ! "$PLUGIN_NAME_OVERRIDE" =~ ^[A-Z] ]] && error "--plugin-name must be PascalCase. Got: '$PLUGIN_NAME_OVERRIDE'"
      WITH_PLUGIN=true
      shift 2 ;;
    --no-plugin)    WITH_PLUGIN=false; PLUGIN_NAME_OVERRIDE=""; shift ;;
    --build)        SKIP_BUILD=false;  shift ;;
    --run-tests)    RUN_TESTS=true; SKIP_BUILD=false; shift ;;
    --skip-build)   SKIP_BUILD=true;   shift ;;
    --run-app)      RUN_APP=true;      shift ;;
    --no-run-app)   RUN_APP=false;     shift ;;
    *)              error "Unknown option: $1" ;;
  esac
done

# ── Derived names ────────────────────────────────────────────────────────────
MODULE="VERA${NAME}"
if [[ -n "$PLUGIN_NAME_OVERRIDE" ]]; then
  PLUGIN="VERA${PLUGIN_NAME_OVERRIDE}"
  PLUGIN_SHORT="$PLUGIN_NAME_OVERRIDE"
else
  PLUGIN="VERAVonage${NAME}Plugin"
  PLUGIN_SHORT="Vonage${NAME}Plugin"
fi
PLUGIN_LOWER=$(echo "$PLUGIN_SHORT" | tr '[:upper:]' '[:lower:]')
NAME_UPPER=$(echo "$NAME" | tr '[:lower:]' '[:upper:]')
NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
NAME_CAMEL="$(echo "${NAME:0:1}" | tr '[:upper:]' '[:lower:]')${NAME:1}"
FLAG="${NAME_UPPER}_ENABLED"
CONFIG_KEY="allow${NAME}"
FUNC_NAME="are${NAME}Enabled"
TODAY=$(date "+%-d/%-m/%y")
HEADER="//\n//  Created by Vonage on ${TODAY}.\n//"

MODULE_DIR="$VERA_DIR/$MODULE"
PLUGIN_DIR="$VERA_DIR/$PLUGIN"

# xcpretty is optional — fall back to cat if not installed
if command -v xcpretty &>/dev/null; then
  PRETTIFY="xcpretty"
else
  warn "xcpretty not found — xcodebuild output will not be prettified"
  PRETTIFY="cat"
fi

# Auto-detect an available iPhone simulator for iOS builds
IOS_SIM_NAME=$(xcrun simctl list devices available 2>/dev/null \
  | grep -oE 'iPhone [^(]+' \
  | head -1 \
  | sed 's/ *$//')
if [[ -z "$IOS_SIM_NAME" ]]; then
  warn "No iPhone simulator found — iOS builds will use generic destination"
  IOS_DESTINATION="platform=iOS Simulator,name=Any iOS Simulator Device"
else
  info "Simulator: $IOS_SIM_NAME"
  IOS_DESTINATION="platform=iOS Simulator,name=$IOS_SIM_NAME"
fi

info "Module  : $MODULE"
info "Plugin  : $PLUGIN (enabled=$WITH_PLUGIN)"
info "Flag    : $FLAG"
info "Config  : meetingRoomSettings.$CONFIG_KEY"

# ══════════════════════════════════════════════════════════════════════════════
# Step 0 — Validate environment
# ══════════════════════════════════════════════════════════════════════════════
step "0: Validate environment"

if [[ ! -d "$VERA_DIR" ]]; then
  error "VERA directory not found at $VERA_DIR"
fi
if [[ ! -f "$VERA_DIR/Project.swift" ]]; then
  error "Root Project.swift not found at $VERA_DIR/Project.swift"
fi
if [[ ! -f "$VERA_DIR/Config/app-config.json" ]]; then
  error "app-config.json not found at $VERA_DIR/Config/app-config.json"
fi
if [[ -d "$MODULE_DIR" ]]; then
  error "Module directory already exists: $MODULE_DIR"
fi
if [[ "$WITH_PLUGIN" == "true" ]] && [[ -d "$PLUGIN_DIR" ]]; then
  error "Plugin directory already exists: $PLUGIN_DIR"
fi

for cmd in tuist xcodebuild; do
  if ! command -v "$cmd" &>/dev/null; then
    error "Required command not found: $cmd"
  fi
done

success "Environment OK"

# Close Xcode to avoid workspace conflicts during generation
if pgrep -x "Xcode" &>/dev/null; then
  warn "Xcode is running — force-quitting to avoid conflicts…"
  killall Xcode 2>/dev/null
  sleep 2
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 1 — Create feature module ($MODULE)
# ══════════════════════════════════════════════════════════════════════════════
step "1: Create feature module $MODULE"

# ---------- directories ----------
mkdir -p "$MODULE_DIR/$MODULE/Domain/Entities"
mkdir -p "$MODULE_DIR/$MODULE/Domain/Repository"
mkdir -p "$MODULE_DIR/$MODULE/Domain/Use cases"
mkdir -p "$MODULE_DIR/$MODULE/Data"
mkdir -p "$MODULE_DIR/$MODULE/UI/View"
mkdir -p "$MODULE_DIR/$MODULE/UI/View models"
mkdir -p "$MODULE_DIR/$MODULE/Utils"
mkdir -p "$MODULE_DIR/$MODULE/Wireframe"
mkdir -p "$MODULE_DIR/$MODULE/Resources"
mkdir -p "$MODULE_DIR/${MODULE}App"
mkdir -p "$MODULE_DIR/${MODULE}Tests"
mkdir -p "$MODULE_DIR/${MODULE}SnapshotTests"
mkdir -p "$MODULE_DIR/Derived/InfoPlists"
mkdir -p "$MODULE_DIR/Derived/Sources"

info "Directories created"

# ---------- Project.swift ----------
cat > "$MODULE_DIR/Project.swift" << SWIFT_EOF
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "$MODULE",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "$MODULE",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.$MODULE",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["$MODULE/**"],
            resources: ["$MODULE/Resources/**"],
            scripts: [.swiftLint(targetName: "$MODULE")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "${MODULE}App",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.${MODULE}App",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "${MODULE}App",
                    "CFBundleDisplayName": "${MODULE}App",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["${MODULE}App/**"],
            scripts: [.swiftLint(targetName: "${MODULE}App")],
            dependencies: [
                .target(name: "$MODULE")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "${MODULE}Tests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.${MODULE}Tests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["${MODULE}Tests/**"],
            dependencies: [
                .target(name: "$MODULE")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "${MODULE}SnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.${MODULE}SnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["${MODULE}SnapshotTests/**"],
            dependencies: [
                .target(name: "$MODULE"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "${MODULE}Tests",
            shared: true,
            buildAction: .buildAction(targets: ["${MODULE}Tests"]),
            testAction: .targets(["${MODULE}Tests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "${MODULE}SnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["${MODULE}SnapshotTests"]),
            testAction: .targets(["${MODULE}SnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
SWIFT_EOF
info "Project.swift created"

# ---------- UI / View ----------
cat > "$MODULE_DIR/$MODULE/UI/View/${NAME}View.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import SwiftUI

/// Main view for the $NAME feature.
public struct ${NAME}View: View {
    @ObservedObject private var viewModel: ${NAME}ViewModel

    public init(viewModel: ${NAME}ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Implement view
        Text("$NAME")
    }
}
SWIFT_EOF

# ---------- UI / View models ----------
cat > "$MODULE_DIR/$MODULE/UI/View models/${NAME}ViewModel.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

/// View model for ``${NAME}View``.
@MainActor
public final class ${NAME}ViewModel: ObservableObject {
    // TODO: Add published properties and dependencies

    public init() {}
}
SWIFT_EOF

# ---------- Utils ----------
cat > "$MODULE_DIR/$MODULE/Utils/Bundle+${MODULE}.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

/// Provides the resource bundle for the $MODULE framework.
extension Bundle {
    /// The bundle associated with the $MODULE module.
    public static var ${NAME_CAMEL}: Bundle { Bundle(for: ${MODULE}BundleToken.self) }
}

private final class ${MODULE}BundleToken {}
SWIFT_EOF

# ---------- Resources (Localizable.xcstrings) ----------
cat > "$MODULE_DIR/$MODULE/Resources/Localizable.xcstrings" << 'XCSTRINGS_EOF'
{
  "sourceLanguage" : "en",
  "strings" : {

  },
  "version" : "1.0"
}
XCSTRINGS_EOF

# ---------- Data ----------
cat > "$MODULE_DIR/$MODULE/Data/${NAME}DataSource.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

// TODO: Add data source implementations
SWIFT_EOF

# ---------- Domain / Entities ----------
cat > "$MODULE_DIR/$MODULE/Domain/Entities/${NAME}Entity.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

// TODO: Add domain entities
SWIFT_EOF

# ---------- Domain / Repository ----------
cat > "$MODULE_DIR/$MODULE/Domain/Repository/${NAME}Repository.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

// TODO: Add repository protocols
SWIFT_EOF

# ---------- Domain / Use cases ----------
cat > "$MODULE_DIR/$MODULE/Domain/Use cases/${NAME}UseCase.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

// TODO: Add use cases
SWIFT_EOF

# ---------- Wireframe ----------
cat > "$MODULE_DIR/$MODULE/Wireframe/${NAME}Factory.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation

/// Factory for creating the $NAME feature components.
public enum ${NAME}Factory {
    // TODO: Add factory methods
}
SWIFT_EOF

# ---------- Demo App ----------
cat > "$MODULE_DIR/${MODULE}App/${MODULE}App.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import SwiftUI
import $MODULE

@main
struct ${MODULE}DemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Text("$MODULE Demo")
                    .font(.largeTitle)
            }
        }
    }
}
SWIFT_EOF

# ---------- Unit Tests ----------
cat > "$MODULE_DIR/${MODULE}Tests/${NAME}Tests.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Testing
@testable import $MODULE

@Suite("${NAME} Tests")
struct ${NAME}Tests {
    // TODO: Add tests
}
SWIFT_EOF

# ---------- Snapshot Tests ----------
cat > "$MODULE_DIR/${MODULE}SnapshotTests/${NAME}SnapshotTests.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Testing
@testable import $MODULE

@Suite("${NAME} Snapshot Tests")
struct ${NAME}SnapshotTests {
    // TODO: Add snapshot tests
}
SWIFT_EOF

success "Feature module $MODULE created"

# ══════════════════════════════════════════════════════════════════════════════
# Step 2 — Create plugin module ($PLUGIN)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$WITH_PLUGIN" == "true" ]]; then
  step "2: Create plugin module $PLUGIN"

  mkdir -p "$PLUGIN_DIR/$PLUGIN"
  mkdir -p "$PLUGIN_DIR/${PLUGIN}Tests"
  mkdir -p "$PLUGIN_DIR/Derived/InfoPlists"
  mkdir -p "$PLUGIN_DIR/Derived/Sources"

  # ---------- Plugin Project.swift ----------
  cat > "$PLUGIN_DIR/Project.swift" << SWIFT_EOF
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "$PLUGIN",
    targets: [
        .target(
            name: "$PLUGIN",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.$PLUGIN",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["$PLUGIN/**"],
            scripts: [.swiftLint(targetName: "$PLUGIN")],
            dependencies: [
                .project(target: "$MODULE", path: "../$MODULE"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "${PLUGIN}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.${PLUGIN}Tests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["${PLUGIN}Tests/**"],
            dependencies: [
                .project(target: "$MODULE", path: "../$MODULE"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "$PLUGIN"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "${PLUGIN}Tests",
            shared: true,
            buildAction: .buildAction(targets: ["${PLUGIN}Tests"]),
            testAction: .targets(["${PLUGIN}Tests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
SWIFT_EOF
  info "Plugin Project.swift created"

  # ---------- Plugin source ----------
  cat > "$PLUGIN_DIR/$PLUGIN/${PLUGIN_SHORT}.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Foundation
import $MODULE

/// Vonage implementation of the $NAME plugin.
public final class ${PLUGIN_SHORT} {
    // TODO: Add plugin implementation

    public init() {}
}
SWIFT_EOF

  # ---------- Plugin tests ----------
  cat > "$PLUGIN_DIR/${PLUGIN}Tests/${PLUGIN_SHORT}Tests.swift" << SWIFT_EOF
$(printf '%b' "$HEADER")

import Testing
import $MODULE
@testable import $PLUGIN

@Suite("${PLUGIN_SHORT} Tests")
struct ${PLUGIN_SHORT}Tests {
    // TODO: Add plugin tests
}
SWIFT_EOF

  success "Plugin module $PLUGIN created (3 files)"
else
  info "Skipping plugin creation (--no-plugin)"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 3 — Update app-config.json
# ══════════════════════════════════════════════════════════════════════════════
step "3: Update app-config.json"

CONFIG_FILE="$VERA_DIR/Config/app-config.json"

# Use python3 to safely add the key to meetingRoomSettings
python3 -c "
import json, sys
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

mrs = config.get('meetingRoomSettings', {})
if '$CONFIG_KEY' in mrs:
    print('Key $CONFIG_KEY already exists — skipping')
    sys.exit(0)

mrs['$CONFIG_KEY'] = True
config['meetingRoomSettings'] = dict(sorted(mrs.items()))

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('Added $CONFIG_KEY to app-config.json')
"

success "app-config.json updated"

# ══════════════════════════════════════════════════════════════════════════════
# Step 4 — Update VERA/Project.swift
# ══════════════════════════════════════════════════════════════════════════════
step "4: Update VERA/Project.swift"

ROOT_PROJECT="$VERA_DIR/Project.swift"

# 4a. Add feature-flag reader function (after the last existing are...Enabled / is...Enabled func)
if ! grep -q "are${NAME}Enabled\|is${NAME}Enabled" "$ROOT_PROJECT"; then

  # Find the line "// MARK: - Dynamic Dependencies" and insert the function before it
  MARKER="// MARK: - Dynamic Dependencies"
  FUNC_BLOCK=$(cat << 'INNEREOF'
/// Returns whether NAME_PH is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "CONFIG_KEY_PH": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.CONFIG_KEY_PH` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func FUNC_NAME_PH() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["CONFIG_KEY_PH"] as! Bool
}

INNEREOF
)
  # Restore trailing newlines stripped by $()
  FUNC_BLOCK="${FUNC_BLOCK}"$'\n\n'

  # Replace placeholders — longest first to avoid substring collisions
  FUNC_BLOCK="${FUNC_BLOCK//FUNC_NAME_PH/$FUNC_NAME}"
  FUNC_BLOCK="${FUNC_BLOCK//CONFIG_KEY_PH/$CONFIG_KEY}"
  FUNC_BLOCK="${FUNC_BLOCK//NAME_PH/$NAME}"

  # Insert before marker
  python3 -c "
import sys
marker = '$MARKER'
block = '''$FUNC_BLOCK'''
with open('$ROOT_PROJECT', 'r') as f:
    content = f.read()
if marker in content:
    content = content.replace(marker, block + marker)
    with open('$ROOT_PROJECT', 'w') as f:
        f.write(content)
    print('Inserted $FUNC_NAME() into Project.swift')
else:
    print('WARNING: Marker not found, skipping function insertion', file=sys.stderr)
"
else
  info "Feature-flag function for $NAME already exists — skipping"
fi

# 4b. Add dependency block in createDependencies()
if ! grep -q "\"$MODULE\"" "$ROOT_PROJECT"; then
  # Find "return dependencies" and insert before it
  if [[ "$WITH_PLUGIN" == "true" ]]; then
    DEP_BLOCK="    if ${FUNC_NAME}() {\n        dependencies.append(contentsOf: [\n            .project(target: \"$MODULE\", path: \"$MODULE\"),\n            .project(target: \"$PLUGIN\", path: \"$PLUGIN\"),\n        ])\n    }\n"
  else
    DEP_BLOCK="    if ${FUNC_NAME}() {\n        dependencies.append(contentsOf: [\n            .project(target: \"$MODULE\", path: \"$MODULE\"),\n        ])\n    }\n"
  fi

  python3 -c "
content = open('$ROOT_PROJECT').read()
marker = '    return dependencies'
block = '''$(printf '%b' "$DEP_BLOCK")'''
if marker in content:
    content = content.replace(marker, block + '\n' + marker)
    open('$ROOT_PROJECT', 'w').write(content)
    print('Inserted dependency block for $MODULE')
else:
    print('WARNING: return dependencies marker not found')
"
else
  info "Dependency for $MODULE already exists — skipping"
fi

# 4c. Add build-settings flag in createBuildSettings()
if ! grep -q "\"$FLAG\"" "$ROOT_PROJECT"; then
  python3 -c "
content = open('$ROOT_PROJECT').read()
# Insert before the 'if !flags.isEmpty' line
marker = '    if !flags.isEmpty'
block = '''    if ${FUNC_NAME}() {
        baseSettings[\"${FLAG}\"] = \"1\"
        flags.append(\"${FLAG}\")
        print(\"${NAME} feature enabled in build settings.\")
    }

'''
if marker in content:
    content = content.replace(marker, block + marker)
    open('$ROOT_PROJECT', 'w').write(content)
    print('Inserted build-settings flag for $FLAG')
else:
    print('WARNING: flags.isEmpty marker not found')
"
else
  info "Build-settings flag $FLAG already exists — skipping"
fi

success "VERA/Project.swift updated"

# ══════════════════════════════════════════════════════════════════════════════
# Step 5 — Update CI workflow
# ══════════════════════════════════════════════════════════════════════════════
step "5: Update CI workflow (.github/workflows/ci.yml)"

CI_FILE="$REPO_ROOT/.github/workflows/ci.yml"

if [[ ! -f "$CI_FILE" ]]; then
  warn "ci.yml not found — skipping CI update"
else
  # 5a. Add macOS unit-test step (after the last *Tests (macOS) step, before "Preboot iOS Simulator")
  if ! grep -q "${MODULE}Tests (macOS)" "$CI_FILE"; then
    NAME_LOWER_ID=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
    python3 -c "
content = open('$CI_FILE').read()
marker = '    - name: Preboot iOS Simulator'
block = '''    - name: Run ${MODULE}Tests (macOS)
      id: ${NAME_LOWER_ID}-tests-macos
      run: |
        echo \"🧪 Running ${MODULE}Tests on macOS\"
        xcodebuild test \\\\
          -workspace VERA/VERA.xcworkspace \\\\
          -scheme ${MODULE}Tests \\\\
          -destination \"platform=macOS\" \\\\
          -derivedDataPath DerivedData \\\\
          -enableCodeCoverage YES \\\\
          -resultBundlePath DerivedData/${MODULE}Tests-macOS.xcresult \\\\
          \$XCODE_COMMON_FLAGS | xcpretty

'''
if marker in content:
    content = content.replace(marker, block + marker)
    open('$CI_FILE', 'w').write(content)
    print('Inserted macOS unit test step for $MODULE')
else:
    print('WARNING: Preboot iOS Simulator marker not found')
"
  else
    info "macOS unit test step already exists — skipping"
  fi

  # 5b. Add iOS snapshot-test step (before plugin test steps)
  if ! grep -q "${MODULE}SnapshotTests (iOS" "$CI_FILE"; then
    NAME_LOWER_ID=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
    # Insert before the plugin tests section (VERAVonageChatPluginTests)
    python3 -c "
content = open('$CI_FILE').read()
marker = '    - name: Run VERAVonageChatPluginTests (iOS Simulator)'
block = '''    - name: Run ${MODULE}SnapshotTests (iOS Simulator)
      id: ${NAME_LOWER_ID}-snapshot-tests
      timeout-minutes: 15
      run: |
        echo \"📸 Building ${MODULE}SnapshotTests on iOS Simulator\"
        xcodebuild build-for-testing \\\\
          -workspace VERA/VERA.xcworkspace \\\\
          -scheme ${MODULE}SnapshotTests \\\\
          -destination \"platform=iOS Simulator,name=iPhone 17\" \\\\
          -derivedDataPath DerivedData \\\\
          -enableCodeCoverage YES \\\\
          -parallel-testing-enabled NO \\\\
          \$XCODE_COMMON_FLAGS | xcpretty
        
        echo \"📸 Running ${MODULE}SnapshotTests on iOS Simulator\"
        xcodebuild test-without-building \\\\
          -workspace VERA/VERA.xcworkspace \\\\
          -scheme ${MODULE}SnapshotTests \\\\
          -destination \"platform=iOS Simulator,name=iPhone 17\" \\\\
          -derivedDataPath DerivedData \\\\
          -enableCodeCoverage YES \\\\
          -resultBundlePath DerivedData/${MODULE}SnapshotTests-iOS.xcresult \\\\
          -parallel-testing-enabled NO \\\\
          \$XCODE_COMMON_FLAGS | xcpretty

'''
if marker in content:
    content = content.replace(marker, block + marker)
    open('$CI_FILE', 'w').write(content)
    print('Inserted iOS snapshot test step for $MODULE')
else:
    print('WARNING: VERAVonageChatPluginTests marker not found — appending at end of tests section')
"
  else
    info "iOS snapshot test step already exists — skipping"
  fi

  # 5c. Add plugin test step (if --with-plugin)
  if [[ "$WITH_PLUGIN" == "true" ]]; then
    if ! grep -q "${PLUGIN}Tests" "$CI_FILE"; then
      NAME_LOWER_ID=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
      python3 -c "
content = open('$CI_FILE').read()
marker = '    - name: Run VERAVonageTests (iOS Simulator)'
block = '''    - name: Run ${PLUGIN}Tests (iOS Simulator)
      id: ${PLUGIN_LOWER}-tests
      timeout-minutes: 15
      run: |
        echo \"📸 Running ${PLUGIN}Tests on iOS Simulator\"
        xcodebuild build-for-testing \\\\
          -workspace VERA/VERA.xcworkspace \\\\
          -scheme ${PLUGIN}Tests \\\\
          -destination \"platform=iOS Simulator,name=iPhone 17\" \\\\
          -derivedDataPath DerivedData \\\\
          -enableCodeCoverage YES \\\\
          \$XCODE_COMMON_FLAGS | xcpretty

        xcodebuild test-without-building \\\\
          -workspace VERA/VERA.xcworkspace \\\\
          -scheme ${PLUGIN}Tests \\\\
          -destination \"platform=iOS Simulator,name=iPhone 17\" \\\\
          -derivedDataPath DerivedData \\\\
          -enableCodeCoverage YES \\\\
          -resultBundlePath DerivedData/${PLUGIN}Tests-iOS.xcresult \\\\
          \$XCODE_COMMON_FLAGS | xcpretty

'''
if marker in content:
    content = content.replace(marker, block + marker)
    open('$CI_FILE', 'w').write(content)
    print('Inserted plugin test step for $PLUGIN')
else:
    print('WARNING: VERAVonageTests marker not found')
"
    else
      info "Plugin test step already exists — skipping"
    fi
  fi

  # 5d. Add artifact paths
  if ! grep -q "${MODULE}Tests-macOS.xcresult" "$CI_FILE"; then
    python3 -c "
content = open('$CI_FILE').read()
marker = '          DerivedData/Build/Products/'
lines = '          DerivedData/${MODULE}Tests-macOS.xcresult\n'
lines += '          DerivedData/${MODULE}SnapshotTests-iOS.xcresult\n'
if '$WITH_PLUGIN' == 'true':
    lines += '          DerivedData/${PLUGIN}Tests-iOS.xcresult\n'
if marker in content:
    content = content.replace(marker, lines + marker)
    open('$CI_FILE', 'w').write(content)
    print('Inserted artifact paths')
else:
    print('WARNING: Build/Products marker not found')
"
  else
    info "Artifact paths already exist — skipping"
  fi

  success "ci.yml updated"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 6 — Run tuist generate
# ══════════════════════════════════════════════════════════════════════════════
step "6: Run tuist clean & generate"

cd "$VERA_DIR"
tuist clean
tuist generate --no-open
cd "$REPO_ROOT"

success "Tuist project generated"

# ══════════════════════════════════════════════════════════════════════════════
# Step 7 — Run format.sh --fix
# ══════════════════════════════════════════════════════════════════════════════
step "7: Run format.sh --fix"

if [[ -x "$SCRIPT_DIR/format.sh" ]]; then
  "$SCRIPT_DIR/format.sh" --fix || warn "format.sh reported issues (non-fatal)"
  success "Formatting complete"
else
  warn "format.sh not found or not executable — skipping"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 8 — Build
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$SKIP_BUILD" == "true" ]]; then
  info "Skipping build (--skip-build)"
else
  step "8: Build $MODULE"

  COMMON_FLAGS="COMPILER_INDEX_STORE_ENABLE=NO ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO RUN_SWIFTLINT=NO"

  info "Building ${MODULE}Tests scheme (macOS)…"
  xcodebuild build \
    -workspace "$VERA_DIR/VERA.xcworkspace" \
    -scheme "${MODULE}Tests" \
    -destination "platform=macOS" \
    -derivedDataPath "$REPO_ROOT/DerivedData" \
    $COMMON_FLAGS | $PRETTIFY || error "Build failed for ${MODULE}Tests"
  success "$MODULE build succeeded"

  if [[ "$WITH_PLUGIN" == "true" ]]; then
    info "Building ${PLUGIN}Tests scheme (iOS Simulator)…"
    xcodebuild build \
      -workspace "$VERA_DIR/VERA.xcworkspace" \
      -scheme "${PLUGIN}Tests" \
      -destination "$IOS_DESTINATION" \
      -derivedDataPath "$REPO_ROOT/DerivedData" \
      $COMMON_FLAGS | $PRETTIFY || error "Build failed for ${PLUGIN}Tests"
    success "$PLUGIN build succeeded"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 9 — Tests (optional)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_TESTS" == "true" ]] && [[ "$SKIP_BUILD" != "true" ]]; then
  step "9: Run tests"

  COMMON_FLAGS="COMPILER_INDEX_STORE_ENABLE=NO ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO RUN_SWIFTLINT=NO"

  info "Running ${MODULE}Tests (macOS)…"
  xcodebuild test \
    -workspace "$VERA_DIR/VERA.xcworkspace" \
    -scheme "${MODULE}Tests" \
    -destination "platform=macOS" \
    -derivedDataPath "$REPO_ROOT/DerivedData" \
    -enableCodeCoverage YES \
    $COMMON_FLAGS | $PRETTIFY || error "Tests failed for ${MODULE}Tests"
  success "${MODULE}Tests passed"

  if [[ "$WITH_PLUGIN" == "true" ]]; then
    info "Running ${PLUGIN}Tests (iOS Simulator)…"
    xcodebuild test \
      -workspace "$VERA_DIR/VERA.xcworkspace" \
      -scheme "${PLUGIN}Tests" \
      -destination "$IOS_DESTINATION" \
      -derivedDataPath "$REPO_ROOT/DerivedData" \
      -enableCodeCoverage YES \
      $COMMON_FLAGS | $PRETTIFY || error "Tests failed for ${PLUGIN}Tests"
    success "${PLUGIN}Tests passed"
  fi
else
  if [[ "$RUN_TESTS" != "true" ]]; then
    info "Skipping tests (use --run-tests to enable)"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Module generation complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Module:  ${CYAN}$MODULE${NC}  →  VERA/$MODULE/"
if [[ "$WITH_PLUGIN" == "true" ]]; then
  echo -e "  Plugin:  ${CYAN}$PLUGIN${NC}  →  VERA/$PLUGIN/"
fi
echo -e "  Config:  meetingRoomSettings.${CONFIG_KEY} = true"
echo -e "  Flag:    ${FLAG}"
echo ""
echo -e "  Files created:"
echo -e "    📁 VERA/$MODULE/Project.swift"
echo -e "    📁 VERA/$MODULE/$MODULE/  (Domain, Data, UI, Utils, Wireframe)"
echo -e "    📁 VERA/$MODULE/${MODULE}App/  (Demo app)"
echo -e "    📁 VERA/$MODULE/${MODULE}Tests/  (Unit tests)"
echo -e "    📁 VERA/$MODULE/${MODULE}SnapshotTests/  (Snapshot tests)"
if [[ "$WITH_PLUGIN" == "true" ]]; then
  echo -e "    📁 VERA/$PLUGIN/Project.swift"
  echo -e "    📁 VERA/$PLUGIN/$PLUGIN/  (Plugin source)"
  echo -e "    📁 VERA/$PLUGIN/${PLUGIN}Tests/  (Plugin tests)"
fi
echo ""
echo -e "  Integration:"
echo -e "    ✅ Config/app-config.json  → ${CONFIG_KEY}: true"
echo -e "    ✅ VERA/Project.swift      → feature flag + dependency + build setting"
echo -e "    ✅ .github/workflows/ci.yml → test steps + artifacts"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Git — Stage all changes & commit
# ══════════════════════════════════════════════════════════════════════════════
step "Git: Commit generated module"

cd "$REPO_ROOT"
git add -A

COMMIT_MSG="feat: Add ${MODULE} feature module"
COMMIT_BODY="- Module: ${MODULE} (VERA/${MODULE}/)"
if [[ "$WITH_PLUGIN" == "true" ]]; then
  COMMIT_BODY="${COMMIT_BODY}
- Plugin: ${PLUGIN} (VERA/${PLUGIN}/)"
fi
COMMIT_BODY="${COMMIT_BODY}
- Config: meetingRoomSettings.${CONFIG_KEY} = true
- Flag: ${FLAG}
- Updated: app-config.json, VERA/Project.swift, ci.yml"

git commit --no-verify -m "$COMMIT_MSG" -m "$COMMIT_BODY"

success "Changes committed: $COMMIT_MSG"

# ══════════════════════════════════════════════════════════════════════════════
# Final — Open Xcode & run VERA app
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$RUN_APP" == "true" ]]; then
  step "Final: Open Xcode & run VERA app"

  info "Opening VERA workspace in Xcode…"
  open "$VERA_DIR/VERA.xcworkspace"

  # Wait for Xcode to finish launching
  sleep 3

  info "Triggering build & run (⌘R) via Xcode…"
  osascript -e 'tell application "Xcode" to activate' \
            -e 'delay 1' \
            -e 'tell application "System Events" to keystroke "r" using command down' \
    2>/dev/null || warn "Could not trigger ⌘R — please press ⌘R manually in Xcode"

  success "Xcode opened — VERA is building & running 🚀"
else
  info "Skipping app launch (use --run-app to enable)"
fi
