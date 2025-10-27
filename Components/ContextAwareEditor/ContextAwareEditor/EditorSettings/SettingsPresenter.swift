import SwiftUI

#if os(macOS)
import AppKit
#endif

// MARK: - Settings Window/Sheet Presenter

struct SettingsPresenter {
    
    #if os(macOS)
    // Store window reference to prevent deallocation
    private static var settingsWindow: NSWindow?
    
    static func presentSettings() {
        // Close existing window if open
        settingsWindow?.close()
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Store reference to prevent deallocation
        settingsWindow = window
        
        // Clean up reference when window closes
        window.delegate = WindowCloseDelegate()
    }
    
    // Helper class to handle window cleanup
    private class WindowCloseDelegate: NSObject, NSWindowDelegate {
        func windowWillClose(_ notification: Notification) {
            settingsWindow = nil
        }
    }
    #endif
    
    #if os(iOS)
    @MainActor
    static func presentSettings(from presentingViewController: UIViewController) {
        let settingsView = SettingsView()
        let hostingController = UIHostingController(rootView: settingsView)
        
        let navigationController = UINavigationController(rootViewController: hostingController)
        navigationController.modalPresentationStyle = .pageSheet
        
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        presentingViewController.present(navigationController, animated: true)
    }
    #endif
}

// MARK: - SwiftUI Environment Key for Settings

private struct SettingsActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = { }
}

extension EnvironmentValues {
    var presentSettings: () -> Void {
        get { self[SettingsActionKey.self] }
        set { self[SettingsActionKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Modifier

struct SettingsViewModifier: ViewModifier {
    @State private var isSettingsPresented = false
    
    func body(content: Content) -> some View {
        content
            .environment(\.presentSettings) {
                #if os(iOS)
                isSettingsPresented = true
                #else
                SettingsPresenter.presentSettings()
                #endif
            }
            #if os(iOS)
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            #endif
    }
}

extension View {
    func withSettings() -> some View {
        modifier(SettingsViewModifier())
    }
}

// MARK: - Usage Examples

/*
 
 // In your main app view or content view:
 
 struct ContentView: View {
     @Environment(\.presentSettings) private var presentSettings
     
     var body: some View {
         VStack {
             // Your main content here
             
             Button("Settings") {
                 presentSettings()
             }
         }
         .withSettings() // Add this modifier to enable settings presentation
     }
 }
 
 // Alternative: Direct usage
 struct SomeView: View {
     var body: some View {
         Button("Open Settings") {
             #if os(macOS)
             SettingsPresenter.presentSettings()
             #else
             // You'll need a reference to the presenting view controller
             // This is typically handled by the withSettings() modifier above
             #endif
         }
     }
 }
 
 */