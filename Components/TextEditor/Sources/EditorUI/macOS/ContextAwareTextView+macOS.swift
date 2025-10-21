// Sources/EditorUI/macOS/ContextAwareTextView+macOS.swift
#if os(macOS)
import AppKit
import EditorCore

/// macOS-specific text view with keyboard interception
public class ContextAwareTextView: NSTextView {
    
    // MARK: - Properties
    
    public weak var viewModel: EditorViewModel?
    
    private var isProcessingKeyEvent = false
    
    // MARK: - Initialization
    
    public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        setupTextView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // Basic setup
        isRichText = false
        isEditable = true
        isSelectable = true
        allowsUndo = true
        font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        
        // Enable automatic quote/dash substitution if needed
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        
        // Layout
        isVerticallyResizable = true
        isHorizontallyResizable = false
        textContainerInset = NSSize(width: 10, height: 10)
        
        // Appearance
        drawsBackground = true
        backgroundColor = .textBackgroundColor
    }
    
    // MARK: - Key Event Handling
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
    }
    
    public override func keyDown(with event: NSEvent) {
        // Prevent re-entry
        guard !isProcessingKeyEvent else {
            super.keyDown(with: event)
            return
        }
        
        isProcessingKeyEvent = true
        defer { isProcessingKeyEvent = false }
        
        // Try to handle with our custom logic
        if handleKeyEvent(event) {
            return
        }
        
        // Fall back to default behavior
        super.keyDown(with: event)
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let viewModel = viewModel else {
            print("⚠️ No viewModel")
            return false
        }
        
        let keyCode = Int(event.keyCode)
        let shifted = event.modifierFlags.contains(.shift)
        
        print("🔑 Key event - code: \(keyCode), char: \(event.characters ?? "nil")")
        
        // Get cursor position and context
        let cursorPosition = selectedRange().location
        guard cursorPosition != NSNotFound else {
            print("⚠️ Invalid cursor position")
            return false
        }
        
        let currentText = string
        let textBefore = String(currentText.prefix(cursorPosition))
        let textAfter = String(currentText.suffix(from: currentText.index(
            currentText.startIndex,
            offsetBy: cursorPosition
        )))
        
        // Try key translation
        if let result = viewModel.translateKey(keyCode: keyCode, shifted: shifted) {
            applyTranslation(result, at: cursorPosition)
            
            // Update predictions for Phase 2
            // viewModel.updatePredictions(
            //     textBefore: textBefore + result.text,
            //     textAfter: textAfter
            // )
            
            return true
        }
        
        return false
    }
    
    private func applyTranslation(_ result: TranslationResult, at position: Int) {
        guard let viewModel = viewModel else { return }
        
        // Apply the translation through view model
        let newPosition = viewModel.applyTranslation(result, cursorPosition: position)
        
        // Update NSTextView's text
        string = viewModel.text
        
        // Update cursor
        setSelectedRange(NSRange(location: newPosition, length: 0))
        
        // Notify of changes
        didChangeText()
    }
    
    // MARK: - Text Change Notifications
    
    public override func didChangeText() {
        super.didChangeText()
        
        // Sync to view model if text was changed by other means
        if let viewModel = viewModel, !isProcessingKeyEvent {
            viewModel.text = string
        }
    }
    
    // MARK: - Public Interface
    
    /// Sync view model text to text view
    public func updateText(_ text: String) {
        guard string != text else { return }
        
        let currentPosition = selectedRange().location
        string = text
        
        // Restore cursor position if possible
        let newPosition = min(currentPosition, text.count)
        setSelectedRange(NSRange(location: newPosition, length: 0))
    }
    
    /// Set cursor position programmatically
    public func setCursor(at position: Int) {
        let safePosition = min(max(0, position), string.count)
        setSelectedRange(NSRange(location: safePosition, length: 0))
    }
}

#endif

