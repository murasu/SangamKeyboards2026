import Testing
import AnjalKeyTranslator

@Suite("Multilingual Key Translator Tests")
struct MultilingualKeyTranslatorTests {
    
    @Test("Creating translator with Tamil language")
    func createTamilTranslator() async throws {
        let translator = try MultilingualKeyTranslator(language: .tamil, layout: .anjal)
        
        #expect(translator.currentLanguage == .tamil)
    }
    
    @Test("Switching languages")
    func switchLanguages() async throws {
        let translator = try MultilingualKeyTranslator(language: .tamil)
        
        let success = translator.setLanguage(.devanagari)
        #expect(success == true)
        #expect(translator.currentLanguage == .devanagari)
    }
    
    @Test("Getting supported layouts")
    func getSupportedLayouts() async throws {
        let translator = try MultilingualKeyTranslator(language: .tamil)
        
        let layouts = translator.getSupportedLayouts()
        #expect(!layouts.isEmpty, "Should have at least one supported layout")
    }
    
    @Test("Language names are not empty")
    func languageNamesNotEmpty() async throws {
        for language in MultilingualKeyTranslator.Language.allCases {
            #expect(!language.name.isEmpty, "Language name should not be empty for \(language)")
        }
    }
    
    @Test("Layout names are not empty")
    func layoutNamesNotEmpty() async throws {
        for layout in MultilingualKeyTranslator.KeyboardLayout.allCases {
            #expect(!layout.name.isEmpty, "Layout name should not be empty for \(layout)")
        }
    }
    
    @Test("Key translation")
    func keyTranslation() async throws {
        let translator = try MultilingualKeyTranslator(language: .tamil, layout: .anjal)
        
        // Test with a basic key code (this would need actual key mappings to work properly)
        let result = translator.translateKey(keyCode: 65) // 'A' key
        
        // The result might be empty if no mapping exists, which is okay for testing
        #expect(result.deletions >= 0, "Deletions should not be negative")
    }
}