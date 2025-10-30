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

/// Manages window-level overlays for candidate windows
class WindowOverlayManager {
    static let shared = WindowOverlayManager()
    private init() {}
    
    private var currentOverlay: WindowOverlayView?
    
    func showOverlay(
        predictions: [PredictionResult],
        at windowPosition: CGPoint,
        size: CGSize,
        showingAbove: Bool,
        in window: UIWindow,
        onTap: @escaping (PredictionResult) -> Void
    ) {
        // Simple cleanup
        hideOverlay()
        
        // Create and show overlay
        let overlay = WindowOverlayView()
        overlay.configure(with: predictions, showingAbove: showingAbove)
        overlay.onTap = onTap
        overlay.frame = CGRect(origin: windowPosition, size: size)
        
        window.addSubview(overlay)
        currentOverlay = overlay
        
        print("SIMPLE_DEBUG: Created overlay at Y: \(windowPosition.y)")
    }
    
    func hideOverlay() {
        currentOverlay?.removeFromSuperview()
        currentOverlay = nil
    }
    
    func updateOverlayPosition(_ position: CGPoint, size: CGSize) {
        currentOverlay?.frame = CGRect(origin: position, size: size)
    }
}

/// Window-level overlay view for predictions
class WindowOverlayView: UIView {
    private let label = UILabel()
    private let backgroundView = UIView()
    private let settings = EditorSettings.shared
    private var settingsObserver: AnyCancellable?
        
    var onTap: ((PredictionResult) -> Void)?
    private var currentPrediction: PredictionResult?
    
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
        backgroundView.layer.shadowOpacity = 0.2
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 8
        
        addSubview(backgroundView)
        
        // Setup label
        updateFont() // Use settings-based font size
        label.textColor = UIColor.systemGray
        label.textAlignment = .left
        label.numberOfLines = 0 // Allow unlimited lines
        
        backgroundView.addSubview(label)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Make sure overlay appears above other content
        layer.zPosition = 1000
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
        if let prediction = currentPrediction {
            onTap?(prediction)
        }
    }
    
    func configure(with predictions: [PredictionResult], showingAbove: Bool = false) {
        guard !predictions.isEmpty else {
            currentPrediction = nil
            label.text = ""
            return
        }
        
        currentPrediction = predictions.first
        
        // Show all predictions, each on a separate line, numbered
        let candidateText = predictions.enumerated().map { index, prediction in
            "\(index + 1). \(prediction.word)"
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

/// Custom UITextView for iOS with key interception and prediction support
class CustomUITextView: UITextView, UITextViewDelegate {
    weak var editorCore: TextEditorCore?
    private var keyboardObserver: NSObjectProtocol?
    private var cachedMaxCandidateWidth: CGFloat = 0
    private var lastEditorWidth: CGFloat = 0
    private let settings = EditorSettings.shared
    private var settingsObserver: AnyCancellable?
    
    // Current word highlighting
    var highlightCurrentWord: Bool = true
    private var wordHighlightLayer: CALayer?
    
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
        // Clean up window overlay
        WindowOverlayManager.shared.hideOverlay()
        
        // Clean up word highlight layer
        wordHighlightLayer?.removeFromSuperlayer()
        
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
                // ONLY refresh display for font changes - don't regenerate candidates
                // This will also update word highlighting
                self?.refreshPredictionDisplayOnly()
            }
    }
    
    private func updateEditorFont() {
        let newFont = settings.createEditorFont()
        font = newFont
        
        // Update both UITextView's textStorage AND the editorCore's textStorage
        let fullRange = NSRange(location: 0, length: textStorage.length)
        if fullRange.length > 0 {
            textStorage.addAttribute(.font, value: newFont, range: fullRange)
        }
        
        // ALSO update the editorCore's textStorage so it doesn't overwrite with old font
        if let editorCore = editorCore {
            let coreRange = NSRange(location: 0, length: editorCore.textStorage.length)
            if coreRange.length > 0 {
                editorCore.textStorage.addAttribute(.font, value: newFont, range: coreRange)
            }
        }
    }
    /*
    private func updateEditorFont() {
        font = settings.createEditorFont()
    } */
    
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
        
        // Set up scroll observers to update predictions when scrolling
        setupScrollObservers()
    }
    
    private func setupKeyboardObservers() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Only refresh display when keyboard shows - don't regenerate candidates
            // This is mainly for repositioning when onscreen keyboard appears/disappears
            self?.refreshPredictionDisplayOnly()
        }
    }
    
    private func setupScrollObservers() {
        // Override the scrollViewDidScroll method by setting ourselves as the delegate
        // Note: We need to be careful not to interfere with existing delegate behavior
        delegate = self
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
    
    /// Get the visible editor bounds that accounts for scrolling within the text view
    private func getVisibleEditorBounds() -> CGRect {
        // UITextView inherits from UIScrollView, so we need to calculate the visible content area
        // The key insight: compositionRect is in text coordinates, but we need to return
        // a rect that represents the visible viewport for positioning calculations
        
        // For UITextView, the visible area is always the bounds size, but positioned
        // at the current scroll offset in the content coordinate system
        let visibleRect = CGRect(
            x: 0, // Always start at 0 for the viewport
            y: 0, // Always start at 0 for the viewport  
            width: bounds.width,
            height: bounds.height
        )
        
        return visibleRect
    }
    
    /// Check if font enforcement is needed (optimization to avoid unnecessary font updates)
    private func shouldEnforceFont() -> Bool {
        // Only enforce font if we detect the text doesn't have the right font
        // Check a sample of the text (first character) to see if font is correct
        if textStorage.length > 0 {
            let currentFont = settings.createEditorFont()
            let actualFont = textStorage.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
            return actualFont?.pointSize != currentFont.pointSize || actualFont?.familyName != currentFont.familyName
        }
        return false
    }
    
    /// Sync the text view content from the core's text storage
    func syncFromCore() {
        guard let editorCore = editorCore else { return }
        
        // Update content first
        attributedText = editorCore.textStorage
        
        // OPTIMIZATION: Only enforce font if we detect font inconsistency
        // This is much cheaper than always updating
        if shouldEnforceFont() {
            let currentFont = settings.createEditorFont()
            let fullRange = NSRange(location: 0, length: textStorage.length)
            if fullRange.length > 0 {
                textStorage.addAttribute(.font, value: currentFont, range: fullRange)
                textStorage.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
            }
        }
        
        // Only manage cursor position when composing
        if editorCore.isCurrentlyComposing, let compRange = editorCore.currentCompositionRange {
            let newCursorPosition = compRange.location + compRange.length
            let newRange = NSRange(location: newCursorPosition, length: 0)
            selectedRange = newRange
        }
        
        // COMPOSITION-AWARE: Only update display if we're actively composing
        // This prevents redundant updates when core syncs non-composition changes
        if editorCore.isCurrentlyComposing {
            updatePredictionDisplay()
        } else {
            // Hide predictions if we're not composing
            hidePredictionOverlay()
        }
    }
    
    // MARK: - Composition Detection
    
    /// Check if we should auto-suggest next word after accepting a suggestion
    private func shouldAutoPredictNextWord() -> Bool {
        return settings.autoPredictNextWord
    }
    
    /// Check if onscreen keyboard is currently visible
    private func isOnscreenKeyboardVisible() -> Bool {
        // Simple heuristic: if we're first responder but don't detect external keyboard,
        // assume onscreen keyboard is visible
        return isFirstResponder && !hasExternalKeyboard()
    }
    
    /// Check if external (hardware) keyboard is connected
    private func hasExternalKeyboard() -> Bool {
        // On iOS, we can't directly detect hardware keyboards
        // But we can use heuristics:
        // Simple approach: assume external keyboard if text view can receive key commands
        // This is a reasonable heuristic for our use case
        return true // For now, assume external keyboard to enable our candidate system
    }
    
    /// Check if composition state changed and candidates should be updated
    private func shouldUpdateCandidates() -> Bool {
        guard let editorCore = editorCore else { return false }
        
        let onscreenVisible = isOnscreenKeyboardVisible()
        let composing = editorCore.isCurrentlyComposing
        
        // Debug logging for composition state changes
        print("🔍 shouldUpdateCandidates: onscreen=\(onscreenVisible), composing=\(composing)")
        
        // Don't show candidates if onscreen keyboard is visible
        if onscreenVisible {
            print("🔍 Blocking candidates: onscreen keyboard visible")
            return false
        }
        
        // Only update candidates if we're actively composing
        if !composing {
            print("🔍 Blocking candidates: not actively composing")
            return false
        }
        
        print("🔍 ✅ Allowing candidates: external keyboard + composing")
        return true
    }
    
    /// Check if we should hide candidates (scroll, escape, etc.)
    private func shouldHideCandidates(reason: String) -> Bool {
        print("🔍 Checking hide candidates for reason: \(reason)")
        return true // For now, always allow hiding
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
            
            // Check user preference for auto-suggesting next word
            if shouldAutoPredictNextWord() {
                // Wait a brief moment then check for next word suggestions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    // Use debounced update for auto-suggest next word
                    self?.editorCore?.requestDebouncedPredictionUpdate(at: self?.selectedRange.location ?? 0)
                    self?.updatePredictionDisplay()
                }
            }
        }
    }
    
    // MARK: - Prediction Display
    
    /// Refresh prediction display without regenerating candidates (for font/layout changes)
    func refreshPredictionDisplayOnly() {
        guard let editorCore = editorCore else { return }
        
        // Only refresh display if we're currently showing predictions
        if editorCore.showingPrediction && 
           !editorCore.currentPredictions.isEmpty && 
           shouldUpdateCandidates() {
            showPredictionOverlay()
        } else {
            hidePredictionOverlay()
        }
        
        // Update word highlight when display is refreshed
        updateWordHighlight()
    }
    
    func updatePredictionDisplay() {
        guard let editorCore = editorCore else { return }
        
        // Only show predictions if we're actively composing and external keyboard is connected
        if shouldUpdateCandidates() && 
           editorCore.showingPrediction && 
           !editorCore.currentPredictions.isEmpty {
            showPredictionOverlay()
        } else {
            hidePredictionOverlay()
        }
        
        // Update word highlight when candidate window is shown/hidden
        updateWordHighlight()
    }
    
    private func showPredictionOverlay() {
        guard let editorCore = editorCore,
              let window = self.window else { return }
        
        // Get composition rect or fallback to cursor position
        let rawCompositionRect: CGRect
        if let rect = editorCore.getCompositionRect(
               layoutManager: layoutManager,
               textContainer: textContainer,
               textContainerInset: CGSize(
                   width: textContainerInset.left + textContainerInset.right,
                   height: textContainerInset.top + textContainerInset.bottom
               )
           ) {
            rawCompositionRect = rect
        } else {
            // Fallback to cursor position
            let cursorRect = caretRect(for: selectedTextRange?.start ?? beginningOfDocument)
            rawCompositionRect = cursorRect
        }
        
        // Convert composition rect to view coordinates
        let compositionRectInTextView = CGRect(
            x: rawCompositionRect.origin.x + textContainerInset.left,
            y: rawCompositionRect.origin.y + textContainerInset.top,
            width: rawCompositionRect.width,
            height: rawCompositionRect.height
        )
        
        // Convert to window coordinates
        let compositionRectInWindow = convert(compositionRectInTextView, to: window)
        
        // Calculate candidate window size based on content (using cached width)
        let maxCandidateWidth = getMaxCandidateWidth()
        let candidateWindowSize = editorCore.calculateCandidateWindowSize(
            for: editorCore.currentPredictions,
            fontSize: settings.getSuggestionsFontPointSize(),
            maxWidth: maxCandidateWidth
        )
        
        // Get editor bounds in window coordinates for proper positioning
        let editorBoundsInWindow = convert(bounds, to: window)
        
        // Calculate optimal position using the core's positioning logic
        let positionResult = editorCore.calculateCandidateWindowPosition(
            editorBounds: editorBoundsInWindow,
            compositionRect: compositionRectInWindow,
            candidateWindowSize: candidateWindowSize
        )
        
        // iOS Visual Positioning Adjustment
        // Both platforms calculate -8.0 distance, but iOS needs more aggressive positioning
        // to achieve the same visual appearance as macOS due to coordinate system differences
        var adjustedPosition = positionResult.position
        
        let iOSVisualAdjustment: CGFloat = -20.0 // More aggressive visual adjustment for iOS
        
        if positionResult.shouldShowAbove {
            // When showing above, move up more to get visually closer
            adjustedPosition.y += iOSVisualAdjustment
        } else {
            // When showing below, move up significantly to get closer to composition
            adjustedPosition.y += iOSVisualAdjustment
        }
        
        print("🔍 iOS_POSITIONING: Original Y: \(positionResult.position.y)")
        print("🔍 iOS_POSITIONING: Adjusted Y: \(adjustedPosition.y)")
        print("🔍 iOS_POSITIONING: Visual adjustment: \(iOSVisualAdjustment)")
        
        // Show window-level overlay
        WindowOverlayManager.shared.showOverlay(
            predictions: editorCore.currentPredictions,
            at: adjustedPosition,
            size: candidateWindowSize,
            showingAbove: positionResult.shouldShowAbove,
            in: window
        ) { [weak self] prediction in
            self?.editorCore?.acceptPrediction(prediction)
            self?.syncFromCore()
        }
    }
    
    func hidePredictionOverlay() {
        WindowOverlayManager.shared.hideOverlay()
    }
    
    // MARK: - Current Word Highlighting
    
    /// Update word highlighting when candidate window is shown
    private func updateWordHighlight() {
        guard highlightCurrentWord else {
            removeWordHighlight()
            return
        }
        
        // Get the current word being typed
        guard let currentWordRange = getCurrentWordRange() else {
            removeWordHighlight()
            return
        }
        
        highlightWordAtRange(currentWordRange)
    }
    
    /// Get the range of the word currently being typed
    private func getCurrentWordRange() -> NSRange? {
        let cursorPosition = selectedRange.location
        guard cursorPosition >= 0 && cursorPosition <= textStorage.length else { return nil }
        
        // If we're composing, use the composition range
        if let editorCore = editorCore, editorCore.isCurrentlyComposing,
           let compositionRange = editorCore.currentCompositionRange {
            return compositionRange
        }
        
        // Otherwise, find the word boundaries around the cursor
        let text = textStorage.string
        guard cursorPosition > 0 && cursorPosition <= text.count else { return nil }
        
        let index = text.index(text.startIndex, offsetBy: cursorPosition - 1)
        let range = text.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted, 
                                        options: [.backwards], range: text.startIndex..<text.index(after: index))
        
        if let wordStart = range?.lowerBound {
            let remainingText = text[wordStart...]
            let wordEndRange = remainingText.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines)
            let wordEnd = wordEndRange?.lowerBound ?? text.endIndex
            
            let startOffset = text.distance(from: text.startIndex, to: wordStart)
            let endOffset = text.distance(from: text.startIndex, to: wordEnd)
            
            return NSRange(location: startOffset, length: endOffset - startOffset)
        }
        
        return nil
    }
    
    /// Highlight the word at the specified range
    private func highlightWordAtRange(_ range: NSRange) {
        // Remove existing highlight
        wordHighlightLayer?.removeFromSuperlayer()
        
        // Get the bounding rect for the word
        guard let wordRect = getTextRect(for: range) else { return }
        
        // Create highlight layer
        let highlightLayer = CALayer()
        highlightLayer.frame = wordRect
        highlightLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        highlightLayer.cornerRadius = 4
        highlightLayer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        highlightLayer.borderWidth = 1
        
        // Add to text view
        layer.addSublayer(highlightLayer)
        wordHighlightLayer = highlightLayer
        
        print("📦 iOS Word highlight - range: \(range), rect: \(wordRect)")
    }
    
    /// Get the visual rect for a text range
    private func getTextRect(for range: NSRange) -> CGRect? {
        guard range.location >= 0 && range.location + range.length <= textStorage.length else { return nil }
        
        // Get the glyph range for the character range
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        // Get the bounding rect for the glyph range
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Adjust for text container inset and add some padding
        let adjustedRect = CGRect(
            x: boundingRect.origin.x + textContainerInset.left - 2,
            y: boundingRect.origin.y + textContainerInset.top - 2,
            width: boundingRect.width + 4,
            height: boundingRect.height + 4
        )
        
        return adjustedRect
    }
    
    /// Remove word highlight
    private func removeWordHighlight() {
        wordHighlightLayer?.removeFromSuperlayer()
        wordHighlightLayer = nil
    }
    
    // MARK: - Text Change Handling
    
    func handleTextChange() {
        guard let editorCore = editorCore else { return }
        
        // COMPOSITION-AWARE: Only update predictions if we're actively composing
        // Regular text changes (paste, delete outside composition, etc.) don't need predictions
        if editorCore.isCurrentlyComposing {
            let location = selectedRange.location
            editorCore.updatePredictions(at: location)
            updatePredictionDisplay()
        } else {
            // If not composing, ensure predictions are hidden
            hidePredictionOverlay()
        }
    }
    
    // MARK: - UITextViewDelegate (Scroll Detection)
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Hide candidates immediately when scrolling starts
        if shouldHideCandidates(reason: "scroll") {
            hidePredictionOverlay()
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
                    // No need to call updatePredictionDisplay here - syncFromCore handles it composition-aware
                }
                return false
            }
            
            /*
            if text == "\n" {
                // Handle enter key - commit any composition and insert newline
                parent.core.forceCommitComposition()
                // Let UITextView handle the newline insertion
                return true
            } */
            if text == "\n" {
                // Handle enter key - commit any composition and insert newline
                parent.core.forceCommitComposition()
                
                // IMPORTANT: Update core's textStorage with the newline immediately
                // so it stays in sync with UITextView
                parent.core.textStorage.insert(NSAttributedString(string: "\n"), at: range.location)
                
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
            
            // COMPOSITION-AWARE: Only update predictions when cursor moves WITHIN composition
            // Regular cursor movement (clicking around, arrow keys outside composition) doesn't need predictions
            if parent.core.isCurrentlyComposing {
                let location = textView.selectedRange.location
                parent.core.updatePredictions(at: location)
                
                if let customTextView = textView as? CustomUITextView {
                    customTextView.updatePredictionDisplay()
                }
            } else {
                // If not composing, ensure predictions are hidden
                if let customTextView = textView as? CustomUITextView {
                    customTextView.hidePredictionOverlay()
                }
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            print("📝 Text changed, length: \(textView.text.count)")
            // This will be called after UITextView handles allowed changes
            
            if let customTextView = textView as? CustomUITextView {
                // handleTextChange is now composition-aware
                customTextView.handleTextChange()
            }
        }
    }
}

#endif
