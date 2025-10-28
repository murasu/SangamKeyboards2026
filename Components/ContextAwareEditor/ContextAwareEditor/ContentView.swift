//
//  ContentView.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var currentText = ""
    @State private var compositionText = ""
    @State private var isComposing = false
    
    // iOS settings presentation
    #if os(iOS)
    @State private var showingSettings = false
    #endif
    
    var body: some View {
        VStack(spacing: 16) {
            // iOS Settings Button at the top
            #if os(iOS)
            HStack {
                Text("Tamil Input Method Editor")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Settings") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            #else
            Text("Tamil Input Method Editor")
                .font(.title2)
                .fontWeight(.semibold)
            #endif
            
            HStack {
                Text("Text length: \(currentText.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isComposing {
                    Text("Composing: '\(compositionText)'")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                } else {
                    Text("Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            let editor = ContextAwareTextEditor()
                //.text("// Tamil Input Method Test\n// Type English letters to compose Tamil text\n// Press Space or Return to commit\n// Try typing some letters...\n")
                .onTextChange { text in
                    currentText = text
                }
                .onKeyTranslation { key, range in
                    print("Key translated: '\(key)' at range: \(range?.description ?? "nil")")
                }
            
            let _ = { // Configure composition callback
                editor.textEditorCore.onCompositionChange = { composition, active in
                    compositionText = composition
                    isComposing = active
                }
            }()
            
            // Test button for positioning logic
            Button("Test Candidate Positioning") {
                editor.textEditorCore.printPositioningTests()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            

            
            editor
                .frame(minHeight: 400)
                .border(Color.gray.opacity(0.3), width: 1)
            
            Text("Instructions:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Type English letters to start Tamil composition")
                Text("• Composition appears underlined in blue")
                Text("• Press Tab to accept prediction suggestions")
                Text("• Press Space/Return to commit current composition")
                Text("• Press Escape to hide predictions (keep composing)")
                Text("• Use Backspace to edit within composition")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        #endif
    }
}

#Preview {
    ContentView()
}
