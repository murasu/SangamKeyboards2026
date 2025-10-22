//
//  MacOSTextEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

#if canImport(AppKit)
import AppKit
import SwiftUI

/// Custom NSTextView for macOS with key interception and prediction support
class CustomNSTextView: NSTextView {
    weak var editorCore: TextEditorCore?
    private var predictionOverlay: PredictionOverlayView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextView()
    }
    
    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // Configure text view for code editing
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isContinuousSpellCheckingEnabled = false
        
        // Enable rich text but we'll handle formatting ourselves
        isRichText = true
        allowsUndo = true
        
        font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    }
    
    func configure(with core: TextEditorCore) {
        self.editorCore = core
        
        // Set the text storage
        textStorage?.setAttributedString(core.textStorage)
        
        // Observe core changes
        setupObservers()
    }
    
    private func setupObservers() {
        // We'll observe the core for prediction changes and update the overlay
    }
    
    // MARK: - Key Handling
    
    override func keyDown(with event: NSEvent) {
        guard let editorCore = editorCore else {
            super.keyDown(with: event)
            return
        }
        
        // Handle special keys
        switch event.keyCode {
        case 48: // Tab key - accept prediction
            if editorCore.showingPrediction && !editorCore.currentPredictions.isEmpty {
                editorCore.acceptPrediction(editorCore.currentPredictions[0])
                return
            }
        case 53: // Escape key - hide predictions
            editorCore.hidePredictions()
            return
        default:
            break
        }
        
        // Get the character typed
        guard let characters = event.characters, !characters.isEmpty else {
            super.keyDown(with: event)
            return
        }
        
        let character = characters
        let currentRange = selectedRange()
        
        // Process the character through our core
        editorCore.processTypedCharacter(character, at: currentRange)
        
        // Update the display
        updatePredictionDisplay()
    }
    
    override func insertText(_ string: Any) {
        // Override to prevent double insertion since we handle it in processTypedCharacter
        if let editorCore = editorCore, editorCore.showingPrediction {
            // If we're showing predictions, let our system handle it
            return
        }
        super.insertText(string)
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
        guard let editorCore = editorCore,
              let layoutManager = layoutManager,
              let textContainer = textContainer else { return }
        
        // Calculate position for the prediction overlay
        let insertionPoint = selectedRange().location
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: insertionPoint)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0),
                                            in: textContainer)
        
        // Create or update prediction overlay
        if predictionOverlay == nil {
            predictionOverlay = PredictionOverlayView()
            addSubview(predictionOverlay!)
        }
        
        predictionOverlay?.configure(with: editorCore.currentPredictions)
        predictionOverlay?.frame = CGRect(
            x: rect.maxX,
            y: rect.minY,
            width: 200,
            height: 30
        )
    }
    
    private func hidePredictionOverlay() {
        predictionOverlay?.removeFromSuperview()
        predictionOverlay = nil
    }
}

/// Simple prediction overlay view for macOS
class PredictionOverlayView: NSView {
    private let textField = NSTextField()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 4
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        
        textField.isBordered = false
        textField.isEditable = false
        textField.backgroundColor = .clear
        textField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        textField.textColor = NSColor.secondaryLabelColor
        
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with predictions: [String]) {
        textField.stringValue = predictions.first ?? ""
    }
}

/// SwiftUI wrapper for the macOS text editor
struct MacOSTextEditor: NSViewRepresentable {
    @ObservedObject var core: TextEditorCore
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CustomNSTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.documentView = textView
        
        // Configure text view
        textView.configure(with: core)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CustomNSTextView else { return }
        
        // Update text if needed
        if textView.string != core.textStorage.string {
            textView.string = core.textStorage.string
        }
    }
}

#endif