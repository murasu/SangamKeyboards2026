# Context-Aware Editor - Project Structure

## Directory Layout

```
ContextAwareEditor/
├── Package.swift
├── README.md
│
├── Sources/
│   ├── EditorCore/                    # Platform-agnostic business logic
│   │   ├── EditorViewModel.swift      # Main view model (iOS 15+/macOS 12+)
│   │   ├── Models/
│   │   │   ├── TranslationResult.swift
│   │   │   └── PredictionCandidate.swift
│   │   └── Protocols/
│   │       ├── MobileKeyTranslator.swift
│   │       └── MobilePredictor.swift
│   │
│   ├── EditorUI/                       # SwiftUI views and representables
│   │   ├── EditorTextView.swift       # Conditional compilation wrapper
│   │   ├── macOS/
│   │   │   └── ContextAwareTextView+macOS.swift
│   │   └── iOS/                       # Phase 2
│   │       └── ContextAwareTextView+iOS.swift
│   │
│   └── Apps/
│       ├── macOS/                      # macOS app target
│       │   ├── EditorApp_macOS.swift
│       │   └── Info.plist
│       └── iOS/                        # Phase 2
│           ├── EditorApp_iOS.swift
│           └── Info.plist
│
├── Tests/
│   └── EditorCoreTests/
│       ├── ViewModelTests.swift
│       └── TranslationTests.swift
│
└── Frameworks/                         # Your C libraries
    ├── CAnjalKeyTranslator.xcframework
    └── PredictorWrapper.xcframework
```

## Build & Run

### macOS App

```bash
# From project root
swift build -c release --product EditorApp-macOS

# Or use Xcode
open Package.swift
# Select EditorApp-macOS scheme and run
```

### Running Tests

```bash
swift test
```

## Phase 1 Implementation Status

### ✅ Completed
- [x] Package structure with iOS 15+ / macOS 12+ support
- [x] Shared `EditorViewModel` with `ObservableObject`
- [x] macOS `NSTextView` subclass with key interception
- [x] SwiftUI `NSViewRepresentable` wrapper
- [x] Basic macOS app with text editing
- [x] Text statistics (character/word count)
- [x] Settings interface

### 🚧 Phase 2 (Next Steps)
- [ ] Integrate actual C library wrappers
- [ ] Implement candidate display (Xcode-style inline)
- [ ] Add candidate selection with arrow keys
- [ ] iOS `UITextView` implementation
- [ ] iOS app target

## Integration Guide

### Adding Your C Libraries

1. **Update Package.swift dependencies:**

```swift
dependencies: [
    .package(path: "../CAnjalKeyTranslator"),
    .package(path: "../PredictorWrapper"),
],
```

2. **Update EditorCore target:**

```swift
.target(
    name: "EditorCore",
    dependencies: [
        "CAnjalKeyTranslator",
        "PredictorWrapper",
    ]
)
```

3. **Adapt the protocols in EditorViewModel.swift:**

Replace the placeholder protocols with your actual types:

```swift
// Remove placeholder protocols
// public protocol MobileKeyTranslator { ... }

// Import your actual libraries
import CAnjalKeyTranslator
import PredictorWrapper

// Update property types
public var translator: SwiftKeyTranslator?  // Your actual type
public var predictor: Predictor?            // Your actual type
```

4. **Initialize in the app:**

```swift
// In ContentView
@StateObject private var viewModel: EditorViewModel = {
    let vm = EditorViewModel()
    
    // Initialize translator
    vm.translator = SwiftKeyTranslator(
        language: LANG_TAMIL,
        layout: .anjal
    )
    
    // Initialize predictor
    let predictor = try? Predictor(debugMode: false)
    try? predictor?.initialize(triePath: "path/to/trie")
    vm.predictor = predictor
    
    return vm
}()
```

## Key Design Decisions

### 1. Target Versions (iOS 15+ / macOS 12+)
- **Rationale**: Maximum device compatibility
- **Trade-off**: Use `ObservableObject` instead of `@Observable`
- **Impact**: Minimal - all core features work perfectly

### 2. Conditional Compilation
- Platform-specific code isolated in separate files
- Shared business logic in `EditorCore`
- Same SwiftUI API surface for both platforms

### 3. ViewModel Pattern
- Single source of truth for editor state
- Testable business logic
- Easy to extend for candidate selection

### 4. NSTextView Subclassing
- Direct key event interception
- Fine-grained control over text manipulation
- Clean separation from SwiftUI layer

## Next Session Plan

1. **Candidate Display UI** (Xcode-style)
   - Floating panel below cursor
   - Semi-transparent background
   - Number indicators (1-9)
   - Arrow key navigation

2. **iOS Implementation**
   - Port key handling to UIKit
   - Handle `pressesBegan` differences
   - Test on iPad with external keyboard

3. **Integration Testing**
   - Test with actual Tamil/multilingual input
   - Verify prediction accuracy
   - Performance profiling
