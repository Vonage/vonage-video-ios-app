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
- ✅ **VERACore tests** on macOS (native, super fast, ~5-10 seconds)
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

# UI tests only (very slow)
./scripts/test-ui.sh
```

### **Why This Strategy?**
- **Fast feedback**: Core tests run in ~30 seconds vs ~5+ minutes for UI tests
- **Better DX**: Developers get quick feedback on logic changes
- **Resource efficient**: UI tests run only when needed
- **Flexible**: Easy to enable UI tests when required

## 📱 Project Structure

This project uses a workspace with three targets:
- **VERA** (iOS app with UI and E2E tests)
- **VERACore** (Universal business logic, testable on macOS)
- **VERAOpenTok** (OpenTok wrapper implementing domain interfaces)
