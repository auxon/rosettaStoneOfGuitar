# Fixing Info.plist Build Error

## Quick Fix (Recommended)

Modern Xcode projects automatically generate Info.plist from build settings. Follow these steps:

### Step 1: Remove Info.plist from Xcode Project
1. In Xcode, find `Info.plist` in the Project Navigator
2. Right-click on it
3. Select **"Delete"**
4. Choose **"Remove Reference"** (not "Move to Trash" - we'll keep it in the repo)

### Step 2: Configure Build Settings
1. Select your project in the Navigator
2. Select the **rSoGuitar** target
3. Go to the **"Build Settings"** tab
4. Search for "Info.plist" in the search bar
5. Find **"Generate Info.plist File"** and ensure it's set to **YES** (default)

### Step 3: Configure App Settings
In the **"Info"** tab (next to Build Settings), configure:

- **Display Name**: `rSoGuitar`
- **Bundle Identifier**: `com.rsoguitar.app` (or your preferred)
- **Version**: `1.0`
- **Build**: `1`
- **Minimum Deployments**: `17.0`

### Step 4: Add Usage Descriptions (if needed)
If you need usage descriptions later, add them in the **"Info"** tab under **"Custom iOS Target Properties"**:
- Add key: `NSMicrophoneUsageDescription` (if needed)
- Add key: `NSPhotoLibraryUsageDescription` (if needed)

## Alternative: Use Custom Info.plist

If you prefer to use the custom Info.plist file:

1. In Build Settings, search for "Info.plist"
2. Set **"Generate Info.plist File"** to **NO**
3. Set **"Info.plist File"** to `rSoGuitar/Info.plist`
4. Make sure Info.plist is NOT in "Copy Bundle Resources" build phase

## Verify Fix

After making changes:
1. Clean build folder: **Product > Clean Build Folder** (Shift+Cmd+K)
2. Build again: **Product > Build** (Cmd+B)

The error should be resolved!

