Yes, this is excellent information! Let me create an updated and more specific setup document based on your actual codebase:

---

# Murasu IME Mobile Editor Components - Project Setup Guide

## Project Overview

This guide describes how to set up a development workspace for building custom editor components for iOS and Android that integrate with the **Murasu IME Engine** - specifically the prediction library and key translator components.

### Architecture

```
MobileEditorWorkspace/
├── MurasuIMEngine/              # Existing C++ core (submodule or copy)
│   ├── include/murasuime/
│   ├── src/prediction_library/
│   ├── src/word_predictor/
│   └── CMakeLists.txt
├── ios-editor/                  # iOS editor component + test app
│   ├── EditorComponent/         # Reusable framework
│   ├── EditorTestApp/           # Test harness
│   └── ios-editor.xcworkspace
└── android-editor/              # Android editor component + test app
    ├── editor-library/          # Reusable library module
    ├── editor-test-app/         # Test harness app
    ├── build.gradle.kts
    └── settings.gradle.kts
```

### Key Components to Integrate

1. **Prediction Library**: `predictor_c_api.h` with word/ngram predictions
2. **Key Translator**: Obj-C protocol wrapper for composition and key translation
3. **Shared Usage**: Same prediction library used in:
   - iOS keyboard extension
   - Android keyboard extension
   - iOS editor test app
   - Android editor test app

---

## Part 1: C++ Core Integration

### Using Existing MurasuIMEngine

Since you already have a working CMake-based build system, you'll reference it rather than restructure it.

**Option A: Git Submodule (Recommended)**
```bash
cd MobileEditorWorkspace
git submodule add <your-murasu-repo-url> MurasuIMEngine
```

**Option B: Direct Copy**
```bash
cp -r /path/to/MurasuIMEngine ./MurasuIMEngine
```

### Relevant Components

From your CMakeLists.txt, the key components are:
- `src/prediction_library/` - C API wrapper (`predictor_c_api.h`)
- `src/word_predictor/` - Core prediction engine
- Key translator C++ files (location TBD in your project)

---

## Part 2: iOS Editor Component Setup

### Directory Structure

```
ios-editor/
├── ios-editor.xcworkspace
├── EditorComponent/
│   ├── EditorComponent.xcodeproj
│   ├── Sources/
│   │   ├── Editor/
│   │   │   ├── ContextAwareTextView.swift
│   │   │   ├── ContextAwareEditor.swift (SwiftUI wrapper)
│   │   │   └── InlineCandidateView.swift
│   │   ├── Bridges/
│   │   │   ├── PredictorWrapper.swift (Swift API)
│   │   │   ├── KeyTranslatorBridge.swift
│   │   │   ├── PredictorBridge.mm (Obj-C++ bridge)
│   │   │   └── KeyTranslatorBridge.mm
│   │   └── KeyTranslator/
│   │       └── KeyTranslator.h (your existing protocol)
│   ├── include/
│   │   └── EditorComponent-Bridging-Header.h
│   └── Resources/
│       └── (trie files, dictionaries if bundled)
└── EditorTestApp/
    ├── EditorTestApp.xcodeproj
    ├── ContentView.swift
    └── Resources/
        ├── TamilTrie.dat
        └── userdict.db
```

### Linking Prediction Library

**Method 1: Build from Source in Framework**

In `EditorComponent.xcodeproj` build settings:
1. Add `MurasuIMEngine/include` to **Header Search Paths**
2. Add source files to compile:
   - `MurasuIMEngine/src/prediction_library/*.cpp`
   - `MurasuIMEngine/src/word_predictor/*.cpp`
   - Key translator `.cpp` files

**Method 2: Link Pre-built Universal Library**

If you build a universal binary for macOS/iOS:
```bash
cd MurasuIMEngine
mkdir build-ios
cd build-ios
cmake -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_ARCHITECTURES="arm64" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  ..
cmake --build . --config Release
```

Then link `libPredictionLibrary.a` in your framework.

### Swift Wrapper API

Based on your existing `PredictorWrapper.swift`, create a simplified mobile API:

```swift
// EditorComponent/Sources/Bridges/MobilePredictor.swift
import Foundation

public class MobilePredictor {
    private let predictor: Predictor
    
    public init(triePath: String, userDictPath: String? = nil) throws {
        predictor = try Predictor(debugMode: false)
        try predictor.initialize(triePath: triePath)
        
        if let userDictPath = userDictPath {
            try predictor.setUserDictionary(path: userDictPath)
        }
    }
    
    // Simplified API for mobile editor
    public func getCandidates(
        prefix: String,
        maxResults: Int = 10
    ) throws -> [String] {
        let results = try predictor.getWordPredictions(
            prefix: prefix,
            targetScript: .tamil,
            annotationType: .notrequired,
            maxResults: maxResults
        )
        return results.map { $0.word }
    }
    
    public func getNgramCandidates(
        previousWord: String,
        prefix: String = "",
        maxResults: Int = 10
    ) throws -> [String] {
        let results = try predictor.getNgramPredictions(
            baseWord: previousWord,
            secondWord: "",
            prefix: prefix,
            targetScript: .tamil,
            annotationType: .notrequired,
            maxResults: maxResults
        )
        return results.map { $0.word }
    }
    
    public func learnWord(_ word: String) throws {
        try predictor.addWord(word)
    }
}
```

### Key Translator Integration

Since you have an Obj-C protocol, create a Swift-friendly wrapper:

```swift
// EditorComponent/Sources/Bridges/KeyTranslatorBridge.swift
import Foundation

public protocol MobileKeyTranslator {
    func translate(
        composing: String,
        keyCode: Int,
        shifted: Bool
    ) -> TranslationResult
    
    func handleDelete(lastChar: Character)
    func reset()
}

public struct TranslationResult {
    public let text: String
    public let deleteCount: Int  // How many chars to delete before inserting
    
    public var handled: Bool {
        return !text.isEmpty || deleteCount > 0
    }
}

// Adapter for your existing Obj-C KeyTranslator
public class KeyTranslatorAdapter: MobileKeyTranslator {
    private let translator: any KeyTranslator  // Your protocol
    
    public init(translator: any KeyTranslator) {
        self.translator = translator
    }
    
    public func translate(
        composing: String,
        keyCode: Int,
        shifted: Bool
    ) -> TranslationResult {
        let mutableStr = NSMutableString(string: composing)
        let result = translator.translateComposition(
            inString: mutableStr,
            newKeyCode: keyCode,
            shifted: shifted
        )
        
        // Parse DELCODE if present
        var deleteCount = 0
        var finalText = result as String
        
        if finalText.contains("\u{2421}") {
            // Extract delete count logic here
            // Based on your DELCODE implementation
        }
        
        return TranslationResult(
            text: finalText,
            deleteCount: deleteCount
        )
    }
    
    public func handleDelete(lastChar: Character) {
        let wchar = lastChar.utf16.first ?? 0
        translator.updateKeyStatesAfterDelete(forLastChar: wchar)
    }
    
    public func reset() {
        translator.terminateComposition()
    }
}
```

### ContextAwareTextView Implementation

```swift
// EditorComponent/Sources/Editor/ContextAwareTextView.swift
import UIKit

public class ContextAwareTextView: UITextView {
    
    private var inlineCandidateView: InlineCandidateView?
    private var candidates: [String] = []
    private var selectedCandidateIndex: Int = -1
    
    // Dependencies injected
    public var predictor: MobilePredictor?
    public var keyTranslator: MobileKeyTranslator?
    
    // Current composition state
    private var composingText: String = ""
    
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            
            // Handle candidate selection first
            if !candidates.isEmpty {
                if handleCandidateNavigation(key: key) {
                    return
                }
            }
            
            // Get context
            guard let selectedRange = selectedTextRange else { continue }
            let cursorPosition = offset(from: beginningOfDocument, to: selectedRange.start)
            let textBefore = String(text.prefix(cursorPosition))
            let textAfter = String(text.suffix(from: text.index(text.startIndex, offsetBy: cursorPosition)))
            
            // Try key translation first
            if let translator = keyTranslator {
                let result = translator.translate(
                    composing: composingText,
                    keyCode: Int(key.keyCode.rawValue),
                    shifted: key.modifierFlags.contains(.shift)
                )
                
                if result.handled {
                    applyTranslation(result, before: textBefore, after: textAfter)
                    
                    // Get predictions for new state
                    updatePredictions(textBefore: textBefore + result.text, textAfter: textAfter)
                    return
                }
            }
            
            // Update predictions as user types
            updatePredictions(textBefore: textBefore, textAfter: textAfter)
        }
        
        super.pressesBegan(presses, with: event)
    }
    
    private func applyTranslation(
        _ result: TranslationResult,
        before: String,
        after: String
    ) {
        let newBefore = result.deleteCount > 0 
            ? String(before.dropLast(result.deleteCount))
            : before
        
        text = newBefore + result.text + after
        composingText += result.text
        
        // Update cursor
        let newCursorPos = newBefore.count + result.text.count
        if let newPosition = position(from: beginningOfDocument, offset: newCursorPos) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
    }
    
    private func updatePredictions(textBefore: String, textAfter: String) {
        guard let predictor = predictor else { return }
        
        // Extract last word for context
        let words = textBefore.split(separator: " ")
        let lastWord = words.last.map(String.init) ?? ""
        let previousWord = words.count > 1 ? String(words[words.count - 2]) : ""
        
        do {
            let newCandidates: [String]
            
            if !previousWord.isEmpty && lastWord.isEmpty {
                // Predict next word after space
                newCandidates = try predictor.getNgramCandidates(
                    previousWord: previousWord,
                    prefix: "",
                    maxResults: 5
                )
            } else if !lastWord.isEmpty {
                // Predict completions for current word
                newCandidates = try predictor.getCandidates(
                    prefix: lastWord,
                    maxResults: 5
                )
            } else {
                newCandidates = []
            }
            
            showInlineCandidates(newCandidates)
        } catch {
            print("Prediction error: \(error)")
        }
    }
    
    private func handleCandidateNavigation(key: UIKey) -> Bool {
        switch key.keyCode {
        case .keyboardDownArrow:
            selectedCandidateIndex = (selectedCandidateIndex + 1) % candidates.count
            inlineCandidateView?.setSelectedIndex(selectedCandidateIndex)
            return true
            
        case .keyboardUpArrow:
            selectedCandidateIndex = selectedCandidateIndex <= 0 
                ? candidates.count - 1 
                : selectedCandidateIndex - 1
            inlineCandidateView?.setSelectedIndex(selectedCandidateIndex)
            return true
            
        case .keyboardReturnOrEnter, .keyboardTab:
            if selectedCandidateIndex >= 0 {
                insertCandidate(candidates[selectedCandidateIndex])
                return true
            }
            
        case .keyboardEscape:
            hideCandidates()
            return true
            
        default:
            // Number key selection (1-9)
            if let char = key.characters.first,
               let num = Int(String(char)),
               num >= 1 && num <= candidates.count {
                insertCandidate(candidates[num - 1])
                return true
            }
        }
        
        return false
    }
    
    private func showInlineCandidates(_ candidates: [String]) {
        self.candidates = candidates
        self.selectedCandidateIndex = candidates.isEmpty ? -1 : 0
        
        guard !candidates.isEmpty else {
            hideCandidates()
            return
        }
        
        // Position and show candidate view
        // (Implementation similar to previous examples)
    }
    
    private func insertCandidate(_ candidate: String) {
        guard let selectedRange = selectedTextRange else { return }
        let cursorPosition = offset(from: beginningOfDocument, to: selectedRange.start)
        
        let before = String(text.prefix(cursorPosition))
        let after = String(text.suffix(from: text.index(text.startIndex, offsetBy: cursorPosition)))
        
        // Find and replace partial word
        let words = before.split(separator: " ")
        let partialWord = words.last.map(String.init) ?? ""
        let beforeWord = before.dropLast(partialWord.count)
        
        text = String(beforeWord) + candidate + after
        composingText = ""  // Reset composition
        
        // Learn the selection
        try? predictor?.learnWord(candidate)
        
        // Update cursor
        let newCursorPos = beforeWord.count + candidate.count
        if let newPosition = position(from: beginningOfDocument, offset: newCursorPos) {
            selectedTextRange = textRange(from: newPosition, to: newPosition)
        }
        
        hideCandidates()
    }
    
    private func hideCandidates() {
        inlineCandidateView?.isHidden = true
        candidates = []
        selectedCandidateIndex = -1
    }
}
```

---

## Part 3: Android Editor Component Setup

### Directory Structure

```
android-editor/
├── settings.gradle.kts
├── build.gradle.kts
├── editor-library/
│   ├── build.gradle.kts
│   ├── src/
│   │   ├── main/
│   │   │   ├── AndroidManifest.xml
│   │   │   ├── java/com/murasu/editor/
│   │   │   │   ├── ContextAwareEditText.kt
│   │   │   │   ├── ContextAwareEditor.kt (Compose)
│   │   │   │   ├── InlineCandidateView.kt
│   │   │   │   ├── MobilePredictor.kt
│   │   │   │   └── KeyTranslator.kt
│   │   │   └── cpp/
│   │   │       ├── CMakeLists.txt
│   │   │       ├── predictor_jni.cpp
│   │   │       └── key_translator_jni.cpp
│   │   └── test/
│   └── proguard-rules.pro
└── editor-test-app/
    ├── build.gradle.kts
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/murasu/editortest/
        │   ├── MainActivity.kt
        │   └── TestScreen.kt
        └── res/
            └── raw/
                └── tamil_trie.dat
```

### CMakeLists.txt for Android

```cmake
# editor-library/src/main/cpp/CMakeLists.txt
cmake_minimum_required(VERSION 3.22.1)
project("murasu_editor")

# Path to MurasuIMEngine
set(MURASU_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../MurasuIMEngine")

# Include directories
include_directories(
    ${MURASU_ROOT}/include
    ${MURASU_ROOT}/include/murasuime
)

# Add prediction library sources
file(GLOB PREDICTION_SOURCES
    "${MURASU_ROOT}/src/prediction_library/*.cpp"
    "${MURASU_ROOT}/src/word_predictor/*.cpp"
)

# Add key translator sources (adjust path as needed)
file(GLOB TRANSLATOR_SOURCES
    "${MURASU_ROOT}/src/key_translator/*.cpp"
)

# Build shared library
add_library(murasu_editor SHARED
    predictor_jni.cpp
    key_translator_jni.cpp
    ${PREDICTION_SOURCES}
    ${TRANSLATOR_SOURCES}
)

# Link libraries
find_library(log-lib log)
find_library(android-lib android)

target_link_libraries(murasu_editor
    ${log-lib}
    ${android-lib}
)

# C++ standard (match your existing CMake)
set_target_properties(murasu_editor PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)
```

### JNI Bridge for Predictor

```cpp
// editor-library/src/main/cpp/predictor_jni.cpp
#include <jni.h>
#include <string>
#include <vector>
#include "predictor_c_api.h"

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_murasu_editor_MobilePredictor_createNative(
    JNIEnv *env, jobject thiz, jboolean debugMode) {
    
    PredictorStatus status;
    PredictorRef predictor = Predictor_Create(debugMode ? 1 : 0, &status);
    
    if (status != PREDICTOR_SUCCESS) {
        return 0;
    }
    
    return reinterpret_cast<jlong>(predictor);
}

JNIEXPORT void JNICALL
Java_com_murasu_editor_MobilePredictor_destroyNative(
    JNIEnv *env, jobject thiz, jlong handle) {
    
    if (handle != 0) {
        PredictorRef predictor = reinterpret_cast<PredictorRef>(handle);
        Predictor_Destroy(predictor);
    }
}

JNIEXPORT jboolean JNICALL
Java_com_murasu_editor_MobilePredictor_initializeNative(
    JNIEnv *env, jobject thiz, jlong handle, jstring triePath) {
    
    if (handle == 0) return JNI_FALSE;
    
    const char* path = env->GetStringUTFChars(triePath, nullptr);
    PredictorRef predictor = reinterpret_cast<PredictorRef>(handle);
    
    PredictorStatus status = Predictor_Initialize(predictor, path);
    
    env->ReleaseStringUTFChars(triePath, path);
    
    return status == PREDICTOR_SUCCESS ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jobjectArray JNICALL
Java_com_murasu_editor_MobilePredictor_getCandidatesNative(
    JNIEnv *env, jobject thiz, jlong handle,
    jstring prefix, jint maxResults) {
    
    if (handle == 0) return nullptr;
    
    PredictorRef predictor = reinterpret_cast<PredictorRef>(handle);
    
    // Convert Java string to wchar_t
    const jchar* prefixChars = env->GetStringChars(prefix, nullptr);
    jsize prefixLen = env->GetStringLength(prefix);
    
    std::vector<wchar_t> wprefix(prefixLen + 1);
    for (jsize i = 0; i < prefixLen; i++) {
        wprefix[i] = static_cast<wchar_t>(prefixChars[i]);
    }
    wprefix[prefixLen] = 0;
    
    env->ReleaseStringChars(prefix, prefixChars);
    
    // Get predictions
    PredictorResult* results = nullptr;
    size_t count = 0;
    
    PredictorStatus status = Predictor_GetWordPredictions(
        predictor,
        wprefix.data(),
        TargetScript_tamil,  // From your enum
        AnnotationDataType_notrequired,
        maxResults,
        &results,
        &count
    );
    
    if (status != PREDICTOR_SUCCESS || count == 0) {
        return env->NewObjectArray(0, env->FindClass("java/lang/String"), nullptr);
    }
    
    // Convert results to Java String array
    jobjectArray jresults = env->NewObjectArray(
        count,
        env->FindClass("java/lang/String"),
        nullptr
    );
    
    for (size_t i = 0; i < count; i++) {
        if (results[i].word) {
            // Convert wchar_t* to jstring
            size_t len = wcslen(results[i].word);
            std::vector<jchar> jchars(len);
            for (size_t j = 0; j < len; j++) {
                jchars[j] = static_cast<jchar>(results[i].word[j]);
            }
            jstring jword = env->NewString(jchars.data(), len);
            env->SetObjectArrayElement(jresults, i, jword);
            env->DeleteLocalRef(jword);
        }
    }
    
    Predictor_FreeResults(results);
    
    return jresults;
}

} // extern "C"
```

### Kotlin Wrapper

```kotlin
// editor-library/src/main/java/com/murasu/editor/MobilePredictor.kt
package com.murasu.editor

class MobilePredictor(debugMode: Boolean = false) {
    private var nativeHandle: Long = 0

    init {
        System.loadLibrary("murasu_editor")
        nativeHandle = createNative(debugMode)
        if (nativeHandle == 0L) {
            throw RuntimeException("Failed to create predictor")
        }
    }

    fun initialize(triePath: String): Boolean {
        return initializeNative(nativeHandle, triePath)
    }

    fun setUserDictionary(dbPath: String): Boolean {
        return setUserDictionaryNative(nativeHandle, dbPath)
    }

    fun getCandidates(prefix: String, maxResults: Int = 10): List<String> {
        val results = getCandidatesNative(nativeHandle, prefix, maxResults)
        return results?.toList() ?: emptyList()
    }

    fun getNgramCandidates(
        previousWord: String,
        prefix: String = "",
        maxResults: Int = 10
    ): List<String> {
        val results = getNgramCandidatesNative(
            nativeHandle,
            previousWord,
            "",  // secondWord
            prefix,
            maxResults
        )
        return results?.toList() ?: emptyList()
    }

    fun learnWord(word: String): Boolean {
        return addWordNative(nativeHandle, word)
    }

    fun close() {
        if (nativeHandle != 0L) {
            destroyNative(nativeHandle)
            nativeHandle = 0
        }
    }

    // Native methods
    private external fun createNative(debugMode: Boolean): Long
    private external fun destroyNative(handle: Long)
    private external fun initializeNative(handle: Long, triePath: String): Boolean
    private external fun setUserDictionaryNative(handle: Long, dbPath: String): Boolean
    private external fun getCandidatesNative(
        handle: Long,
        prefix: String,
        maxResults: Int
    ): Array<String>?
    private external fun getNgramCandidatesNative(
        handle: Long,
        baseWord: String,
        secondWord: String,
        prefix: String,
        maxResults: Int
    ): Array<String>?
    private external fun addWordNative(handle: Long, word: String): Boolean
}
```

### build.gradle.kts Configuration

```kotlin
// editor-library/build.gradle.kts
plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.murasu.editor"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
        
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
        
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++20"
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DANDROID_PLATFORM=android-24"
                )
            }
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.8"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
}
```

---

## Part 4: Sharing with Keyboard Extensions

### iOS Keyboard Extension Integration

**App Group Setup:**
1. Enable App Groups in both targets (app + keyboard)
2. Share trie file location via App Group container

```swift
// In keyboard extension
let sharedContainer = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.murasu.keyboard"
)
let triePath = sharedContainer?.appendingPathComponent("TamilTrie.dat").path

let predictor = try MobilePredictor(
    triePath: triePath!,
    userDictPath: nil
)
```

**Linking EditorComponent Framework:**
- Add `EditorComponent.framework` to keyboard extension target
- Set "Embed Without Signing" (extensions can't embed)
- Framework must be in main app's bundle

### Android Keyboard Extension Integration

**Using Same Library Module:**

```kotlin
// settings.gradle.kts (in keyboard project)
include(":app")
include(":keyboard")
include(":editor-library")
project(":editor-library").projectDir = 
    file("../android-editor/editor-library")
```

```kotlin
// keyboard/build.gradle.kts
dependencies {
    implementation(project(":editor-library"))
}
```

**In InputMethodService:**
```kotlin
class MurasuKeyboard : InputMethodService() {
    private lateinit var predictor: MobilePredictor
    
    override fun onCreate() {
        super.onCreate()
        
        val triePath = "${filesDir}/TamilTrie.dat"
        predictor = MobilePredictor()
        predictor.initialize(triePath)
    }
    
    override fun onDestroy() {
        predictor.close()
        super.onDestroy()
    }
    
    // Use predictor in your keyboard logic
}
```

---

## Part 5: Resource Management

### Trie File Deployment

**iOS:**
```swift
// Copy from bundle to App Group container on first run
if let triePath = Bundle.main.path(forResource: "TamilTrie", ofType: "dat"),
   let sharedContainer = FileManager.default.containerURL(
       forSecurityApplicationGroupIdentifier: "group.com.murasu.keyboard"
   ) {
    let destPath = sharedContainer.appendingPathComponent("TamilTrie.dat")
    
    if !FileManager.default.fileExists(atPath: destPath.path) {
        try? FileManager.default.copyItem(
            atPath: triePath,
            toPath: destPath.path
        )
    }
}
```

**Android:**
```kotlin
// Copy from assets to internal storage
fun copyTrieFromAssets(context: Context) {
    val destFile = File(context.filesDir, "TamilTrie.dat")
    if (!destFile.exists()) {
        context.assets.open("TamilTrie.dat").use { input ->
            destFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }
    }
}
```

---

## Part 6: Testing Strategy

### Test Scenarios

1. **Key Translation**
   - Type sequences that trigger composition
   - Verify DELCODE handling
   - Test script-specific rules

2. **Word Predictions**
   - Type partial words
   - Verify correct Tamil script output
   - Test ranking/scoring

3. **N-gram Predictions**
   - Complete sentences
   - Verify context-aware suggestions
   - Test bigram/trigram learning

4. **Cross-Platform Consistency**
   - Same input → same candidates
   - Same learning behavior
   - Same resource files

### Performance Targets

- Prediction latency: < 50ms
- Key translation: < 10ms
- Memory usage: < 50MB for trie + predictions
- APK/IPA size impact: < 10MB

---

## Summary

This setup gives you:

✅ **Reuse existing MurasuIMEngine** C++ codebase  
✅ **Shared prediction library** across editor + keyboard  
✅ **Native key translation** on both platforms  
✅ **Test apps** for isolated development  
✅ **Easy integration** into production apps and keyboard extensions  

### Directory Layout Summary

```
MobileEditorWorkspace/
├── MurasuIMEngine/           # Existing C++ (submodule)
├── ios-editor/
│   ├── EditorComponent/      # Reusable framework
│   └── EditorTestApp/        # Test harness
└── android-editor/
    ├── editor-library/       # Reusable module
    └── editor-test-app/      # Test harness
```

Both platforms link/build from the same `MurasuIMEngine` source, ensuring consistency and code reuse.

---
