#!/bin/bash

# Script to create a universal library from iOS and macOS libraries
# This combines both libraries into a single file that works on both platforms

PROJECT_DIR="/Users/muthu/Projects/SangamKeyboards-2026/Components/ContextAwareEditor/ContextAwareEditor"

LIB_DIR="/Users/muthu/Projects/SangamKeyboards-2026/Components/PredictionLib"
IOS_LIB_DIR="${LIB_DIR}/ios"
MACOS_LIB_DIR="${LIB_DIR}/macos"

echo "Creating universal library for MurasuPredictionLib..."

# Paths to your current libraries
IOS_LIB="${IOS_LIB_DIR}/libMurasuPredictionLib.a"
MACOS_LIB="${MACOS_LIB_DIR}/libMurasuPredictionLib.a"
UNIVERSAL_LIB="${LIB_DIR}/universal/libMurasuPredictionLib.a"

# Check if libraries exist
if [ ! -f "$IOS_LIB" ]; then
    echo "❌ iOS library not found: $IOS_LIB"
    exit 1
fi

if [ ! -f "$MACOS_LIB" ]; then
    echo "❌ macOS library not found: $MACOS_LIB"
    exit 1
fi

echo "✓ Found iOS library: $IOS_LIB"
echo "✓ Found macOS library: $MACOS_LIB"

# Show current architectures
echo ""
echo "📋 Current library architectures:"
echo "iOS library:"
lipo -info "$IOS_LIB"
echo "macOS library:"
lipo -info "$MACOS_LIB"

# Create universal library using lipo
echo ""
echo "🔧 Creating universal library..."
lipo -create "$IOS_LIB" "$MACOS_LIB" -output "$UNIVERSAL_LIB"

if [ $? -eq 0 ]; then
    echo "✅ Universal library created successfully!"
    echo "📍 Location: $UNIVERSAL_LIB"
    
    # Show the result
    echo ""
    echo "📋 Universal library architectures:"
    lipo -info "$UNIVERSAL_LIB"
    
    echo ""
    echo "📁 File size comparison:"
    echo "iOS:       $(ls -lh "$IOS_LIB" | awk '{print $5}')"
    echo "macOS:     $(ls -lh "$MACOS_LIB" | awk '{print $5}')"
    echo "Universal: $(ls -lh "$UNIVERSAL_LIB" | awk '{print $5}')"
    
    echo ""
    echo "🎯 Next steps:"
    echo "1. In Xcode Build Settings, set Library Search Paths to:"
    echo "   \$(PROJECT_DIR)/ContextAwareEditor/MurasuIMEngine"
    echo ""
    echo "2. In Other Linker Flags, add:"
    echo "   -lMurasuPredictionLib -lc++"
    echo ""
    echo "3. Remove any platform-specific library settings"
    
else
    echo "❌ Failed to create universal library"
    echo "This might happen if the libraries have conflicting architectures"
    echo "Check the architecture information above"
fi
