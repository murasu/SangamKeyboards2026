# ContextAwareTextView for macOS

A SwiftUI ViewRepresentable that provides context-aware text editing with keyboard input translation and intelligent word predictions for macOS applications.

## Features

- **Real-time Keyboard Translation**: Intercepts keyboard input and translates keystrokes using the SwiftKeyTranslator library
- **Context-Aware Predictions**: Shows word suggestions based on the current context using N-gram predictions
- **Multiple Keyboard Layouts**: Supports Anjal, Tamil 99, Tamil 97, Mylai, Typewriter, and other layouts
- **Multi-language Support**: Works with Tamil, Malayalam, Kannada, Telugu, Gurmukhi, and Devanagari
- **Floating Candidate Window**: Shows suggestions in a native macOS-style floating window
- **Custom Dictionary Support**: Allows importing custom dictionaries and user-defined words
- **Auto-learning**: Automatically learns new words as you type

## Usage

### Basic Implementation

```swift
import SwiftUI

struct MyTextEditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var text: String = ""
    
    var body: some View {
        ContextAwareTextView(
            text: $text,
            viewModel: viewModel,
            font: NSFont.systemFont(ofSize: 16),
            isEditable: true,
            allowsUndo: true,
            isRichText: false
        )
        .onAppear {
            setupEditor()
        }
    }
    
    private func setupEditor() {
        // Initialize translator
        let translator = SwiftKeyTranslator(
            language: LANG_TAMIL,
            layout: .anjal
        )
        viewModel.translator = translator
        
        // Initialize predictor
        do {
            let predictor = try Predictor()
            // Initialize with your trie file
            try predictor.initialize(triePath: "/path/to/your/trie/file")
            viewModel.predictor = predictor
        } catch {
            print("Failed to initialize predictor: \(error)")
        }
    }
}
```

### Configuration Options

The `ContextAwareTextView` can be customized with several parameters:

- `text`: Binding to the text content
- `viewModel`: The EditorViewModel that manages translation and prediction
- `font`: NSFont for the text display (default: system font size 14)
- `isEditable`: Whether the text view is editable (default: true)
- `allowsUndo`: Whether to enable undo/redo (default: true)
- `isRichText`: Whether to support rich text formatting (default: false)

### Key Features

#### Keyboard Input Translation

The text view intercepts keyboard events and translates them using your configured keyboard layout:

```swift
// In your EditorViewModel setup
let translator = SwiftKeyTranslator(
    language: LANG_TAMIL,  // Target language
    layout: .anjal         // Keyboard layout
)
viewModel.translator = translator
```

#### Word Predictions

The system provides context-aware word predictions using N-gram analysis:

```swift
// Configure prediction settings
viewModel.maxCandidates = 8
viewModel.autoLearnEnabled = true

// The predictor automatically provides suggestions based on:
// - Current partial word
// - Previous word context (bigrams)
// - Two previous words (trigrams)
```

#### Candidate Selection

Users can navigate suggestions using:
- **Arrow Keys**: Navigate up/down through candidates
- **Enter/Return**: Accept selected candidate
- **Escape**: Hide candidate window
- **Mouse Click**: Select candidate directly

## Architecture

### Components

1. **ContextAwareTextView**: SwiftUI ViewRepresentable wrapper
2. **ContextAwareNSTextView**: Custom NSTextView for keyboard interception
3. **Coordinator**: Handles text view delegation and candidate management
4. **EditorViewModel**: ObservableObject managing editor state and business logic

### Key Classes

#### ContextAwareTextView

The main ViewRepresentable that creates and manages the NSTextView:

```swift
ContextAwareTextView(
    text: $text,
    viewModel: editorViewModel
)
```

#### EditorViewModel

Manages the editor state and provides methods for:
- Key translation
- Text manipulation
- Prediction management
- Candidate selection

### Integration with Translation Libraries

#### SwiftKeyTranslator Integration

```swift
// Initialize translator
let translator = SwiftKeyTranslator(
    language: selectedLanguage,
    layout: selectedLayout
)

// Translate key input
let translatedText = translator.translateKey(
    keyCode: keyCode,
    shifted: isShifted
)
```

#### Predictor Integration

```swift
// Get word predictions
let predictions = try predictor.getWordPredictions(
    prefix: currentWord,
    targetScript: .tamil,
    annotationType: .notrequired,
    maxResults: maxCandidates
)

// Get N-gram predictions
let contextPredictions = try predictor.getNgramPredictions(
    baseWord: previousWord,
    secondWord: currentWord,
    prefix: partialWord,
    targetScript: .tamil,
    annotationType: .notrequired,
    maxResults: maxCandidates
)
```

## Requirements

- macOS 12.0+
- SwiftUI
- SwiftKeyTranslator library
- Predictor library with C wrapper
- CAnjalKeyTranslator framework

## Setup

1. Add the ContextAwareTextView files to your project
2. Ensure SwiftKeyTranslator and Predictor libraries are properly linked
3. Initialize the trie file for predictions
4. Configure your desired language and keyboard layout

## Example App

The included example app demonstrates:
- Language and layout switching
- Real-time translation
- Candidate display and selection
- Settings management
- Language auto-detection

## Notes

- The candidate window automatically positions itself near the cursor
- The system handles composition termination on space and punctuation
- Auto-learning can be enabled to improve predictions over time
- Custom dictionaries can be imported for specialized vocabularies

## Future Enhancements

- iOS support (parallel implementation)
- Rich text formatting support
- Custom candidate window styling
- Plugin architecture for additional languages
- User dictionary management UI