//
//  TextEditorCore.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import Foundation
import SwiftUI
import Combine

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
class TextEditorCore: ObservableObject {
    @Published var textStorage = NSTextStorage()
    @Published var currentPredictions: [String] = []
    @Published var showingPrediction = false
    @Published var predictionRange: NSRange?
    
    private let textProcessor = TextProcessor()
    private let predictionEngine = PredictionEngine()
    
    var onTextChange: ((String) -> Void)?
    var onKeyTranslation: ((String, NSRange?) -> Void)?
    
    init() {
        setupTextStorage()
    }
    
    private func setupTextStorage() {
        // Set up default attributes for the text
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: PlatformColor.label
        ]
        
        let attributedString = NSAttributedString(string: "", attributes: defaultAttributes)
        textStorage.setAttributedString(attributedString)
    }
    
    /// Process a typed character through the translation system
    func processTypedCharacter(_ character: String, at range: NSRange) {
        let translatedText = textProcessor.translateCharacter(character)
        
        if translatedText.deleteCount > 0 {
            // Delete previous characters
            let deleteRange = NSRange(
                location: max(0, range.location - translatedText.deleteCount),
                length: translatedText.deleteCount
            )
            textStorage.deleteCharacters(in: deleteRange)
        }
        
        // Insert new text
        let insertRange = NSRange(location: range.location - translatedText.deleteCount, length: 0)
        textStorage.insert(NSAttributedString(string: translatedText.newText), at: insertRange.location)
        
        // Update predictions
        updatePredictions(at: insertRange.location + translatedText.newText.count)
        
        onTextChange?(textStorage.string)
        onKeyTranslation?(translatedText.newText, insertRange)
    }
    
    /// Update word predictions based on current cursor position
    func updatePredictions(at location: Int) {
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
    func acceptPrediction(_ prediction: String) {
        guard let range = predictionRange else { return }
        
        textStorage.replaceCharacters(in: range, with: prediction)
        hidePredictions()
        
        onTextChange?(textStorage.string)
    }
    
    /// Hide predictions
    func hidePredictions() {
        showingPrediction = false
        currentPredictions = []
        predictionRange = nil
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
class TextProcessor {
    struct TranslationResult {
        let newText: String
        let deleteCount: Int
    }
    
    /// Translate a typed character - placeholder implementation
    func translateCharacter(_ character: String) -> TranslationResult {
        // For now, just pass through the character
        // Later, this can be replaced with actual translation logic
        return TranslationResult(newText: character, deleteCount: 0)
    }
}

/// Handles word prediction (placeholder implementation)
class PredictionEngine {
    private let samplePredictions = [
        "function", "variable", "constant", "import", "export",
        "class", "struct", "protocol", "extension", "enum",
        "private", "public", "internal", "override", "static",
        "async", "await", "throws", "return", "guard"
    ]
    
    /// Get predictions for a word - placeholder implementation
    func getPrediction(forWord word: String) -> [String] {
        guard word.count >= 2 else { return [] }
        
        // Filter sample predictions that start with the word
        let filtered = samplePredictions.filter { $0.hasPrefix(word.lowercased()) }
        
        // Add some random predictions to simulate real behavior
        let randomPredictions = samplePredictions.shuffled().prefix(2)
        
        return Array(Set(filtered + randomPredictions)).prefix(3).map { $0 }
    }
}