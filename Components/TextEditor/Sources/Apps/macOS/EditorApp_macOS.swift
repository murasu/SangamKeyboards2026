// Sources/Apps/macOS/EditorApp_macOS.swift
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
import EditorCore
import EditorUI

@main
struct ContextAwareEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Additional activation when view appears
                    DispatchQueue.main.async {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.automatic)
        .commands {
            // Add custom menu commands here
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App did finish launching")
        
        // Force app activation
        NSApp.activate(ignoringOtherApps: true)
        
        // Use a timer to repeatedly try to activate until we succeed
        var attempts = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            attempts += 1
            print("🔄 Activation attempt \(attempts)")
            
            if let window = NSApp.windows.first {
                print("🪟 Found window, is key: \(window.isKeyWindow)")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                
                if window.isKeyWindow {
                    print("✅ Window successfully became key")
                    timer.invalidate()
                } else if attempts >= 10 {
                    print("❌ Failed to make window key after 10 attempts")
                    timer.invalidate()
                }
            } else if attempts >= 10 {
                print("❌ No window found after 10 attempts")
                timer.invalidate()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When app icon is clicked in dock, bring to front
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
        return !flag
    }
}

struct ContentView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider()
            
            // Main editor
            EditorTextView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onAppear {
            print("💫 ContentView appeared")
            
            // Force activation when the content view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("💫 Forcing app activation from ContentView")
                NSApp.activate(ignoringOtherApps: true)
                
                // Find our window and force it to become key
                if let window = NSApp.windows.first(where: { $0.contentView != nil }) {
                    print("💫 Found content window: \(window)")
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()  // Even more aggressive
                    print("💫 Window is key after orderFrontRegardless: \(window.isKeyWindow)")
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack {
            Text("Context-Aware Editor")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Character/word count
            HStack(spacing: 16) {
                Label("\(viewModel.text.count) chars", systemImage: "textformat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(wordCount) words", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var wordCount: Int {
        viewModel.text
            .split(whereSeparator: \.isWhitespace)
            .count
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Use VStack instead of Form for macOS 12 compatibility
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Prediction") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Auto-learn words", isOn: $viewModel.autoLearnEnabled)
                        
                        HStack {
                            Text("Max candidates: \(viewModel.maxCandidates)")
                            Stepper("", value: $viewModel.maxCandidates, in: 1...10)
                                .labelsHidden()
                        }
                    }
                    .padding(8)
                }
                
                GroupBox("Editor") {
                    Text("Font size, theme, etc. coming soon")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                }
            }
            .padding()
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

