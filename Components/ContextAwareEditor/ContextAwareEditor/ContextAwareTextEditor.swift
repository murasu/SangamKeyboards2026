//
//  ContextAwareTextEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI
import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Cross-platform SwiftUI text editor with context-aware features
public struct ContextAwareTextEditor: View {
    let core: TextEditorCore
    
    // Configuration options
    private var fontSize: CGFloat
    private var textColor: Color
    private var backgroundColor: Color
    
    public init(
        fontSize: CGFloat = 24,
        textColor: Color = .primary,
        backgroundColor: Color = {
            #if canImport(AppKit)
            return Color(NSColor.textBackgroundColor)
            #else
            return Color(UIColor.systemBackground)
            #endif
        }()
    ) {
        self.core = TextEditorCore()
        self.fontSize = fontSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        Group {
            #if canImport(AppKit)
            MacOSTextEditorView(core: core)
            #elseif canImport(UIKit)
            IOSTextEditor(core: core)
            #else
            Text("Platform not supported")
                .foregroundColor(.red)
            #endif
        }
        .background(backgroundColor)
    }
    
    // MARK: - Configuration Methods
    
    /// Set a callback for text changes
    public func onTextChange(_ callback: @escaping (String) -> Void) -> ContextAwareTextEditor {
        core.onTextChange = callback
        return self
    }
    
    /// Set a callback for key translation events
    public func onKeyTranslation(_ callback: @escaping (String, NSRange?) -> Void) -> ContextAwareTextEditor {
        core.onKeyTranslation = callback
        return self
    }
    
    /// Configure the text processor for character translation
    public func configureTextProcessor(_ configure: @escaping (TextProcessor) -> Void) -> ContextAwareTextEditor {
        configure(core.textProcessor)
        return self
    }
    
    /// Configure the prediction engine
    public func configurePredictionEngine(_ configure: @escaping (PredictionEngine) -> Void) -> ContextAwareTextEditor {
        configure(core.predictionEngine)
        return self
    }
    
    /// Set initial text content
    public func text(_ initialText: String) -> ContextAwareTextEditor {
        core.textStorage.replaceCharacters(
            in: NSRange(location: 0, length: core.textStorage.length),
            with: initialText
        )
        return self
    }
    
    /// Access to the underlying core for advanced configuration
    public var textEditorCore: TextEditorCore {
        core
    }
}

// MARK: - Usage Examples and Documentation

/*
 Usage Examples:
 
 Basic usage:
 ```swift
 ContextAwareTextEditor()
     .onTextChange { text in
         print("Text changed: \(text)")
     }
 ```
 
 With custom translation:
 ```swift
 ContextAwareTextEditor()
     .configureTextProcessor { processor in
         processor.setTranslationFunction { character in
             // Example: Convert digits to words
             switch character {
             case "1": return TextProcessor.TranslationResult(newText: "one", deleteCount: 0)
             case "2": return TextProcessor.TranslationResult(newText: "two", deleteCount: 0)
             default: return TextProcessor.TranslationResult(newText: character, deleteCount: 0)
             }
         }
     }
 ```
 
 With custom predictions:
 ```swift
 ContextAwareTextEditor()
     .configurePredictionEngine { engine in
         engine.setPredictionFunction { word in
             // Custom prediction logic
             return ["custom1", "custom2", "custom3"]
         }
         
         engine.addCustomWords(["func", "var", "let", "class", "struct"])
     }
 ```
 
 Complete example:
 ```swift
 struct ContentView: View {
     @State private var currentText = ""
     
     var body: some View {
         VStack {
             Text("Current text: \(currentText)")
             
             ContextAwareTextEditor()
                 .text("// Start typing here...")
                 .onTextChange { text in
                     currentText = text
                 }
                 .onKeyTranslation { key, range in
                     print("Key translated: \(key) at \(range?.description ?? "nil")")
                 }
                 .configureTextProcessor { processor in
                     // Add your custom translation logic
                 }
                 .configurePredictionEngine { engine in
                     engine.addCustomWords(["function", "variable", "constant"])
                 }
         }
         .padding()
     }
 }
 ```
 
 The editor automatically:
 - Uses NSViewRepresentable on macOS
 - Uses UIViewRepresentable on iOS
 - Handles keyboard input and external keyboards
 - Shows inline predictions
 - Supports custom character translation
 - Provides extensible prediction system
 */
