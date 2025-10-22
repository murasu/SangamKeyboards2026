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
public class TextEditorCore: ObservableObject {
    @Published var textStorage = NSTextStorage()
    @Published var currentPredictions: [String] = []
    @Published var showingPrediction = false
    @Published var predictionRange: NSRange?
    
    public let textProcessor = TextProcessor()
    public let predictionEngine = PredictionEngine()
    
    var onTextChange: ((String) -> Void)?
    var onKeyTranslation: ((String, NSRange?) -> Void)?
    
    public init() {
        setupTextStorage()
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
    
    /// Process a typed character through the translation system
    public func processTypedCharacter(_ character: String, at range: NSRange) {
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
        guard let range = predictionRange else { return }
        
        textStorage.replaceCharacters(in: range, with: prediction)
        hidePredictions()
        
        onTextChange?(textStorage.string)
    }
    
    /// Hide predictions
    public func hidePredictions() {
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