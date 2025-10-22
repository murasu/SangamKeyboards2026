//
//  EditorViewModel.swift
//  ContextAwareTextView
//
//  Created by Muthu Nedumaran on 22/10/2025.
//
//  Target Membership: ✅ macOS ✅ iOS

import Foundation
import Combine

/// Shared view model for editor state and business logic
public class EditorViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var text: String = ""
    @Published public var candidates: [String] = []
    @Published public var selectedCandidateIndex: Int = -1
    @Published public var isShowingCandidates: Bool = false
    
    // MARK: - Dependencies
    
    public var translator: SwiftKeyTranslator?
    public var predictor: Predictor?
    
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
        $text
            .dropFirst()
            .sink { _ in
                // Could add debouncing here if needed
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Key Translation
    
    public func translateKey(keyCode: Int32, shifted: Bool) -> String {
        guard let translator = translator else { return "" }
        
        let result = translator.translateKey(keyCode: keyCode, shifted: shifted)
        
        return result
    }
    
    // MARK: - Text Manipulation
    
    public func insertText(_ insertText: String, at position: Int) -> Int {
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        text = beforeCursor + insertText + afterCursor
        
        return beforeCursor.count + insertText.count
    }
    
    public func deleteBackward(count: Int, at position: Int) {
        guard count > 0, position >= count else { return }
        
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        let newBefore = String(beforeCursor.dropLast(count))
        text = newBefore + afterCursor
    }
    
    // MARK: - Prediction
    
    public func updatePredictions(textBefore: String, textAfter: String) {
        guard let predictor = predictor else { return }
        
        let words = textBefore.split(separator: " ")
        let lastWord = words.last.map(String.init) ?? ""
        let previousWord = words.count > 1 ? String(words[words.count - 2]) : ""
        let secondPreviousWord = words.count > 2 ? String(words[words.count - 3]) : ""
        
        do {
            var newCandidates: [PredictionResult] = []
            
            if !previousWord.isEmpty && lastWord.isEmpty {
                // Get next word predictions based on previous words
                if !secondPreviousWord.isEmpty {
                    // Try trigram predictions
                    newCandidates = try predictor.getNgramPredictions(
                        baseWord: secondPreviousWord,
                        secondWord: previousWord,
                        prefix: "",
                        targetScript: .tamil,
                        annotationType: .notrequired,
                        maxResults: maxCandidates
                    )
                } else {
                    // Try bigram predictions
                    newCandidates = try predictor.getNgramPredictions(
                        baseWord: previousWord,
                        secondWord: "",
                        prefix: "",
                        targetScript: .tamil,
                        annotationType: .notrequired,
                        maxResults: maxCandidates
                    )
                }
            } else if !lastWord.isEmpty {
                // Get word completions for current partial word
                newCandidates = try predictor.getWordPredictions(
                    prefix: lastWord,
                    targetScript: .tamil,
                    annotationType: .notrequired,
                    maxResults: maxCandidates
                )
            }
            
            candidates = newCandidates.map { $0.word }
            selectedCandidateIndex = candidates.isEmpty ? -1 : 0
            isShowingCandidates = !candidates.isEmpty
            
        } catch {
            print("Prediction error: \(error)")
            candidates = []
            isShowingCandidates = false
        }
    }
    
    // MARK: - Candidate Selection
    
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
        
        let beforeCursor = String(text.prefix(position))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        let words = beforeCursor.split(separator: " ")
        let partialWord = words.last.map(String.init) ?? ""
        let beforeWord = beforeCursor.dropLast(partialWord.count)
        
        text = String(beforeWord) + candidate + afterCursor
        composingText = ""
        
        if autoLearnEnabled {
            try? predictor?.addWord(candidate)
        }
        
        hideCandidates()
        
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


