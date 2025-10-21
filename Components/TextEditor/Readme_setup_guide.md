# Setup Guide - Context-Aware Editor

## Quick Start

### 1. Create the Folder Structure

From your project root (`TextEditor/`), create this structure:

```bash
mkdir -p Sources/EditorCore
mkdir -p Sources/EditorUI/macOS
mkdir -p Sources/Apps/macOS
mkdir -p Tests/EditorCoreTests
```

### 2. Place Files in Correct Locations

```
TextEditor/
├── Package.swift                                          # Root
│
├── Sources/
│   ├── EditorCore/
│   │   └── EditorViewModel.swift                         # From artifact
│   │
│   ├── EditorUI/
│   │   ├── EditorTextView.swift                          # From artifact
│   │   └── macOS/
│   │       └── ContextAwareTextView+macOS.swift          # From artifact
│   │
│   └── Apps/
│       └── macOS/
│           └── EditorApp_macOS.swift                     # From artifact (FIXED)
```

### 3. Build the Project

```bash
cd TextEditor
swift build --product EditorApp-macOS
```

### 4. Run in Xcode (Recommended)

```bash
open Package.swift
```

Then:
1. Select the **EditorApp-macOS** scheme from the dropdown
2. Press **Cmd+R** to run

## Troubleshooting

### Error: "Cannot find EditorTextView in scope"

**Cause**: The macOS app file can't see the EditorUI module.

**Solution**: Make sure you have these imports at the top of `EditorApp_macOS.swift`:

```swift
import SwiftUI
import EditorCore
import EditorUI
```

### Error: "File not found: Resources"

**Cause**: Package.swift was referencing a Resources folder that doesn't exist.

**Solution**: Already fixed in the updated Package.swift artifact. The `resources` line has been removed.

### Error: "'titleBarHidden' is unavailable in macOS 12"

**Cause**: That API is only available in macOS 13+.

**Solution**: Already fixed in the updated EditorApp_macOS.swift. Removed that line entirely.

### Error: "'formStyle' is only available in macOS 13.0 or newer"

**Cause**: Form modifiers require macOS 13+.

**Solution**: Already fixed in the updated EditorApp_macOS.swift. Using `GroupBox` and `VStack` instead of `Form`.

## Expected Behavior After Setup

When you run the app, you should see:

1. **Window Opens**: A macOS window with minimum size 600x400
2. **Toolbar**: Shows "Context-Aware Editor" with character/word count
3. **Text Area**: Large, scrollable text editing area
4. **Settings Button**: Gear icon in toolbar (opens settings sheet)
5. **Typing Works**: You can type normally (translation not yet active)

## Next: Integration with Your Libraries

Once the basic app runs, follow these steps:

### Step 1: Link Your C Libraries

Update `Package.swift`:

```swift
dependencies: [
    // Point to your actual library locations
    .package(path: "../CAnjalKeyTranslator"),
    .package(path: "../PredictorWrapper"),
],
```

And in the EditorCore target:

```swift
.target(
    name: "EditorCore",
    dependencies: [
        "CAnjalKeyTranslator",
        "PredictorWrapper",
    ]
)
```

### Step 2: Replace Protocol Placeholders

In `EditorViewModel.swift`, remove the bottom placeholder protocols and import your real types:

```swift
// At the top of the file
import CAnjalKeyTranslator
import PredictorWrapper

// Remove these at the bottom:
// public protocol MobileKeyTranslator { ... }
// public protocol MobilePredictor { ... }
```

### Step 3: Update Property Types

```swift
// Change from protocols to actual types
public var translator: SwiftKeyTranslator?
public var predictor: Predictor?
```

### Step 4: Initialize in App

In `EditorApp_macOS.swift`, update the ContentView:

```swift
struct ContentView: View {
    @StateObject private var viewModel: EditorViewModel = {
        let vm = EditorViewModel()
        
        // Initialize your translator
        vm.translator = SwiftKeyTranslator(
            language: LANG_TAMIL,
            layout: .anjal
        )
        
        // Initialize your predictor
        if let predictor = try? Predictor(debugMode: false) {
            try? predictor.initialize(triePath: "path/to/your/trie/file")
            vm.predictor = predictor
        }
        
        return vm
    }()
    
    // ... rest of the code
}
```

### Step 5: Test Translation

1. Build and run
2. Start typing English characters
3. They should translate to Tamil (or your configured language)

## Verifying It Works

### Basic App (Current Phase)
- [ ] App launches without crashes
- [ ] Can type text normally
- [ ] Character/word count updates
- [ ] Settings sheet opens
- [ ] Can adjust max candidates setting

### After Library Integration
- [ ] Typing English keys produces Tamil characters
- [ ] Key translation follows your configured layout
- [ ] Console shows no errors

## Common Issues & Fixes

### Issue: "Module 'EditorUI' not found"

**Fix**: Clean build folder and rebuild:
```bash
swift package clean
swift build
```

### Issue: Keys don't translate

**Check**:
1. Is `translator` properly initialized?
2. Add debug print in `handleKeyEvent`:
```swift
print("Key code: \(keyCode), shifted: \(shifted)")
```

### Issue: App builds but window is empty

**Check**: Make sure all three modules (EditorCore, EditorUI, Apps/macOS) are in the correct folders.

## File Checklist

Before building, verify you have:

- [ ] `Package.swift` in project root
- [ ] `Sources/EditorCore/EditorViewModel.swift`
- [ ] `Sources/EditorUI/EditorTextView.swift`
- [ ] `Sources/EditorUI/macOS/ContextAwareTextView+macOS.swift`
- [ ] `Sources/Apps/macOS/EditorApp_macOS.swift`

## What's Next?

Once this basic structure works:

1. **Phase 2A**: Add candidate display UI (Xcode-style)
2. **Phase 2B**: Add arrow key navigation for candidates
3. **Phase 3**: Port to iOS

Let me know when you're ready for the next phase!
