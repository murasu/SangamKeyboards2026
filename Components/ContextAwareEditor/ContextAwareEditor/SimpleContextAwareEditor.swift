//
//  SimpleContextAwareEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI

/// Simplified context-aware text editor that actually works
public struct SimpleContextAwareEditor: View {
    @State private var text: String
    @State private var predictions: [PredictionResult] = []
    @State private var showingPredictions = false
    
    private let core = TextEditorCore()
    private var onTextChangeCallback: ((String) -> Void)?
    private var onKeyTranslationCallback: ((String, NSRange?) -> Void)?
    
    public init(initialText: String = "") {
        self._text = State(initialValue: initialText)
    }
    
    public var body: some View {
        VStack {
            #if canImport(AppKit)
            SimpleMacOSTextEditor(text: $text) { newText in
                handleTextChange(newText)
            }
            #else
            Text("iOS version not implemented yet")
            #endif
            
            if showingPredictions && !predictions.isEmpty {
                HStack {
                    Text("Predictions:")
                        .font(.caption)
                    ForEach(predictions.prefix(3), id: \.wordId) { prediction in
                        Button(prediction.word) {
                            acceptPrediction(prediction)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func handleTextChange(_ newText: String) {
        text = newText
        onTextChangeCallback?(newText)
        updatePredictions()
    }
    
    private func updatePredictions() {
        // Get the last word being typed
        let words = text.split(separator: " ")
        guard let lastWord = words.last, lastWord.count >= 2 else {
            showingPredictions = false
            predictions = []
            return
        }
        
        let wordString = String(lastWord)
        predictions = core.predictionEngine.getPrediction(forWord: wordString)
        showingPredictions = !predictions.isEmpty
    }
    
    private func acceptPrediction(_ prediction: PredictionResult) {
        // Replace the last word with the prediction
        var words = text.split(separator: " ").map(String.init)
        if !words.isEmpty {
            words[words.count - 1] = prediction.word
            text = words.joined(separator: " ") + " "
        }
        
        showingPredictions = false
        predictions = []
    }
    
    // MARK: - Configuration Methods
    
    public func onTextChange(_ callback: @escaping (String) -> Void) -> SimpleContextAwareEditor {
        var editor = self
        editor.onTextChangeCallback = callback
        return editor
    }
    
    public func onKeyTranslation(_ callback: @escaping (String, NSRange?) -> Void) -> SimpleContextAwareEditor {
        var editor = self
        editor.onKeyTranslationCallback = callback
        return editor
    }
    
    public func configureTextProcessor(_ configure: @escaping (TextProcessor) -> Void) -> SimpleContextAwareEditor {
        configure(core.textProcessor)
        return self
    }
    
    public func configurePredictionEngine(_ configure: @escaping (PredictionEngine) -> Void) -> SimpleContextAwareEditor {
        configure(core.predictionEngine)
        return self
    }
}