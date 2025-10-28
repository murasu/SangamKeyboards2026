import Foundation
import SwiftUI
import Combine

// Import the keyboard type constants from the C header
// These will be used directly without redefinition

enum SuggestionsFontSize: String, CaseIterable {
    case small = "Small"
    case regular = "Regular"
    case medium = "Medium"
    case large = "Large"
}

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

#if os(iOS)
enum KeyboardStyle: String, CaseIterable {
    case `default` = "Default"
    case compact = "Compact"
}
#endif

@MainActor
class EditorSettings: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var keyboardType: Int = 0 // kbdAnjal as default
    @Published var editorFontSize: Double = 24.0
    @Published var fontFamily: String = "Tamil Sangam MN"
    @Published var enableSuggestions: Bool = true
    @Published var suggestionsFontSize: SuggestionsFontSize = .regular
    @Published var predictionDelay: Double = 0.5
    @Published var maxSuggestions: Int = 5
    @Published var autoSelectBestWord: Bool = true
    @Published var learnTypedWords: Bool = true
    @Published var showAnnotations: Bool = false
    @Published var includeEmojis: Bool = false
    @Published var showVertical: Bool = true
    @Published var enableComposition: Bool = true
    @Published var enableSoundEffects: Bool = false
    @Published var appTheme: AppTheme = .system
    
    // Platform-specific settings
    #if os(macOS)
    @Published var windowOpacity: Double = 0.95
    @Published var enableVibrancy: Bool = true
    #endif
    
    #if os(iOS)
    @Published var hapticFeedback: Bool = true
    @Published var keyboardStyle: KeyboardStyle = .default
    #endif
    
    // MARK: - Static Properties
    
    static let shared = EditorSettings()
    
    // Store cancellables to prevent deallocation
    private var cancellables = Set<AnyCancellable>()
    
    static let availableFonts = [
        "Tamil Sangam MN",
        "Annai MN",
        "Anjal Chittu",
        "Anjal Malar"
    ]
    
    // Keyboard type definitions with display names
    static let keyboardTypes: [(id: Int, name: String)] = [
        (0, "Anjal"), // kbdAnjal
        (1, "Tamil 99"), // kbdTamil99
        (2, "Tamil 97"), // kbdTamil97
        (3, "Mylai"), // kbdMylai
        (4, "TW New"), // kbdTWNew
        (5, "TW Old"), // kbdTWOld
        (6, "Anjal Indic"), // kbdAnjalIndic
        (7, "Murasu 6"), // kbdMurasu6
        (8, "Bamini"), // kbdBamini
        (9, "TN TWriter"), // kbdTNTWriter
        (100, "System") // kbdSystem (not defined in header)
    ]
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKeys {
        static let keyboardType = "keyboardType"
        static let editorFontSize = "editorFontSize"
        static let fontFamily = "fontFamily"
        static let enableSuggestions = "enableSuggestions"
        static let suggestionsFontSize = "suggestionsFontSize"
        static let predictionDelay = "predictionDelay"
        static let maxSuggestions = "maxSuggestions"
        static let autoSelectBestWord = "autoSelectBestWord"
        static let learnTypedWords = "learnTypedWords"
        static let showAnnotations = "showAnnotations"
        static let includeEmojis = "includeEmojis"
        static let showVertical = "showVertical"
        static let enableComposition = "enableComposition"
        static let enableSoundEffects = "enableSoundEffects"
        static let appTheme = "appTheme"
        
        #if os(macOS)
        static let windowOpacity = "windowOpacity"
        static let enableVibrancy = "enableVibrancy"
        #endif
        
        #if os(iOS)
        static let hapticFeedback = "hapticFeedback"
        static let keyboardStyle = "keyboardStyle"
        #endif
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        setupObservers()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        keyboardType = defaults.object(forKey: UserDefaultsKeys.keyboardType) as? Int ?? 0
        editorFontSize = defaults.object(forKey: UserDefaultsKeys.editorFontSize) as? Double ?? 24.0
        fontFamily = defaults.object(forKey: UserDefaultsKeys.fontFamily) as? String ?? "Tamil Sangam MN"
        enableSuggestions = defaults.object(forKey: UserDefaultsKeys.enableSuggestions) as? Bool ?? true
        
        if let fontSizeRaw = defaults.object(forKey: UserDefaultsKeys.suggestionsFontSize) as? String {
            suggestionsFontSize = SuggestionsFontSize(rawValue: fontSizeRaw) ?? .regular
        }
        
        predictionDelay = defaults.object(forKey: UserDefaultsKeys.predictionDelay) as? Double ?? 0.5
        maxSuggestions = defaults.object(forKey: UserDefaultsKeys.maxSuggestions) as? Int ?? 5
        autoSelectBestWord = defaults.object(forKey: UserDefaultsKeys.autoSelectBestWord) as? Bool ?? true
        learnTypedWords = defaults.object(forKey: UserDefaultsKeys.learnTypedWords) as? Bool ?? true
        showAnnotations = defaults.object(forKey: UserDefaultsKeys.showAnnotations) as? Bool ?? false
        includeEmojis = defaults.object(forKey: UserDefaultsKeys.includeEmojis) as? Bool ?? false
        showVertical = defaults.object(forKey: UserDefaultsKeys.showVertical) as? Bool ?? true
        enableComposition = defaults.object(forKey: UserDefaultsKeys.enableComposition) as? Bool ?? true
        enableSoundEffects = defaults.object(forKey: UserDefaultsKeys.enableSoundEffects) as? Bool ?? false
        
        if let themeRaw = defaults.object(forKey: UserDefaultsKeys.appTheme) as? String {
            appTheme = AppTheme(rawValue: themeRaw) ?? .system
        }
        
        #if os(macOS)
        windowOpacity = defaults.object(forKey: UserDefaultsKeys.windowOpacity) as? Double ?? 0.95
        enableVibrancy = defaults.object(forKey: UserDefaultsKeys.enableVibrancy) as? Bool ?? true
        #endif
        
        #if os(iOS)
        hapticFeedback = defaults.object(forKey: UserDefaultsKeys.hapticFeedback) as? Bool ?? true
        
        if let styleRaw = defaults.object(forKey: UserDefaultsKeys.keyboardStyle) as? String {
            keyboardStyle = KeyboardStyle(rawValue: styleRaw) ?? .default
        }
        #endif
    }
    
    private func setupObservers() {
        // Save settings whenever any published property changes
        $keyboardType.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $editorFontSize.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $fontFamily.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $enableSuggestions.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $suggestionsFontSize.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $predictionDelay.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $maxSuggestions.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $autoSelectBestWord.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $learnTypedWords.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $showAnnotations.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $includeEmojis.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $showVertical.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $enableComposition.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $enableSoundEffects.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $appTheme.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        #if os(macOS)
        $windowOpacity.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $enableVibrancy.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        #endif
        
        #if os(iOS)
        $hapticFeedback.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        $keyboardStyle.sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        #endif
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(keyboardType, forKey: UserDefaultsKeys.keyboardType)
        defaults.set(editorFontSize, forKey: UserDefaultsKeys.editorFontSize)
        defaults.set(fontFamily, forKey: UserDefaultsKeys.fontFamily)
        defaults.set(enableSuggestions, forKey: UserDefaultsKeys.enableSuggestions)
        defaults.set(suggestionsFontSize.rawValue, forKey: UserDefaultsKeys.suggestionsFontSize)
        defaults.set(predictionDelay, forKey: UserDefaultsKeys.predictionDelay)
        defaults.set(maxSuggestions, forKey: UserDefaultsKeys.maxSuggestions)
        defaults.set(autoSelectBestWord, forKey: UserDefaultsKeys.autoSelectBestWord)
        defaults.set(learnTypedWords, forKey: UserDefaultsKeys.learnTypedWords)
        defaults.set(showAnnotations, forKey: UserDefaultsKeys.showAnnotations)
        defaults.set(includeEmojis, forKey: UserDefaultsKeys.includeEmojis)
        defaults.set(showVertical, forKey: UserDefaultsKeys.showVertical)
        defaults.set(enableComposition, forKey: UserDefaultsKeys.enableComposition)
        defaults.set(enableSoundEffects, forKey: UserDefaultsKeys.enableSoundEffects)
        defaults.set(appTheme.rawValue, forKey: UserDefaultsKeys.appTheme)
        
        #if os(macOS)
        defaults.set(windowOpacity, forKey: UserDefaultsKeys.windowOpacity)
        defaults.set(enableVibrancy, forKey: UserDefaultsKeys.enableVibrancy)
        #endif
        
        #if os(iOS)
        defaults.set(hapticFeedback, forKey: UserDefaultsKeys.hapticFeedback)
        defaults.set(keyboardStyle.rawValue, forKey: UserDefaultsKeys.keyboardStyle)
        #endif
    }
    
    // MARK: - Convenience Methods
    
    func getKeyboardTypeName() -> String {
        return Self.keyboardTypes.first { $0.id == keyboardType }?.name ?? "Unknown"
    }
    
    func resetToDefaults() {
        keyboardType = 0
        editorFontSize = 24.0
        fontFamily = "Tamil Sangam MN"
        enableSuggestions = true
        suggestionsFontSize = .regular
        predictionDelay = 0.5
        maxSuggestions = 5
        autoSelectBestWord = true
        learnTypedWords = true
        showAnnotations = false
        includeEmojis = false
        showVertical = true
        enableComposition = true
        enableSoundEffects = false
        appTheme = .system
        
        #if os(macOS)
        windowOpacity = 0.95
        enableVibrancy = true
        #endif
        
        #if os(iOS)
        hapticFeedback = true
        keyboardStyle = .default
        #endif
    }
    
    // MARK: - Font Size Mapping
    
    /// Get the actual font point size for suggestions based on the enum setting
    func getSuggestionsFontPointSize() -> CGFloat {
        switch suggestionsFontSize {
        case .small:
            return 16.0
        case .regular:
            return 18.0
        case .medium:
            return 20.0
        case .large:
            return 22.0
        }
    }
    
    // MARK: - Font Creation Methods
    
    #if canImport(AppKit)
    /// Create the main editor font for macOS using current settings
    func createEditorFont() -> NSFont {
        let fontSize = CGFloat(editorFontSize)
        return NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
    }
    
    /// Create the suggestions font for macOS using current settings
    func createSuggestionsFont() -> NSFont {
        let fontSize = getSuggestionsFontPointSize()
        return NSFont(name: fontFamily, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
    }
    #endif
    
    #if canImport(UIKit)
    /// Create the main editor font for iOS using current settings
    func createEditorFont() -> UIFont {
        let fontSize = CGFloat(editorFontSize)
        return UIFont(name: fontFamily, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    }
    
    /// Create the suggestions font for iOS using current settings
    func createSuggestionsFont() -> UIFont {
        let fontSize = getSuggestionsFontPointSize()
        return UIFont(name: fontFamily, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    }
    #endif
}
