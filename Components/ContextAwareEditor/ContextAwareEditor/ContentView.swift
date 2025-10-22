//
//  ContentView.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var currentText = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Context-Aware Text Editor")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Current text length: \(currentText.count) characters")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ContextAwareTextEditor()
                .text("// Start typing here...\n// Try typing: func, var, class, etc.\n")
                .onTextChange { text in
                    currentText = text
                }
                .onKeyTranslation { key, range in
                    print("Key translated: '\(key)' at range: \(range?.description ?? "nil")")
                }
                .configureTextProcessor { processor in
                    // Example: Convert some characters
                    processor.setTranslationFunction { character in
                        switch character {
                        case "->":
                            return TextProcessor.TranslationResult(newText: " → ", deleteCount: 0)
                        case "=>":
                            return TextProcessor.TranslationResult(newText: " ⇒ ", deleteCount: 0)
                        default:
                            return TextProcessor.TranslationResult(newText: character, deleteCount: 0)
                        }
                    }
                }
                .configurePredictionEngine { engine in
                    engine.addCustomWords([
                        "SwiftUI", "UIKit", "AppKit", "Foundation",
                        "import", "struct", "class", "func", "var", "let",
                        "private", "public", "internal", "@State", "@Binding"
                    ])
                }
                .frame(minHeight: 300)
                .border(Color.gray.opacity(0.3), width: 1)
                .id("text-editor") // Force SwiftUI to treat this as a unique view
                .onAppear {
                    // Force refresh after SwiftUI layout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Trigger a state change to force SwiftUI refresh
                        if currentText.isEmpty {
                            currentText = " " // Tiny change to trigger refresh
                            DispatchQueue.main.async {
                                currentText = ""
                            }
                        }
                    }
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
