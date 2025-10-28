#!/bin/bash

# Script to create XCFramework from separate iOS and macOS libraries
# Place your libMurasuPrediction.a files in the appropriate directories:
# ios/libMurasuPrediction.a
# macos/libMurasuPrediction.a

# Create XCFramework
xcodebuild -create-xcframework \
    -library ios/libMurasuPrediction.a \
    -headers headers/ \
    -library macos/libMurasuPrediction.a \
    -headers headers/ \
    -output MurasuPrediction.xcframework

echo "XCFramework created successfully!"
echo "Add MurasuPrediction.xcframework to your Xcode project"