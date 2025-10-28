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
import Combine

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
    private var arrowIndicator: NSView?
    private var isShowingAbove = false
    private let settings = EditorSettings.shared
    private var settingsObserver: AnyCancellable?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
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
        textField.font = settings.createSuggestionsFont()
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
        updateFont() // Use settings-based font size
        textField.textColor = NSColor.secondaryLabelColor
        textField.alignment = .left
        textField.maximumNumberOfLines = 0 // Allow unlimited lines
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    func configure(with predictions: [PredictionResult], showingAbove: Bool = false) {
        guard !predictions.isEmpty else { 
            textField.stringValue = ""
            return 
        }
        
        self.isShowingAbove = showingAbove
        
        // Show all predictions, each on a separate line, numbered
        let candidateText = predictions.enumerated().map { index, prediction in
            "\(index + 1). \(prediction.word)"
        }.joined(separator: "\n")
        
        textField.stringValue = candidateText
        
        // Adjust shadow direction based on position
        if showingAbove {
            layer?.shadowOffset = CGSize(width: 0, height: -2)
        } else {
            layer?.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
    
    func configure(with predictions: [PredictionResult]) {
        configure(with: predictions, showingAbove: false)
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
    private let settings = EditorSettings.shared
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // CRITICAL: Manual text system setup - this makes text visible in SwiftUI
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
        textView.font = settings.createEditorFont() // Use settings-based font
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
        
        // CRITICAL FIX: Apply color directly to textStorage with manual dark/light mode handling
        let fullRange = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
        
        // Manual color selection since NSColor.labelColor doesn't work in SwiftUI context
        let textColor: NSColor
        textColor = .labelColor
        /*
        if NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            textColor = NSColor.white  // Dark mode - white text
        } else {
            textColor = NSColor.black  // Light mode - black text
        } */
        
        textView.textStorage?.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        
        // Fix text color visibility
        textView.textColor = textColor  // This gets ignored, but set it anyway
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = textColor
        
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
        private var cachedMaxCandidateWidth: CGFloat = 0
        private var lastEditorWidth: CGFloat = 0
        private let settings = EditorSettings.shared
        private var settingsObserver: AnyCancellable?
        
        init(_ parent: MacOSTextEditor) {
            self.parent = parent
            super.init()
            setupSettingsObserver()
        }
        
        deinit {
            settingsObserver?.cancel()
        }
        
        private func setupSettingsObserver() {
            settingsObserver = settings.$suggestionsFontSize
                .combineLatest(settings.$fontFamily, settings.$editorFontSize)
                .sink { [weak self] _, _, _ in
                    self?.refreshMaxCandidateWidth()
                    self?.updateTextViewFont()
                    self?.updatePredictionDisplay(for: self?.textView)
                }
        }
        
        private func updateTextViewFont() {
            guard let textView = self.textView else { return }
            textView.font = settings.createEditorFont()
            
            // Update the text storage font attributes to match
            let fullRange = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
            if fullRange.length > 0 {
                textView.textStorage?.addAttribute(.font, value: settings.createEditorFont(), range: fullRange)
            }
        }
        
        func setTextView(_ textView: NSTextView) {
            self.textView = textView
            
            // Calculate the cached max candidate width once during initialization
            calculateMaxCandidateWidth(editorWidth: textView.visibleRect.width)
            
            // Pass delete key handling to text view when we don't handle it
            parent.core.onBackspacePassThrough = { [weak textView] in
                textView?.deleteBackward(nil)
            }
        }
        
        /// Calculate maximum candidate window width once and cache it
        private func calculateMaxCandidateWidth(editorWidth: CGFloat) {
            let fontSize = settings.getSuggestionsFontPointSize()
            let requiredWidth = parent.core.calculateMinimumCandidateWidth(fontSize: fontSize)
            let preferredWidth = editorWidth * 0.4
            
            cachedMaxCandidateWidth = max(preferredWidth, requiredWidth)
            lastEditorWidth = editorWidth
        }
        
        /// Get the cached max candidate width, recalculating if editor width changed significantly
        private func getMaxCandidateWidth(editorWidth: CGFloat) -> CGFloat {
            // Recalculate if editor width changed by more than 50px (window resize)
            if abs(editorWidth - lastEditorWidth) > 50 {
                calculateMaxCandidateWidth(editorWidth: editorWidth)
            }
            return cachedMaxCandidateWidth
        }
        
        /// Force recalculation of max candidate width (call when user changes font preferences)
        func refreshMaxCandidateWidth() {
            guard let textView = self.textView else { return }
            calculateMaxCandidateWidth(editorWidth: textView.visibleRect.width)
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Check if this is an external change (paste, programmatic change, etc.)
            let currentText = textView.string
            if currentText != parent.core.textStorage.string {
                // External change detected - commit any active composition
                if parent.core.isCurrentlyComposing {
                    parent.core.forceCommitComposition()
                }
                
                // Sync the external change to core
                parent.core.textStorage.replaceCharacters(
                    in: NSRange(location: 0, length: parent.core.textStorage.length),
                    with: currentText
                )
                
                // Notify text change
                parent.core.onTextChange?(currentText)
            }
            
            // Update predictions for non-composition changes
            if !parent.core.isCurrentlyComposing {
                parent.core.updatePredictions(at: textView.selectedRange().location)
            }
            updatePredictionDisplay(for: textView)
        }

        
        // MARK: - Prediction Display
        
        private func updatePredictionDisplay(for textView: NSTextView?) {
            guard let textView = textView else { return }
            if parent.core.showingPrediction && !parent.core.currentPredictions.isEmpty {
                showPredictionOverlay(for: textView)
            } else {
                hidePredictionOverlay()
            }
        }
        
        private func showPredictionOverlay(for textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }
            
            // Get composition rect or fallback to cursor position
            let compositionRect: CGRect
            if let rect = parent.core.getCompositionRect(
                layoutManager: layoutManager,
                textContainer: textContainer,
                textContainerInset: textView.textContainerInset
            ) {
                compositionRect = rect
            } else {
                // Fallback to cursor position
                let insertionPoint = textView.selectedRange().location
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: insertionPoint)
                let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 0),
                                                    in: textContainer)
                compositionRect = CGRect(
                    x: rect.origin.x + textView.textContainerInset.width,
                    y: rect.origin.y + textView.textContainerInset.height,
                    width: max(rect.width, 10),
                    height: rect.height
                )
            }
            
            // Get editor bounds (text view's visible rect)
            let editorBounds = textView.visibleRect
            
            // Get cached maximum candidate window width (efficient - no recalculation)
            let maxCandidateWidth = getMaxCandidateWidth(editorWidth: editorBounds.width)
            
            // Calculate candidate window size based on content
            let candidateWindowSize = parent.core.calculateCandidateWindowSize(
                for: parent.core.currentPredictions,
                fontSize: settings.getSuggestionsFontPointSize(),
                maxWidth: maxCandidateWidth
            )
            
            // Calculate optimal position using the core's positioning logic
            let positionResult = parent.core.calculateCandidateWindowPosition(
                editorBounds: editorBounds,
                compositionRect: compositionRect,
                candidateWindowSize: candidateWindowSize
            )
            
            // Create or update prediction overlay
            if predictionOverlay == nil {
                predictionOverlay = PredictionOverlayView()
                textView.addSubview(predictionOverlay!)
            }
            
            predictionOverlay?.configure(with: parent.core.currentPredictions, showingAbove: positionResult.shouldShowAbove)
            
            // Apply the calculated position
            predictionOverlay?.frame = CGRect(
                origin: positionResult.position,
                size: candidateWindowSize
            )
            
            // Optional: Add visual indication if showing above
            if positionResult.shouldShowAbove {
                // Could add an arrow or different styling to indicate it's above
                print("📍 Candidate window positioned above composition (bottom overflow detected)")
            } else {
                print("📍 Candidate window positioned below composition")
            }
        }
        
        private func hidePredictionOverlay() {
            predictionOverlay?.removeFromSuperview()
            predictionOverlay = nil
        }
        
        // MARK: - Key Handling
        
        func handleKeyDown(with event: NSEvent) -> Bool {
            guard let textView = self.textView else { return false }
            
            let currentRange = textView.selectedRange()
            
            // Handle special keys first
            switch event.keyCode {
            case 48: // Tab key - accept prediction
                if parent.core.showingPrediction && !parent.core.currentPredictions.isEmpty {
                    parent.core.acceptPrediction(parent.core.currentPredictions[0])
                    updateTextViewFromCore(textView)
                    return true // Consume the event
                }
            case 53: // Escape key - handle escape
                parent.core.handleEscapeKey()
                updatePredictionDisplay(for: textView)
                return true // Consume the event
            case 36: // Return key - commit composition and insert newline
                if parent.core.isCurrentlyComposing {
                    parent.core.forceCommitComposition()
                    updateTextViewFromCore(textView)
                }
                // Let the return key be processed normally
                return false
                /*
            case 49: // Space key - commit composition and insert space
                if parent.core.isCurrentlyComposing {
                    parent.core.forceCommitComposition()
                    updateTextViewFromCore(textView)
                }
                // Let the space key be processed normally
                return false */
            default:
                break
            }
            
            // Handle character input for composition/translation
            if let characters = event.characters, !characters.isEmpty {
                for character in characters {
                    let charString = String(character)
                    let keyCode = Int32(event.keyCode)
                    let isShifted = event.modifierFlags.contains(.shift)
                    
                    // Use the new composition-aware processing
                    parent.core.processKeyInput(charString, keyCode: keyCode, isShifted: isShifted, at: currentRange)
                    
                    // Update the text view
                    updateTextViewFromCore(textView)
                    updatePredictionDisplay(for: textView)
                    
                    return true // Consume the event to prevent default handling
                }
            }
            
            return false // Don't consume the event
        }
        
        private func updateTextViewFromCore(_ textView: NSTextView) {
            // Update text view content from core
            let coreText = parent.core.textStorage.string
            if textView.string != coreText {
                textView.string = coreText
                
                // Apply the attributed string to maintain formatting
                textView.textStorage?.setAttributedString(parent.core.textStorage)
            }
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
