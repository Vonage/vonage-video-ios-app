# vonage-video-ios-app

[![CI](https://github.com/Vonage/vonage-video-ios-app/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Vonage/vonage-video-ios-app/actions/workflows/ci.yml)
[![UI Tests](https://github.com/Vonage/vonage-video-ios-app/actions/workflows/ui-tests.yml/badge.svg)](https://github.com/Vonage/vonage-video-ios-app/actions/workflows/ui-tests.yml)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)

Vonage Video API Swift iOS reference application

## 🚀 CI/CD Strategy

### **Fast CI Pipeline** (Default - runs on every PR/push)
- ✅ **Code formatting** check with swift-format
- ✅ **Build** verification for iOS Simulator
- ✅ **VERACore tests** on macOS (native, super fast, ~1 second)
- ✅ **UI tests enabled** on Pull Requests (with smart detection)

### **UI Tests Pipeline** (Automatic on PRs)
- **Triggered on**: Pull Requests to main branch with UI-relevant changes
- **Smart detection**: Only runs when Swift/UI files change (single macOS job)
- **Automatic feedback**: Comments on PR with test results
- 🎯 **Manual trigger**: Use GitHub Actions "Run workflow" button
- 🔧 **Device selection**: Choose iPhone 16, iPhone 16 Pro, iPhone 15, or iPad

### **Local Development**
```bash
# Fast tests only (recommended for development)
./scripts/test-core.sh

# Core tests + UI tests (slow)
./scripts/test.sh -ui

# Core tests + coverage reports
./scripts/test.sh -coverage

# Core tests + UI tests + coverage reports
./scripts/test.sh -ui -coverage

# UI tests only (very slow)
./scripts/test-ui.sh

# Generate coverage reports from existing test results
./scripts/generate-coverage.sh

# Upload to SonarCloud (requires SONAR_TOKEN)
export SONAR_TOKEN=your_token_here
./scripts/upload-sonarcloud.sh
```

### **Why This Strategy?**
- **Ultra-fast feedback**: Core tests run natively on macOS in ~1 second
- **No simulator overhead**: VERACore tests run directly on macOS
- **CI-friendly**: Works without code signing certificates
- **Better DX**: Developers get instant feedback on logic changes
- **Intelligent automation**: UI tests run automatically on PRs with relevant changes
- **Resource efficient**: Smart detection prevents unnecessary test runs
- **Immediate feedback**: PR comments show test results instantly

## 📱 Project Structure

This project uses a workspace with three targets:
- **VERA** (iOS app with UI and E2E tests)
- **VERACore** (Universal business logic, testable on macOS)
- **VERAOpenTok** (OpenTok wrapper implementing domain interfaces)

## 📊 Code Coverage & Quality

This project integrates with **SonarCloud** for code quality analysis and coverage reporting.

### **Coverage Reports**
- Generated from native macOS VERACore tests
- Supports both local and CI environments
- Compatible with SonarCloud format

### **SonarCloud Integration**
- **Automatic analysis** on main branch and pull requests
- **Coverage tracking** for Swift code
- **Quality gate** enforcement
- **Security hotspot** detection

### **Local Quality Analysis**
```bash
# Run tests with coverage
./scripts/test.sh -coverage

# Generate coverage from existing test results
./scripts/generate-coverage.sh

# Run code quality checks (swift-format + SwiftLint)
./scripts/code-quality.sh

# Run only swift-format
./scripts/code-quality.sh --format-only

# Run only SwiftLint
./scripts/code-quality.sh --lint-only
./scripts/lint-swift.sh

# Auto-fix code quality issues
./scripts/code-quality.sh --fix

# Simulate CI environment locally
./scripts/simulate-ci.sh

# Upload to SonarCloud (requires token)
export SONAR_TOKEN=your_sonar_token
./scripts/upload-sonarcloud.sh
```

### **Code Quality Tools**
This project uses two complementary tools for code quality:

- **swift-format**: Handles code formatting and style consistency
- **SwiftLint**: Enforces Swift best practices and detects potential issues

Both tools are configured to work on all Swift files in the workspace and can be run individually or together.

### **Git Hooks**
This project includes a pre-push git hook that automatically runs SwiftLint before allowing a push:

- **Automatic enforcement**: Runs SwiftLint on every push
- **Prevents quality issues**: Blocks push if code doesn't meet standards
- **Fast execution**: Only runs essential code quality checks
- **Helpful feedback**: Shows exactly what needs to be fixed

```bash
# Git hook runs automatically on push, but you can test it manually:
scripts/git-hooks/pre-push

# If quality checks fail, fix them with:
swiftlint --fix
scripts/lint-swift.sh --fix
scripts/code-quality.sh --fix  # For both swift-format + SwiftLint
```

The git hook is installed automatically during project setup. If you need to reinstall it manually:
```bash
cp scripts/git-hooks/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

**Why only SwiftLint in the pre-push hook?**
- **Faster execution**: Only essential quality checks before push
- **Less disruptive**: Developers can format code locally with their IDE
- **Focus on quality**: Pre-push should prevent real issues, not minor formatting

### **Setting up SonarCloud**
1. Go to [SonarCloud.io](https://sonarcloud.io)
2. Import your GitHub repository
3. Get your project token from Account → Security
4. Add `SONAR_TOKEN` to your GitHub repository secrets
5. Configure the project key in `sonar-project.properties`

### **Troubleshooting SonarCloud**

#### **Coverage Issues**
```bash
# If coverage generation fails, try:
./scripts/simulate-ci.sh  # Full CI simulation

# Manual cleanup and regeneration:
rm -rf DerivedData coverage-reports
./scripts/test-core.sh -coverage
```

#### **CI/CD Issues**
- **Missing SONAR_TOKEN**: Add token to GitHub repository secrets
- **No test results**: Check that VERACore scheme is configured for testing
- **Coverage report empty**: Verify tests are actually running and generating coverage

#### **Local Development**
```bash
# Check if coverage data exists
ls -la coverage-reports/

# Verify coverage JSON format
cat coverage-reports/coverage.json | python3 -m json.tool

# Debug test execution
./scripts/test-core.sh -coverage --verbose
```

## 📸 Snapshot Testing

VERACore includes comprehensive snapshot testing for iOS UI components using [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing).

### Architecture

**📦 Test Separation Strategy:**

- **`VERACoreTests`**: Universal tests (macOS, iOS) for core functionality
  - ✅ Fast execution (< 5 seconds)
  - ✅ No simulators required  
  - ✅ Logic, algorithms, data processing
  - ✅ Runs automatically in CI

- **`VERACoreSnapshotTests`**: iOS-specific snapshot tests for UI components
  - ⚠️ Slow execution (30+ seconds)
  - ⚠️ Requires iOS simulator
  - 🎯 UI component visual validation
  - 🎯 **Manual execution only** - not part of regular test suite

### Setup Snapshot Testing

✅ **Snapshot testing is now configured and ready to use!**

The project includes:
- **`VERACoreTests`**: Universal tests (macOS, iOS) for core functionality  
- **`VERACoreSnapshotTests`**: iOS-specific snapshot tests for UI components
- **Reference images**: Committed snapshots for iPhone 16 simulator

### Running Tests

**🚀 Core/Logic Tests (Fast - Recommended for development):**
```bash
# Run core tests (universal - macOS, no UI)
./scripts/test-core.sh

# Run core tests with coverage
./scripts/test-core.sh -coverage
```

**🎮 Platform/UI Tests (Slow - For integration testing):**
```bash
# Run all platform tests including UI
./scripts/test.sh -ui

# Run with coverage 
./scripts/test.sh -ui -coverage
```

**📸 Snapshot Tests (Separate - Only for UI component validation):**
```bash
# Run iOS snapshot tests (independent from other tests)
./scripts/test-snapshots.sh

# Record new reference snapshots
./scripts/test-snapshots.sh -r

# Test on specific device
./scripts/test-snapshots.sh -d "iPhone 16 Pro"
```

### Snapshot Testing Features

- **📱 Multi-device testing**: iPhone, iPad, different screen sizes
- **🌓 Light/Dark mode**: Automatic testing of both themes
- **♿️ Accessibility**: Tests with different Dynamic Type sizes
- **🔄 Orientation**: Portrait and landscape testing
- **🎯 Precision control**: Configurable pixel tolerance
- **📁 Organized output**: Snapshots stored in `__Snapshots__` folders

### Best Practices

1. **Separate concerns**: Use universal tests for logic, iOS tests for UI
2. **Development workflow**: Use `./scripts/test-core.sh` for fast feedback
3. **UI changes**: Run `./scripts/test-snapshots.sh` when modifying UI components
4. **Record snapshots** when creating new UI components
5. **Review changes** carefully when snapshots fail
6. **Commit reference images** to version control
7. **Use descriptive names** for your snapshot tests
8. **Test edge cases** like empty states, errors, loading

### When to Use Snapshot Tests

**✅ Use snapshot tests for:**
- New UI components or views
- Visual regression testing
- Before releasing UI changes
- Validating design consistency

**❌ Don't use snapshot tests for:**
- Regular development (too slow)
- Logic testing (use core tests)
- Automated CI runs (unless specific UI validation needed)

### Example Snapshot Test

```swift
func testVideoCallButton() throws {
    let button = VideoCallButton(
        title: "Join Call",
        isEnabled: true,
        action: { }
    )
    
    // Test with size that fits
    assertSnapshot(
        of: button, 
        as: .image(layout: .sizeThatFits), 
        record: SnapshotTestConfig.isRecording
    )
}
```

## 📸 **Snapshot Testing & Git LFS**

This project uses **Git LFS** (Large File Storage) to efficiently manage snapshot test images.

### **Git LFS Setup**
```bash
# Install Git LFS (if not already installed)
brew install git-lfs

# Initialize LFS in your local repository
git lfs install
```

### **Working with Snapshot Images**
- **PNG files are automatically tracked** by Git LFS
- **Faster clones** - Images are downloaded on-demand
- **Better collaboration** - Reduces repository size for all developers

```bash
# Run snapshot tests (generates reference images)
./scripts/test-snapshots.sh

# Re-record snapshots when UI changes
./scripts/test-snapshots.sh -r

# Check LFS status
git lfs ls-files
git lfs status
```

### **Important Notes**
- **First-time setup**: Run `git lfs pull` after cloning to download images
- **CI/CD**: GitHub Actions automatically handles LFS files
- **File types tracked**: `*.png`, `*.jpg`, `*.jpeg`

## 🆕 **Quick Start for New Developers**

### **Automated Setup (Recommended)**
```bash
# Clone the repository
git clone https://github.com/vonage/vonage-video-ios-app.git
cd vonage-video-ios-app

# Run the automated setup script
./scripts/setup-project.sh
```

The setup script will:
- ✅ Check system requirements (macOS, Xcode)
- ✅ Install development tools (Homebrew, Git LFS, swift-format)
- ✅ Configure Git LFS and download snapshot images
- ✅ Validate project configuration
- ✅ Test initial build
- ✅ Show you next steps and useful commands

### **Manual Setup (if needed)**
```bash
# Install dependencies
brew install git-lfs swift-format

# Initialize Git LFS
git lfs install
git lfs pull

# Verify setup
./scripts/validate-setup.sh
```

### **First Steps After Setup**
```bash
# Run core tests (fast)
./scripts/test-core.sh

# Run all tests with coverage
./scripts/test.sh -coverage

# Try snapshot testing
./scripts/test-snapshots.sh
```
