# libMurasuPrediction Integration Guide

## Directory Structure
Create this structure in your Xcode project:

```
Libraries/
├── iOS/
│   └── libMurasuPrediction.a      # Your iOS library
├── macOS/
│   └── libMurasuPrediction.a      # Your macOS library
└── Headers/
    ├── predictor_c_api.h          # Already exists
    └── ScriptConverterStructs.h   # Already exists
```

## Xcode Build Settings Configuration

### 1. Library Search Paths
In your target's Build Settings, set **Library Search Paths**:
- For iOS: `$(SRCROOT)/Libraries/iOS`
- For macOS: `$(SRCROOT)/Libraries/macOS`

Or use conditional settings:
- `$(SRCROOT)/Libraries/$(PLATFORM_NAME)`

### 2. Header Search Paths
Set **Header Search Paths** to:
- `$(SRCROOT)/Libraries/Headers`

### 3. Other Linker Flags
Add to **Other Linker Flags**:
- `-lMurasuPrediction`
- `-lc++` (since it's a C++ library)

### 4. Platform-Specific Configuration

#### Option A: Using Build Configurations
Create separate build configurations for iOS and macOS, each with their own library search paths.

#### Option B: Using Conditional Build Settings (Recommended)
In Build Settings, use the "+" button to add conditions:

**Library Search Paths:**
- Any iOS Simulator SDK: `$(SRCROOT)/Libraries/iOS`
- Any iOS SDK: `$(SRCROOT)/Libraries/iOS`  
- Any macOS SDK: `$(SRCROOT)/Libraries/macOS`

## Alternative: Using Swift Package Manager

If you prefer SPM, create a Package.swift:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MurasuPrediction",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "MurasuPrediction", targets: ["MurasuPrediction"])
    ],
    targets: [
        .target(
            name: "MurasuPrediction",
            dependencies: ["MurasuPredictionBinary"]
        ),
        .binaryTarget(
            name: "MurasuPredictionBinary",
            path: "MurasuPrediction.xcframework" // If using XCFramework
        )
    ]
)
```

## Verification Steps

1. Build for iOS Simulator - should link iOS library
2. Build for iOS Device - should link iOS library  
3. Build for macOS - should link macOS library
4. Check that all prediction functions work on both platforms

## Troubleshooting

### Issue: "library not found"
- Verify library search paths are correct
- Check that .a files are in the specified directories
- Ensure target membership is set correctly

### Issue: "symbol not found" 
- Add `-lc++` to Other Linker Flags
- Verify the library was built for the correct architecture
- Check that headers match the library version

### Issue: Platform detection not working
- Use `lipo -info libMurasuPrediction.a` to verify architectures
- For iOS: should include arm64, x86_64 (simulator)
- For macOS: should include arm64, x86_64