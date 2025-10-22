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
        print("🔧 Setting up ContextAwareTextView")
        
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
        
        print("🔧 ContextAwareTextView setup complete - isEditable: \(isEditable), acceptsFirstResponder: \(acceptsFirstResponder)")
    }
    
    // MARK: - Key Event Handling
    
    public override var acceptsFirstResponder: Bool {
        return true
    }
    
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        print("📍 Text view became first responder: \(result)")
        return result
    }
    
    public override func resignFirstResponder() -> Bool {
        print("📍 Text view resigning first responder")
        return super.resignFirstResponder()
    }
    
    public override func mouseDown(with event: NSEvent) {
        print("🖱️ Mouse down in text view")
        print("🖱️ Current first responder: \(window?.firstResponder?.className ?? "none")")
        print("🖱️ Text view can become first responder: \(acceptsFirstResponder)")
        print("🖱️ Text view is editable: \(isEditable)")
        print("🖱️ Text view window: \(window != nil ? "exists" : "nil")")
        
        super.mouseDown(with: event)
        
        // Aggressively ensure we become first responder and the window becomes key
        if let window = window {
            print("🖱️ Window is key before: \(window.isKeyWindow)")
            
            // Force window to be key first
            if !window.isKeyWindow {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            
            // Then make this text view the first responder
            if window.firstResponder != self {
                print("🖱️ Attempting to make text view first responder...")
                let success = window.makeFirstResponder(self)
                print("🖱️ Make first responder result: \(success)")
                print("🖱️ New first responder: \(window.firstResponder?.className ?? "none")")
            } else {
                print("🖱️ Text view is already first responder")
            }
            
            print("🖱️ Window is key after: \(window.isKeyWindow)")
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Try to become first responder when awakened
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let window = self?.window, window.isKeyWindow {
                window.makeFirstResponder(self)
            }
        }
    }
    
    public override func keyDown(with event: NSEvent) {
        print("⌨️ Key down received in ContextAwareTextView!")
        print("⌨️ Key: \(event.characters ?? "nil"), code: \(event.keyCode)")
        print("⌨️ First responder: \(window?.firstResponder?.className ?? "none")")
        print("⌨️ Is first responder: \(window?.firstResponder === self)")
        
        // Prevent re-entry
        guard !isProcessingKeyEvent else {
            super.keyDown(with: event)
            return
        }
        
        // Only try to handle specific keys that we want to translate
        // For normal typing, let the system handle it
        if shouldHandleKeyEvent(event) {
            print("⌨️ Handling key event with custom logic")
            isProcessingKeyEvent = true
            defer { isProcessingKeyEvent = false }
            
            // Try to handle with our custom logic
            if handleKeyEvent(event) {
                return
            }
        } else {
            print("⌨️ Letting system handle key event")
        }
        
        // Fall back to default behavior for all other keys
        super.keyDown(with: event)
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        print("🎯 performKeyEquivalent called: \(event.characters ?? "nil")")
        return super.performKeyEquivalent(with: event)
    }
    
    public override func keyUp(with event: NSEvent) {
        print("⌨️ Key up received: \(event.characters ?? "nil")")
        super.keyUp(with: event)
    }
    
    public override func flagsChanged(with event: NSEvent) {
        print("🚩 Flags changed: \(event.modifierFlags)")
        super.flagsChanged(with: event)
    }
    
    public override func insertText(_ insertString: Any) {
        print("📝 insertText called: \(insertString)")
        super.insertText(insertString)
    }
    
    private func shouldHandleKeyEvent(_ event: NSEvent) -> Bool {
        // For now, only try to handle keys when we have a translator
        // and the key is not a normal typing character
        guard let _ = viewModel?.translator else { return false }
        
        // Don't intercept normal character input
        if let characters = event.characters, !characters.isEmpty {
            let character = characters.first!
            // Allow normal printable characters to go through the normal text input system
            if character.isLetter || character.isNumber || character.isPunctuation || character.isSymbol || character.isWhitespace {
                return false
            }
        }
        
        // Handle special keys or modified keys
        let hasModifiers = !event.modifierFlags.intersection([.command, .option, .control]).isEmpty
        return hasModifiers
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

