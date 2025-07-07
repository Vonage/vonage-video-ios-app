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
