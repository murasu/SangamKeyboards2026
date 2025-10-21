//
//  ThemeManager.swift
//  KeyboardCore
//
//  Created by Muthu Nedumaran on 01/10/2025.
//

import UIKit
import Foundation

public class ThemeManager: NSObject {
    
    // MARK: - Properties
    @objc dynamic public private(set) var currentThemeId: String
    private let userDefaults: UserDefaults
    private let appGroupIdentifier: String?
    
    // Keys for UserDefaults
    private let themeIdKey = "selected_theme_id"
    
    // Storage for loaded themes
    private var themeConfigurations: [String: ThemeConfiguration] = [:]
    
    // MARK: - Initialization
    public init(appGroupIdentifier: String? = nil) {
        self.appGroupIdentifier = appGroupIdentifier
        
        if let groupId = appGroupIdentifier,
           let groupDefaults = UserDefaults(suiteName: groupId) {
            self.userDefaults = groupDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
        
        self.currentThemeId = userDefaults.string(forKey: themeIdKey) ?? "ios_default"
        
        super.init()
        
        loadBundledThemes()
        loadUserThemes()
        
        // Preload fonts for better performance
        let allThemes = Array(themeConfigurations.values)
        KeyboardTheme.preloadFonts(for: allThemes)
    }
    
    // MARK: - Theme Loading
    
    /// Load all bundled themes from KeyboardCore bundle
    private func loadBundledThemes() {
        let bundle = Bundle(for: type(of: self))
        
        guard let resourcePath = bundle.resourcePath else {
            print("No resource path in bundle")
            createDefaultiOSTheme()
            return
        }
        
        do {
            let allFiles = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
            
            // Filter for theme files with th_ prefix
            let themeFiles = allFiles.filter { $0.hasPrefix("th_") && $0.hasSuffix(".json") }
            
            print("Found \(themeFiles.count) theme files in bundle:")
            
            for filename in themeFiles {
                print("  - \(filename)")
                let fileURL = URL(fileURLWithPath: resourcePath).appendingPathComponent(filename)
                loadThemeFromFile(url: fileURL)
            }
            
            if themeConfigurations.isEmpty {
                print("No themes loaded, creating default")
                createDefaultiOSTheme()
            } else {
                print("Successfully loaded \(themeConfigurations.count) themes")
            }
            
        } catch {
            print("Error scanning bundle resources: \(error)")
            createDefaultiOSTheme()
        }
    }

    /// Load user-created themes from app group container
    private func loadUserThemes() {
        guard let appGroupIdentifier = appGroupIdentifier,
              let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
              ) else {
            print("No app group identifier configured, skipping user themes")
            return
        }
        
        let themesURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent("Themes")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: themesURL,
            withIntermediateDirectories: true
        )
        
        do {
            let themeFiles = try FileManager.default.contentsOfDirectory(
                at: themesURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.lastPathComponent.hasPrefix("th_") && $0.pathExtension == "json" }
            
            for themeFile in themeFiles {
                loadThemeFromFile(url: themeFile)
            }
            
            print("Loaded \(themeFiles.count) user themes")
            
        } catch {
            print("No user themes found or error: \(error)")
        }
    }
    
    private func loadThemeFromFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ThemeConfiguration.self, from: data)
            
            themeConfigurations[config.id] = config
            print("✅ Loaded theme: \(config.name) (id: \(config.id))")
            
        } catch {
            print("❌ Error loading theme from \(url.lastPathComponent): \(error)")
        }
    }
    
    /// Create default iOS theme programmatically as fallback
    private func createDefaultiOSTheme() {
        let lightVariant = ThemeVariant(
            keyboardBackground: "#F3F3F8",
            keyboardBackgroundGradient: nil,
            keyboardBackgroundGradientDirection: nil,
            keyboardBackgroundCornerRadius: 12.0,
            regularKeyBackground: "#FFFFFF",
            regularKeyText: "#000000",
            regularKeyBorder: "#D1D1D6",
            regularKeyBorderWidth: 0.5,
            regularKeyShadowColor: "#00000026",
            regularKeyShadowOffset: [0, 1],
            regularKeyShadowBlur: 2.0,
            regularKeyCornerRadius: 5.0,
            modifierKeyBackground: "#AEB3BB",
            modifierKeyText: "#000000",
            modifierKeyBorder: "#8E8E93",
            modifierKeyBorderWidth: 0.5,
            modifierKeyShadowColor: "#00000026",
            modifierKeyShadowOffset: [0, 1],
            modifierKeyShadowBlur: 2.0,
            modifierKeyCornerRadius: 5.0,
            pressedKeyBackground: "#C7C7CC",
            pressedKeyText: "#000000",
            pressedKeyScale: 0.95,
            pressedKeyShadowColor: "#00000040",
            pressedKeyShadowOffset: [0, 2],
            pressedKeyShadowBlur: 4.0,
            previewBackground: "#FFFFFF",
            previewText: "#000000",
            previewBorder: "#D1D1D6",
            previewBorderWidth: 1.0,
            previewCornerRadius: 8.0,
            previewShadowColor: "#00000066",
            previewShadowOffset: [0, 4],
            previewShadowBlur: 8.0,
            popupBackground: "#FFFFFF",
            popupBorder: "#D1D1D6",
            popupBorderWidth: 1.0,
            popupCornerRadius: 8.0,
            popupShadowColor: "#00000066",
            popupShadowOffset: [0, 4],
            popupShadowBlur: 12.0,
            popupKeyText: "#000000",
            popupKeyBackground: "#FFFFFF",
            popupKeySelectedBackground: "#007AFF",
            popupKeySelectedText: "#FFFFFF",
            popupKeyCornerRadius: 4.0,
            candidateBarBackground: "#F3F3F8",
            candidateBarBorder: "#D1D1D6",
            candidateBarBorderWidth: 0.5,
            candidateBarCornerRadius: 8.0,
            candidateText: "#000000",
            candidateAnnotationText: "#8E8E93",
            candidateSelectedBackground: "#007AFF",
            candidateSelectedText: "#FFFFFF",
            candidateSelectedBorder: "#0051D5",
            candidateSelectedBorderWidth: 1.0,
            candidateCornerRadius: 12.0,
            candidateSeparator: "#D1D1D6",
            keyFontSize: 18.0,
            keyFontWeight: "regular",
            modifierKeyFontSize: 16.0,
            modifierKeyFontWeight: "medium",
            previewFontSize: 32.0,
            previewFontWeight: "regular",
            popupKeyFontSize: 28.0,
            popupKeyFontWeight: "regular",
            candidateFontSize: 18.0,
            candidateFontWeight: "regular",
            candidateAnnotationFontSize: 14.0,
            customFontName: "Tamil Sangam MN",
            keySpacing: 3.0,
            rowSpacing: 6.0
        )
        
        let darkVariant = ThemeVariant(
            keyboardBackground: "#1C1C1E",
            keyboardBackgroundGradient: nil,
            keyboardBackgroundGradientDirection: nil,
            keyboardBackgroundCornerRadius: 12.0,
            regularKeyBackground: "#3A3A3C",
            regularKeyText: "#FFFFFF",
            regularKeyBorder: "#545456",
            regularKeyBorderWidth: 0.5,
            regularKeyShadowColor: "#00000040",
            regularKeyShadowOffset: [0, 1],
            regularKeyShadowBlur: 2.0,
            regularKeyCornerRadius: 5.0,
            modifierKeyBackground: "#636366",
            modifierKeyText: "#FFFFFF",
            modifierKeyBorder: "#7C7C80",
            modifierKeyBorderWidth: 0.5,
            modifierKeyShadowColor: "#00000040",
            modifierKeyShadowOffset: [0, 1],
            modifierKeyShadowBlur: 2.0,
            modifierKeyCornerRadius: 5.0,
            pressedKeyBackground: "#8E8E93",
            pressedKeyText: "#FFFFFF",
            pressedKeyScale: 0.95,
            pressedKeyShadowColor: "#00000066",
            pressedKeyShadowOffset: [0, 2],
            pressedKeyShadowBlur: 4.0,
            previewBackground: "#3A3A3C",
            previewText: "#FFFFFF",
            previewBorder: "#545456",
            previewBorderWidth: 1.0,
            previewCornerRadius: 8.0,
            previewShadowColor: "#000000CC",
            previewShadowOffset: [0, 4],
            previewShadowBlur: 8.0,
            popupBackground: "#3A3A3C",
            popupBorder: "#545456",
            popupBorderWidth: 1.0,
            popupCornerRadius: 8.0,
            popupShadowColor: "#000000CC",
            popupShadowOffset: [0, 4],
            popupShadowBlur: 12.0,
            popupKeyText: "#FFFFFF",
            popupKeyBackground: "#3A3A3C",
            popupKeySelectedBackground: "#0A84FF",
            popupKeySelectedText: "#FFFFFF",
            popupKeyCornerRadius: 4.0,
            candidateBarBackground: "#1C1C1E",
            candidateBarBorder: "#545456",
            candidateBarBorderWidth: 0.5,
            candidateBarCornerRadius: 8.0,
            candidateText: "#FFFFFF",
            candidateAnnotationText: "#8E8E93",
            candidateSelectedBackground: "#0A84FF",
            candidateSelectedText: "#FFFFFF",
            candidateSelectedBorder: "#0051D5",
            candidateSelectedBorderWidth: 1.0,
            candidateCornerRadius: 12.0,
            candidateSeparator: "#545456",
            keyFontSize: 18.0,
            keyFontWeight: "regular",
            modifierKeyFontSize: 16.0,
            modifierKeyFontWeight: "medium",
            previewFontSize: 32.0,
            previewFontWeight: "regular",
            popupKeyFontSize: 28.0,
            popupKeyFontWeight: "regular",
            candidateFontSize: 18.0,
            candidateFontWeight: "regular",
            candidateAnnotationFontSize: 14.0,
            customFontName: "Tamil Sangam MN",
            keySpacing: 3.0,
            rowSpacing: 6.0
        )
        
        let defaultTheme = ThemeConfiguration(
            id: "ios_default",
            name: "iOS Default",
            version: "1.0",
            author: "Murasu Systems",
            light: lightVariant,
            dark: darkVariant
        )
        
        themeConfigurations["ios_default"] = defaultTheme
        print("✅ Created default iOS theme")
    }
    
    // MARK: - Public API
    
    /// Get the current theme for the given interface style
    public func getCurrentTheme(for interfaceStyle: UIUserInterfaceStyle) -> KeyboardTheme? {
        guard let config = themeConfigurations[currentThemeId] else {
            print("⚠️ Theme '\(currentThemeId)' not found, falling back to default")
            return getDefaultTheme(for: interfaceStyle)
        }
        
        let variant = interfaceStyle == .dark ? config.dark : config.light
        return KeyboardTheme(from: variant)
    }
    
    /// Get default theme (fallback)
    private func getDefaultTheme(for interfaceStyle: UIUserInterfaceStyle) -> KeyboardTheme? {
        guard let config = themeConfigurations["ios_default"] else { return nil }
        let variant = interfaceStyle == .dark ? config.dark : config.light
        return KeyboardTheme(from: variant)
    }
    
    /// Set the current theme
    public func setTheme(_ themeId: String) {
        guard themeConfigurations[themeId] != nil else {
            print("⚠️ Theme '\(themeId)' not found")
            return
        }
        
        currentThemeId = themeId
        userDefaults.set(themeId, forKey: themeIdKey)
        print("✅ Theme set to: \(themeId)")
    }
    
    /// Get list of available theme IDs and names
    public func getAvailableThemes() -> [(id: String, name: String)] {
        return themeConfigurations.map { (id: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name }
    }
    
    /// Get theme configuration by ID
    public func getThemeConfiguration(_ themeId: String) -> ThemeConfiguration? {
        return themeConfigurations[themeId]
    }
    
    /// Save a user theme to the app group container
    public func saveUserTheme(_ config: ThemeConfiguration) throws {
        guard let appGroupIdentifier = appGroupIdentifier,
              let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
              ) else {
            throw ThemeError.noAppGroupContainer
        }
        
        let themesURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent("Themes")
        
        // Create directory if needed
        try FileManager.default.createDirectory(
            at: themesURL,
            withIntermediateDirectories: true
        )
        
        let fileURL = themesURL.appendingPathComponent("\(config.id).json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        
        try data.write(to: fileURL)
        
        // Add to loaded themes
        themeConfigurations[config.id] = config
        
        print("✅ Saved user theme: \(config.name)")
    }
    
    /// Delete a user theme
    public func deleteUserTheme(_ themeId: String) throws {
        guard let appGroupIdentifier = appGroupIdentifier,
              let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
              ) else {
            throw ThemeError.noAppGroupContainer
        }
        
        let fileURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent("Themes")
            .appendingPathComponent("\(themeId).json")
        
        try FileManager.default.removeItem(at: fileURL)
        themeConfigurations.removeValue(forKey: themeId)
        
        // If deleted theme was current, fall back to default
        if currentThemeId == themeId {
            setTheme("ios_default")
        }
        
        print("✅ Deleted user theme: \(themeId)")
    }
    
    /// Reload all themes (useful after downloading new themes)
    public func reloadThemes() {
        themeConfigurations.removeAll()
        loadBundledThemes()
        loadUserThemes()
    }
    
    /// Update all existing themes to use Tamil Sangam MN font
    /// This is a utility method to help update your theme files
    public func updateAllThemesToTamilFont() {
        print("🔤 Updating all themes to use Tamil Sangam MN font...")
        
        for (themeId, config) in themeConfigurations {
            // Create updated variants with Tamil font
            let updatedLight = ThemeVariant(
                keyboardBackground: config.light.keyboardBackground,
                keyboardBackgroundGradient: config.light.keyboardBackgroundGradient,
                keyboardBackgroundGradientDirection: config.light.keyboardBackgroundGradientDirection,
                keyboardBackgroundCornerRadius: config.light.keyboardBackgroundCornerRadius,
                regularKeyBackground: config.light.regularKeyBackground,
                regularKeyText: config.light.regularKeyText,
                regularKeyBorder: config.light.regularKeyBorder,
                regularKeyBorderWidth: config.light.regularKeyBorderWidth,
                regularKeyShadowColor: config.light.regularKeyShadowColor,
                regularKeyShadowOffset: config.light.regularKeyShadowOffset,
                regularKeyShadowBlur: config.light.regularKeyShadowBlur,
                regularKeyCornerRadius: config.light.regularKeyCornerRadius,
                modifierKeyBackground: config.light.modifierKeyBackground,
                modifierKeyText: config.light.modifierKeyText,
                modifierKeyBorder: config.light.modifierKeyBorder,
                modifierKeyBorderWidth: config.light.modifierKeyBorderWidth,
                modifierKeyShadowColor: config.light.modifierKeyShadowColor,
                modifierKeyShadowOffset: config.light.modifierKeyShadowOffset,
                modifierKeyShadowBlur: config.light.modifierKeyShadowBlur,
                modifierKeyCornerRadius: config.light.modifierKeyCornerRadius,
                pressedKeyBackground: config.light.pressedKeyBackground,
                pressedKeyText: config.light.pressedKeyText,
                pressedKeyScale: config.light.pressedKeyScale,
                pressedKeyShadowColor: config.light.pressedKeyShadowColor,
                pressedKeyShadowOffset: config.light.pressedKeyShadowOffset,
                pressedKeyShadowBlur: config.light.pressedKeyShadowBlur,
                previewBackground: config.light.previewBackground,
                previewText: config.light.previewText,
                previewBorder: config.light.previewBorder,
                previewBorderWidth: config.light.previewBorderWidth,
                previewCornerRadius: config.light.previewCornerRadius,
                previewShadowColor: config.light.previewShadowColor,
                previewShadowOffset: config.light.previewShadowOffset,
                previewShadowBlur: config.light.previewShadowBlur,
                popupBackground: config.light.popupBackground,
                popupBorder: config.light.popupBorder,
                popupBorderWidth: config.light.popupBorderWidth,
                popupCornerRadius: config.light.popupCornerRadius,
                popupShadowColor: config.light.popupShadowColor,
                popupShadowOffset: config.light.popupShadowOffset,
                popupShadowBlur: config.light.popupShadowBlur,
                popupKeyText: config.light.popupKeyText,
                popupKeyBackground: config.light.popupKeyBackground,
                popupKeySelectedBackground: config.light.popupKeySelectedBackground,
                popupKeySelectedText: config.light.popupKeySelectedText,
                popupKeyCornerRadius: config.light.popupKeyCornerRadius,
                candidateBarBackground: config.light.candidateBarBackground,
                candidateBarBorder: config.light.candidateBarBorder,
                candidateBarBorderWidth: config.light.candidateBarBorderWidth,
                candidateBarCornerRadius: config.light.candidateBarCornerRadius,
                candidateText: config.light.candidateText,
                candidateAnnotationText: config.light.candidateAnnotationText,
                candidateSelectedBackground: config.light.candidateSelectedBackground,
                candidateSelectedText: config.light.candidateSelectedText,
                candidateSelectedBorder: config.light.candidateSelectedBorder,
                candidateSelectedBorderWidth: config.light.candidateSelectedBorderWidth,
                candidateCornerRadius: config.light.candidateCornerRadius,
                candidateSeparator: config.light.candidateSeparator,
                keyFontSize: config.light.keyFontSize,
                keyFontWeight: config.light.keyFontWeight,
                modifierKeyFontSize: config.light.modifierKeyFontSize,
                modifierKeyFontWeight: config.light.modifierKeyFontWeight,
                previewFontSize: config.light.previewFontSize,
                previewFontWeight: config.light.previewFontWeight,
                popupKeyFontSize: config.light.popupKeyFontSize,
                popupKeyFontWeight: config.light.popupKeyFontWeight,
                candidateFontSize: config.light.candidateFontSize,
                candidateFontWeight: config.light.candidateFontWeight,
                candidateAnnotationFontSize: config.light.candidateAnnotationFontSize,
                customFontName: "Tamil Sangam MN", // This is the key change
                keySpacing: config.light.keySpacing,
                rowSpacing: config.light.rowSpacing
            )
            
            let updatedDark = ThemeVariant(
                keyboardBackground: config.dark.keyboardBackground,
                keyboardBackgroundGradient: config.dark.keyboardBackgroundGradient,
                keyboardBackgroundGradientDirection: config.dark.keyboardBackgroundGradientDirection,
                keyboardBackgroundCornerRadius: config.dark.keyboardBackgroundCornerRadius,
                regularKeyBackground: config.dark.regularKeyBackground,
                regularKeyText: config.dark.regularKeyText,
                regularKeyBorder: config.dark.regularKeyBorder,
                regularKeyBorderWidth: config.dark.regularKeyBorderWidth,
                regularKeyShadowColor: config.dark.regularKeyShadowColor,
                regularKeyShadowOffset: config.dark.regularKeyShadowOffset,
                regularKeyShadowBlur: config.dark.regularKeyShadowBlur,
                regularKeyCornerRadius: config.dark.regularKeyCornerRadius,
                modifierKeyBackground: config.dark.modifierKeyBackground,
                modifierKeyText: config.dark.modifierKeyText,
                modifierKeyBorder: config.dark.modifierKeyBorder,
                modifierKeyBorderWidth: config.dark.modifierKeyBorderWidth,
                modifierKeyShadowColor: config.dark.modifierKeyShadowColor,
                modifierKeyShadowOffset: config.dark.modifierKeyShadowOffset,
                modifierKeyShadowBlur: config.dark.modifierKeyShadowBlur,
                modifierKeyCornerRadius: config.dark.modifierKeyCornerRadius,
                pressedKeyBackground: config.dark.pressedKeyBackground,
                pressedKeyText: config.dark.pressedKeyText,
                pressedKeyScale: config.dark.pressedKeyScale,
                pressedKeyShadowColor: config.dark.pressedKeyShadowColor,
                pressedKeyShadowOffset: config.dark.pressedKeyShadowOffset,
                pressedKeyShadowBlur: config.dark.pressedKeyShadowBlur,
                previewBackground: config.dark.previewBackground,
                previewText: config.dark.previewText,
                previewBorder: config.dark.previewBorder,
                previewBorderWidth: config.dark.previewBorderWidth,
                previewCornerRadius: config.dark.previewCornerRadius,
                previewShadowColor: config.dark.previewShadowColor,
                previewShadowOffset: config.dark.previewShadowOffset,
                previewShadowBlur: config.dark.previewShadowBlur,
                popupBackground: config.dark.popupBackground,
                popupBorder: config.dark.popupBorder,
                popupBorderWidth: config.dark.popupBorderWidth,
                popupCornerRadius: config.dark.popupCornerRadius,
                popupShadowColor: config.dark.popupShadowColor,
                popupShadowOffset: config.dark.popupShadowOffset,
                popupShadowBlur: config.dark.popupShadowBlur,
                popupKeyText: config.dark.popupKeyText,
                popupKeyBackground: config.dark.popupKeyBackground,
                popupKeySelectedBackground: config.dark.popupKeySelectedBackground,
                popupKeySelectedText: config.dark.popupKeySelectedText,
                popupKeyCornerRadius: config.dark.popupKeyCornerRadius,
                candidateBarBackground: config.dark.candidateBarBackground,
                candidateBarBorder: config.dark.candidateBarBorder,
                candidateBarBorderWidth: config.dark.candidateBarBorderWidth,
                candidateBarCornerRadius: config.dark.candidateBarCornerRadius,
                candidateText: config.dark.candidateText,
                candidateAnnotationText: config.dark.candidateAnnotationText,
                candidateSelectedBackground: config.dark.candidateSelectedBackground,
                candidateSelectedText: config.dark.candidateSelectedText,
                candidateSelectedBorder: config.dark.candidateSelectedBorder,
                candidateSelectedBorderWidth: config.dark.candidateSelectedBorderWidth,
                candidateCornerRadius: config.dark.candidateCornerRadius,
                candidateSeparator: config.dark.candidateSeparator,
                keyFontSize: config.dark.keyFontSize,
                keyFontWeight: config.dark.keyFontWeight,
                modifierKeyFontSize: config.dark.modifierKeyFontSize,
                modifierKeyFontWeight: config.dark.modifierKeyFontWeight,
                previewFontSize: config.dark.previewFontSize,
                previewFontWeight: config.dark.previewFontWeight,
                popupKeyFontSize: config.dark.popupKeyFontSize,
                popupKeyFontWeight: config.dark.popupKeyFontWeight,
                candidateFontSize: config.dark.candidateFontSize,
                candidateFontWeight: config.dark.candidateFontWeight,
                candidateAnnotationFontSize: config.dark.candidateAnnotationFontSize,
                customFontName: "Tamil Sangam MN", // This is the key change
                keySpacing: config.dark.keySpacing,
                rowSpacing: config.dark.rowSpacing
            )
            
            let updatedConfig = ThemeConfiguration(
                id: config.id,
                name: config.name,
                version: config.version,
                author: config.author,
                light: updatedLight,
                dark: updatedDark
            )
            
            // Update the in-memory configuration
            themeConfigurations[themeId] = updatedConfig
            
            // Try to save it back to file (only for user themes)
            do {
                try saveUserTheme(updatedConfig)
                print("✅ Updated theme: \(config.name)")
            } catch {
                print("⚠️ Could not save updated theme \(config.name): \(error)")
                print("   You may need to manually update this theme's JSON file.")
            }
        }
        
        print("🔤 Theme font update completed!")
    }
}

// MARK: - Errors
public enum ThemeError: Error {
    case noAppGroupContainer
    case themeNotFound
    case invalidThemeData
}
