//
//  TextEditorCore.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import Foundation
import SwiftUI
import Combine
import SangamKeyTranslator
import CAnjalKeyTranslator

#if canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#endif

/// Core text editor logic shared across platforms
@MainActor
public class TextEditorCore: ObservableObject {
    @Published var textStorage = NSTextStorage()
    @Published var currentPredictions: [String] = []
    @Published var showingPrediction = false
    @Published var predictionRange: NSRange?
    
    // Composition system properties
    @Published var isComposing = false
    private var compositionBuffer = ""
    private var compositionRange: NSRange?
    private var compositionStartIndex: String.Index?  // Track using String.Index
    private var sangamTranslator: SangamKeyTranslator?
    
    // User properties
    private var showCandidateWindow: Bool = true
    private var maxCandidates: Int {
        return UserDefaults.standard.object(forKey: "MaxCandidates") as? Int ?? 3
    }
    
    // Font configuration
    private var defaultFont: PlatformFont {
        let fontName = UserDefaults.standard.string(forKey: "TextEditorFontName") ?? "Tamil Sangam MN"
        let fontSize = UserDefaults.standard.object(forKey: "TextEditorFontSize") as? CGFloat ?? 24.0
        
        if let customFont = PlatformFont(name: fontName, size: fontSize) {
            return customFont
        } else {
            // Fallback to system monospaced font if Tamil Sangam MN is not available
            print("⚠️ Font '\(fontName)' not available, falling back to system monospaced font")
            return PlatformFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    public let textProcessor = TextProcessor()
    public let predictionEngine = PredictionEngine()
    
    var onTextChange: ((String) -> Void)?
    var onKeyTranslation: ((String, NSRange?) -> Void)?
    var onCompositionChange: ((String, Bool) -> Void)? // compositionText, isActive
    var onBackspacePassThrough: (() -> Void)? // Called when backspace should be handled by text view
    
    public init() {
        // Register default font preferences
        registerDefaultFontPreferences()
        
        setupTextStorage()
        setupSangamTranslator()
        
        // TODO: Read candidate window preference from UserDefaults
        //showCandidateWindow = UserDefaults.standard.object(forKey: "showCandidateWindow") as? Bool ?? true
        showCandidateWindow = maxCandidates > 0
    }
    
    private func registerDefaultFontPreferences() {
        let defaults: [String: Any] = [
            "TextEditorFontName": "Tamil Sangam MN",
            "TextEditorFontSize": 24.0,
            "MaxCandidates": 3
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    private func setupSangamTranslator() {
        // Use the singleton instead of creating new instances
        sangamTranslator = SangamKeyTranslator.shared
        if sangamTranslator?.getLayout() == kbdNone {
            sangamTranslator?.setLayout(kbdAnjal)
        }
    }
    
    private func setupTextStorage() {
        // Set up default attributes for the text
        #if canImport(AppKit)
        let textColor = NSColor.labelColor
        #elseif canImport(UIKit)
        let textColor = UIColor.label
        #endif
        
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: "", attributes: defaultAttributes)
        textStorage.setAttributedString(attributedString)
    }
    
    /// Process a typed character through the composition system
    public func processKeyInput(_ character: String, keyCode: Int32, isShifted: Bool, at range: NSRange) {
        // Handle cursor movement - commit any active composition
        //if range.location != (compositionRange?.location ?? range.location) {
        //    commitComposition()
        //}
        
        if isTranslatableKey(character, keyCode: keyCode) {
            handleTranslatableKey(character, keyCode: keyCode, isShifted: isShifted, at: range)
        } else {
            commitComposition()
            insertRegularText(character, at: range)
            updateCompositionDisplay(character)
        }
    }
    
    /// Process a typed character through the translation system (legacy method)
    public func processTypedCharacter(_ character: String, at range: NSRange) {
        // Convert to new composition system
        let keyCode = Int32(character.first?.asciiValue ?? 0)
        processKeyInput(character, keyCode: keyCode, isShifted: false, at: range)
    }
    
    // MARK: - Key Classification
    
    private func isTranslatableKey(_ character: String, keyCode: Int32) -> Bool {
        // For now, let's consider letters and some punctuation as translatable
        // You can refine this based on your Tamil input requirements
        
        // Special keys by keyCode (backspace, etc.)
        if keyCode == 51 { return true } // Backspace
        
        
        if character.isEmpty { return false }
        
        let char = character.first!
        
        // Letters are translatable
        if char.isLetter { return true }
        
        // Some punctuation that might be part of Tamil transliteration
        let translatablePunctuation: Set<Character> = [".", ",", ";", ":", "'", "\""]
        if translatablePunctuation.contains(char) { return true }
        
        // Numbers might be translatable in some contexts
        if char.isNumber { return true }
        
        return false
    }
    
    // MARK: - Composition Handling
    
    private func handleTranslatableKey(_ character: String, keyCode: Int32, isShifted: Bool, at range: NSRange) {
        if !isComposing {
            startComposition(at: range)
        }
        
        // Handle backspace specially
        if keyCode == 51 { // Backspace
            // If not composing or composition buffer is empty, pass to text view
            if !isComposing || compositionBuffer.isEmpty {
                onBackspacePassThrough?()
            } else {
                // Handle backspace within composition
                handleBackspaceInComposition()
            }
            return
        }
        
        let charKey = character.unicodeScalars.first?.value ?? 0
        
        // Translate the current composition
        translateCurrentComposition(keyCode: Int32(charKey), isShifted: isShifted)
    }
    
    private func startComposition(at range: NSRange) {
        isComposing = true
        compositionRange = range
        compositionBuffer = ""
        onCompositionChange?("", true)
    }
    
    private func translateCurrentComposition(keyCode: Int32, isShifted: Bool) {
        guard let translator = sangamTranslator else {
            // Fallback: just display the buffer as-is
            updateCompositionDisplay(compositionBuffer)
            return
        }
        
        let translatedResult = translator.translateComposition(
            in: compositionBuffer,
            newKeyCode: keyCode,
            shifted: isShifted
        )
        
        let updatedComposition = appendComposition(translated: translatedResult)
        updateCompositionDisplay(updatedComposition)
        compositionBuffer = updatedComposition
        
        let parsedResult = parseSangamResult(translatedResult)
        //updateCompositionDisplay(parsedResult.translatedText)
        
        // Generate candidates for the translated text only if user preference allows
        if showCandidateWindow {
            generateCandidates(for: parsedResult.translatedText)
        }
    }
    
    func appendComposition(translated: String) -> String {
        var deleteNext = false
        // We use a temporary variable so typedString is updated in one go
        // This will prevent candidates from loadig for every char appended
        var newComposition = compositionBuffer
        
        for c in translated.unicodeScalars {
            //            Log("Append String: checking \(c)")
            if c.value == DELCODE { //} Character(UnicodeScalar(127) ?? UnicodeScalar(0)) {
                //                Log("Append String: character is DEL")
                deleteNext = true
            }
            else if Character(c).isNumber && deleteNext {
                //                Log("Append String: character is number and deleteNext is TRUE")
                let deleteCount = Character(c).wholeNumberValue
                //Log("TYPED STRING set at appendComposition 1")
                newComposition = String(newComposition.unicodeScalars.dropLast(deleteCount!))
            }
            else {
                //                Log("Append String: appending c to string")
                //Log("TYPED STRING appended at appendComposition 2")
                newComposition.append(Character(c))
            }
            //Log("Append String: typedString is now \(typedString)")
        }
        
        //compositionBuffer = typedStringTemp
        return newComposition
    }
    
    private func handleBackspaceInComposition() {
        var deletedComposition = compositionBuffer
        guard let translator = sangamTranslator else {
            // Simple backspace
            if !deletedComposition.isEmpty {
                deletedComposition.removeLast()
                updateCompositionDisplay(deletedComposition)
            } else {
                commitComposition()
            }
            
            compositionBuffer = deletedComposition
            return
        }
        
        // Use translator's delete functionality
        if !deletedComposition.isEmpty {
            deletedComposition = translator.deleteLastChar(in: deletedComposition)
        
            if compositionBuffer.isEmpty {
                commitComposition()
            } else {
                updateCompositionDisplay(deletedComposition)
                compositionBuffer = deletedComposition

                // Generate candidates only if user preference allows
                if showCandidateWindow {
                    generateCandidates(for: compositionBuffer)
                }
            }
        } else {
            commitComposition()
        }
    }
    
    private func updateCompositionDisplay(_ text: String) {
        guard let range = compositionRange else { 
            print("❌ updateCompositionDisplay: No composition range")
            return 
        }
        
        let currentStorageText = textStorage.string
        
        print("🔍 updateCompositionDisplay:")
        debugStringLengths(text, label: "Input text '\(text)'")
        debugStringLengths(currentStorageText, label: "Current storage '\(currentStorageText)'")
        print("  - Current range: \(range)")
        print("  - Text storage length (UTF-16): \(textStorage.length)")
        
        // Convert the composition range to use grapheme-accurate length
        let workingRange = getGraphemeAwareRange(nsRange: range, in: currentStorageText)
        
        print("  - Working range: \(workingRange)")
        
        // Validate range
        if workingRange.location + workingRange.length > textStorage.length {
            print("  - ⚠️ Working range is invalid!")
            return
        }
        
        // Get current text in the range for comparison
        let currentText = textStorage.attributedSubstring(from: workingRange).string
        debugStringLengths(currentText, label: "Current text in range '\(currentText)'")
        
        // Create attributed string with composition styling
        let attributes = getCompositionAttributes()
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Clear the old composition range completely first
        print("  - Clearing range \(workingRange)")
        textStorage.deleteCharacters(in: workingRange)
        
        // Then insert the new text at the location
        print("  - Inserting '\(text)' at location \(range.location)")
        textStorage.insert(attributedText, at: range.location)
        
        // Force text storage to process the change
        textStorage.processEditing()
        
        // Update the composition range based on UTF-16 length of new text
        let newLength = utf16Length(of: text) // Use UTF-16 length for NSRange
        let newRange = NSRange(location: range.location, length: newLength)
        compositionRange = newRange
        
        print("  - New range: \(newRange)")
        print("  - Text storage after: '\(textStorage.string)'")
        
        // Verify the new range
        if newRange.location + newRange.length <= textStorage.length {
            let verifyText = textStorage.attributedSubstring(from: newRange).string
            debugStringLengths(verifyText, label: "Verified text in new range '\(verifyText)'")
        }
        
        onTextChange?(textStorage.string)
        onCompositionChange?(text, true)
    }
    
    // Helper function to count grapheme clusters properly
    private func graphemeCount(of string: String) -> Int {
        return string.count // This already gives us grapheme cluster count
    }
    
    // Helper function to get UTF-16 length (what NSRange uses)
    private func utf16Length(of string: String) -> Int {
        return string.utf16.count
    }
    
    // Helper function to get Unicode scalar count
    private func unicodeScalarCount(of string: String) -> Int {
        return string.unicodeScalars.count
    }
    
    // Debug helper to show all string length representations
    private func debugStringLengths(_ string: String, label: String) {
        print("  \(label):")
        print("    - Graphemes: \(string.count)")
        print("    - Unicode scalars: \(string.unicodeScalars.count)")
        print("    - UTF-16: \(string.utf16.count)")
        print("    - UTF-8: \(string.utf8.count)")
    }
    
    // Helper function to create grapheme-aware range
    private func getGraphemeAwareRange(nsRange: NSRange, in string: String) -> NSRange {
        // For now, return the original range, but this could be enhanced
        // to properly handle grapheme cluster boundaries
        let maxLength = min(nsRange.length, string.utf16.count - nsRange.location)
        return NSRange(location: nsRange.location, length: max(0, maxLength))
    }
    
    private func commitComposition() {
        guard isComposing, let range = compositionRange else { return }
        
        // Remove composition styling and apply normal text attributes
        let normalAttributes = getNormalTextAttributes()
        //textStorage.addAttributes(normalAttributes, range: range)
        textStorage.setAttributes(normalAttributes, range: range)
        
        // Clear composition state
        isComposing = false
        compositionBuffer = ""
        compositionRange = nil
        
        // Hide predictions
        hidePredictions()
        
        onCompositionChange?("", false)
    }
    
    private func insertRegularText(_ character: String, at range: NSRange) {
        let attributes = getNormalTextAttributes()
        let attributedText = NSAttributedString(string: character, attributes: attributes)
        
        textStorage.insert(attributedText, at: range.location)
        onTextChange?(textStorage.string)
    }
    
    // MARK: - Styling
    
    private func getCompositionAttributes() -> [NSAttributedString.Key: Any] {
        #if canImport(AppKit)
        let textColor = NSColor.systemBlue
        let backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1)
        #elseif canImport(UIKit)
        let textColor = UIColor.systemBlue
        let backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        #endif
        
        return [
            .font: defaultFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor//,
            //.underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
    
    private func getNormalTextAttributes() -> [NSAttributedString.Key: Any] {
        #if canImport(AppKit)
        let textColor = NSColor.labelColor
        #elseif canImport(UIKit)
        let textColor = UIColor.label
        #endif
        
        return [
            .font: defaultFont,
            .foregroundColor: textColor
        ]
    }
    
    // MARK: - Candidate Generation
    
    private func generateCandidates(for text: String) {
        // For now, generate dummy Tamil candidates
        // You can replace this with actual candidate generation logic
        let dummyTamilCandidates = [
            "அன்பு", "இன்பம்", "உயிர்", "எழுத்து", "ஒலி", "கல்வி", "நட்பு"
        ].shuffled().prefix(maxCandidates)
        
        if !dummyTamilCandidates.isEmpty {
            currentPredictions = Array(dummyTamilCandidates)
            predictionRange = compositionRange
            showingPrediction = true
        } else {
            hidePredictions()
        }
    }
    
    // MARK: - Candidate Window Positioning
    
    /// Calculate the appropriate size for the candidate window based on content
    public func calculateCandidateWindowSize(for predictions: [String], maxWidth: CGFloat = 250) -> CGSize {
        guard !predictions.isEmpty else {
            return CGSize(width: 150, height: 30)
        }
        
        // Base dimensions
        let padding: CGFloat = 16 // 8px on each side (top/bottom + left/right)
        let lineHeight: CGFloat = 18 // Height per line of text
        
        // Calculate width based on longest prediction
        let longestPrediction = predictions.max { $0.count < $1.count } ?? ""
        let estimatedTextWidth = CGFloat(longestPrediction.count) * 8 + 20 // Rough estimate: 8pts per char + number prefix
        let width = min(maxWidth, max(120, estimatedTextWidth + padding))
        
        // Calculate height based on number of predictions (no header now)
        let contentHeight = CGFloat(predictions.count) * lineHeight
        let height = contentHeight + padding
        
        return CGSize(width: width, height: height)
    }
    
    /// Calculate the ideal position for the candidate window relative to the composition range
    /// 
    /// This method implements smart positioning logic that:
    /// 1. Positions the candidate window below the composition by default
    /// 2. Adjusts horizontally if the window would overflow the right edge
    /// 3. Positions above the composition if it would overflow the bottom edge
    /// 4. Ensures the window stays within the editor bounds
    ///
    /// - Parameters:
    ///   - editorBounds: The bounds of the text editor view
    ///   - compositionRect: The rectangle containing the composition text
    ///   - candidateWindowSize: The desired size of the candidate window
    /// - Returns: A tuple containing the calculated position and a boolean indicating if positioned above
    public func calculateCandidateWindowPosition(
        editorBounds: CGRect,
        compositionRect: CGRect,
        candidateWindowSize: CGSize
    ) -> (position: CGPoint, shouldShowAbove: Bool) {
        
        let margin: CGFloat = 4.0 // Small margin from the composition
        let minMarginFromEdge: CGFloat = 8.0 // Minimum margin from editor edges
        
        // Start with positioning below the composition
        var candidateX = compositionRect.minX
        var candidateY = compositionRect.maxY + margin
        var shouldShowAbove = false
        
        // Check if we'll overshoot the right edge
        let rightEdge = candidateX + candidateWindowSize.width
        if rightEdge > (editorBounds.maxX - minMarginFromEdge) {
            // Align to the right edge of the editor with margin
            candidateX = editorBounds.maxX - candidateWindowSize.width - minMarginFromEdge
            // Ensure we don't go past the left edge
            candidateX = max(candidateX, editorBounds.minX + minMarginFromEdge)
        }
        
        // Check if we'll overshoot the bottom
        let bottomEdge = candidateY + candidateWindowSize.height
        if bottomEdge > (editorBounds.maxY - minMarginFromEdge) {
            // Position above the composition instead
            candidateY = compositionRect.minY - candidateWindowSize.height - margin
            shouldShowAbove = true
            
            // Ensure we don't go past the top edge
            if candidateY < (editorBounds.minY + minMarginFromEdge) {
                candidateY = editorBounds.minY + minMarginFromEdge
                // If we still don't fit, we might need to position beside instead
                // For now, just clamp to the top
            }
        }
        
        // Final bounds check to ensure we're always within the editor
        candidateX = max(editorBounds.minX + minMarginFromEdge, 
                        min(candidateX, editorBounds.maxX - candidateWindowSize.width - minMarginFromEdge))
        candidateY = max(editorBounds.minY + minMarginFromEdge,
                        min(candidateY, editorBounds.maxY - candidateWindowSize.height - minMarginFromEdge))
        
        return (CGPoint(x: candidateX, y: candidateY), shouldShowAbove)
    }
    
    /// Get the composition rectangle in the text coordinate system
    public func getCompositionRect(
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        textContainerInset: CGSize = .zero
    ) -> CGRect? {
        guard let range = compositionRange else { return nil }
        
        // Ensure the range is valid
        guard range.location + range.length <= layoutManager.numberOfGlyphs else { return nil }
        
        // Get the glyph range for the composition
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        // Get the bounding rect for the composition
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Adjust for text container inset
        return CGRect(
            x: rect.origin.x + textContainerInset.width,
            y: rect.origin.y + textContainerInset.height,
            width: max(rect.width, 10), // Ensure minimum width for cursor position
            height: rect.height
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseSangamResult(_ result: String) -> (translatedText: String, deleteCount: Int) {
        // Parse the result format from SangamKeyTranslator
        if result.hasPrefix("\u{2421}") { // DELCODE
            let withoutDelCode = String(result.dropFirst())
            var deleteCount = 0
            var translatedText = ""
            
            // Extract the number for delete count
            var numberStr = ""
            for char in withoutDelCode {
                if char.isNumber {
                    numberStr += String(char)
                } else {
                    translatedText = String(withoutDelCode.dropFirst(numberStr.count))
                    break
                }
            }
            
            deleteCount = Int(numberStr) ?? 0
            return (translatedText, deleteCount)
        }
        
        return (result, 0)
    }
    
    /// Update word predictions based on current cursor position
    public func updatePredictions(at location: Int) {
        // Check user preference first - don't generate predictions if disabled
        guard showCandidateWindow else {
            hidePredictions()
            return
        }
        
        guard location > 0 else {
            hidePredictions()
            return
        }
        
        let currentWord = getCurrentWord(at: location)
        if currentWord.isEmpty {
            hidePredictions()
            return
        }
        
        // Get predictions for the current word
        let predictions = predictionEngine.getPrediction(forWord: currentWord, maxCount: maxCandidates)
        
        if !predictions.isEmpty {
            currentPredictions = predictions
            predictionRange = getCurrentWordRange(at: location)
            showingPrediction = true
        } else {
            hidePredictions()
        }
    }
    
    /// Accept the current prediction
    public func acceptPrediction(_ prediction: String) {
        if isComposing {
            // Replace composition with selected candidate
            guard let range = compositionRange else { return }
            
            let attributes = getNormalTextAttributes()
            let attributedText = NSAttributedString(string: prediction, attributes: attributes)
            
            textStorage.replaceCharacters(in: range, with: attributedText)
            
            // Commit the composition
            commitComposition()
            
            onTextChange?(textStorage.string)
        } else {
            // Legacy behavior for word predictions
            guard let range = predictionRange else { return }
            
            textStorage.replaceCharacters(in: range, with: prediction)
            hidePredictions()
            
            onTextChange?(textStorage.string)
        }
    }
    
    /// Hide predictions
    public func hidePredictions() {
        showingPrediction = false
        currentPredictions = []
        predictionRange = nil
    }
    
    /// Handle escape key - hide candidates but keep composition
    public func handleEscapeKey() {
        if showingPrediction {
            hidePredictions()
        }
    }
    
    /// Force commit current composition (useful for programmatic control)
    public func forceCommitComposition() {
        commitComposition()
    }
    
    /// Check if currently composing
    public var isCurrentlyComposing: Bool {
        return isComposing
    }
    
    /// Get current composition text
    public var currentComposition: String {
        return compositionBuffer
    }
    
    /// Get current composition range
    public var currentCompositionRange: NSRange? {
        return compositionRange
    }
    
    // MARK: - Font Configuration
    
    /// Update the font name preference
    public func setFontName(_ fontName: String) {
        UserDefaults.standard.set(fontName, forKey: "TextEditorFontName")
        refreshTextStorageFont()
    }
    
    /// Update the font size preference
    public func setFontSize(_ fontSize: CGFloat) {
        UserDefaults.standard.set(fontSize, forKey: "TextEditorFontSize")
        refreshTextStorageFont()
    }
    
    /// Get current font name
    public var currentFontName: String {
        return UserDefaults.standard.string(forKey: "TextEditorFontName") ?? "Tamil Sangam MN"
    }
    
    /// Get current font size
    public var currentFontSize: CGFloat {
        return UserDefaults.standard.object(forKey: "TextEditorFontSize") as? CGFloat ?? 24.0
    }
    
    /// Update the max candidates preference (3, 4, or 5)
    public func setMaxCandidates(_ count: Int) {
        let clampedCount = max(3, min(5, count)) // Ensure it's between 3 and 5
        UserDefaults.standard.set(clampedCount, forKey: "MaxCandidates")
    }
    
    /// Get current max candidates setting
    public var currentMaxCandidates: Int {
        return maxCandidates
    }
    
    /// Refresh the text storage font after preference changes
    private func refreshTextStorageFont() {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        if fullRange.length > 0 {
            let normalAttributes = getNormalTextAttributes()
            textStorage.addAttributes(normalAttributes, range: fullRange)
            textStorage.processEditing()
            onTextChange?(textStorage.string)
        }
    }
    
    // MARK: - Testing Helpers
    
    /// Test the candidate window positioning logic with various scenarios
    public func testCandidatePositioning() -> [(scenario: String, position: CGPoint, shouldShowAbove: Bool)] {
        var results: [(String, CGPoint, Bool)] = []
        
        // Test scenario 1: Normal positioning (below, fits within bounds)
        let editorBounds1 = CGRect(x: 0, y: 0, width: 400, height: 300)
        let compositionRect1 = CGRect(x: 50, y: 50, width: 20, height: 20)
        let candidateSize = CGSize(width: 150, height: 30)
        
        let result1 = calculateCandidateWindowPosition(
            editorBounds: editorBounds1,
            compositionRect: compositionRect1,
            candidateWindowSize: candidateSize
        )
        results.append(("Normal below", result1.position, result1.shouldShowAbove))
        
        // Test scenario 2: Right edge overflow
        let compositionRect2 = CGRect(x: 350, y: 50, width: 20, height: 20)
        let result2 = calculateCandidateWindowPosition(
            editorBounds: editorBounds1,
            compositionRect: compositionRect2,
            candidateWindowSize: candidateSize
        )
        results.append(("Right overflow", result2.position, result2.shouldShowAbove))
        
        // Test scenario 3: Bottom overflow (should show above)
        let compositionRect3 = CGRect(x: 50, y: 280, width: 20, height: 20)
        let result3 = calculateCandidateWindowPosition(
            editorBounds: editorBounds1,
            compositionRect: compositionRect3,
            candidateWindowSize: candidateSize
        )
        results.append(("Bottom overflow", result3.position, result3.shouldShowAbove))
        
        // Test scenario 4: Both right and bottom overflow
        let compositionRect4 = CGRect(x: 350, y: 280, width: 20, height: 20)
        let result4 = calculateCandidateWindowPosition(
            editorBounds: editorBounds1,
            compositionRect: compositionRect4,
            candidateWindowSize: candidateSize
        )
        results.append(("Both overflows", result4.position, result4.shouldShowAbove))
        
        // Test scenario 5: Near top edge (when showing above)
        let editorBounds5 = CGRect(x: 0, y: 0, width: 400, height: 300)
        let compositionRect5 = CGRect(x: 50, y: 10, width: 20, height: 20)
        let result5 = calculateCandidateWindowPosition(
            editorBounds: editorBounds5,
            compositionRect: compositionRect5,
            candidateWindowSize: candidateSize
        )
        results.append(("Near top", result5.position, result5.shouldShowAbove))
        
        return results
    }
    
    /// Print test results for debugging
    public func printPositioningTests() {
        let results = testCandidatePositioning()
        print("📍 Candidate Window Positioning Tests:")
        print("=====================================")
        
        for (scenario, position, showingAbove) in results {
            let direction = showingAbove ? "above" : "below"
            print("✓ \(scenario): x=\(Int(position.x)), y=\(Int(position.y)) (\(direction))")
        }
        print("=====================================")
        print("Expected Results:")
        print("• Normal below: Should be at (50, 74) below composition")
        print("• Right overflow: Should align right with margin from edge")
        print("• Bottom overflow: Should be above composition")
        print("• Both overflows: Should be above and right-aligned with margins")
        print("• Near top: Should maintain minimum margin from top")
        print("=====================================")
        
        // Additional validation
        let candidateSize = CGSize(width: 150, height: 30)
        let editorBounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        
        for (scenario, position, _) in results {
            let fitsHorizontally = position.x >= 8 && (position.x + candidateSize.width) <= (400 - 8)
            let fitsVertically = position.y >= 8 && (position.y + candidateSize.height) <= (300 - 8)
            let status = (fitsHorizontally && fitsVertically) ? "✅" : "⚠️"
            print("\(status) \(scenario): Bounds check \(fitsHorizontally ? "✓" : "✗")H \(fitsVertically ? "✓" : "✗")V")
        }
        print("=====================================")
    }
    
    /// Create a test composition at a specific location for testing
    public func simulateCompositionForTesting(at location: Int, text: String) {
        // Simulate a composition being active
        isComposing = true
        compositionBuffer = text
        compositionRange = NSRange(location: location, length: text.count)
        
        // Generate some test candidates
        generateCandidates(for: text)
        
        print("🧪 Test composition created: '\(text)' at location \(location)")
    }
    
    /// Get the current word being typed
    private func getCurrentWord(at location: Int) -> String {
        let text = textStorage.string
        guard location <= text.count else { return "" }
        
        let substring = String(text.prefix(location))
        let components = substring.components(separatedBy: .whitespacesAndNewlines)
        return components.last ?? ""
    }
    
    /// Get the range of the current word
    private func getCurrentWordRange(at location: Int) -> NSRange {
        let text = textStorage.string
        guard location <= text.count else { return NSRange(location: location, length: 0) }
        
        // Find the start of the current word
        var start = location
        while start > 0 {
            let index = text.index(text.startIndex, offsetBy: start - 1)
            if text[index].isWhitespace || text[index].isNewline {
                break
            }
            start -= 1
        }
        
        return NSRange(location: start, length: location - start)
    }
}

/// Handles character translation (placeholder implementation)
public class TextProcessor {
    public struct TranslationResult {
        public let newText: String
        public let deleteCount: Int
        
        public init(newText: String, deleteCount: Int) {
            self.newText = newText
            self.deleteCount = deleteCount
        }
    }
    
    var customTranslation: ((String) -> TranslationResult)?
    
    public init() {}
    
    /// Translate a typed character - enhanced with custom function support
    public func translateCharacter(_ character: String) -> TranslationResult {
        if let customTranslation = customTranslation {
            return customTranslation(character)
        }
        
        // Default implementation - just pass through the character
        return TranslationResult(newText: character, deleteCount: 0)
    }
    
    /// Set a custom character translation function
    public func setTranslationFunction(_ translate: @escaping (String) -> TranslationResult) {
        self.customTranslation = translate
    }
}

/// Handles word prediction (placeholder implementation)
public class PredictionEngine {
    private let samplePredictions = [
        "function", "variable", "constant", "import", "export",
        "class", "struct", "protocol", "extension", "enum",
        "private", "public", "internal", "override", "static",
        "async", "await", "throws", "return", "guard"
    ]
    
    var customPrediction: ((String) -> [String])?
    var customWords: [String] = []
    
    public init() {}
    
    /// Get predictions for a word - enhanced with custom function support
    public func getPrediction(forWord word: String, maxCount: Int = 3) -> [String] {
        if let customPrediction = customPrediction {
            let results = customPrediction(word)
            return Array(results.prefix(maxCount))
        }
        
        guard word.count >= 2 else { return [] }
        
        // Filter sample predictions that start with the word
        let filtered = samplePredictions.filter { $0.hasPrefix(word.lowercased()) }
        
        // Add custom words that match
        let customMatches = customWords.filter { $0.lowercased().hasPrefix(word.lowercased()) }
        
        // Combine and deduplicate
        let combined = Array(Set(filtered + customMatches))
        
        // Add some random predictions to simulate real behavior if we don't have enough matches
        let randomPredictions = combined.isEmpty ? samplePredictions.shuffled().prefix(maxCount) : []
        
        return Array((combined + randomPredictions).prefix(maxCount))
    }
    
    /// Set a custom prediction function
    public func setPredictionFunction(_ predict: @escaping (String) -> [String]) {
        self.customPrediction = predict
    }
    
    /// Add custom word list for predictions
    public func addCustomWords(_ words: [String]) {
        self.customWords.append(contentsOf: words)
    }
}
