# rSoGuitar iOS App - Setup Guide

## Quick Start

### Option 1: Create New Xcode Project (Recommended)

1. **Open Xcode** and create a new project:
   - File > New > Project
   - Choose "iOS" > "App"
   - Product Name: `rSoGuitar`
   - Team: Select your development team
   - Organization Identifier: `com.rsoguitar` (or your preferred)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - Minimum iOS Version: **17.0**

2. **Delete default files**:
   - Delete `ContentView.swift` (if created)
   - Keep `rSoGuitarApp.swift` but replace its contents with the one from this repo

3. **Add all source files**:
   - In Xcode, right-click on the project in Navigator
   - Select "Add Files to rSoGuitar..."
   - Navigate to the `rSoGuitar` folder
   - Select all subfolders (App, Models, ViewModels, Views, Services, Utilities)
   - Check "Copy items if needed"
   - Check "Create groups"
   - Add to targets: rSoGuitar

4. **Configure Info.plist**:
   - Replace the default Info.plist with the one from `rSoGuitar/Info.plist`
   - Or copy the settings manually

5. **Add Assets**:
   - Add `Resources/Assets.xcassets` to the project
   - Add app icon (1024x1024) to AppIcon

6. **Enable Capabilities**:
   - Select the project in Navigator
   - Select the rSoGuitar target
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "In-App Purchase"

7. **Configure Bundle Identifier**:
   - In "Signing & Capabilities"
   - Set Bundle Identifier to: `com.rsoguitar.app` (or your preferred)

8. **Build and Run**:
   - Select a simulator or device
   - Press Cmd+R to build and run

### Option 2: Use Existing Project Structure

If you already have an Xcode project:

1. Copy all Swift files to your project
2. Ensure all files are added to the target
3. Update Info.plist with the provided settings
4. Enable In-App Purchase capability
5. Build and run

## Project Configuration

### Minimum Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Capabilities Required
- In-App Purchase (for StoreKit 2)

### Bundle Identifier
Recommended: `com.rsoguitar.app`

## StoreKit Setup (For Testing)

1. **Create App in App Store Connect**:
   - Go to App Store Connect
   - Create new app with bundle ID matching your project

2. **Create In-App Purchase Products**:
   - Monthly Subscription: `com.rsoguitar.premium.monthly`
   - Yearly Subscription: `com.rsoguitar.premium.yearly`
   - Lifetime Purchase: `com.rsoguitar.premium.lifetime`

3. **Test in Sandbox**:
   - Use sandbox test accounts in App Store Connect
   - Test purchases will not charge real money

## Troubleshooting

### Build Errors

1. **Missing imports**: Ensure all files have proper imports
2. **SwiftData errors**: Ensure iOS 17.0+ is set as minimum deployment target
3. **StoreKit errors**: Ensure In-App Purchase capability is enabled

### Runtime Issues

1. **Audio not playing**: Check that audio files are in Resources/Audio/ (if using)
2. **Patterns not showing**: Verify FretboardCalculator is working correctly
3. **Subscription not working**: Ensure StoreKit products are configured in App Store Connect

## Next Steps

1. Add audio samples to `Resources/Audio/`
2. Add lesson content JSON files to `Resources/Content/` (optional)
3. Customize app icon and launch screen
4. Configure App Store Connect for distribution
5. Test on physical devices

## File Structure Verification

After setup, verify you have:
- ✅ 31 Swift files
- ✅ Info.plist configured
- ✅ Assets.xcassets with AppIcon
- ✅ All folders properly organized
- ✅ In-App Purchase capability enabled

