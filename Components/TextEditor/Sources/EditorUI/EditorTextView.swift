// Sources/EditorUI/EditorTextView.swift
import SwiftUI
import EditorCore

#if os(macOS)
import AppKit

/// SwiftUI wrapper for macOS NSTextView
public struct EditorTextView: NSViewRepresentable {
    
    @ObservedObject var viewModel: EditorViewModel
    
    public init(viewModel: EditorViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        print("🏗️ Creating NSScrollView and ContextAwareTextView")
        
        // Create text storage and container
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        // Create text view with frame and container
        let textView = ContextAwareTextView(frame: .zero, textContainer: textContainer)
        textView.viewModel = viewModel
        textView.delegate = context.coordinator
        
        print("🏗️ Text view created - acceptsFirstResponder: \(textView.acceptsFirstResponder)")
        print("🏗️ Text view editable: \(textView.isEditable)")
        
        // Create scroll view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        scrollView.documentView = textView
        
        print("🏗️ Text view added to scroll view")
        print("🏗️ Text view window: \(textView.window != nil ? "exists" : "nil")")
        
        // Make text view first responder after a brief delay to ensure window is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🏗️ Attempting to make first responder (delayed)")
            if let window = textView.window {
                print("📍 Window exists: \(window)")
                print("📍 Window is key: \(window.isKeyWindow)")
                print("📍 Window is main: \(window.isMainWindow)")
                print("📍 Window can become key: \(window.canBecomeKey)")
                
                // Force window to become key
                if !window.isKeyWindow {
                    print("📍 Forcing window to become key...")
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                print("📍 Making text view first responder in makeNSView")
                let success = window.makeFirstResponder(textView)
                print("📍 First responder success: \(success)")
                print("📍 Current first responder: \(window.firstResponder?.className ?? "none")")
                print("📍 Window is key after: \(window.isKeyWindow)")
            } else {
                print("⚠️ No window available for text view")
            }
        }
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ContextAwareTextView else {
            return
        }
        
        // Update text if it changed externally
        textView.updateText(viewModel.text)
        
        // Ensure text view can receive keyboard input
        if let window = textView.window, window.firstResponder != textView {
            print("📍 Making text view first responder in updateNSView")
            print("📍 Window is key: \(window.isKeyWindow)")
            
            let success = window.makeFirstResponder(textView)
            print("📍 First responder success: \(success)")
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        let viewModel: EditorViewModel
        
        init(viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }
        
        public func textDidChange(_ notification: Notification) {
            print("📋 Coordinator: textDidChange called")
            guard let textView = notification.object as? NSTextView else { return }
            
            // Sync changes to view model
            viewModel.text = textView.string
        }
        
        public func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            print("📋 Coordinator: shouldChangeTextIn called with replacement: '\(replacementString ?? "nil")'")
            // Allow all changes for now
            // We can add validation here if needed
            return true
        }
    }
}

#elseif os(iOS)
import UIKit

/// SwiftUI wrapper for iOS UITextView
/// This will be implemented in Phase 2
public struct EditorTextView: UIViewRepresentable {
    
    @ObservedObject var viewModel: EditorViewModel
    
    public init(viewModel: EditorViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        textView.delegate = context.coordinator
        return textView
    }
    
    public func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != viewModel.text {
            textView.text = viewModel.text
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    public class Coordinator: NSObject, UITextViewDelegate {
        let viewModel: EditorViewModel
        
        init(viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }
        
        public func textViewDidChange(_ textView: UITextView) {
            viewModel.text = textView.text
        }
    }
}

#endif

