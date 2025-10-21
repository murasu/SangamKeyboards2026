// Sources/Apps/macOS/EditorApp_macOS.swift
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
import EditorCore
import EditorUI

@main
struct ContextAwareEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Add custom menu commands here
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider()
            
            // Main editor
            EditorTextView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack {
            Text("Context-Aware Editor")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Character/word count
            HStack(spacing: 16) {
                Label("\(viewModel.text.count) chars", systemImage: "textformat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(wordCount) words", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if canImport(AppKit)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
    }
    
    private var wordCount: Int {
        viewModel.text
            .split(whereSeparator: \.isWhitespace)
            .count
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Use VStack instead of Form for macOS 12 compatibility
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Prediction") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto-learn words", isOn: $viewModel.autoLearnEnabled)
                        
                        HStack {
                            Text("Max candidates: \(viewModel.maxCandidates)")
                            Stepper("", value: $viewModel.maxCandidates, in: 1...10)
                                .labelsHidden()
                        }
                    }
                    .padding(8)
                }
                
                GroupBox("Editor") {
                    Text("Font size, theme, etc. coming soon")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                }
            }
            .padding()
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

