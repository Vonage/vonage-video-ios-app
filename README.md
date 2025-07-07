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
- ❌ **UI tests disabled** by default (too slow for regular CI)

### **UI Tests Pipeline** (On demand only)
- 🎯 **Manual trigger**: Use GitHub Actions "Run workflow" button
- ⏰ **Scheduled**: Runs automatically at 2 AM UTC daily  
- 📝 **Commit message**: Include `[ui-tests]` in commit message
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
- **Resource efficient**: UI tests run only when needed
- **Flexible**: Easy to enable UI tests when required

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

# Simulate CI environment locally
./scripts/simulate-ci.sh

# Upload to SonarCloud (requires token)
export SONAR_TOKEN=your_sonar_token
./scripts/upload-sonarcloud.sh
```

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
