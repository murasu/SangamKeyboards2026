// Sources/EditorCore/EditorViewModel.swift
import Foundation
import Combine

/// Shared view model for editor state and business logic
/// Compatible with iOS 15+ and macOS 12+
public class EditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var text: String = ""
    @Published public var candidates: [String] = []
    @Published public var selectedCandidateIndex: Int = -1
    @Published public var isShowingCandidates: Bool = false
    
    // MARK: - Dependencies
    
    // These will be injected from your C library wrappers
    public var translator: MobileKeyTranslator?
    public var predictor: MobilePredictor?
    
    // MARK: - Internal State
    
    private var composingText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    public var maxCandidates: Int = 5
    public var autoLearnEnabled: Bool = true
    
    // MARK: - Initialization
    
    public init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe text changes to clear candidates when appropriate
        $text
            .dropFirst()
            .sink { _ in
                // Could add debouncing here if needed
                // Will implement debouncing in Phase 2 if needed
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Key Translation
    
    /// Translate a key press using the key translator
    /// Returns the translation result if handled, nil otherwise
    public func translateKey(keyCode: Int, shifted: Bool) -> TranslationResult? {
        guard let translator = translator else { return nil }
        
        let result = translator.translate(
            composing: composingText,
            keyCode: keyCode,
            shifted: shifted
        )
        
        return result.handled ? result : nil
    }
    
    // MARK: - Text Manipulation
    
    /// Apply translation result to text at cursor position
    public func applyTranslation(
        _ result: TranslationResult,
        cursorPosition: Int
    ) -> Int {
        let beforeCursor = String(text.prefix(cursorPosition))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: cursorPosition)))
        
        // Handle deletion if needed
        let newBefore = result.deleteCount > 0
            ? String(beforeCursor.dropLast(result.deleteCount))
            : beforeCursor
        
        // Update text
        text = newBefore + result.text + afterCursor
        composingText += result.text
        
        // Return new cursor position
        return newBefore.count + result.text.count
    }
    
    /// Insert text at cursor position
    public func insertText(_ insertText: String, at position: Int) {
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        text = beforeCursor + insertText + afterCursor
    }
    
    /// Delete text before cursor
    public func deleteBackward(count: Int, at position: Int) {
        guard count > 0, position >= count else { return }
        
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        let newBefore = String(beforeCursor.dropLast(count))
        text = newBefore + afterCursor
    }
    
    // MARK: - Prediction (Phase 2)
    
    /// Update predictions based on context
    /// This will be implemented in Phase 2 with candidate selection
    public func updatePredictions(textBefore: String, textAfter: String) {
        guard let predictor = predictor else { return }
        
        // Extract context
        let words = textBefore.split(separator: " ")
        let lastWord = words.last.map(String.init) ?? ""
        let previousWord = words.count > 1 ? String(words[words.count - 2]) : ""
        
        do {
            let newCandidates: [String]
            
            if !previousWord.isEmpty && lastWord.isEmpty {
                // Predict next word after space
                newCandidates = try predictor.getNgramCandidates(
                    previousWord: previousWord,
                    prefix: "",
                    maxResults: maxCandidates
                )
            } else if !lastWord.isEmpty {
                // Predict completions for current word
                newCandidates = try predictor.getCandidates(
                    prefix: lastWord,
                    maxResults: maxCandidates
                )
            } else {
                newCandidates = []
            }
            
            // Update state
            candidates = newCandidates
            selectedCandidateIndex = newCandidates.isEmpty ? -1 : 0
            isShowingCandidates = !newCandidates.isEmpty
            
        } catch {
            print("Prediction error: \(error)")
            candidates = []
            isShowingCandidates = false
        }
    }
    
    // MARK: - Candidate Selection (Phase 2)
    
    public func selectNextCandidate() {
        guard !candidates.isEmpty else { return }
        selectedCandidateIndex = (selectedCandidateIndex + 1) % candidates.count
    }
    
    public func selectPreviousCandidate() {
        guard !candidates.isEmpty else { return }
        selectedCandidateIndex = selectedCandidateIndex <= 0
            ? candidates.count - 1
            : selectedCandidateIndex - 1
    }
    
    public func insertSelectedCandidate(at position: Int) -> Int? {
        guard selectedCandidateIndex >= 0,
              selectedCandidateIndex < candidates.count else { return nil }
        
        let candidate = candidates[selectedCandidateIndex]
        
        // Find and replace partial word
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        let words = beforeCursor.split(separator: " ")
        let partialWord = words.last.map(String.init) ?? ""
        let beforeWord = beforeCursor.dropLast(partialWord.count)
        
        // Update text
        text = String(beforeWord) + candidate + afterCursor
        composingText = ""
        
        // Learn if enabled
        if autoLearnEnabled {
            try? predictor?.learnWord(candidate)
        }
        
        // Hide candidates
        hideCandidates()
        
        // Return new cursor position
        return beforeWord.count + candidate.count
    }
    
    public func hideCandidates() {
        candidates = []
        selectedCandidateIndex = -1
        isShowingCandidates = false
    }
    
    // MARK: - Composition State
    
    public func resetComposition() {
        composingText = ""
    }
    
    public func terminateComposition() {
        translator?.terminateComposition()
        composingText = ""
    }
}

// MARK: - Placeholder Types
// These will be replaced by your actual library types

public protocol MobileKeyTranslator {
    func translate(composing: String, keyCode: Int, shifted: Bool) -> TranslationResult
    func terminateComposition()
}

public struct TranslationResult {
    public let text: String
    public let deleteCount: Int
    public let handled: Bool
    
    public init(text: String, deleteCount: Int, handled: Bool) {
        self.text = text
        self.deleteCount = deleteCount
        self.handled = handled
    }
}

public protocol MobilePredictor {
    func getCandidates(prefix: String, maxResults: Int) throws -> [String]
    func getNgramCandidates(previousWord: String, prefix: String, maxResults: Int) throws -> [String]
    func learnWord(_ word: String) throws
}
