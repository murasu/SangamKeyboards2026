//
//  ContextAwareEditorApp.swift
//  ContextAwareEditor
//
//  Created by Muthu Nedumaran on 22/10/2025.
//

import SwiftUI

@main
struct ContextAwareEditorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    SettingsPresenter.presentSettings()
                }
                .keyboardShortcut(",")
            }
        }
        #endif
    }
}
