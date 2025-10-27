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
            Form {
                keyboardSection
                textSection
            }
            .tabItem {
                Label("Editor", systemImage: "textformat")
            }
            .padding()
            
            Form {
                suggestionsSection
            }
            .tabItem {
                Label("Suggestions", systemImage: "text.bubble")
            }
            .padding()
            
            Form {
                Section {
                    Button("Reset to Defaults") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
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
        Section("Keyboard") {
            Picker("Keyboard Type", selection: $settings.keyboardType) {
                ForEach(EditorSettings.keyboardTypes, id: \.id) { keyboardType in
                    Text(keyboardType.name)
                        .tag(keyboardType.id)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        }
    }
    
    private var textSection: some View {
        Section("Text & Font") {
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
                ) {
                    Text("Font Size")
                } minimumValueLabel: {
                    Text("12")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("72")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var suggestionsSection: some View {
        Section("Suggestions & Predictions") {
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
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Max Predictions")
                        Spacer()
                        Text("\(settings.maxPredictions)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(settings.maxPredictions) },
                            set: { settings.maxPredictions = Int($0) }
                        ),
                        in: 1...10,
                        step: 1
                    ) {
                        Text("Max Predictions")
                    } minimumValueLabel: {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Prediction Delay")
                        Spacer()
                        Text("\(settings.predictionDelay, specifier: "%.1f")s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $settings.predictionDelay,
                        in: 0.1...2.0,
                        step: 0.1
                    ) {
                        Text("Prediction Delay")
                    } minimumValueLabel: {
                        Text("0.1s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("2.0s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}