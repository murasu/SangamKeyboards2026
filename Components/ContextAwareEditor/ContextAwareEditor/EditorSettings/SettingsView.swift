import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = EditorSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        #if os(macOS)
        macOSSettingsView
        #else
        iOSSettingsView
        #endif
    }
    
    // MARK: - iOS Settings View
    
    #if os(iOS)
    private var iOSSettingsView: some View {
        NavigationView {
            Form {
                keyboardSection
                textSection
                suggestionsSection
                
                Section {
                    Button("Reset to Defaults") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    #endif
    
    // MARK: - macOS Settings View
    
    #if os(macOS)
    private var macOSSettingsView: some View {
        TabView {
            VStack(alignment: .leading) {
                Form {
                    keyboardSection
                    textSection
                }
                Spacer()
            }
            .tabItem {
                Label("Editor", systemImage: "textformat")
            }
            .padding()
            
            VStack(alignment: .leading) {
                Form {
                    suggestionsSection
                }
                Spacer()
            }
            .tabItem {
                Label("Suggestions", systemImage: "text.bubble")
            }
            .padding()
            
            VStack(alignment: .leading) {
                Form {
                    Section {
                        Button("Reset to Defaults") {
                            settings.resetToDefaults()
                        }
                        .foregroundColor(.red)
                    }
                }
                Spacer()
            }
            .tabItem {
                Label("Advanced", systemImage: "gearshape")
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
    #endif
    
    // MARK: - Common Sections
    
    private var keyboardSection: some View {
        Section {
            Picker("Keyboard Type", selection: $settings.keyboardType) {
                ForEach(EditorSettings.keyboardTypes, id: \.id) { keyboardType in
                    Text(keyboardType.name)
                        .tag(keyboardType.id)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        } header: {
            #if os(macOS)
            Text("Keyboard")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            #else
            Text("Keyboard")
            #endif
        }
    }
    
    private var textSection: some View {
        Section {
            Picker("Font Family", selection: $settings.fontFamily) {
                ForEach(EditorSettings.availableFonts, id: \.self) { font in
                    Text(font)
                        .tag(font)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(settings.editorFontSize)) pt")
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $settings.editorFontSize,
                    in: 12...72,
                    step: 1
                )
                #if os(iOS)
                .accessibilityLabel("Font Size")
                #endif
            }
        } header: {
            #if os(macOS)
            Text("Text & Font")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            #else
            Text("Text & Font")
            #endif
        }
    }
    
    private var suggestionsSection: some View {
        Section {
            Toggle("Enable Suggestions", isOn: $settings.enableSuggestions)
            
            if settings.enableSuggestions {
                Picker("Suggestions Font Size", selection: $settings.suggestionsFontSize) {
                    ForEach(SuggestionsFontSize.allCases, id: \.self) { size in
                        Text(size.rawValue)
                            .tag(size)
                    }
                }
                #if os(iOS)
                .pickerStyle(.segmented)
                #endif
                
                Picker("Max Suggestions", selection: $settings.maxSuggestions) {
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                }
                #if os(iOS)
                .pickerStyle(.segmented)
                #endif
                
                Toggle("Auto-Select Best Word", isOn: $settings.autoSelectBestWord)
                
                Toggle("Learn Typed Words", isOn: $settings.learnTypedWords)
                
                Toggle("Auto-suggest next word after Tab", isOn: $settings.autoPredictNextWord)
                
                Toggle("Show Annotations", isOn: $settings.showAnnotations)
                
                Toggle("Include Emojis", isOn: $settings.includeEmojis)
                
                Toggle("Show Vertical Layout", isOn: $settings.showVertical)
            }
        } header: {
            #if os(macOS)
            Text("Suggestions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            #else
            Text("Suggestions")
            #endif
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}