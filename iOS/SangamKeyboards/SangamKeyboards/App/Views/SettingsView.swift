import SwiftUI
import SwiftUI
import KeyboardCore

struct SettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var themeViewModel = ThemeSelectionViewModel()
    
    var body: some View {
        Form {
            // Input Settings Section
            Section(header: Text("Input Settings")) {
                Toggle("Show suggestions", isOn: $settingsViewModel.predictionsEnabled)
                Toggle("Show next words", isOn: $settingsViewModel.nextWordPredictionsEnabled)
                Toggle("Include emojis", isOn: $settingsViewModel.emojisEnabled)
                Toggle("Space selects best word", isOn: $settingsViewModel.autoCommitEnabled)
                //Toggle("Auto correct", isOn: $settingsViewModel.autoCorrectEnabled)
                Toggle("Play Key Click Sounds", isOn: $settingsViewModel.soundsEnabled)
            }
            
            // Learning Section
            Section(header: Text("Learning")) {
                Toggle("Learn my typed words", isOn: $settingsViewModel.learnMyTypedWords)
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Shortcut for '.'", isOn: $settingsViewModel.shortcutForPeriod)
                    Text("Double tapping space will insert a period followed by space")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
            }
            
            // Annotations Section
            Section(header: Text("Annotations")) {
                Toggle("Show annotations", isOn: $settingsViewModel.showAnnotations)
                
                if settingsViewModel.showAnnotations {
                    HStack {
                        Text("Annotation type")
                        Spacer()
                        Picker("Annotation Type", selection: $settingsViewModel.annotationType) {
                            ForEach(AnnotationType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            // Script and Theme Section
            Section(header: Text("Script & Theme")) {
                HStack {
                    Text("Script")
                    Spacer()
                    Picker("Script", selection: $settingsViewModel.script) {
                        ForEach(ScriptType.allCases) { script in
                            Text(script.displayName).tag(script)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                NavigationLink(destination: ThemeSelectionView(themeViewModel: themeViewModel)) {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text(themeViewModel.currentThemeName)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            settingsViewModel.loadSettings()
            themeViewModel.loadThemes()
        }
        .onChange(of: settingsViewModel.predictionsEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.nextWordPredictionsEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.autoCommitEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.autoCorrectEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.soundsEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.emojisEnabled) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.learnMyTypedWords) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.shortcutForPeriod) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.showAnnotations) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.annotationType) { _ in settingsViewModel.saveSettings() }
        .onChange(of: settingsViewModel.script) { _ in settingsViewModel.saveSettings() }
    }
}

struct ThemeRow: View {
    let theme: ThemeInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(theme.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let version = theme.version {
                        Text("Version \(version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @ObservedObject var themeViewModel: ThemeSelectionViewModel
    
    var body: some View {
        Form {
            Section {
                Text("Select the theme for your keyboard. Changes will apply to all installed keyboards.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Available Themes")) {
                ForEach(themeViewModel.availableThemes, id: \.id) { theme in
                    ThemeRow(
                        theme: theme,
                        isSelected: theme.id == themeViewModel.currentThemeId
                    ) {
                        themeViewModel.selectTheme(theme.id)
                    }
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Themes are shared across all keyboards")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Themes")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            themeViewModel.loadThemes()
        }
    }
}

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    @Published var predictionsEnabled: Bool = true
    @Published var nextWordPredictionsEnabled: Bool = true
    @Published var autoCommitEnabled: Bool = false
    @Published var autoCorrectEnabled: Bool = true
    @Published var soundsEnabled: Bool = true
    @Published var emojisEnabled: Bool = true
    @Published var learnMyTypedWords: Bool = true
    @Published var shortcutForPeriod: Bool = true
    @Published var showAnnotations: Bool = true
    @Published var annotationType: AnnotationType = .meaning
    @Published var script: ScriptType = .tamil
    
    private let userDefaults: UserDefaults
    private let appGroupIdentifier = "group.murasu.Sangam"
    
    var settings: InputSettings {
        InputSettings(
            predictionsEnabled: predictionsEnabled,
            nextWordPredictionsEnabled: nextWordPredictionsEnabled,
            autoCommitEnabled: autoCommitEnabled,
            autoCorrectEnabled: autoCorrectEnabled,
            soundsEnabled: soundsEnabled,
            emojisEnabled: emojisEnabled,
            learnMyTypedWords: learnMyTypedWords,
            shortcutForPeriod: shortcutForPeriod,
            showAnnotations: showAnnotations,
            annotationType: annotationType,
            script: script
        )
    }
    
    init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
        loadSettings()
    }
    
    func loadSettings() {
        self.predictionsEnabled = userDefaults.object(forKey: "predictionsEnabled") as? Bool ?? true
        self.nextWordPredictionsEnabled = userDefaults.object(forKey: "nextWordPredictionsEnabled") as? Bool ?? true
        self.autoCommitEnabled = userDefaults.object(forKey: "autoCommitEnabled") as? Bool ?? false
        self.autoCorrectEnabled = userDefaults.object(forKey: "autoCorrectEnabled") as? Bool ?? true
        self.soundsEnabled = userDefaults.object(forKey: "soundsEnabled") as? Bool ?? true
        self.emojisEnabled = userDefaults.object(forKey: "emojisEnabled") as? Bool ?? true
        self.learnMyTypedWords = userDefaults.object(forKey: "learnMyTypedWords") as? Bool ?? true
        self.shortcutForPeriod = userDefaults.object(forKey: "shortcutForPeriod") as? Bool ?? true
        self.showAnnotations = userDefaults.object(forKey: "showAnnotations") as? Bool ?? true
        
        let annotationTypeString = userDefaults.string(forKey: "annotationType") ?? AnnotationType.meaning.rawValue
        self.annotationType = AnnotationType(rawValue: annotationTypeString) ?? .meaning
        
        let scriptTypeString = userDefaults.string(forKey: "script") ?? ScriptType.tamil.rawValue
        self.script = ScriptType(rawValue: scriptTypeString) ?? .tamil
    }
    
    func saveSettings() {
        userDefaults.set(predictionsEnabled, forKey: "predictionsEnabled")
        userDefaults.set(nextWordPredictionsEnabled, forKey: "nextWordPredictionsEnabled")
        userDefaults.set(autoCommitEnabled, forKey: "autoCommitEnabled")
        userDefaults.set(autoCorrectEnabled, forKey: "autoCorrectEnabled")
        userDefaults.set(soundsEnabled, forKey: "soundsEnabled")
        userDefaults.set(emojisEnabled, forKey: "emojisEnabled")
        userDefaults.set(learnMyTypedWords, forKey: "learnMyTypedWords")
        userDefaults.set(shortcutForPeriod, forKey: "shortcutForPeriod")
        userDefaults.set(showAnnotations, forKey: "showAnnotations")
        userDefaults.set(annotationType.rawValue, forKey: "annotationType")
        userDefaults.set(script.rawValue, forKey: "script")
        userDefaults.synchronize()
    }
}

// MARK: - Theme Selection ViewModel
class ThemeSelectionViewModel: ObservableObject {
    @Published var availableThemes: [ThemeInfo] = []
    @Published var currentThemeId: String = "ios_default"
    
    private let themeManager: ThemeManager
    
    var currentThemeName: String {
        availableThemes.first { $0.id == currentThemeId }?.name ?? "Default"
    }
    
    init() {
        self.themeManager = ThemeManager(
            appGroupIdentifier: "group.murasu.Sangam"
        )
        self.currentThemeId = themeManager.currentThemeId
    }
    
    func loadThemes() {
        let themes = themeManager.getAvailableThemes()
        
        // Convert to ThemeInfo with additional metadata
        self.availableThemes = themes.map { theme in
            let config = themeManager.getThemeConfiguration(theme.id)
            return ThemeInfo(
                id: theme.id,
                name: theme.name,
                author: config?.author ?? "Unknown",
                version: config?.version
            )
        }
        
        self.currentThemeId = themeManager.currentThemeId
    }
    
    func selectTheme(_ themeId: String) {
        themeManager.setTheme(themeId)
        self.currentThemeId = themeId
        
        // Trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Theme Info Model
struct ThemeInfo: Identifiable {
    let id: String
    let name: String
    let author: String
    let version: String?
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
