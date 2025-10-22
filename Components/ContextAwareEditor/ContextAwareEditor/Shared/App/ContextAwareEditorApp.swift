//
//  ContextAwareEditorApp.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI

@main
struct ContextAwareEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 700)
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @State private var selectedLanguage: SwiftKeyTranslator.KeyboardLayout = .anjal
    @State private var maxCandidates: Int = 5
    @State private var autoLearnEnabled: Bool = true
    
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Keyboard Layout")
                    .font(.headline)
                
                Picker("Layout", selection: $selectedLanguage) {
                    Text("Anjal").tag(SwiftKeyTranslator.KeyboardLayout.anjal)
                    Text("Tamil 99").tag(SwiftKeyTranslator.KeyboardLayout.tamil99)
                    Text("Tamil 97").tag(SwiftKeyTranslator.KeyboardLayout.tamil97)
                    Text("Mylai").tag(SwiftKeyTranslator.KeyboardLayout.mylai)
                    Text("Typewriter New").tag(SwiftKeyTranslator.KeyboardLayout.typewriterNew)
                    Text("Typewriter Old").tag(SwiftKeyTranslator.KeyboardLayout.typewriterOld)
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("Prediction Settings")
                    .font(.headline)
                
                HStack {
                    Text("Max Candidates:")
                    Stepper(value: $maxCandidates, in: 1...10) {
                        Text("\(maxCandidates)")
                            .frame(minWidth: 30)
                    }
                }
                
                Toggle("Auto Learn New Words", isOn: $autoLearnEnabled)
                
                Spacer()
            }
            .padding()
            .frame(width: 400, height: 300)
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context Aware Text Editor")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                    
                    Text("A multilingual text editor with context-aware input translation and intelligent word predictions.")
                        .padding(.top, 8)
                    
                    Text("Features:")
                        .fontWeight(.medium)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Real-time keyboard input translation")
                        Text("• Context-aware word predictions")
                        Text("• Multiple keyboard layouts")
                        Text("• Custom dictionary support")
                        Text("• N-gram based suggestions")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .frame(width: 400, height: 300)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
    }
}
