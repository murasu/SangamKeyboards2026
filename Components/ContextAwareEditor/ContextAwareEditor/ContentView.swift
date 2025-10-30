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
    @State private var editorHeight: CGFloat = 400
    
    // iOS settings presentation
    #if os(iOS)
    @State private var showingSettings = false
    #endif
    
    var body: some View {
        VStack(spacing: 16) {
            // iOS Settings Button at the top
            #if os(iOS)
            HStack {
                Text("Something Awesome Lah!")
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
                .frame(minHeight: editorHeight)
                .border(Color.gray.opacity(0.3), width: 1)
                .onAppear {
                    calculateOptimalHeight()
                }
                #if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    // Recalculate height when device rotates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        calculateOptimalHeight()
                    }
                }
                #endif
            /*
            Text("Instructions:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Type letters to start Tamil composition")
                Text("• Composition appears underlined in blue")
                Text("• Press Tab to accept prediction suggestions")
                Text("• Press Space/Return to commit current composition")
                Text("• Press Escape to hide predictions (keep composing)")
                Text("• Use Backspace to edit within composition")
            }
            .font(.caption)
            .foregroundColor(.secondary) */
        }
        .padding()
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        #endif
    }
    
    private func calculateOptimalHeight() {
        #if os(iOS)
        let screenBounds = UIScreen.main.bounds
        let screenHeight = screenBounds.height
        let screenWidth = screenBounds.width
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let isLandscape = screenWidth > screenHeight
        
        let reservedHeight: CGFloat
        let minHeight: CGFloat
        let maxHeight: CGFloat
        
        if isPhone {
            if isLandscape {
                // iPhone Landscape: Very limited vertical space
                reservedHeight = 180 // Compact for landscape
                minHeight = 200
                maxHeight = 280
            } else {
                // iPhone Portrait: More generous
                reservedHeight = 250
                minHeight = 300
                maxHeight = 450
            }
        } else {
            // iPad: Generous in both orientations
            if isLandscape {
                reservedHeight = 180
                minHeight = 350
                maxHeight = 500
            } else {
                reservedHeight = 200
                minHeight = 400
                maxHeight = 700
            }
        }
        
        let availableHeight = screenHeight - reservedHeight
        editorHeight = max(minHeight, min(maxHeight, availableHeight))
        
        let orientation = isLandscape ? "Landscape" : "Portrait"
        print("📱 Screen: \(Int(screenWidth))x\(Int(screenHeight)), Device: \(isPhone ? "iPhone" : "iPad"), Orientation: \(orientation), Editor height: \(Int(editorHeight))")
        
        #else
        // macOS: Use a generous fixed height since we have plenty of screen space
        editorHeight = 500
        print("💻 macOS: Using fixed editor height: \(Int(editorHeight))")
        #endif
    }
}

#Preview {
    ContentView()
}
