//
//  ContextAwareTextView+macOS.swift
//  ContextAwareTextView
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

#if os(macOS)
import SwiftUI
import AppKit
import Combine
//import CAnjalKeyTranslator

// MARK: - SwiftUI ViewRepresentable

public struct ContextAwareTextView: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var viewModel: EditorViewModel
    
    // Configuration
    var font: NSFont
    var isEditable: Bool
    var allowsUndo: Bool
    var isRichText: Bool
    
    public init(
        text: Binding<String>,
        viewModel: EditorViewModel,
        font: NSFont = NSFont.systemFont(ofSize: 14),
        isEditable: Bool = true,
        allowsUndo: Bool = true,
        isRichText: Bool = false
    ) {
        self._text = text
        self.viewModel = viewModel
        self.font = font
        self.isEditable = isEditable
        self.allowsUndo = allowsUndo
        self.isRichText = isRichText
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = ContextAwareNSTextView()
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        // Configure text view
        textView.isEditable = isEditable
        textView.allowsUndo = allowsUndo
        textView.isRichText = isRichText
        textView.font = font
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.usesRuler = false
        
        // Set up the coordinator
        let coordinator = context.coordinator
        textView.delegate = coordinator
        coordinator.textView = textView
        coordinator.viewModel = viewModel
        
        // Create and configure the candidate window
        coordinator.setupCandidateWindow()
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ContextAwareNSTextView else { return }
        
        // Update text if it changed externally
        if textView.string != text {
            textView.string = text
        }
        
        // Update font if needed
        if textView.font != font {
            textView.font = font
        }
        
        // Update candidates display
        context.coordinator.updateCandidatesDisplay()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
}

// MARK: - Custom NSTextView

class ContextAwareNSTextView: NSTextView {
    
    override func keyDown(with event: NSEvent) {
        // Let the delegate handle key events first
        if let delegate = delegate as? ContextAwareTextView.Coordinator,
           delegate.handleKeyEvent(event) {
            return
        }
        
        // Fall back to default handling
        super.keyDown(with: event)
    }
    
    override func insertText(_ insertString: Any) {
        // Let the delegate handle text insertion
        if let delegate = delegate as? ContextAwareTextView.Coordinator,
           delegate.handleTextInsertion(insertString) {
            return
        }
        
        // Fall back to default handling
        super.insertText(insertString)
    }
    
    override func deleteBackward(_ sender: Any?) {
        // Let the delegate handle deletion
        if let delegate = delegate as? ContextAwareTextView.Coordinator,
           delegate.handleBackwardDeletion() {
            return
        }
        
        // Fall back to default handling
        super.deleteBackward(sender)
    }
}

// MARK: - Coordinator

extension ContextAwareTextView {
    public class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var viewModel: EditorViewModel?
        weak var textView: ContextAwareNSTextView?
        
        // Candidate window
        private var candidateWindow: NSWindow?
        private var candidateTableView: NSTableView?
        
        // Key translation state
        private var translator: SwiftKeyTranslator?
        private var predictor: Predictor?
        
        init(text: Binding<String>) {
            self._text = text
            super.init()
            setupTranslationServices()
        }
        
        private func setupTranslationServices() {
            // Initialize key translator
            translator = SwiftKeyTranslator(
                language: LANG_TAMIL, // You can make this configurable
                layout: .anjal
            )
            
            // Initialize predictor
            do {
                predictor = try Predictor()
                // You'll need to provide the path to your trie file
                // try predictor?.initialize(triePath: "path/to/your/trie/file")
            } catch {
                print("Failed to initialize predictor: \(error)")
            }
        }
        
        // MARK: - Key Event Handling
        
        func handleKeyEvent(_ event: NSEvent) -> Bool {
            guard let textView = textView,
                  let translator = translator else { return false }
            
            let keyCode = Int32(event.keyCode)
            let shifted = event.modifierFlags.contains(.shift)
            
            // Special key handling
            if event.modifierFlags.contains(.command) {
                return false // Let system handle command keys
            }
            
            // Handle candidate selection
            if viewModel?.isShowingCandidates == true {
                if handleCandidateSelection(event) {
                    return true
                }
            }
            
            // Translate the key
            let translatedText = translator.translateKey(keyCode: keyCode, shifted: shifted)
            
            if !translatedText.isEmpty {
                // Insert the translated text
                insertTranslatedText(translatedText)
                updatePredictions()
                return true
            }
            
            // Handle space and punctuation to commit composition
            if event.charactersIgnoringModifiers == " " ||
               event.charactersIgnoringModifiers?.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil {
                translator.terminateComposition()
                viewModel?.resetComposition()
            }
            
            return false
        }
        
        func handleTextInsertion(_ insertString: Any) -> Bool {
            guard let string = insertString as? String else { return false }
            
            // Handle regular text insertion
            insertText(string)
            updatePredictions()
            return true
        }
        
        func handleBackwardDeletion() -> Bool {
            guard let textView = textView else { return false }
            
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                // Delete selected text
                textView.replaceCharacters(in: selectedRange, with: "")
            } else if selectedRange.location > 0 {
                // Delete one character backward
                let deleteRange = NSRange(location: selectedRange.location - 1, length: 1)
                textView.replaceCharacters(in: deleteRange, with: "")
            }
            
            updateTextBinding()
            updatePredictions()
            return true
        }
        
        // MARK: - Text Manipulation
        
        private func insertTranslatedText(_ translatedText: String) {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange()
            textView.replaceCharacters(in: selectedRange, with: translatedText)
            
            updateTextBinding()
        }
        
        private func insertText(_ string: String) {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange()
            textView.replaceCharacters(in: selectedRange, with: string)
            
            updateTextBinding()
        }
        
        private func updateTextBinding() {
            guard let textView = textView else { return }
            
            DispatchQueue.main.async {
                self.text = textView.string
            }
        }
        
        // MARK: - Prediction
        
        private func updatePredictions() {
            guard let textView = textView,
                  let predictor = predictor else { return }
            
            let cursorPosition = textView.selectedRange().location
            let textBeforeCursor = String(textView.string.prefix(cursorPosition))
            let textAfterCursor = String(textView.string.suffix(from: textView.string.index(textView.string.startIndex, offsetBy: cursorPosition)))
            
            viewModel?.updatePredictions(textBefore: textBeforeCursor, textAfter: textAfterCursor)
        }
        
        // MARK: - Candidate Window
        
        func setupCandidateWindow() {
            let windowRect = NSRect(x: 0, y: 0, width: 300, height: 150)
            candidateWindow = NSWindow(
                contentRect: windowRect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            candidateWindow?.isOpaque = false
            candidateWindow?.backgroundColor = NSColor.clear
            candidateWindow?.hasShadow = true
            candidateWindow?.level = .floating
            
            // Create table view for candidates
            let scrollView = NSScrollView(frame: windowRect)
            let tableView = NSTableView()
            
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("candidate"))
            column.title = "Candidates"
            column.width = 280
            tableView.addTableColumn(column)
            
            tableView.headerView = nil
            tableView.delegate = self
            tableView.dataSource = self
            
            scrollView.documentView = tableView
            scrollView.hasVerticalScroller = true
            
            candidateWindow?.contentView = scrollView
            candidateTableView = tableView
        }
        
        func updateCandidatesDisplay() {
            guard let viewModel = viewModel else { return }
            
            if viewModel.isShowingCandidates && !viewModel.candidates.isEmpty {
                showCandidateWindow()
                candidateTableView?.reloadData()
                
                // Select the current candidate
                if viewModel.selectedCandidateIndex >= 0 {
                    candidateTableView?.selectRowIndexes(
                        IndexSet(integer: viewModel.selectedCandidateIndex),
                        byExtendingSelection: false
                    )
                }
            } else {
                hideCandidateWindow()
            }
        }
        
        private func showCandidateWindow() {
            guard let candidateWindow = candidateWindow,
                  let textView = textView else { return }
            
            // Position the candidate window near the cursor
            let cursorRect = textView.firstRect(for: textView.selectedRange(), actualRange: nil)
            let windowRect = NSRect(
                x: cursorRect.maxX,
                y: cursorRect.minY - candidateWindow.frame.height,
                width: candidateWindow.frame.width,
                height: candidateWindow.frame.height
            )
            
            candidateWindow.setFrame(windowRect, display: true)
            candidateWindow.orderFront(nil)
        }
        
        private func hideCandidateWindow() {
            candidateWindow?.orderOut(nil)
        }
        
        // MARK: - Candidate Selection
        
        private func handleCandidateSelection(_ event: NSEvent) -> Bool {
            guard let viewModel = viewModel else { return false }
            
            switch event.keyCode {
            case 125: // Down arrow
                viewModel.selectNextCandidate()
                candidateTableView?.selectRowIndexes(
                    IndexSet(integer: viewModel.selectedCandidateIndex),
                    byExtendingSelection: false
                )
                return true
                
            case 126: // Up arrow
                viewModel.selectPreviousCandidate()
                candidateTableView?.selectRowIndexes(
                    IndexSet(integer: viewModel.selectedCandidateIndex),
                    byExtendingSelection: false
                )
                return true
                
            case 36: // Return/Enter
                if let newCursorPosition = viewModel.insertSelectedCandidate(at: textView?.selectedRange().location ?? 0) {
                    updateTextBinding()
                    textView?.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
                }
                return true
                
            case 53: // Escape
                viewModel.hideCandidates()
                return true
                
            default:
                return false
            }
        }
        
        // MARK: - NSTextViewDelegate
        
        public func textDidChange(_ notification: Notification) {
            updateTextBinding()
            updatePredictions()
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate

extension ContextAwareTextView.Coordinator: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel?.candidates.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let viewModel = viewModel,
              row < viewModel.candidates.count else { return nil }
        
        let identifier = NSUserInterfaceItemIdentifier("CandidateCell")
        
        let cellView = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView
            ?? NSTableCellView()
        
        if cellView.textField == nil {
            let textField = NSTextField()
            textField.isBezeled = false
            textField.isEditable = false
            textField.backgroundColor = NSColor.clear
            cellView.textField = textField
            cellView.addSubview(textField)
            
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -8),
                textField.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 4),
                textField.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -4)
            ])
        }
        
        cellView.textField?.stringValue = viewModel.candidates[row]
        cellView.identifier = identifier
        
        // Highlight selected candidate
        if row == viewModel.selectedCandidateIndex {
            cellView.wantsLayer = true
            cellView.layer?.backgroundColor = NSColor.selectedControlColor.cgColor
            cellView.textField?.textColor = NSColor.selectedControlTextColor
        } else {
            cellView.layer?.backgroundColor = NSColor.clear.cgColor
            cellView.textField?.textColor = NSColor.controlTextColor
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        viewModel?.selectedCandidateIndex = row
        return true
    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        if let index = proposedSelectionIndexes.first {
            viewModel?.selectedCandidateIndex = index
        }
        return proposedSelectionIndexes
    }
}

#endif
