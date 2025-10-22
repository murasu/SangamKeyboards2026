import Foundation
import CAnjalKeyTranslator

/// Swift wrapper for the multilingual key translator
public class MultilingualKeyTranslator {
    private let translator: MultilingualTranslatorRef
    
    /// Supported languages for input translation
    public enum Language: Int32, CaseIterable {
        case tamil = 0
        case devanagari = 1      // Hindi, Sanskrit, Marathi, Nepali
        case malayalam = 2
        case kannada = 3
        case telugu = 4
        case gurmukhi = 5        // Punjabi
        case diacritics = 6      // Linguistic transcription
        
        /// Human-readable name for the language
        public var name: String {
            String(cString: multilingual_get_language_name(SupportedLanguage(rawValue)))
        }
    }
    
    /// Available keyboard layouts (primarily for Tamil)
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
        
        /// Human-readable name for the layout
        public var name: String {
            String(cString: multilingual_get_layout_name(CAnjalKeyTranslator.KeyboardLayout(rawValue)))
        }
    }
    
    /// Translation result containing the output text and number of deletions needed
    public struct TranslationResult {
        public let text: String
        public let deletions: Int
        
        public init(text: String, deletions: Int = 0) {
            self.text = text
            self.deletions = deletions
        }
    }
    
    /// Initialize translator with language and keyboard layout
    public init(language: Language, layout: KeyboardLayout = .anjal) throws {
        guard let translator = multilingual_translator_create(
            SupportedLanguage(language.rawValue),
            CAnjalKeyTranslator.KeyboardLayout(layout.rawValue)
        ) else {
            throw TranslatorError.failedToCreateTranslator
        }
        self.translator = translator
    }
    
    deinit {
        multilingual_translator_destroy(translator)
    }
    
    /// Translate a key code to the target language
    public func translateKey(keyCode: Int32, shifted: Bool = false) -> TranslationResult {
        let bufferSize = 32
        var buffer = [wchar_t](repeating: 0, count: bufferSize)
        
        let result = multilingual_translator_translate_key(
            translator,
            keyCode,
            shifted,
            &buffer,
            Int32(bufferSize)
        )
        
        guard result > 0 else {
            return TranslationResult(text: "")
        }
        
        // Convert wchar_t array to String
        let output = String(decodingCString: buffer, as: UTF32.self)
        
        // Check for deletion code
        if let firstChar = output.unicodeScalars.first,
           firstChar.value == 0x2421 { // DELCODE
            let deletionCount = output.unicodeScalars.dropFirst().first?.value ?? 0
            let remainingText = String(output.unicodeScalars.dropFirst(2))
            return TranslationResult(text: remainingText, deletions: Int(deletionCount))
        }
        
        return TranslationResult(text: output)
    }
    
    /// Switch to a different language
    public func setLanguage(_ language: Language) -> Bool {
        return multilingual_translator_set_language(translator, SupportedLanguage(language.rawValue))
    }
    
    /// Set keyboard layout
    public func setLayout(_ layout: KeyboardLayout) -> Bool {
        return multilingual_translator_set_layout(translator, CAnjalKeyTranslator.KeyboardLayout(layout.rawValue))
    }
    
    /// Get current language
    public var currentLanguage: Language {
        let lang = multilingual_translator_get_language(translator)
        return Language(rawValue: lang.rawValue) ?? .tamil
    }
    
    /// Get supported layouts for current language
    public func getSupportedLayouts() -> [KeyboardLayout] {
        let maxLayouts = 16
        var buffer = [CAnjalKeyTranslator.KeyboardLayout](repeating: CAnjalKeyTranslator.KeyboardLayout(0), count: maxLayouts)
        
        let count = multilingual_translator_get_supported_layouts(translator, &buffer, Int32(maxLayouts))
        
        return Array(buffer.prefix(Int(count))).compactMap { layout in
            KeyboardLayout(rawValue: layout.rawValue)
        }
    }
    
    /// Terminate current composition
    public func terminateComposition() {
        multilingual_translator_terminate_composition(translator)
    }
    
    /// Check if a layout is supported for a language
    public static func isLayoutSupported(for language: Language, layout: KeyboardLayout) -> Bool {
        return multilingual_is_layout_supported_for_language(
            SupportedLanguage(language.rawValue),
            CAnjalKeyTranslator.KeyboardLayout(layout.rawValue)
        )
    }
}

/// Errors that can occur during translation
public enum TranslatorError: Error, LocalizedError {
    case failedToCreateTranslator
    case invalidKeyCode
    case bufferTooSmall
    
    public var errorDescription: String? {
        switch self {
        case .failedToCreateTranslator:
            return "Failed to create multilingual translator"
        case .invalidKeyCode:
            return "Invalid key code provided"
        case .bufferTooSmall:
            return "Output buffer too small for translation"
        }
    }
}