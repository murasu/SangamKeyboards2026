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
    private var sangamTranslator: SangamKeyTranslator?
    
    public let textProcessor = TextProcessor()
    public let predictionEngine = PredictionEngine()
    
    var onTextChange: ((String) -> Void)?
    var onKeyTranslation: ((String, NSRange?) -> Void)?
    var onCompositionChange: ((String, Bool) -> Void)? // compositionText, isActive
    
    public init() {
        setupTextStorage()
        setupSangamTranslator()
    }
    
    private func setupSangamTranslator() {
        do {
            sangamTranslator = try SangamKeyTranslator(imeType: kbdAnjal)
        } catch {
            print("Failed to initialize SangamKeyTranslator: \(error)")
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
            .font: PlatformFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: "", attributes: defaultAttributes)
        textStorage.setAttributedString(attributedString)
    }
    
    /// Process a typed character through the composition system
    public func processKeyInput(_ character: String, keyCode: Int32, isShifted: Bool, at range: NSRange) {
        // Handle cursor movement - commit any active composition
        if range.location != (compositionRange?.location ?? range.location) {
            commitComposition()
        }
        
        if isTranslatableKey(character, keyCode: keyCode) {
            handleTranslatableKey(character, keyCode: keyCode, isShifted: isShifted, at: range)
        } else {
            commitComposition()
            insertRegularText(character, at: range)
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
        if character.isEmpty { return false }
        
        let char = character.first!
        
        // Letters are translatable
        if char.isLetter { return true }
        
        // Some punctuation that might be part of Tamil transliteration
        let translatablePunctuation: Set<Character> = [".", ",", ";", ":", "'", "\""]
        if translatablePunctuation.contains(char) { return true }
        
        // Numbers might be translatable in some contexts
        if char.isNumber { return true }
        
        // Special keys by keyCode (backspace, etc.)
        if keyCode == 51 { return true } // Backspace
        
        return false
    }
    
    // MARK: - Composition Handling
    
    private func handleTranslatableKey(_ character: String, keyCode: Int32, isShifted: Bool, at range: NSRange) {
        if !isComposing {
            startComposition(at: range)
        }
        
        // Handle backspace specially
        if keyCode == 51 { // Backspace
            handleBackspaceInComposition()
            return
        }
        
        // Add character to composition buffer
        compositionBuffer += character
        
        // Translate the current composition
        translateCurrentComposition(isShifted: isShifted)
    }
    
    private func startComposition(at range: NSRange) {
        isComposing = true
        compositionRange = range
        compositionBuffer = ""
        onCompositionChange?("", true)
    }
    
    private func translateCurrentComposition(isShifted: Bool) {
        guard let translator = sangamTranslator else {
            // Fallback: just display the buffer as-is
            updateCompositionDisplay(compositionBuffer)
            return
        }
        
        // Use the last character for keyCode
        let keyCode = Int32(compositionBuffer.last?.asciiValue ?? 0)
        
        let translatedResult = translator.translateComposition(
            in: compositionBuffer,
            newKeyCode: keyCode,
            shifted: isShifted
        )
        
        let parsedResult = parseSangamResult(translatedResult)
        updateCompositionDisplay(parsedResult.translatedText)
        
        // Generate candidates for the translated text
        generateCandidates(for: parsedResult.translatedText)
    }
    
    private func handleBackspaceInComposition() {
        guard let translator = sangamTranslator else {
            // Simple backspace
            if !compositionBuffer.isEmpty {
                compositionBuffer.removeLast()
                updateCompositionDisplay(compositionBuffer)
            } else {
                commitComposition()
            }
            return
        }
        
        // Use translator's delete functionality
        if !compositionBuffer.isEmpty {
            let deletedComposition = translator.deleteLastChar(in: compositionBuffer)
            compositionBuffer = deletedComposition
            
            if compositionBuffer.isEmpty {
                commitComposition()
            } else {
                updateCompositionDisplay(compositionBuffer)
                generateCandidates(for: compositionBuffer)
            }
        } else {
            commitComposition()
        }
    }
    
    private func updateCompositionDisplay(_ text: String) {
        guard let range = compositionRange else { return }
        
        // Create attributed string with composition styling
        let attributes = getCompositionAttributes()
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        
        // Replace the composition range with new text
        textStorage.replaceCharacters(in: range, with: attributedText)
        
        // Update the composition range
        compositionRange = NSRange(location: range.location, length: text.count)
        
        onTextChange?(textStorage.string)
        onCompositionChange?(text, true)
    }
    
    private func commitComposition() {
        guard isComposing, let range = compositionRange else { return }
        
        // Remove composition styling and apply normal text attributes
        let normalAttributes = getNormalTextAttributes()
        textStorage.addAttributes(normalAttributes, range: range)
        
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
            .font: PlatformFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
    
    private func getNormalTextAttributes() -> [NSAttributedString.Key: Any] {
        #if canImport(AppKit)
        let textColor = NSColor.labelColor
        #elseif canImport(UIKit)
        let textColor = UIColor.label
        #endif
        
        return [
            .font: PlatformFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: textColor
        ]
    }
    
    // MARK: - Candidate Generation
    
    private func generateCandidates(for text: String) {
        // For now, generate dummy Tamil candidates
        // You can replace this with actual candidate generation logic
        let dummyTamilCandidates = [
            "அன்பு", "இன்பம்", "உயிர்", "எழுத்து", "ஒலி"
        ].shuffled().prefix(3)
        
        if !dummyTamilCandidates.isEmpty {
            currentPredictions = Array(dummyTamilCandidates)
            predictionRange = compositionRange
            showingPrediction = true
        } else {
            hidePredictions()
        }
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
        let predictions = predictionEngine.getPrediction(forWord: currentWord)
        
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
    public func getPrediction(forWord word: String) -> [String] {
        if let customPrediction = customPrediction {
            return customPrediction(word)
        }
        
        guard word.count >= 2 else { return [] }
        
        // Filter sample predictions that start with the word
        let filtered = samplePredictions.filter { $0.hasPrefix(word.lowercased()) }
        
        // Add custom words that match
        let customMatches = customWords.filter { $0.lowercased().hasPrefix(word.lowercased()) }
        
        // Combine and deduplicate
        let combined = Array(Set(filtered + customMatches))
        
        // Add some random predictions to simulate real behavior if we don't have enough matches
        let randomPredictions = combined.isEmpty ? samplePredictions.shuffled().prefix(2) : []
        
        return Array((combined + randomPredictions).prefix(3))
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
