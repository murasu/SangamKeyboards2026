//
//  ContentView.swift
//  ContextAwareTextView
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI
//import CAnjalKeyTranslator

struct ContentView: View {
    @StateObject private var editorViewModel = EditorViewModel()
    @State private var text: String = ""
    @State private var selectedLayout: SwiftKeyTranslator.KeyboardLayout = .anjal
    @State private var selectedLanguage: SupportedLanguage = LANG_TAMIL
    @State private var showingLanguageDetection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    // Language and Layout Selection
                    HStack {
                        Text("Language:")
                            .font(.caption)
                        
                        Picker("Language", selection: $selectedLanguage) {
                            Text("Tamil").tag(LANG_TAMIL)
                            Text("Malayalam").tag(LANG_MALAYALAM)
                            Text("Kannada").tag(LANG_KANNADA)
                            Text("Telugu").tag(LANG_TELUGU)
                            Text("Gurmukhi").tag(LANG_GURMUKHI)
                            Text("Devanagari").tag(LANG_DEVANAGARI)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        
                        Text("Layout:")
                            .font(.caption)
                        
                        Picker("Layout", selection: $selectedLayout) {
                            Text("Anjal").tag(SwiftKeyTranslator.KeyboardLayout.anjal)
                            Text("Tamil 99").tag(SwiftKeyTranslator.KeyboardLayout.tamil99)
                            Text("Tamil 97").tag(SwiftKeyTranslator.KeyboardLayout.tamil97)
                            Text("Mylai").tag(SwiftKeyTranslator.KeyboardLayout.mylai)
                            Text("TW New").tag(SwiftKeyTranslator.KeyboardLayout.typewriterNew)
                            Text("TW Old").tag(SwiftKeyTranslator.KeyboardLayout.typewriterOld)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    
                    Spacer()
                    
                    // Auto-detect language button
                    Button("Detect Language") {
                        if let detectedLanguage = SwiftKeyTranslator.detectLanguage(from: text) {
                            selectedLanguage = detectedLanguage
                            showingLanguageDetection = true
                        }
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    // Clear button
                    Button("Clear") {
                        text = ""
                        editorViewModel.hideCandidates()
                        editorViewModel.resetComposition()
                    }
                    .disabled(text.isEmpty)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Editor area
                ContextAwareTextView(
                    text: $text,
                    viewModel: editorViewModel,
                    font: NSFont.systemFont(ofSize: 16),
                    isEditable: true,
                    allowsUndo: true,
                    isRichText: false
                )
                .frame(minHeight: 400)
                
                // Status bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Characters: \(text.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Words: \(text.split(separator: " ").count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if editorViewModel.isShowingCandidates {
                            Text("Showing \(editorViewModel.candidates.count) suggestions")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Current settings display
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Current: \(languageName(selectedLanguage)) - \(layoutName(selectedLayout))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if editorViewModel.isShowingCandidates && editorViewModel.selectedCandidateIndex >= 0 {
                            Text("Selected: \(editorViewModel.candidates[editorViewModel.selectedCandidateIndex])")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationTitle("Context Aware Text Editor")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Reset Composition") {
                        editorViewModel.terminateComposition()
                    }
                    .help("Reset the current input composition")
                    
                    Button("Settings") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                    .help("Open application settings")
                }
            }
        }
        .alert("Language Detected", isPresented: $showingLanguageDetection) {
            Button("OK") { }
        } message: {
            Text("Detected language: \(languageName(selectedLanguage))")
        }
        .onAppear {
            setupEditor()
        }
        .onChange(of: selectedLanguage) { _, newLanguage in
            updateTranslator()
        }
        .onChange(of: selectedLayout) { _, newLayout in
            updateTranslator()
        }
        .onChange(of: text) { _, newText in
            editorViewModel.text = newText
        }
    }
    
    private func setupEditor() {
        // Initialize the translator and predictor
        updateTranslator()
        setupPredictor()
        
        // Set up initial configuration
        editorViewModel.maxCandidates = 8
        editorViewModel.autoLearnEnabled = true
    }
    
    private func updateTranslator() {
        // Create new translator with current settings
        let translator = SwiftKeyTranslator(
            language: selectedLanguage,
            layout: selectedLayout
        )
        editorViewModel.translator = translator
    }
    
    private func setupPredictor() {
        do {
            let predictor = try Predictor(debugMode: false)
            // Note: You'll need to initialize with your trie file path
            // try predictor.initialize(triePath: "/path/to/your/trie/file")
            editorViewModel.predictor = predictor
        } catch {
            print("Failed to initialize predictor: \(error)")
        }
    }
    
    private func languageName(_ language: SupportedLanguage) -> String {
        switch language {
        case LANG_TAMIL: return "Tamil"
        case LANG_MALAYALAM: return "Malayalam"
        case LANG_KANNADA: return "Kannada"
        case LANG_TELUGU: return "Telugu"
        case LANG_GURMUKHI: return "Gurmukhi"
        case LANG_DEVANAGARI: return "Devanagari"
        default: return "Unknown"
        }
    }
    
    private func layoutName(_ layout: SwiftKeyTranslator.KeyboardLayout) -> String {
        switch layout {
        case .anjal: return "Anjal"
        case .tamil99: return "Tamil 99"
        case .tamil97: return "Tamil 97"
        case .mylai: return "Mylai"
        case .typewriterNew: return "Typewriter New"
        case .typewriterOld: return "Typewriter Old"
        case .anjalIndic: return "Anjal Indic"
        case .murasu6: return "Murasu 6"
        case .bamini: return "Bamini"
        case .tnTypewriter: return "TN Typewriter"
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
