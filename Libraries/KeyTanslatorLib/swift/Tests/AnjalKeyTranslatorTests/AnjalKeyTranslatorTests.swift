import XCTest
@testable import AnjalKeyTranslator

final class AnjalKeyTranslatorTests: XCTestCase {
    func testBasicTranslation() throws {
        // Basic test to ensure the library loads
        let translator = SwiftKeyTranslator(language: .tamil, layout: .anjal)
        XCTAssertNotNil(translator)
    }
    
    func testLanguageDetection() throws {
        let tamilText = "வணக்கம்"
        let detectedLanguage = SwiftKeyTranslator.detectLanguage(from: tamilText)
        XCTAssertEqual(detectedLanguage, .tamil)
    }
}
