import Foundation
import CAnjalKeyTranslator

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public class SwiftKeyTranslator {
    
    public enum SupportedLanguage: Int32, CaseIterable {
        case tamil = 101
        case devanagari = 100    
        case malayalam = 102
        case kannada = 105
        case telugu = 104
        case gurmukhi = 103
        
        public var displayName: String {
            switch self {
            case .tamil: return "Tamil"
            case .devanagari: return "Devanagari (Hindi/Sanskrit)"
            case .malayalam: return "Malayalam"
            case .kannada: return "Kannada"
            case .telugu: return "Telugu"
            case .gurmukhi: return "Gurmukhi (Punjabi)"
            }
        }
    }
    
    public enum KeyboardLayout: Int32, CaseIterable {
        case anjal = 0
        case tamil99 = 1
        case tamil97 = 2
        case mylai = 3
        case typewriterNew = 4
        case typewriterOld = 5
        case anjalIndic = 6
        case murasu6 = 7
        case bamini = 8
        case tnTypewriter = 9
    }
    
    private let translatorRef: MultilingualTranslatorRef
    private var currentLanguage: SupportedLanguage
    private var currentLayout: KeyboardLayout
    
    public init(language: SupportedLanguage, layout: KeyboardLayout = .anjal) {
        self.currentLanguage = language
        self.currentLayout = layout
        
        // Create the C translator instance
        self.translatorRef = multilingual_translator_create(language.rawValue, layout.rawValue)
    }
    
    deinit {
        multilingual_translator_destroy(translatorRef)
    }
    
    public func translateKey(keyCode: Int32, shifted: Bool = false) -> String {
        let buffer = UnsafeMutablePointer<wchar_t>.allocate(capacity: 20)
        defer { buffer.deallocate() }
        
        let length = multilingual_translator_translate_key(
            translatorRef,
            keyCode,
            shifted,
            buffer,
            20
        )
        
        guard length > 0 else { return "" }
        
        return convertWCharArrayToString(buffer: buffer, length: Int(length))
    }
    
    public func switchLanguage(to language: SupportedLanguage) -> Bool {
        let success = multilingual_translator_set_language(translatorRef, language.rawValue)
        if success {
            currentLanguage = language
        }
        return success
    }
    
    public func setLayout(_ layout: KeyboardLayout) -> Bool {
        let success = multilingual_translator_set_layout(translatorRef, layout.rawValue)
        if success {
            currentLayout = layout
        }
        return success
    }
    
    public func terminateComposition() {
        multilingual_translator_terminate_composition(translatorRef)
    }
    
    public func getCurrentLanguage() -> SupportedLanguage {
        return currentLanguage
    }
    
    public func getCurrentLayout() -> KeyboardLayout {
        return currentLayout
    }
    
    // MARK: - Helper Methods
    
    private func convertWCharArrayToString(buffer: UnsafeMutablePointer<wchar_t>, length: Int) -> String {
        var result = ""
        for i in 0..<length {
            if buffer[i] == 0 { break }
            
            let unicodeValue = UInt32(buffer[i])
            if let unicodeScalar = UnicodeScalar(unicodeValue) {
                result.append(Character(unicodeScalar))
            }
        }
        return result
    }
    
    // Static helper for language detection
    public static func detectLanguage(from text: String) -> SupportedLanguage? {
        for char in text.unicodeScalars {
            let value = char.value
            
            // Tamil: 0x0B80-0x0BFF
            if value >= 0x0B80 && value <= 0x0BFF {
                return .tamil
            }
            // Devanagari: 0x0900-0x097F  
            else if value >= 0x0900 && value <= 0x097F {
                return .devanagari
            }
            // Malayalam: 0x0D00-0x0D7F
            else if value >= 0x0D00 && value <= 0x0D7F {
                return .malayalam
            }
            // Kannada: 0x0C80-0x0CFF
            else if value >= 0x0C80 && value <= 0x0CFF {
                return .kannada
            }
            // Telugu: 0x0C00-0x0C7F
            else if value >= 0x0C00 && value <= 0x0C7F {
                return .telugu
            }
            // Gurmukhi: 0x0A00-0x0A7F
            else if value >= 0x0A00 && value <= 0x0A7F {
                return .gurmukhi
            }
        }
        return nil
    }
}
