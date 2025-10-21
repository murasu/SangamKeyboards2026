//
//  KeyboardTheme.swift
//  KeyboardCore
//
//  Created by Muthu Nedumaran on 01/10/2025.
//

import UIKit
import UIKit
import CoreText

// MARK: - Theme Configuration (matches JSON structure)
public struct ThemeConfiguration: Codable {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    
    public let light: ThemeVariant
    public let dark: ThemeVariant
    
    public init(id: String, name: String, version: String, author: String,
                light: ThemeVariant, dark: ThemeVariant) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.light = light
        self.dark = dark
    }
}

public struct ThemeVariant: Codable {
    // Keyboard background
    public let keyboardBackground: String
    public let keyboardBackgroundGradient: [String]?
    public let keyboardBackgroundGradientDirection: String?
    public let keyboardBackgroundCornerRadius: CGFloat
    
    // Regular keys
    public let regularKeyBackground: String
    public let regularKeyText: String
    public let regularKeyBorder: String
    public let regularKeyBorderWidth: CGFloat
    public let regularKeyShadowColor: String
    public let regularKeyShadowOffset: [CGFloat]
    public let regularKeyShadowBlur: CGFloat
    public let regularKeyCornerRadius: CGFloat
    
    // Modifier keys
    public let modifierKeyBackground: String
    public let modifierKeyText: String
    public let modifierKeyBorder: String
    public let modifierKeyBorderWidth: CGFloat
    public let modifierKeyShadowColor: String
    public let modifierKeyShadowOffset: [CGFloat]
    public let modifierKeyShadowBlur: CGFloat
    public let modifierKeyCornerRadius: CGFloat
    
    // Pressed state
    public let pressedKeyBackground: String
    public let pressedKeyText: String
    public let pressedKeyScale: CGFloat
    public let pressedKeyShadowColor: String
    public let pressedKeyShadowOffset: [CGFloat]
    public let pressedKeyShadowBlur: CGFloat
    
    // Key preview popup
    public let previewBackground: String
    public let previewText: String
    public let previewBorder: String
    public let previewBorderWidth: CGFloat
    public let previewCornerRadius: CGFloat
    public let previewShadowColor: String
    public let previewShadowOffset: [CGFloat]
    public let previewShadowBlur: CGFloat
    
    // Long-press popup
    public let popupBackground: String
    public let popupBorder: String
    public let popupBorderWidth: CGFloat
    public let popupCornerRadius: CGFloat
    public let popupShadowColor: String
    public let popupShadowOffset: [CGFloat]
    public let popupShadowBlur: CGFloat
    public let popupKeyText: String
    public let popupKeyBackground: String
    public let popupKeySelectedBackground: String
    public let popupKeySelectedText: String
    public let popupKeyCornerRadius: CGFloat
    
    // Candidate bar
    public let candidateBarBackground: String
    public let candidateBarBorder: String
    public let candidateBarBorderWidth: CGFloat
    public let candidateBarCornerRadius: CGFloat
    public let candidateText: String
    public let candidateAnnotationText: String
    public let candidateSelectedBackground: String
    public let candidateSelectedText: String
    public let candidateSelectedBorder: String
    public let candidateSelectedBorderWidth: CGFloat
    public let candidateCornerRadius: CGFloat?
    public let candidateSeparator: String
    
    // Typography
    public let keyFontSize: CGFloat
    public let keyFontWeight: String
    public let modifierKeyFontSize: CGFloat
    public let modifierKeyFontWeight: String
    public let previewFontSize: CGFloat
    public let previewFontWeight: String
    public let popupKeyFontSize: CGFloat
    public let popupKeyFontWeight: String
    public let candidateFontSize: CGFloat
    public let candidateFontWeight: String
    public let candidateAnnotationFontSize: CGFloat
    
    public let customFontName: String?
    
    // Spacing
    public let keySpacing: CGFloat
    public let rowSpacing: CGFloat
}

// MARK: - Runtime Theme (converted from ThemeVariant)
public struct KeyboardTheme {
    // Keyboard background
    public let keyboardBackground: UIColor
    public let keyboardBackgroundGradient: [UIColor]?
    public let keyboardBackgroundGradientDirection: GradientDirection
    public let keyboardBackgroundCornerRadius: CGFloat
    
    // Regular keys
    public let regularKeyBackground: UIColor
    public let regularKeyText: UIColor
    public let regularKeyBorder: UIColor
    public let regularKeyBorderWidth: CGFloat
    public let regularKeyShadow: ShadowStyle
    public let regularKeyCornerRadius: CGFloat
    
    // Modifier keys
    public let modifierKeyBackground: UIColor
    public let modifierKeyText: UIColor
    public let modifierKeyBorder: UIColor
    public let modifierKeyBorderWidth: CGFloat
    public let modifierKeyShadow: ShadowStyle
    public let modifierKeyCornerRadius: CGFloat
    
    // Pressed state
    public let pressedKeyBackground: UIColor
    public let pressedKeyText: UIColor
    public let pressedKeyScale: CGFloat
    public let pressedKeyShadow: ShadowStyle
    
    // Preview popup
    public let previewBackground: UIColor
    public let previewText: UIColor
    public let previewBorder: UIColor
    public let previewBorderWidth: CGFloat
    public let previewCornerRadius: CGFloat
    public let previewShadow: ShadowStyle
    
    // Long-press popup
    public let popupBackground: UIColor
    public let popupBorder: UIColor
    public let popupBorderWidth: CGFloat
    public let popupCornerRadius: CGFloat
    public let popupShadow: ShadowStyle
    public let popupKeyText: UIColor
    public let popupKeyBackground: UIColor
    public let popupKeySelectedBackground: UIColor
    public let popupKeySelectedText: UIColor
    public let popupKeyCornerRadius: CGFloat
    
    // Candidate bar
    public let candidateBarBackground: UIColor
    public let candidateBarBorder: UIColor
    public let candidateBarBorderWidth: CGFloat
    public let candidateBarCornerRadius: CGFloat
    public let candidateText: UIColor
    public let candidateAnnotationText: UIColor
    public let candidateSelectedBackground: UIColor
    public let candidateSelectedText: UIColor
    public let candidateSelectedBorder: UIColor
    public let candidateSelectedBorderWidth: CGFloat
    public let candidateCornerRadius: CGFloat
    public let candidateSeparator: UIColor
    
    // Typography
    public let keyFont: UIFont
    public let modifierKeyFont: UIFont
    public let previewFont: UIFont
    public let popupKeyFont: UIFont
    public let candidateFont: UIFont
    public let candidateAnnotationFont: UIFont
    
    // Spacing
    public let keySpacing: CGFloat
    public let rowSpacing: CGFloat
    
    // MARK: - Initialize from ThemeVariant
    public init(from variant: ThemeVariant) {
        // Keyboard background
        self.keyboardBackground = UIColor(hex: variant.keyboardBackground) ?? .systemBackground
        self.keyboardBackgroundGradient = variant.keyboardBackgroundGradient?.compactMap { UIColor(hex: $0) }
        self.keyboardBackgroundGradientDirection = GradientDirection(rawValue: variant.keyboardBackgroundGradientDirection ?? "vertical") ?? .vertical
        self.keyboardBackgroundCornerRadius = variant.keyboardBackgroundCornerRadius
        
        // Regular keys
        self.regularKeyBackground = UIColor(hex: variant.regularKeyBackground) ?? .white
        self.regularKeyText = UIColor(hex: variant.regularKeyText) ?? .black
        self.regularKeyBorder = UIColor(hex: variant.regularKeyBorder) ?? .gray
        self.regularKeyBorderWidth = variant.regularKeyBorderWidth
        self.regularKeyShadow = ShadowStyle(
            color: UIColor(hex: variant.regularKeyShadowColor) ?? .black,
            offset: CGSize(width: variant.regularKeyShadowOffset[0], height: variant.regularKeyShadowOffset[1]),
            blur: variant.regularKeyShadowBlur
        )
        self.regularKeyCornerRadius = variant.regularKeyCornerRadius
        
        // Modifier keys
        self.modifierKeyBackground = UIColor(hex: variant.modifierKeyBackground) ?? .systemGray4
        self.modifierKeyText = UIColor(hex: variant.modifierKeyText) ?? .black
        self.modifierKeyBorder = UIColor(hex: variant.modifierKeyBorder) ?? .gray
        self.modifierKeyBorderWidth = variant.modifierKeyBorderWidth
        self.modifierKeyShadow = ShadowStyle(
            color: UIColor(hex: variant.modifierKeyShadowColor) ?? .black,
            offset: CGSize(width: variant.modifierKeyShadowOffset[0], height: variant.modifierKeyShadowOffset[1]),
            blur: variant.modifierKeyShadowBlur
        )
        self.modifierKeyCornerRadius = variant.modifierKeyCornerRadius
        
        // Pressed state
        self.pressedKeyBackground = UIColor(hex: variant.pressedKeyBackground) ?? .gray
        self.pressedKeyText = UIColor(hex: variant.pressedKeyText) ?? .white
        self.pressedKeyScale = variant.pressedKeyScale
        self.pressedKeyShadow = ShadowStyle(
            color: UIColor(hex: variant.pressedKeyShadowColor) ?? .black,
            offset: CGSize(width: variant.pressedKeyShadowOffset[0], height: variant.pressedKeyShadowOffset[1]),
            blur: variant.pressedKeyShadowBlur
        )
        
        // Preview popup
        self.previewBackground = UIColor(hex: variant.previewBackground) ?? .white
        self.previewText = UIColor(hex: variant.previewText) ?? .black
        self.previewBorder = UIColor(hex: variant.previewBorder) ?? .gray
        self.previewBorderWidth = variant.previewBorderWidth
        self.previewCornerRadius = variant.previewCornerRadius
        self.previewShadow = ShadowStyle(
            color: UIColor(hex: variant.previewShadowColor) ?? .black,
            offset: CGSize(width: variant.previewShadowOffset[0], height: variant.previewShadowOffset[1]),
            blur: variant.previewShadowBlur
        )
        
        // Long-press popup
        self.popupBackground = UIColor(hex: variant.popupBackground) ?? .white
        self.popupBorder = UIColor(hex: variant.popupBorder) ?? .gray
        self.popupBorderWidth = variant.popupBorderWidth
        self.popupCornerRadius = variant.popupCornerRadius
        self.popupShadow = ShadowStyle(
            color: UIColor(hex: variant.popupShadowColor) ?? .black,
            offset: CGSize(width: variant.popupShadowOffset[0], height: variant.popupShadowOffset[1]),
            blur: variant.popupShadowBlur
        )
        self.popupKeyText = UIColor(hex: variant.popupKeyText) ?? .black
        self.popupKeyBackground = UIColor(hex: variant.popupKeyBackground) ?? .white
        self.popupKeySelectedBackground = UIColor(hex: variant.popupKeySelectedBackground) ?? .systemBlue
        self.popupKeySelectedText = UIColor(hex: variant.popupKeySelectedText) ?? .white
        self.popupKeyCornerRadius = variant.popupKeyCornerRadius
        
        // Candidate bar
        self.candidateBarBackground = UIColor(hex: variant.candidateBarBackground) ?? .systemGray6
        self.candidateBarBorder = UIColor(hex: variant.candidateBarBorder) ?? .gray
        self.candidateBarBorderWidth = variant.candidateBarBorderWidth
        self.candidateBarCornerRadius = variant.candidateBarCornerRadius
        self.candidateText = UIColor(hex: variant.candidateText) ?? .black
        self.candidateAnnotationText = UIColor(hex: variant.candidateAnnotationText) ?? .gray
        self.candidateSelectedBackground = UIColor(hex: variant.candidateSelectedBackground) ?? .systemBlue
        self.candidateSelectedText = UIColor(hex: variant.candidateSelectedText) ?? .white
        self.candidateSelectedBorder = UIColor(hex: variant.candidateSelectedBorder) ?? .blue
        self.candidateSelectedBorderWidth = variant.candidateSelectedBorderWidth
        self.candidateCornerRadius = variant.candidateCornerRadius ?? 8.0
        self.candidateSeparator = UIColor(hex: variant.candidateSeparator) ?? .separator
        
        // Typography - use custom font if specified, otherwise system
        // Try multiple approaches for loading custom fonts (especially downloadable ones)
        let customFont = Self.loadCustomFont(name: variant.customFontName, size: variant.keyFontSize)
        let customModifierFont = Self.loadCustomFont(name: variant.customFontName, size: variant.modifierKeyFontSize)
        let customPreviewFont = Self.loadCustomFont(name: variant.customFontName, size: variant.previewFontSize)
        let customPopupFont = Self.loadCustomFont(name: variant.customFontName, size: variant.popupKeyFontSize)
        let customCandidateFont = Self.loadCustomFont(name: variant.customFontName, size: variant.candidateFontSize)
        let customAnnotationFont = Self.loadCustomFont(name: variant.customFontName, size: variant.candidateAnnotationFontSize)
        
        // Debug: Print font loading status
        if let customFontName = variant.customFontName {
            if customFont != nil {
                print("✅ Successfully loaded custom font: \(customFontName)")
            } else {
                print("⚠️ Failed to load custom font: \(customFontName) - falling back to system font")
            }
        }
        
        self.keyFont = customFont ?? UIFont.systemFont(
            ofSize: variant.keyFontSize,
            weight: UIFont.Weight.from(string: variant.keyFontWeight)
        )
        self.modifierKeyFont = customModifierFont ?? UIFont.systemFont(
            ofSize: variant.modifierKeyFontSize,
            weight: UIFont.Weight.from(string: variant.modifierKeyFontWeight)
        )
        self.previewFont = customPreviewFont ?? UIFont.systemFont(
            ofSize: variant.previewFontSize,
            weight: UIFont.Weight.from(string: variant.previewFontWeight)
        )
        self.popupKeyFont = customPopupFont ?? UIFont.systemFont(
            ofSize: variant.popupKeyFontSize,
            weight: UIFont.Weight.from(string: variant.popupKeyFontWeight)
        )
        self.candidateFont = customCandidateFont ?? UIFont.systemFont(
            ofSize: variant.candidateFontSize,
            weight: UIFont.Weight.from(string: variant.candidateFontWeight)
        )
        self.candidateAnnotationFont = UIFont(name: "Tamil Sangam MN", size: variant.candidateAnnotationFontSize) ?? 
                                        customAnnotationFont ?? 
                                        UIFont.systemFont(
                                            ofSize: variant.candidateAnnotationFontSize,
                                            weight: UIFont.Weight.from(string: variant.candidateFontWeight)
                                        )
        
        // Spacing
        self.keySpacing = variant.keySpacing
        self.rowSpacing = variant.rowSpacing
    }
    
    // MARK: - Helper Methods
    
    /// Shared font manager instance for registration tracking
    private static let fontManager = FontPackManager.shared
    
    /// Check if a font is available in the system
    private static func isFontAvailable(_ fontName: String) -> Bool {
        return UIFont(name: fontName, size: 12) != nil
    }
    
    /// Maps common font display names to their actual PostScript names
    private static let fontNameMapping: [String: String] = [
        "Tamil Sangam MN": "TamilSangamMN",
        "Anjal Annai MN": "AnjalAnnaiMN-Regular",
        "Noto Sans Tamil": "NotoSansTamil-Regular",
        "Mukti": "Mukti-Regular"
        // Add more mappings as needed for fonts in your pack
    ]
    
    /// Enhanced font loading with font pack extraction support
    private static func loadCustomFont(name: String?, size: CGFloat) -> UIFont? {
        guard let fontName = name else { return nil }
        
        // 1. Try direct loading first (fastest path - font may already be registered)
        if let font = UIFont(name: fontName, size: size) {
            return font
        }
        
        // 2. Check mapped font names (e.g., "Tamil Sangam MN" -> "TamilSangamMN")
        let actualFontName = fontNameMapping[fontName] ?? fontName
        if let font = UIFont(name: actualFontName, size: size) {
            return font
        }
        
        // 3. Check if this font might be in our font pack and extract if needed
        if fontManager.shouldExtractFontPack(for: fontName) {
            print("🔄 Font '\(fontName)' not available, attempting extraction from font pack...")
            
            if fontManager.extractAndRegisterFonts() {
                print("✅ Font pack extracted successfully")
                
                // Try loading again after extraction
                if let font = UIFont(name: fontName, size: size) {
                    return font
                }
                if let font = UIFont(name: actualFontName, size: size) {
                    return font
                }
                
                // Try to find the font among the extracted fonts
                if let extractedFont = fontManager.findExtractedFont(displayName: fontName, size: size) {
                    return extractedFont
                }
            }
        }
        
        // 4. Try with font descriptor (better for downloadable fonts)
        let descriptor = UIFontDescriptor(name: fontName, size: size)
        let font = UIFont(descriptor: descriptor, size: size)
        
        // Verify this isn't just the fallback system font
        if font.fontName.lowercased() != "helvetica" && 
           font.fontName.lowercased() != "helveticaneue" &&
           font.fontName.lowercased() != ".appfont" {
            return font
        }
        
        // 5. Try common variations
        let variations = [
            fontName.replacingOccurrences(of: " ", with: ""),
            fontName.replacingOccurrences(of: " ", with: "-"),
            "\(fontName)-Regular",
            fontName.replacingOccurrences(of: " ", with: "") + "Regular"
        ]
        
        for variation in variations {
            if let font = UIFont(name: variation, size: size) {
                print("🔄 Loaded font using variation: \(variation)")
                return font
            }
        }
        
        print("⚠️ Could not load font '\(fontName)' - using system font fallback")
        return nil
    }
}

// MARK: - Supporting Types
public struct ShadowStyle {
    public let color: UIColor
    public let offset: CGSize
    public let blur: CGFloat
    
    public init(color: UIColor, offset: CGSize, blur: CGFloat) {
        self.color = color
        self.offset = offset
        self.blur = blur
    }
}

public enum GradientDirection: String {
    case vertical
    case horizontal
    case diagonalTopLeftToBottomRight
    case diagonalTopRightToBottomLeft
}

// MARK: - Extensions
extension UIColor {
    convenience init?(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }
        
        let length = hexString.count
        let r, g, b, a: CGFloat
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIFont.Weight {
    static func from(string: String) -> UIFont.Weight {
        switch string.lowercased() {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
}

// MARK: - Font Pack Manager

/// Manages extraction and registration of fonts from the SellinamAssets.fpk2 font pack
class FontPackManager {
    static let shared = FontPackManager()
    
    private let fontExtractor = FontExtractor()
    private var extractedPackInfo: PackInfo?
    private var extractionAttempted = false
    private let fontPackName = "SellinamAssets.fpk2"
    
    /// Fonts that should trigger font pack extraction
    private let fontPackFonts: Set<String> = [
        "Anjal Annai MN Regular",
        "Anjal Chittu New Light",
        "Anjal Malar New Light",
        "Anjal Sudar New Light"
        // Add other font names that are in your pack
    ]
    
    private init() {}
    
    /// Check if we should attempt to extract the font pack for this font
    func shouldExtractFontPack(for fontName: String) -> Bool {
        // Don't extract if we already attempted
        guard !extractionAttempted else { return false }
        
        // Check if this font is one that should be in our pack
        return fontPackFonts.contains(fontName) || 
               fontPackFonts.contains { packFont in
                   fontName.localizedCaseInsensitiveContains(packFont) ||
                   packFont.localizedCaseInsensitiveContains(fontName)
               }
    }
    
    /// Extract and register all fonts from the font pack
    @discardableResult
    func extractAndRegisterFonts() -> Bool {
        // Prevent multiple extraction attempts
        guard !extractionAttempted else {
            print("⚠️ Font pack extraction already attempted")
            return extractedPackInfo != nil
        }
        
        extractionAttempted = true
        
        // Get paths
        guard let fpkPath = Bundle.main.path(forResource: "SellinamAssets", ofType: "fpk2") else {
            print("❌ Font pack '\(fontPackName)' not found in bundle")
            print("🔍 Bundle path: \(Bundle.main.bundlePath)")
            return false
        }
        
        // Create temporary directory for extracted fonts
        let tempDir = FileManager.default.temporaryDirectory
        let extractionDir = tempDir.appendingPathComponent("ExtractedFonts_\(ProcessInfo.processInfo.processIdentifier)")
        
        do {
            try FileManager.default.createDirectory(at: extractionDir, withIntermediateDirectories: true)
            print("📁 Created extraction directory: \(extractionDir.path)")
        } catch {
            print("❌ Could not create extraction directory: \(error)")
            return false
        }
        
        // Extract the font pack
        guard let packInfo = fontExtractor.extractFontPack(
            fpkPath: fpkPath, 
            outputPath: extractionDir.path
        ) else {
            print("❌ Failed to extract font pack")
            cleanup(directory: extractionDir)
            return false
        }
        
        print("✅ Font pack '\(packInfo.packName)' extracted with \(packInfo.fonts.count) fonts")
        
        // Register each extracted font
        var successCount = 0
        for fontInfo in packInfo.fonts {
            let fontPath = URL(fileURLWithPath: fontInfo.extractedPath)
                .appendingPathComponent(fontInfo.encryptedName)
            
            if registerFont(at: fontPath, originalName: fontInfo.fontName) {
                successCount += 1
            }
        }
        
        print("✅ Successfully registered \(successCount)/\(packInfo.fonts.count) fonts")
        
        // Clean up extracted files (fonts are now registered in memory)
        //cleanup(directory: extractionDir)
        
        self.extractedPackInfo = packInfo
        return successCount > 0
    }
    
    /// Register a font file with the system
    private func registerFont(at url: URL, originalName: String) -> Bool {
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        
        if success {
            // Verify the font is actually accessible
            if let _ = getActualFontName(from: url) {
                print("✅ Registered font: \(originalName)")
                return true
            } else {
                print("⚠️ Font registered but not accessible: \(originalName)")
                return false
            }
        } else {
            if let cfError = error?.takeRetainedValue() {
                print("❌ Failed to register font '\(originalName)': \(cfError)")
            } else {
                print("❌ Failed to register font '\(originalName)': Unknown error")
            }
            return false
        }
    }
    
    /// Get the actual PostScript name from a font file
    private func getActualFontName(from url: URL) -> String? {
        guard let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let firstDescriptor = fontDescriptors.first else {
            return nil
        }
        
        return CTFontDescriptorCopyAttribute(firstDescriptor, kCTFontNameAttribute) as? String
    }
    
    /// Find an extracted font by display name
    func findExtractedFont(displayName: String, size: CGFloat) -> UIFont? {
        guard let packInfo = extractedPackInfo else { return nil }
        
        // Look for a font that matches the display name
        for fontInfo in packInfo.fonts {
            // Try exact match first
            if fontInfo.fontName == displayName {
                // The actual font name might be different from the display name
                // Try several variations
                let variations = [
                    fontInfo.fontName,
                    fontInfo.fontName.replacingOccurrences(of: " ", with: ""),
                    fontInfo.fontName.replacingOccurrences(of: " ", with: "-"),
                    "\(fontInfo.fontName)-Regular"
                ]
                
                for variation in variations {
                    if let font = UIFont(name: variation, size: size) {
                        print("✅ Found extracted font '\(displayName)' as '\(variation)'")
                        return font
                    }
                }
            }
        }
        
        // Try partial matching
        for fontInfo in packInfo.fonts {
            if displayName.localizedCaseInsensitiveContains(fontInfo.fontName) ||
               fontInfo.fontName.localizedCaseInsensitiveContains(displayName) {
                
                let variations = [
                    fontInfo.fontName,
                    fontInfo.fontName.replacingOccurrences(of: " ", with: ""),
                    fontInfo.fontName.replacingOccurrences(of: " ", with: "-"),
                    "\(fontInfo.fontName)-Regular"
                ]
                
                for variation in variations {
                    if let font = UIFont(name: variation, size: size) {
                        print("✅ Found similar extracted font for '\(displayName)': '\(variation)'")
                        return font
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Clean up temporary extraction directory
    private func cleanup(directory: URL) {
        do {
            try FileManager.default.removeItem(at: directory)
            print("🗑️ Cleaned up extraction directory")
        } catch {
            print("⚠️ Could not clean up extraction directory: \(error)")
        }
    }
    
    /// Get information about the extracted font pack (for debugging)
    func getPackInfo() -> PackInfo? {
        return extractedPackInfo
    }
    
    /// Reset the manager (useful for testing)
    func reset() {
        extractionAttempted = false
        extractedPackInfo = nil
    }
}

// MARK: - Font Management Extensions

extension KeyboardTheme {
    /// Preload fonts for better performance
    static func preloadFonts(for themes: [ThemeConfiguration]) {
        let uniqueFontNames = Set(themes.flatMap { theme in
            [theme.light.customFontName, theme.dark.customFontName].compactMap { $0 }
        })
        
        print("🔄 Preloading \(uniqueFontNames.count) unique fonts...")
        
        for fontName in uniqueFontNames {
            // This will trigger extraction if needed
            _ = loadCustomFont(name: fontName, size: 16)
        }
        
        print("✅ Font preloading completed")
    }
    
    /// Check if a specific font is available
    static func isFontLoaded(_ fontName: String) -> Bool {
        return loadCustomFont(name: fontName, size: 16) != nil
    }
    
    /// Get debug information about font availability
    static func getFontDebugInfo() -> [String: Any] {
        let packInfo = FontPackManager.shared.getPackInfo()
        let systemFonts = UIFont.familyNames.sorted()
        
        return [
            "extractedPack": packInfo?.packName ?? "None",
            "extractedFonts": packInfo?.fonts.map { $0.fontName } ?? [],
            "systemFontFamilies": systemFonts.prefix(10), // First 10 to avoid too much output
            "totalSystemFontFamilies": systemFonts.count
        ]
    }
}
