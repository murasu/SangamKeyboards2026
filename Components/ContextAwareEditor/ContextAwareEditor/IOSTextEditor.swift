//
//  IOSTextEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

#if canImport(UIKit)
import UIKit
import SwiftUI
import Combine

/// Custom UITextView for iOS with key interception and prediction support
class CustomUITextView: UITextView {
    weak var editorCore: TextEditorCore?
    private var predictionOverlay: PredictionOverlayUIView?
    private var keyboardObserver: NSObjectProtocol?
    private var cachedMaxCandidateWidth: CGFloat = 0
    private var lastEditorWidth: CGFloat = 0
    private let settings = EditorSettings.shared
    private var settingsObserver: AnyCancellable?
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
        setupSettingsObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
        setupSettingsObserver()
    }
    
    deinit {
        if let observer = keyboardObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        settingsObserver?.cancel()
    }
    
    private func setupSettingsObserver() {
        // Observe editor font changes (fontFamily + editorFontSize) and suggestion font changes
        settingsObserver = settings.$fontFamily
            .combineLatest(settings.$editorFontSize, settings.$suggestionsFontSize)
            .sink { [weak self] _, _, _ in
                self?.updateEditorFont()
                self?.refreshMaxCandidateWidth()
                self?.updatePredictionDisplay()
            }
    }
    
    private func updateEditorFont() {
        font = settings.createEditorFont()
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
        
        font = settings.createEditorFont() // Use settings-based editor font
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
        
        // Set initial content
        attributedText = core.textStorage
        
        // Calculate the cached max candidate width once during initialization
        calculateMaxCandidateWidth()
        
        // Set up callback for when core updates text
        core.onTextChange = { [weak self] _ in
            DispatchQueue.main.async {
                self?.syncFromCore()
            }
        }
    }
    
    /// Calculate maximum candidate window width once and cache it
    private func calculateMaxCandidateWidth() {
        let fontSize = settings.getSuggestionsFontPointSize()
        
        // Get minimum width required for long words from the unified core method
        let requiredWidth = editorCore?.calculateMinimumCandidateWidth(fontSize: fontSize) ?? 200
        
        // Use 40% of editor width, but ensure it can fit long words
        let preferredWidth = bounds.width * 0.4
        
        cachedMaxCandidateWidth = max(preferredWidth, requiredWidth)
        lastEditorWidth = bounds.width
    }
    
    /// Get the cached max candidate width, recalculating if editor width changed significantly
    private func getMaxCandidateWidth() -> CGFloat {
        // Recalculate if editor width changed by more than 50px (device rotation, etc.)
        if abs(bounds.width - lastEditorWidth) > 50 {
            calculateMaxCandidateWidth()
        }
        return cachedMaxCandidateWidth
    }
    
    /// Force recalculation of max candidate width (call when user changes font preferences)
    func refreshMaxCandidateWidth() {
        calculateMaxCandidateWidth()
    }
    
    /// Sync the text view content from the core's text storage
    func syncFromCore() {
        guard let editorCore = editorCore else { return }
        
        print("🔄 Syncing from core:")
        print("  - Core text: '\(editorCore.textStorage.string)'")
        print("  - TextView text: '\(text ?? "")'")
        print("  - Current selection: \(selectedRange)")
        
        // Calculate the correct cursor position based on composition state
        let newCursorPosition: Int
        if editorCore.isCurrentlyComposing, let compRange = editorCore.currentCompositionRange {
            // During composition, cursor should be at the end of the composition
            newCursorPosition = compRange.location + compRange.length
            print("  - Composing: setting cursor to end of composition at \(newCursorPosition)")
        } else {
            // Not composing, cursor should be at the end of the text
            newCursorPosition = editorCore.textStorage.length
            print("  - Not composing: setting cursor to end of text at \(newCursorPosition)")
        }
        
        // Update content
        attributedText = editorCore.textStorage
        
        // Set the correct cursor position
        let newRange = NSRange(location: newCursorPosition, length: 0)
        selectedRange = newRange
        
        print("  - Updated cursor position: \(selectedRange)")
        
        // Update prediction display
        updatePredictionDisplay()
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
            syncFromCore()
        }
    }
    
    // MARK: - Prediction Display
    
    func updatePredictionDisplay() {
        guard let editorCore = editorCore else { return }
        
        print ("updatePredictionDisplay: showingPrediction=\(editorCore.showingPrediction), currentPredictions=\(editorCore.currentPredictions)")
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
        if let rect = editorCore.getCompositionRect(
               layoutManager: layoutManager,
               textContainer: textContainer,
               textContainerInset: CGSize(
                   width: textContainerInset.left + textContainerInset.right,
                   height: textContainerInset.top + textContainerInset.bottom
               )
           ) {
            compositionRect = rect
        } else {
            // Fallback to cursor position
            let cursorRect = caretRect(for: selectedTextRange?.start ?? beginningOfDocument)
            compositionRect = cursorRect
        }
        
        // Create overlay if needed to calculate size
        if predictionOverlay == nil {
            predictionOverlay = PredictionOverlayUIView()
            predictionOverlay?.onTap = { [weak self] prediction in
                self?.editorCore?.acceptPrediction(prediction)
                self?.syncFromCore()
            }
            addSubview(predictionOverlay!)
        }

        // Calculate candidate window size based on content (using cached width)
        let maxCandidateWidth = getMaxCandidateWidth()
        let candidateWindowSize = editorCore.calculateCandidateWindowSize(
            for: editorCore.currentPredictions,
            fontSize: settings.getSuggestionsFontPointSize(),
            maxWidth: maxCandidateWidth
        )
        
        // Get editor bounds (text view's bounds)
        let editorBounds = bounds
        
        // Calculate optimal position using the core's positioning logic
        let positionResult = editorCore.calculateCandidateWindowPosition(
            editorBounds: editorBounds,
            compositionRect: compositionRect,
            candidateWindowSize: candidateWindowSize
        )
        
        // Configure the overlay with the correct showingAbove value
        predictionOverlay?.configure(with: editorCore.currentPredictions, showingAbove: positionResult.shouldShowAbove)
        
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
    private let settings = EditorSettings.shared
    private var settingsObserver: AnyCancellable?
        
    var onTap: ((String) -> Void)?
    private var currentPrediction: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupSettingsObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupSettingsObserver()
    }
    
    deinit {
        settingsObserver?.cancel()
    }
    
    private func setupSettingsObserver() {
        settingsObserver = settings.$suggestionsFontSize
            .combineLatest(settings.$fontFamily)
            .sink { [weak self] _, _ in
                self?.updateFont()
            }
    }
    
    private func updateFont() {
        label.font = settings.createSuggestionsFont()
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
        
        // Setup label
        updateFont() // Use settings-based font size
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 0 // Allow unlimited lines
        
        backgroundView.addSubview(label)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Manually layout the background and label
        backgroundView.frame = bounds
        label.frame = CGRect(
            x: 8,
            y: 4,
            width: bounds.width - 16,
            height: bounds.height - 8
        )
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
        
        // Show all predictions, each on a separate line, numbered
        let candidateText = predictions.enumerated().map { index, prediction in
            "\(index + 1). \(prediction)"
        }.joined(separator: "\n")
        
        label.text = candidateText
        
        // Adjust shadow direction based on position
        if showingAbove {
            backgroundView.layer.shadowOffset = CGSize(width: 0, height: -2)
        } else {
            backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
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
        // The text view syncs from the core automatically through callbacks
        // No manual synchronization needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: IOSTextEditor
        
        init(_ parent: IOSTextEditor) {
            self.parent = parent
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            print("📝 shouldChangeTextIn: range=\(range), text='\(text)'")
            
            // Handle special keys
            if text == "\t" && parent.core.showingPrediction && !parent.core.currentPredictions.isEmpty {
                parent.core.acceptPrediction(parent.core.currentPredictions[0])
                if let customTextView = textView as? CustomUITextView {
                    customTextView.syncFromCore()
                    
                    customTextView.updatePredictionDisplay()
                }
                return false
            }
            
            if text == "\n" {
                // Handle enter key - commit any composition and insert newline
                parent.core.forceCommitComposition()
                // Let UITextView handle the newline insertion
                return true
            }
            
            // Handle delete operations (empty text means delete)
            if text.isEmpty {
                print("🗑️ Delete operation: range=\(range)")
                
                // If we're composing, handle through our system
                // If we're composing, handle through our system
                if parent.core.isCurrentlyComposing {
                    // Use the composition range instead of the text view's selection range
                    if let compositionRange = parent.core.currentCompositionRange {
                        parent.core.processKeyInput("", keyCode: 51, isShifted: false, at: compositionRange)
                    }
                    if let customTextView = textView as? CustomUITextView {
                        customTextView.syncFromCore()
                    }
                    return false
                }
                /*if parent.core.isCurrentlyComposing {
                    parent.core.processKeyInput("", keyCode: 51, isShifted: false, at: range)
                    if let customTextView = textView as? CustomUITextView {
                        customTextView.syncFromCore()
                    }
                    return false
                } */else {
                    // For regular delete, update our text storage manually then let UITextView handle it
                    parent.core.textStorage.deleteCharacters(in: range)
                    print("🗑️ Updated core text storage after delete: '\(parent.core.textStorage.string)'")
                    // Let UITextView handle the delete visually
                    return true
                }
            }
            
            // For regular characters, process through our translation system
            if !text.isEmpty {
                // Process through the core translation system
                parent.core.processTypedCharacter(text, at: range)
                
                // Update the text view with the translated content
                if let customTextView = textView as? CustomUITextView {
                    customTextView.syncFromCore()
                }
                return false // We handled the text change
            }
            
            // For other cases, let UITextView handle it
            return true
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            print("🎯 Selection changed to: \(textView.selectedRange)")
            
            // Update predictions when cursor moves
            let location = textView.selectedRange.location
            parent.core.updatePredictions(at: location)
            
            if let customTextView = textView as? CustomUITextView {
                customTextView.updatePredictionDisplay()
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            print("📝 Text changed, length: \(textView.text.count)")
            // This will be called after UITextView handles allowed changes
            
            if let customTextView = textView as? CustomUITextView {
                customTextView.handleTextChange()
            }
        }
    }
}

#endif
