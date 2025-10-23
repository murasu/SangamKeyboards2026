//
//  IOSTextEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

/// Custom UITextView for iOS with key interception and prediction support
class CustomUITextView: UITextView {
    weak var editorCore: TextEditorCore?
    private var predictionOverlay: PredictionOverlayUIView?
    private var keyboardObserver: NSObjectProtocol?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    deinit {
        if let observer = keyboardObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupTextView() {
        // Configure text view for code editing
        autocorrectionType = .no
        autocapitalizationType = .none
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        spellCheckingType = .no
        
        // Enable rich text but we'll handle formatting ourselves
        allowsEditingTextAttributes = true
        
        font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        backgroundColor = UIColor.systemBackground
        textColor = UIColor.label
        
        // Set up keyboard observers for external keyboard support
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePredictionDisplay()
        }
    }
    
    func configure(with core: TextEditorCore) {
        self.editorCore = core
        
        // Pass delete event to textview to handle when we are not composing
        core.onBackspacePassThrough = { [weak self] in
            self?.deleteBackward()
        }
        
        // Set the attributed text
        attributedText = core.textStorage
    }
    
    // MARK: - Text Input Handling
    
    override func insertText(_ text: String) {
        guard let editorCore = editorCore else {
            super.insertText(text)
            return
        }
        
        // Handle special keys from external keyboard
        if text == "\t" { // Tab key - accept prediction
            if editorCore.showingPrediction && !editorCore.currentPredictions.isEmpty {
                editorCore.acceptPrediction(editorCore.currentPredictions[0])
                updateTextFromCore()
                return
            }
        }
        
        // Process the character through our core
        let currentRange = selectedRange
        editorCore.processTypedCharacter(text, at: currentRange)
        
        // Update the display
        updateTextFromCore()
        updatePredictionDisplay()
        handleTextChange()
    }
    
    override func deleteBackward() {
        guard let editorCore = editorCore else {
            super.deleteBackward()
            return
        }
        
        // Handle delete through our system
        let currentRange = selectedRange
        if currentRange.length == 0 && currentRange.location > 0 {
            let deleteRange = NSRange(location: currentRange.location - 1, length: 1)
            editorCore.textStorage.deleteCharacters(in: deleteRange)
            
            updateTextFromCore()
            updatePredictionDisplay()
            handleTextChange()
        } else if currentRange.length > 0 {
            editorCore.textStorage.deleteCharacters(in: currentRange)
            updateTextFromCore()
            updatePredictionDisplay()
            handleTextChange()
        }
    }
    
    // MARK: - Keyboard Input (for external keyboards)
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapePressed)),
            UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(tabPressed))
        ]
    }
    
    @objc private func escapePressed() {
        editorCore?.hidePredictions()
        updatePredictionDisplay()
    }
    
    @objc private func tabPressed() {
        guard let editorCore = editorCore else { return }
        
        if editorCore.showingPrediction && !editorCore.currentPredictions.isEmpty {
            editorCore.acceptPrediction(editorCore.currentPredictions[0])
            updateTextFromCore()
        }
    }
    
    // MARK: - Text Updates
    
    private func updateTextFromCore() {
        guard let editorCore = editorCore else { return }
        
        let currentSelection = selectedRange
        attributedText = editorCore.textStorage
        
        // Restore selection if possible
        if currentSelection.location <= text.count {
            selectedRange = currentSelection
        }
    }
    
    // MARK: - Prediction Display
    
    private func updatePredictionDisplay() {
        guard let editorCore = editorCore else { return }
        
        if editorCore.showingPrediction && !editorCore.currentPredictions.isEmpty {
            showPredictionOverlay()
        } else {
            hidePredictionOverlay()
        }
    }
    
    private func showPredictionOverlay() {
        guard let editorCore = editorCore else { return }
        
        // Get composition rect or fallback to cursor position
        let compositionRect: CGRect
        if let layoutManager = layoutManager,
           let textContainer = textContainer,
           let rect = editorCore.getCompositionRect(
               layoutManager: layoutManager,
               textContainer: textContainer,
               textContainerInset: textContainerInset
           ) {
            compositionRect = rect
        } else {
            // Fallback to cursor position
            let cursorRect = caretRect(for: selectedTextRange?.start ?? beginningOfDocument)
            compositionRect = cursorRect
        }
        
        // Create or update prediction overlay
        if predictionOverlay == nil {
            predictionOverlay = PredictionOverlayUIView()
            predictionOverlay?.onTap = { [weak self] prediction in
                self?.editorCore?.acceptPrediction(prediction)
                self?.updateTextFromCore()
            }
            addSubview(predictionOverlay!)
        }
        
        predictionOverlay?.configure(with: editorCore.currentPredictions, showingAbove: positionResult.shouldShowAbove)
        
        // Calculate candidate window size based on content
        let candidateWindowSize = editorCore.calculateCandidateWindowSize(
            for: editorCore.currentPredictions,
            maxWidth: min(250, frame.width * 0.7)
        )
        
        // Get editor bounds (text view's bounds)
        let editorBounds = bounds
        
        // Calculate optimal position using the core's positioning logic
        let positionResult = editorCore.calculateCandidateWindowPosition(
            editorBounds: editorBounds,
            compositionRect: compositionRect,
            candidateWindowSize: candidateWindowSize
        )
        
        // Apply the calculated position
        predictionOverlay?.frame = CGRect(
            origin: positionResult.position,
            size: candidateWindowSize
        )
        
        // Optional: Add visual indication if showing above
        if positionResult.shouldShowAbove {
            print("📍 Candidate window positioned above composition (bottom overflow detected)")
        } else {
            print("📍 Candidate window positioned below composition")
        }
    }
    
    private func hidePredictionOverlay() {
        predictionOverlay?.removeFromSuperview()
        predictionOverlay = nil
    }
    
    // MARK: - Text Change Handling
    
    func handleTextChange() {
        // Update predictions when text changes
        let location = selectedRange.location
        editorCore?.updatePredictions(at: location)
        updatePredictionDisplay()
    }
}

/// Simple prediction overlay view for iOS
class PredictionOverlayUIView: UIView {
    private let label = UILabel()
    private let backgroundView = UIView()
    
    var onTap: ((String) -> Void)?
    private var currentPrediction: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Setup background
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.layer.cornerRadius = 6
        backgroundView.layer.borderColor = UIColor.separator.cgColor
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.1
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 4
        
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup label
        label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular) // Smaller font for multiple lines
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 0 // Allow unlimited lines
        
        backgroundView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            label.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -4)
        ])
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func overlayTapped() {
        onTap?(currentPrediction)
    }
    
    func configure(with predictions: [String], showingAbove: Bool = false) {
        guard !predictions.isEmpty else {
            currentPrediction = ""
            label.text = ""
            return
        }
        
        currentPrediction = predictions.first ?? ""
        
        // Show all predictions, each on a separate line
        let candidateText = predictions.enumerated().map { index, prediction in
            "\(index + 1). \(prediction)"
        }.joined(separator: "\n")
        
        let prefix = showingAbove ? "▲" : "▼"
        label.text = "\(prefix)\n\(candidateText)"
        
        // Adjust shadow direction based on position
        if showingAbove {
            backgroundView.layer.shadowOffset = CGSize(width: 0, height: -2)
        } else {
            backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
    
    func configure(with predictions: [String]) {
        configure(with: predictions, showingAbove: false)
    }
}

/// SwiftUI wrapper for the iOS text editor
struct IOSTextEditor: UIViewRepresentable {
    @ObservedObject var core: TextEditorCore
    
    func makeUIView(context: Context) -> CustomUITextView {
        let textView = CustomUITextView()
        textView.configure(with: core)
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: CustomUITextView, context: Context) {
        // Update text if needed
        if uiView.attributedText.string != core.textStorage.string {
            uiView.attributedText = core.textStorage
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: IOSTextEditor
        
        init(_ parent: IOSTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Notify the core of text changes
            parent.core.onTextChange?(textView.text)
            
            // If this is our CustomUITextView, trigger its text change handling
            if let customTextView = textView as? CustomUITextView {
                customTextView.handleTextChange()
            }
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update predictions when cursor moves
            let location = textView.selectedRange.location
            parent.core.updatePredictions(at: location)
        }
    }
}

#endif
