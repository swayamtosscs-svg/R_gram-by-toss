# iOS Build Guide for R-Gram App

## ⚠️ Important Note
**iOS builds can ONLY be done on macOS with Xcode installed.**  
Windows cannot build iOS apps directly. You'll need:
- A Mac computer, OR
- Access to a macOS virtual machine, OR  
- A CI/CD service like GitHub Actions, Codemagic, or AppCircle

## Prerequisites for iOS Build

1. **macOS** (macOS 12.0 or later)
2. **Xcode** (latest version from App Store)
3. **CocoaPods** (iOS dependency manager)
4. **Apple Developer Account** (for App Store distribution)
5. **Flutter SDK** installed

## Setup Steps (on macOS)

### 1. Install CocoaPods
```bash
sudo gem install cocoapods
```

### 2. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

### 3. Configure Signing & Bundle Identifier

Open `ios/Runner.xcworkspace` in Xcode and:
- Set your Team (Apple Developer Account)
- Set Bundle Identifier (e.g., `com.yourcompany.rgram`)
- Configure Signing & Capabilities

### 4. Build for iOS Simulator (Testing)
```bash
flutter build ios --simulator
```

### 5. Build iOS App Archive (for App Store/TestFlight)
```bash
flutter build ipa
```

This will create an `.ipa` file in `build/ios/ipa/` directory.

### 6. Build for Development (Device Testing)
```bash
flutter build ios --release
```

## Alternative: Build Using Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target device/simulator
3. Product → Archive
4. Distribute App → Choose distribution method (App Store, Ad Hoc, Enterprise, or Development)

## CI/CD Options (Build from Windows)

### Option 1: GitHub Actions
Create `.github/workflows/ios-build.yml` to build on macOS runners.

### Option 2: Codemagic
- Free tier available
- Connect your Git repository
- Automatic iOS builds

### Option 3: AppCircle
- Free tier available
- Automated iOS builds

## Current iOS Configuration

- **Bundle Display Name**: My Auth App (update in Info.plist)
- **Bundle Name**: my_auth_app
- **Version**: 1.0.0+1 (from pubspec.yaml)
- **Minimum iOS Version**: Check in Xcode project settings

## Required Permissions (Already Configured)

- Camera (for live streaming)
- Microphone (for live streaming)
- Photo Library (for profile pictures)

## Notes

- The `.ipa` file is the iOS equivalent of Android's `.apk`
- For testing on a device, you need a provisioning profile
- For App Store, you need an Apple Developer account ($99/year)



