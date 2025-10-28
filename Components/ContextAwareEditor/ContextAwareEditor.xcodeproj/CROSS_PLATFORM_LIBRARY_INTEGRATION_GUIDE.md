# Cross-Platform Library Integration Guide

This guide documents the solution for integrating platform-specific static libraries (iOS and macOS) in an Xcode project when the libraries have conflicting architectures that prevent creating a universal binary.

## Problem

- **iOS library**: Contains `arm64` architecture only
- **macOS library**: Contains `x86_64` and `arm64` architectures (universal binary)
- **Conflict**: Cannot combine into single universal library due to duplicate `arm64` architecture
- **Solution**: Use conditional build settings to link the correct library per platform

## Solution Steps

### Step 1: Organize Libraries with Platform-Specific Names

Use this script to copy and rename your libraries:

```bash
#!/bin/bash

# Script to organize platform-specific libraries
# This copies libraries from their original locations and renames them for conditional linking

# Update these paths to match your project structure
SOURCE_IOS_LIB="/Users/muthu/Projects/SangamKeyboards-2026/Components/PredictionLib/ios/libMurasuPredictionLib.a"
SOURCE_MACOS_LIB="/Users/muthu/Projects/SangamKeyboards-2026/Components/PredictionLib/macos/libMurasuPredictionLib.a"
TARGET_DIR="/Users/muthu/Projects/SangamKeyboards-2026/Components/ContextAwareEditor/ContextAwareEditor/MurasuIMEngine/lib"

echo "🔧 Setting up platform-specific libraries..."

# Create target directory
mkdir -p "${TARGET_DIR}"

# Copy and rename libraries
if [ -f "${SOURCE_IOS_LIB}" ]; then
    cp "${SOURCE_IOS_LIB}" "${TARGET_DIR}/libMurasuPredictionLib-iOS.a"
    echo "✅ iOS library copied and renamed"
else
    echo "❌ iOS library not found at: ${SOURCE_IOS_LIB}"
    exit 1
fi

if [ -f "${SOURCE_MACOS_LIB}" ]; then
    cp "${SOURCE_MACOS_LIB}" "${TARGET_DIR}/libMurasuPredictionLib-macOS.a"
    echo "✅ macOS library copied and renamed"
else
    echo "❌ macOS library not found at: ${SOURCE_MACOS_LIB}"
    exit 1
fi

echo ""
echo "📋 Final library structure:"
ls -la "${TARGET_DIR}/"

echo ""
echo "📋 Library architectures:"
echo "iOS library:"
lipo -info "${TARGET_DIR}/libMurasuPredictionLib-iOS.a"
echo "macOS library:"
lipo -info "${TARGET_DIR}/libMurasuPredictionLib-macOS.a"

echo ""
echo "✅ Libraries ready for conditional linking!"
echo "📍 Location: ${TARGET_DIR}"
echo ""
echo "🎯 Next: Configure Xcode build settings (see guide below)"
```

### Step 2: Configure Library Search Paths

In Xcode Build Settings:

1. **Select your target**
2. **Find "Library Search Paths"**
3. **Set to**: `$(PROJECT_DIR)/ContextAwareEditor/MurasuIMEngine/lib`

This single path works for both platforms since both renamed libraries are in the same directory.

### Step 3: Configure Platform-Specific Linker Flags

In Xcode Build Settings:

1. **Find "Other Linker Flags"**
2. **Click the disclosure arrow** to expand the setting
3. **For each configuration** (Debug, Release):
   - Click the **"+"** button
   - Select **"Any iOS Simulator SDK"**
   - Enter: `-lMurasuPredictionLib-iOS`
   - Click **"+"** again
   - Select **"Any iOS SDK"**
   - Enter: `-lMurasuPredictionLib-iOS`
   - Click **"+"** again  
   - Select **"Any macOS SDK"**
   - Enter: `-lMurasuPredictionLib-macOS`
   - Click **"+"** again
   - Select **"Any iOS Simulator SDK"** (or add to existing)
   - Enter: `-lc++`
   - Click **"+"** again
   - Select **"Any iOS SDK"** (or add to existing)
   - Enter: `-lc++`
   - Click **"+"** again
   - Select **"Any macOS SDK"** (or add to existing)
   - Enter: `-lc++`

**Important**: Each flag (`-lMurasuPredictionLib-XXX` and `-lc++`) should be **separate entries**, not combined.

## Final Configuration Summary

### Directory Structure
```
ContextAwareEditor/
└── MurasuIMEngine/
    └── lib/
        ├── libMurasuPredictionLib-iOS.a     # iOS library (arm64)
        └── libMurasuPredictionLib-macOS.a   # macOS library (x86_64, arm64)
```

### Build Settings Configuration

| Setting | Value |
|---------|-------|
| **Library Search Paths** | `$(PROJECT_DIR)/ContextAwareEditor/MurasuIMEngine/lib` |

| Platform | Other Linker Flags |
|----------|-------------------|
| **Any iOS Simulator SDK** | `-lMurasuPredictionLib-iOS` and `-lc++` (separate entries) |
| **Any iOS SDK** | `-lMurasuPredictionLib-iOS` and `-lc++` (separate entries) |
| **Any macOS SDK** | `-lMurasuPredictionLib-macOS` and `-lc++` (separate entries) |

### Verification

After configuration:

1. **Clean Build Folder** (⌘+Shift+K)
2. **Build for iOS Simulator** - should link `libMurasuPredictionLib-iOS.a`
3. **Build for iOS Device** - should link `libMurasuPredictionLib-iOS.a`
4. **Build for macOS** - should link `libMurasuPredictionLib-macOS.a`

## Common Troubleshooting

### Error: "Library 'LibraryName -lc++' not found"
- **Cause**: Combined linker flags into single entry
- **Fix**: Separate library flag and `-lc++` into individual entries

### Error: "Building for 'macOS', but linking iOS library"
- **Cause**: Conditional settings not configured correctly
- **Fix**: Verify macOS conditional entries point to macOS library

### Error: "Multiple commands produce"
- **Cause**: Script files added to Xcode target membership
- **Fix**: Remove scripts from target membership or move outside project

## Notes

- This solution works when libraries have conflicting architectures that prevent universal binary creation
- Each platform automatically links its appropriate library at build time
- The `-lc++` flag is required because the underlying library is written in C++
- Library search paths can be the same for all platforms since libraries have different names
