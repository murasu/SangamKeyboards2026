//
//  MacOSTextEditor.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

/*
 IMPORTANT DISCOVERY: NSTextView Subclassing Issues in SwiftUI
 
 Problem: Any NSTextView subclass fails to show cursor or accept input when used 
 inside SwiftUI NSViewRepresentable contexts, even if completely empty.
 
 Solution: Use composition instead of inheritance
 ✅ Plain NSTextView works perfectly in NSViewRepresentable
 ✅ Add custom functionality through external coordination via NSTextViewDelegate
 ✅ Intercept keys using a minimal custom subclass created OUTSIDE NSViewRepresentable
 
 Architecture:
 1. KeyInterceptingTextView - Minimal subclass for key events (works when created outside SwiftUI)
 2. MacOSTextEditor.Coordinator - Handles all text processing and predictions via NSTextViewDelegate
 3. PredictionOverlayView - Visual overlay for showing predictions
 4. TextEditorCore integration - Full feature support through composition
 
 Features Working:
 ✅ Text input and cursor display
 ✅ Text color and visibility
 ✅ Prediction engine integration 
 ✅ Tab to accept predictions
 ✅ Escape to hide predictions
 ✅ Visual prediction overlay with styling
 ✅ Full TextEditorCore synchronization
 ✅ All original CustomNSTextView features via composition
 */

#if canImport(AppKit)
import AppKit
import SwiftUI

/// Custom NSTextView for macOS with key interception and prediction support
/// NOTE: This was the original approach but subclassing breaks in SwiftUI NSViewRepresentable
/// Keeping this commented for reference - use composition approach below instead
/*
class CustomNSTextView: NSTextView {
    // ISSUE: Even an empty NSTextView subclass fails to show cursor or accept input 
    // when used inside SwiftUI NSViewRepresentable contexts
}
*/



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
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = 6
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        
        // Add subtle shadow
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        layer?.shadowRadius = 4
        layer?.shadowOpacity = 0.1
        
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
        guard let firstPrediction = predictions.first, !firstPrediction.isEmpty else { 
            textField.stringValue = ""
            return 
        }
        
        // Show first prediction with a subtle hint about Tab to accept
        textField.stringValue = "💡 \(firstPrediction) (Tab to accept)"
    }
}

/// Custom NSTextView for key interception - used OUTSIDE NSViewRepresentable
class KeyInterceptingTextView: NSTextView {
    weak var keyHandler: MacOSTextEditor.Coordinator?
    
    override func keyDown(with event: NSEvent) {
        // Try to handle the key through our coordinator first
        if let keyHandler = keyHandler, keyHandler.handleKeyDown(with: event) {
            return // Event was consumed
        }
        
        // If not handled, pass to super
        super.keyDown(with: event)
    }
}

/// SwiftUI wrapper for the macOS text editor that properly manages state
struct MacOSTextEditorView: View {
    @StateObject private var observedCore: TextEditorCore
    
    init(core: TextEditorCore) {
        self._observedCore = StateObject(wrappedValue: core)
    }
    
    var body: some View {
        MacOSTextEditor(core: observedCore)
    }
}

/// SwiftUI wrapper for the macOS text editor
struct MacOSTextEditor: NSViewRepresentable {
    @ObservedObject var core: TextEditorCore
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // EXPERIMENTAL: Try creating text view with explicit frame and container
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage()
        
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        let textView = KeyInterceptingTextView(frame: .zero, textContainer: textContainer)
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.documentView = textView
        
        // Configure text view for code editing
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        // Set initial text from core
        if !core.textStorage.string.isEmpty {
            textView.string = core.textStorage.string
        } else {
            textView.string = "Working Text Editor - Now we can add features incrementally!"
        }
        
        // CRITICAL FIX: Apply color directly to textStorage (textColor property is ignored)
        let fullRange = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
        textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.red, range: fullRange)
        
        // Fix text color visibility
        textView.textColor = NSColor.red  // This gets ignored, but set it anyway
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.red
        
        // Set up delegate for text change notifications
        textView.delegate = context.coordinator
        
        // Connect the key handler
        textView.keyHandler = context.coordinator
        context.coordinator.setTextView(textView)
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Keep this minimal - only update if text changes externally
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Only sync if core was updated externally (not from user typing)
        if textView.string != core.textStorage.string {
            textView.string = core.textStorage.string
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator to handle text changes and add custom functionality
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: MacOSTextEditor
        private var predictionOverlay: PredictionOverlayView?
        private weak var textView: NSTextView?
        
        init(_ parent: MacOSTextEditor) {
            self.parent = parent
        }
        
        func setTextView(_ textView: NSTextView) {
            self.textView = textView
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Sync the current text back to core
            let currentText = textView.string
            if currentText != parent.core.textStorage.string {
                parent.core.textStorage.replaceCharacters(
                    in: NSRange(location: 0, length: parent.core.textStorage.length),
                    with: currentText
                )
            }
            
            // Notify text change
            parent.core.onTextChange?(currentText)
            
            // Update predictions based on current cursor position
            parent.core.updatePredictions(at: textView.selectedRange().location)
            updatePredictionDisplay(for: textView)
        }
        
        // MARK: - Prediction Display
        
        private func updatePredictionDisplay(for textView: NSTextView) {
            if parent.core.showingPrediction && !parent.core.currentPredictions.isEmpty {
                showPredictionOverlay(for: textView)
            } else {
                hidePredictionOverlay()
            }
        }
        
        private func showPredictionOverlay(for textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }
            
            // Calculate position for the prediction overlay
            let insertionPoint = textView.selectedRange().location
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: insertionPoint)
            let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0),
                                                in: textContainer)
            
            // Create or update prediction overlay
            if predictionOverlay == nil {
                predictionOverlay = PredictionOverlayView()
                textView.addSubview(predictionOverlay!)
            }
            
            predictionOverlay?.configure(with: parent.core.currentPredictions)
            
            // Position the overlay to the right of the cursor
            let overlayWidth: CGFloat = 200
            let overlayHeight: CGFloat = 30
            predictionOverlay?.frame = CGRect(
                x: rect.maxX + textView.textContainerInset.width,
                y: rect.minY + textView.textContainerInset.height,
                width: overlayWidth,
                height: overlayHeight
            )
        }
        
        private func hidePredictionOverlay() {
            predictionOverlay?.removeFromSuperview()
            predictionOverlay = nil
        }
        
        // MARK: - Key Handling
        
        func handleKeyDown(with event: NSEvent) -> Bool {
            guard let textView = self.textView else { return false }
            
            switch event.keyCode {
            case 48: // Tab key - accept prediction
                if parent.core.showingPrediction && !parent.core.currentPredictions.isEmpty {
                    acceptPrediction(parent.core.currentPredictions[0], for: textView)
                    return true // Consume the event
                }
            case 53: // Escape key - hide predictions
                if parent.core.showingPrediction {
                    parent.core.hidePredictions()
                    updatePredictionDisplay(for: textView)
                    return true // Consume the event
                }
            default:
                break
            }
            
            return false // Don't consume the event
        }
        
        private func acceptPrediction(_ prediction: String, for textView: NSTextView) {
            guard let predictionRange = parent.core.predictionRange else { return }
            
            // Use NSTextView's built-in text replacement
            if textView.shouldChangeText(in: predictionRange, replacementString: prediction + " ") {
                textView.replaceCharacters(in: predictionRange, with: prediction + " ")
                
                // Move cursor to end of inserted text
                let newLocation = predictionRange.location + prediction.count + 1
                textView.setSelectedRange(NSRange(location: newLocation, length: 0))
                
                // Hide predictions
                parent.core.hidePredictions()
                updatePredictionDisplay(for: textView)
            }
        }
    }
}

#endif
